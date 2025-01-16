module tests;

import std;
import http;

void test_0001()
{
   auto test = HttpTest("Minimal HTTP/1.0 request");
   test.run("GET / HTTP/1.0\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].httpVersion != "HTTP/1.0") { test.error = "Wrong HTTP version: " ~ test.result.responses[0].httpVersion.to!string; }
   else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0002()
{
   auto test = HttpTest("Partial HTTP/1.1 request #1");
   test.run("GET / HTTP/1.1\r\0\nConnection: close\r\nHost: \0localhost\r\n\0\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0003()
{
   auto test = HttpTest("Partial HTTP/1.1 request #2");
   test.run("G\0E\0T\0 / \0H\0TTP/1.1\r\0\n\0Conne\0ction\0: cl\0ose\0\r\nHo\0st:\0 \0loca\0lhost\r\0\n\0\r\0\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0004()
{
   auto test = HttpTest("Malformed HTTP request #1");
   test.run("GET / HTTP/1.0\r\nmalformed\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0005()
{
   auto test = HttpTest("Malformed HTTP request #2");
   test.run("GAS / HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0006()
{
   auto test = HttpTest("Malformed HTTP request #3");
   test.run("GET HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0007()
{
   auto test = HttpTest("Malformed HTTP request #4");
   test.run("GET / / HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0008()
{
   auto test = HttpTest("Malformed HTTP request #5");
   test.run("GET invalid.html HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0009()
{
   auto test = HttpTest("Malformed HTTP request #6");
   test.run("GET / HTTP/1.1\r\n:\r\nconnection: close\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0010()
{
   auto test = HttpTest("Invalid header #1");
   test.run("GET / HTTP/1.1\r\nX-invalid-è: test\r\nhost: localhost\r\nconnection: close\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0011()
{
   auto test = HttpTest("Invalid header #2");
   test.run("GET / HTTP/1.1\r\nX-invalid: è\r\nhost: localhost\r\nconnection: close\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0012()
{
   auto test = HttpTest("Valid empty header");
   test.run("GET / HTTP/1.1\r\nEmpty:\r\nhost: localhost\r\nconnection: close\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0013()
{
   auto test = HttpTest("Missing HTTP/1.1 host");
   test.run("GET / HTTP/1.1\r\nconnection: close\r\n\r\n");

   if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0014()
{
   auto test = HttpTest("Wrong HTTP version");
   test.run("GET / HTTP/1.3\r\nHost: localhost\r\n\r\n");

   if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0015()
{
   auto test = HttpTest("Connection: keep-alive");
   test.run("GET / HTTP/1.1\r\nHost: localhost\r\nConnection: keep-alive\r\n\r\n");

   if (test.result.status != ResultStatus.KEEP_ALIVE) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }


   test.print();
}

void test_0016()
{
   auto test = HttpTest("Connection: keep-alive is default for HTTP/1.1");
   test.run("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n");

   if (test.result.status != ResultStatus.KEEP_ALIVE) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0017()
{
   auto test = HttpTest("Connection: close is default for HTTP/1.0");
   test.run("GET / HTTP/1.0\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }


   test.print();
}

void test_0018()
{
   auto test = HttpTest("Connection: close");
   test.run("GET / HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }


   test.print();
}

void test_0019()
{
   auto test = HttpTest("Mixed case headers");
   test.run("GET / HTTP/1.1\r\nHost: localhost\r\nConNecTion: CLose\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0020()
{
   auto test = HttpTest("Headers without space between colon and value");
   test.run("GET / HTTP/1.1\r\nHost: localhost\r\nconnection:close\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0021()
{
   auto test = HttpTest("Date header is mandatory for HTTP/1.1");
   test.run("GET / HTTP/1.1\r\nHost: localhost\r\nconnection: close\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (!("date" in test.result.responses[0].headers)) { test.error = "Date header not found"; }
   else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0022()
{
   auto test = HttpTest("100-continue with GET");
   test.run("GET / HTTP/1.1\r\nHost: localhost\r\nExpect: 100-continue\r\nconnection: close\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0023()
{
   auto test = HttpTest("100-continue with POST");
   test.run("POST /user HTTP/1.1\r\nHost: localhost\r\nContent-Length: 100\r\nExpect: 100-continue\r\nconnection: close\r\n\r\n");

   if (test.result.responses.length < 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "100") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0024()
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

void test_0025()
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

void test_0027()
{
   auto test = HttpTest("Multipart post");

   auto postBody = "--123\r\nContent-Disposition: form-data; name=\"field1\"\r\n\r\nHello World\r\n--123--\r\n";
   test.run("POST /user HTTP/1.1\r\nHost: localhost\r\nconnection: close\r\ncontent-type: multipart/form-data; boundary=123\r\ncontent-length: " ~ postBody.length.to!string ~ "\r\n\r\n" ~ postBody);

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0028()
{
   auto test = HttpTest("Invalid multipart post");

   auto postBody = "--123\r\nContent-Disposition: form-data; name=\"field1\"\r\n\r\nHello World\r\n";;
   test.run("POST /user HTTP/1.1\r\nHost: localhost\r\nconnection: close\r\ncontent-type: multipart/form-data; boundary=123\r\ncontent-length: " ~ postBody.length.to!string ~ "\r\n\r\n" ~ postBody);

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0029()
{
   auto test = HttpTest("Wrong line terminator");
   test.run("GET / HTTP/1.1\rHost: localhost\rConnection: close\r\n\r\n");
   if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0030()
{
   auto test = HttpTest("Wrong line terminator");
   test.run("GET / HTTP/1.1\nHost: localhost\nConnection: close\r\n\r\n");
   if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0031()
{
   auto test = HttpTest("Missing HTTP version");
   test.run("GET / \r\nHost: localhost\r\nConnection: close\r\n\r\n");
   if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0032()
{
   auto test = HttpTest("Wrong protocol");
   test.run("GET / SIP/2.0\r\nHost: localhost\r\n\r\n");
   if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0033()
{
   auto test = HttpTest("Empty request");
   test.run("\r\n\r\n");
   if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0034()
{
   auto test = HttpTest("Lowercase method");
   test.run("get / HTTP/1.1\r\nConnection: close\r\nhost: localhost\r\n\r\n");
   if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0035()
{
   auto test = HttpTest("Bad content length (negative)");
   test.run("POST / HTTP/1.1\r\nConnection: close\r\nhost: localhost\r\nContent-length: -1\r\n\r\n");
   if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0036()
{
   auto test = HttpTest("Bad content-length (zzz)");
   test.run("POST /user HTTP/1.1\r\nConnection: close\r\nhost: localhost\r\nContent-length: zzz\r\n\r\n");
   if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0037()
{
   auto test = HttpTest("Bad content-length (fake hex)");
   test.run("POST /user HTTP/1.1\r\nConnection: close\r\nhost: localhost\r\nContent-length: ff\r\n\r\n");
   if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0038()
{
   enum hundred_tb = 100_000_000_000_000;

   // Sending 100TB file (not really)
   auto test = HttpTest("Fill up server's memory and/or disk? (100TB request)");
   auto bodyReader = new class BodyReader
   {
      size_t size = 1024*1024*5;   // Sending just 5MB, I don't want kill the server for real
      size_t remaining() { return size; }
      char[] chunk(size_t sz) { auto data = 'a'.repeat(sz).to!(char[]); this.size -= data.length; return data; }
   };

   test.run("POST /user HTTP/1.1\r\nConnection: close\r\nhost: localhost\r\nContent-length: " ~ hundred_tb.to!string ~ "\r\n\r\n", bodyReader);

   if (test.result.status == ResultStatus.DATA_NOT_SENT) { test.error = "Data not sent"; }
   else if (test.result.status == ResultStatus.KEEP_ALIVE && test.result.responses.length == 0) { test.error = "Server is not blocking data sending?"; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400" && test.result.responses[0].status != "413") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }
   else test.message = "Returned status: " ~ test.result.responses[0].status.to!string;

   test.print();
}

void test_0039()
{
   enum four_gb = 4_000_000_000;

   // Sending 4GB file
   auto test = HttpTest("Fill up server's memory and/or disk? (4GB request)");
   auto bodyReader = new class BodyReader
   {
      size_t size = 1024*1024*5;   // Sending just 5MB, I don't want kill the server for real
      size_t remaining() { return size; }
      char[] chunk(size_t sz) { auto data = 'a'.repeat(sz).to!(char[]); this.size -= data.length; return data; }
   };

   test.run("POST /user HTTP/1.1\r\nConnection: close\r\nhost: localhost\r\nContent-length: " ~ four_gb.to!string ~ "\r\n\r\n", bodyReader);
   if (test.result.status == ResultStatus.DATA_NOT_SENT) { test.error = "Data not sent"; }
   else if (test.result.status == ResultStatus.KEEP_ALIVE && test.result.responses.length == 0) { test.error = "Server is not blocking data sending?"; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "400" && test.result.responses[0].status != "413") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }
   else test.message = "Returned status: " ~ test.result.responses[0].status.to!string;

   test.print();
}

void test_0040()
{
   enum one_kb = 1024;

   // Sending 1kb file
   auto test = HttpTest("Sending just one kb, should be ok");
   auto bodyReader = new class BodyReader
   {
      size_t size = one_kb;   // Sending just one kb
      size_t remaining() { return size; }
      char[] chunk(size_t sz) { auto data = 'a'.repeat(sz).to!(char[]); this.size -= data.length; return data; }
   };

   test.run("POST /user HTTP/1.1\r\nConnection: close\r\nhost: localhost\r\nContent-length: " ~ one_kb.to!string ~ "\r\n\r\n", bodyReader);
   if (test.result.status == ResultStatus.DATA_NOT_SENT) { test.error = "Data not sent"; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}

void test_0041()
{
   auto randomId = uniform(150, 999).to!string;
   auto test = HttpTest("Sanity check #1");
   test.run("GET /user/" ~ randomId ~ " HTTP/1.1\r\nConnection: close\r\nHost: localhost\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }
   else if (test.result.responses[0].body != randomId) { test.error = "Wrong body: " ~ test.result.responses[0].body.to!string; }
   else test.message = "Url: /user/" ~ randomId ~ " Returned body: " ~ test.result.responses[0].body.to!string;
   test.print();
}

void test_0042()
{
   auto randomId = uniform(150, 999).to!string;
   auto randomKey = iota(uniform(4,8)).map!(i => uniform('a', 'z')).array.to!string;
   auto randomValue = iota(uniform(4,8)).map!(i => uniform('a', 'z')).array.to!string;

   auto url = "/user/" ~ randomId ~ "?" ~ randomKey ~ "=" ~ randomValue;
   auto test = HttpTest("Sanity check #2");
   test.run("GET " ~ url ~ " HTTP/1.1\r\nConnection: close\r\nHost: localhost\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }
   else if (test.result.responses[0].body != randomId) { test.error = "Wrong body: " ~ test.result.responses[0].body.to!string; }
   else test.message = "Url: " ~ url ~ " Returned body: " ~ test.result.responses[0].body.to!string;
   test.print();
}

void test_0043()
{
   auto randomId = iota(uniform(4,8)).map!(i => uniform('a', 'z')).array.to!string;
   auto test = HttpTest("Sanity check #3");
   test.run("GET /user/" ~ randomId ~ " HTTP/1.1\r\nConnection: close\r\nHost: localhost\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "200") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }
   else if (test.result.responses[0].body != randomId) { test.error = "Wrong body: " ~ test.result.responses[0].body.to!string; }
   else test.message = "Url: /user/" ~ randomId ~ " Returned body: " ~ test.result.responses[0].body.to!string;

   test.print();
}


void test_0044()
{
   auto test = HttpTest("Sanity check #4 (404)");
   test.run("GET /not-found HTTP/1.1\r\nConnection: close\r\nHost: localhost\r\n\r\n");

   if (test.result.status != ResultStatus.CLOSED) { test.error = "Error: " ~ test.result.status.to!string; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "404") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }

   test.print();
}


void test_0045()
{
   auto test = HttpTest("Long first line (DoS attack?)");

   auto bodyReader = new class BodyReader
   {
      size_t size = 1024*1024*50; // 50MB
      size_t remaining() { return size; }
      char[] chunk(size_t sz) { auto data = 'a'.repeat(sz).to!(char[]); this.size -= data.length; return data; }
   };

   test.run("\0", bodyReader);

   if (test.result.status == ResultStatus.SLOW_RESPONSE) { test.error = "Upload was taking too long. Freezed?"; }
   else if (test.result.status == ResultStatus.KEEP_ALIVE && test.result.responses.length == 0) { test.error = "Not blocking data sending?"; }
   else if (test.result.status == ResultStatus.DATA_NOT_SENT) { test.error = "Slow upload. Is server freezing?"; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "431" && test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }
   else test.message = "Returned status: " ~ test.result.responses[0].status.to!string;

   test.print();
}

void test_0046()
{
   auto test = HttpTest("Long headers (DoS attack?)");

   auto bodyReader = new class BodyReader
   {
      size_t size = 1024*1024*50; // 50MB
      size_t remaining() { return size; }
      char[] chunk(size_t sz) { auto data = 'a'.repeat(sz).to!(char[]); this.size -= data.length; return data; }
   };

   test.run("GET / HTTP/1.0\r\n", bodyReader);

   if (test.result.status == ResultStatus.SLOW_RESPONSE) { test.error = "Upload was taking too long. Freezed?"; }
   else if (test.result.status == ResultStatus.DATA_NOT_SENT) { test.error = "Slow upload. Is server freezing?"; }
   else if (test.result.status == ResultStatus.KEEP_ALIVE && test.result.responses.length == 0) { test.error = "Not blocking data sending?"; }
   else if (test.result.responses.length != 1) { test.error = "Wrong number of responses: " ~ test.result.responses.length.to!string; }
   else if (test.result.responses[0].status != "431" && test.result.responses[0].status != "400") { test.error = "Wrong status: " ~ test.result.responses[0].status.to!string; }
   else test.message = "Returned status: " ~ test.result.responses[0].status.to!string;
   test.print();
}

void test_0047()
{
   auto test = HttpTest("Check \"connection:\" header");

   auto subtests = [
      HttpTest("Check connection: k"),
      HttpTest("Check connection: c"),
      HttpTest("Check connection: a"),
      HttpTest("Check connection: cloes"),
      HttpTest("Check connection: Keep-"),
      HttpTest("Check connection: Cl")
   ];

   foreach (ref subtest; subtests)
   {
      subtest.run("GET / HTTP/1.1\r\nConnection: k\r\nHost: localhost\r\n\r\n");
   }

   auto r = subtests[0].result.status;

   foreach (subtest; subtests[1..$])
      if (subtest.result.status != r || r == ResultStatus.SOCKET_EXCEPTION) { test.error = "Unmatched connection status"; }

   if (test.passed)
      test.message = "Connection status: " ~ r.to!string;

   test.print();
}