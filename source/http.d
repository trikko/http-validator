module http;

import std;

import consolecolors;
import core.thread;

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
	char[] httpVersion;       // HTTP version (e.g., HTTP/1.1)
	char[] status;            // Status code (e.g., 200, 404)
	char[] reason;            // Status reason (e.g., OK, Not Found)
	string[string] headers;   // Response headers
	char[] body;              // Response body
}

// Possible test result statuses
enum ResultStatus
{
	CLOSED = 0,              	// Connection closed normally
	KEEP_ALIVE = 1,         	// Connection kept alive
	MISSING_HEADERS = 2,    	// Response headers not found
	MISSING_HTTP_VERSION = 3, 	// HTTP version not found in response
	BAD_STATUS_LINE = 4,    	// Malformed status line
	MISSING_BODY = 5,       	// Response body missing
	BAD_CHUNKED_BODY = 6,   	// Malformed chunked encoding
	SOCKET_EXCEPTION = 7    	// Socket connection error
}

// Main test structure
struct HttpTest
{
   static short PORT = 3000;
   static string HOST = "localhost";

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

	void run(string request, Duration timeout = 100.msecs)
	{
		// Optimistic
		passed = true;

		// Setup socket connection
		auto tm = Clock.currTime;
		auto socket = new TcpSocket(AddressFamily.INET);
		scope(exit) socket.close();

		// Try to connect to server
		try {
			socket.setOption(SocketOptionLevel.SOCKET, SocketOption.RCVTIMEO, 10.msecs);
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

      auto original = response;

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

               response = response[chunkSizeChars[1].length..$];

					// Get chunk size
					auto chunkSize = chunkSizeChars[1].to!int(16);

					// Read chunk
               if (chunkSize > response.length)
               {
                  result.status = ResultStatus.BAD_CHUNKED_BODY;
                  break;
               }
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