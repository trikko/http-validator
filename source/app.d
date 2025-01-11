import std;
import http;
import tests;



// Main function with test cases
int main(string[] args)
{

	// Parse command line arguments
	auto info = getopt(
		args,
		"host",   &(HttpTest.HOST),
		"port",   &(HttpTest.PORT)
	);

	if (info.helpWanted)
	{
		defaultGetoptPrinter("http-tester", info.options);
		return -1;
	}


	foreach (string memberName; __traits(allMembers, tests))
	{
		static if (memberName.startsWith("test_"))
		{
			// Get the function pointer
			auto func = &__traits(getMember, tests, memberName);
			// Call the function
			func();
		}
	}

	// Test cases follow this pattern:
	// 1. Create test with descriptive name
	// 2. Send HTTP request
	// 3. Verify response matches expectations
	// 4. Print results

/+
	{
		auto test = HttpTest("Test case description");
		test.run("HTTP REQUEST STRING");

		// Verify conditions
		if (check) { test.error = "Error message"; }

		test.print();
	}
+/


	return 0;
}
