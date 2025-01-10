# http-validator

A simple test suite designed to validate whether your HTTP server implementation adheres to standard HTTP specifications. This tool runs a series of tests to verify compliance with HTTP/1.1 protocol requirements, checking basic functionality like proper header handling, status codes, and request/response formats.

### How to run

1. Install a D compiler from [dlang.org](https://dlang.org)
2. Run the tests using dub: `dub` or `dub -- --port 8080 --host localhost`
