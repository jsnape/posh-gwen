posh-gwen
=========

Powershell behaviour driven testing of batch systems.

# Overview #

It is difficult to test batch systems using modern test frameworks such as [Specflow](http://www.specflow.org) or [FitNesse](http://www.fitnesse.org/) because of the simple rule that good tests should be isolated from one another. All these frameworks run tests in sequence:

- do something
- check something
- clean up
- move on to the next test

For this to be successful each test has to run very fast. Most batch processing systems are optimised for bulk processing of data. They may take tens of seconds to run end to end even with a single row of data so running hundreds of tests independently can take hours.

This framework is designed to break the rule of sequential test execution. All tests are run in parallel by phase.

# Workflow #

The best way to test batch processing is for a known input to contain many test cases. The batch is run loading all data at once. Finally a number of queries are executed against the resulting system. So for example a data warehouse might load a number of source files using an [ETL framework](http://en.wikipedia.org/wiki/Extract,_transform,_load) such as [SQL Server Integration Services](http://msdn.microsoft.com/en-us/library/ms141026.aspx). Once loaded the data warehouse can be queried to check that expected values exist in the final system.

# Test Isolation #

It is still important to ensure that individual tests are isolated from each other or else changes in one might cause a number of others to fail or become invalid.

The best way to do this for batch processing is by **data isolation** - that is to carve up data domains in a way that only a single test uses data from that domain. Then verifications of the result force the query to execute against that test specific sub-domain.

There are a number of suitable domains to use but any with high cardinality are best:

- **Dates** - each day is a single test (or blocks of days, weeks, years etc. for those tests that need to span days).
- **Transaction identifiers** - use a map of IDs to test cases or in the case of strings prefix the transaction id with the test case number.
- **Business keys** - for entities such as customer or product there is usually an ID field used as the business key; use the same methods as transaction identifiers.
- **Custom attributes** - if none of the above will work then you might consider adding an additional attribute to the source data which is passed through the batch system. Obviously this is not a preferred solution single you will have to modify your system.
- Combinations of the above - sometimes depending on where you need to validate you might need multiple solutions.

# Writing Tests #

Tests are written in Powershell and can use just about any Powershell feature. The basic test looks like:

```Powershell
Feature "Batch file generation" {
	Scenario "Generate a file" {
		Given {
		}
		
		When {
		}

		Then {
		}
	}
}
```

All parts are optional but the hierarchy _Feature > Scenario > Given, When, Then_ must be maintained. If Feature or Scenario is missing then the test will just be ignored.

# Running Tests #

Most of posh-gwen is contained in a Powershell module but there is also a folder suite runner that will pipe all the .ps1 files in a specified folder to the test runner:

```Powershell
PS> .\gwen.ps1 -suitePath .\Specs
```

If you want more control over which tests are run and how the output is processed you need to Invoke-Gwen directly.

TODO TODO TODO.