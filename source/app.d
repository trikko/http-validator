import std;
import consolecolors;
import core.thread;

// Global configuration
short PORT = 3000;
string HOST = "localhost";

// Structure to hold HTTP test results
struct Result
{
	HttpResponse[] 	responses;   // Array of HTTP responses received
	Duration 			duration;    // Test execution time
	ResultStatus 		status;      // Final status of the test
}

// Structure to parse and store HTTP response components
struct HttpResponse
{
	char[] httpVersion;         // HTTP version (e.g., HTTP/1.1)
	char[] status;             // Status code (e.g., 200, 404)
	char[] reason;             // Status reason (e.g., OK, Not Found)
	string[string] headers;    // Response headers
	char[] body;              // Response body
}

// Possible test result statuses
enum ResultStatus
{
	CLOSED = 0,               // Connection closed normally
	KEEP_ALIVE = 1,          // Connection kept alive
	MISSING_HEADERS = 2,     // Response headers not found
	MISSING_HTTP_VERSION = 3, // HTTP version not found in response
	BAD_STATUS_LINE = 4,     // Malformed status line
	MISSING_BODY = 5,        // Response body missing
	BAD_CHUNKED_BODY = 6,    // Malformed chunked encoding
	SOCKET_EXCEPTION = 7     // Socket connection error
}

// Main test structure
struct HttpTest
{
	string 	name;
	bool 		passed;
	string 	message;

	Result 	result;

	void print()
	{
		if (passed) cwrite("[ <green>OK</green> ] <white>", name, "</white>");
		else cwrite("[<red>FAIL</red>] <white>", name, "</white>");

		if (message.length > 0) cwrite(" <gray>(", message, ")</gray>");

		cwriteln(" <yellow>", result.duration.total!"msecs", "ms</yellow>");
	}

	@disable this();

	this(string name) { this.name = name; }

	void error(string message)
	{
		passed = false;
		this.message = message;
	}

	void run(string request, Duration timeout = 1000.msecs)
	{
		// Optimistic
		passed = true;

		// Setup socket connection
		auto tm = Clock.currTime;
		auto socket = new TcpSocket(AddressFamily.INET);
		scope(exit) socket.close();

		// Try to connect to server
		try {
			socket.setOption(SocketOptionLevel.SOCKET, SocketOption.RCVTIMEO, 100.msecs);
			socket.connect(new InternetAddress(HOST, PORT));
		}
		catch(Exception e)
		{
			result.duration = 0.msecs;
			result.status = ResultStatus.SOCKET_EXCEPTION;
			return;
		}

		// Send request in chunks if split by null bytes
		foreach (idx, chunk; request.split("\0"))
		{
			if (idx > 0)
				Thread.sleep(5.msecs);
			socket.send(chunk);
		}

		// Read and parse response
		char[] response;
		char[1024] buffer;

		while (true)
		{
			auto received = socket.receive(buffer);
			if (received <= 0)
			{
				if (received == -1)
				{
					// Socket timeout, every 100ms
					if (Clock.currTime - tm > timeout)
					{
						// We hit the timeout
						result.status = ResultStatus.KEEP_ALIVE;
						break;
					}
					else continue;
				}

				// Request completed
				else break;
			}
			response ~= buffer[0..received];
		}

		// How much does it takes?
		result.duration = Clock.currTime - tm;

		// Parse all responses
		while(!response.empty)
		{
			// Find the end of headers
			auto headersEnd = response.indexOf("\r\n\r\n");

			// If headers not found, something went wrong
			if (headersEnd == -1)
			{
				result.status = ResultStatus.MISSING_HEADERS;
				break;
			}

			// Get current response
			auto current = response[0..headersEnd + 2];
			response = response[headersEnd + 4..$];

			// Check if it's HTTP/1.x
			if (!current.startsWith("HTTP/1."))
			{
				result.status = ResultStatus.MISSING_HTTP_VERSION;
				break;
			}

			// Parse the first line of the response
			auto firstLine = current.matchFirst("^(HTTP/1.[0-9]) ([0-9]{3}) ?([^\r\n]*)\r\n");

			// If first line do not match, something went wrong
			if (!firstLine)
			{
				result.status = ResultStatus.BAD_STATUS_LINE;
				break;
			}

			// Parse HTTP version, status code, and reason
			auto httpVersion = firstLine[1];
			auto httpStatus = firstLine[2];
			auto httpReason = firstLine[3];

			// Remove the first line from the current response
			current = current[firstLine[0].length..$];

			auto headers = current.matchAll("([^:]*): ?(.*)\r\n");

			// Create a new HttpResponse structure
			HttpResponse currentHttpResponse;
			currentHttpResponse.httpVersion = httpVersion;
			currentHttpResponse.status = httpStatus;
			currentHttpResponse.reason = httpReason;

			// Parse headers
			foreach (header; headers)
				currentHttpResponse.headers[cast(string)header[1].toLower] = cast(string)header[2];

			// If content-length header is present, check if body is present
			if ("content-length" in currentHttpResponse.headers)
			{
				// Get content length
				auto contentLength = currentHttpResponse.headers["content-length"].to!int;

				// If content length is greater than 0, check if body is present
				if (contentLength > 0)
				{
					// If body is not present, something went wrong
					if (response.length < contentLength)
					{
						result.status = ResultStatus.MISSING_BODY;
						break;
					}

					currentHttpResponse.body = response[0..contentLength];
					response = response[contentLength..$];
				}
			}
			else if ("transfer-encoding" in currentHttpResponse.headers && currentHttpResponse.headers["transfer-encoding"].toLower == "chunked")
			{
				// If transfer-encoding is chunked, read body in chunks
				while(!response.empty)
				{
					// Read the size of the chunk
					auto chunkSizeChars = response.matchFirst("^([0-9a-fA-F]+)\r\n");

					// If chunk size is not found, something went wrong
					if (!chunkSizeChars)
					{
						result.status = ResultStatus.BAD_CHUNKED_BODY;
						break;
					}

					// Get chunk size
					auto chunkSize = chunkSizeChars[1].to!int(16);

					// Read chunk
					auto chunk = response[0..chunkSize];

					// If chunk size is 0, we've reached the end of the body
					if (chunkSize == 0)
						break;

					// Remove the chunk from the response
					response = response[chunkSize + 2..$];

					// Append chunk to the body
					currentHttpResponse.body ~= chunk;
				}
			}

			// Add current response to the list
			result.responses ~= currentHttpResponse;
		}
	}
}

// Main function with test cases
int main(string[] args)
{
	// Parse command line arguments
	auto info = getopt(
		args,
		"host",   &HOST,
		"port",   &PORT
	);

	if (info.helpWanted)
	{
		defaultGetoptPrinter("http-tester", info.options);
		return -1;
	}

	// Test cases follow this pattern:
	// 1. Create test with descriptive name
	// 2. Send HTTP request
	// 3. Verify response matches expectations
	// 4. Print results

	{
		auto test = HttpTest("Test case description");
		test.run("HTTP REQUEST STRING");

		// Verify conditions
		if (condition) { test.error = "Error message"; }

		test.print();
	}

	{
		auto test = HttpTest("Minimal HTTP/1.0 request");
		test.run("GET / HTTP/1.0\r\n\r\n");

		if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].httpVersion != "HTTP/1.0") { test.error = "Wrong HTTP version: " ~ test.result.responses[0].httpVersion.to!string; }
		else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("Partial HTTP/1.1 request #1");
		test.run("GET / HTTP/1.1\r\0\nConnection: close\r\nHost: \0localhost\r\n\0\r\n");

		if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("Partial HTTP/1.1 request #2");
		test.run("G\0E\0T\0 / \0HTTP/1.1\r\0\n\0Connection: close\0\r\nHost: \0localhost\r\0\n\0\r\0\n");

		if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("Malformed HTTP request #1");
		test.run("GET / HTTP/1.0\r\nmalformed\r\n\r\n");

		if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("Malformed HTTP request #2");
		test.run("GAS / HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n");

		if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("Malformed HTTP request #3");
		test.run("GET HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n");

		if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("Malformed HTTP request #4");
		test.run("GET / / HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n");

		if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("Malformed HTTP request #5");
		test.run("GET invalid.html HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n");

		if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("Malformed HTTP request #6");
		test.run("GET / HTTP/1.1\r\n:\r\nconnection: close\r\n\r\n");

		if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("Invalid header #1");
		test.run("GET / HTTP/1.1\r\nX-invalid-è: test\r\nhost: localhost\r\nconnection: close\r\n\r\n");

		if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("Invalid header #2");
		test.run("GET / HTTP/1.1\r\nX-invalid: è\r\nhost: localhost\r\nconnection: close\r\n\r\n");

		if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("Valid empty header");
		test.run("GET / HTTP/1.1\r\nEmpty:\r\nhost: localhost\r\nconnection: close\r\n\r\n");

		if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("Missing HTTP/1.1 host");
		test.run("GET / HTTP/1.1\r\nconnection: close\r\n\r\n");

		if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("Wrong HTTP version");
		test.run("GET / HTTP/1.3\r\n\r\n");

		if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("Connection: keep-alive");
		test.run("GET / HTTP/1.1\r\nHost: localhost\r\nConnection: keep-alive\r\n\r\n");

		if (test.result.status != ResultStatus.KEEP_ALIVE) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }


		test.print();
	}

	{
		auto test = HttpTest("Connection: keep-alive is default for HTTP/1.1");
		test.run("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n");

		if (test.result.status != ResultStatus.KEEP_ALIVE) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("Connection: close is default for HTTP/1.0");
		test.run("GET / HTTP/1.0\r\n\r\n");

		if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }


		test.print();
	}

	{
		auto test = HttpTest("Connection: close");
		test.run("GET / HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n");

		if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }


		test.print();
	}

	{
		auto test = HttpTest("Mixed case headers");
		test.run("GET / HTTP/1.1\r\nHost: localhost\r\nConNecTion: CLose\r\n\r\n");

		if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("Headers without space between colon and value");
		test.run("GET / HTTP/1.1\r\nHost: localhost\r\nconnection:close\r\n\r\n");

		if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("Date header is mandatory for HTTP/1.1");
		test.run("GET / HTTP/1.1\r\nHost: localhost\r\nconnection: close\r\n\r\n");

		if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (!("date" in test.result.responses[0].headers)) { test.error = "Date header not found"; }
		else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("100-continue with GET");
		test.run("GET / HTTP/1.1\r\nHost: localhost\r\nExpect: 100-continue\r\nconnection: close\r\n\r\n");

		if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("100-continue with POST");
		test.run("POST / HTTP/1.1\r\nHost: localhost\r\nContent-Length: 100\r\nExpect: 100-continue\r\nconnection: close\r\n\r\n");

		if (test.result.responses.length < 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "100") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("Basic pipelined request");
		test.run("GET / HTTP/1.1\r\nHost: localhost\r\nconnection: keep-alive\r\n\r\nGET / HTTP/1.1\r\nHost: localhost\r\nconnection: keep-alive\r\n\r\nGET / HTTP/1.1\r\nHost: localhost\r\nconnection: keep-alive\r\n\r\nGET / HTTP/1.1\r\nHost: localhost\r\nconnection: keep-alive\r\n\r\n");

		if (test.result.status != ResultStatus.KEEP_ALIVE) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 4) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }
		else if (test.result.responses[1].status != "200") { test.error = "Wrong status: " ~ test.result.responses[1].status.to!string; }
		else if (test.result.responses[2].status != "200") { test.error = "Wrong status: " ~ test.result.responses[2].status.to!string; }
		else if (test.result.responses[3].status != "200") { test.error = "Wrong status: " ~ test.result.responses[3].status.to!string; }

		test.print();
	}

	{
		auto test = HttpTest("Partial pipelined request");
		test.run("GET / HTTP/1.1\r\nHost: localh\0ost\r\nconnection: keep-alive\r\n\r\n\0GET / HTTP/1.1\r\nHost: localhost\r\n\0connection: keep-alive\r\n\0\r\nGET / HTTP/1.1\r\nHost: localhost\r\nconnection: keep-alive\r\n\r\nGE\0T / HTTP/1.1\r\n\0Host: localhost\r\nconnection: keep-alive\r\n\r\n");

		if (test.result.status != ResultStatus.KEEP_ALIVE) { test.error = "Error: " ~ test.result.status.to!string; }
		else if (test.result.responses.length != 4) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
		else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }
		else if (test.result.responses[1].status != "200") { test.error = "Wrong status: " ~ test.result.responses[1].status.to!string; }
		else if (test.result.responses[2].status != "200") { test.error = "Wrong status: " ~ test.result.responses[2].status.to!string; }
		else if (test.result.responses[3].status != "200") { test.error = "Wrong status: " ~ test.result.responses[3].status.to!string; }

		test.print();
	}

	return 0;
}
