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
## A feature is the basic unit of testing.
Feature "Batch file generation" {
	## A feature can contain many scenarios.
	Scenario "Generate a file" {
		Given {
			## Arrange the test context.
		}
		
		When {
			## Act
			## e.g. Kick of an import and wait for it to complete.
		}

		Then {
			## Assert the outcome.
		}
	}
}
```

All parts are optional but the hierarchy _Feature > Scenario > Given, When, Then_ must be maintained. If Feature or Scenario is missing then the test will just be ignored.

## Variable Scope ##

If you want to access variables in parent scopes such as at the feature or scenario level you need to create a closure since the given, when and then blocks are executed much later than the feature or scenario blocks.

Powershell doesn't automatically create closures for every script block so you must add a call to _GetNewClosure()_ after each block. For example:

```Powershell
Feature "Closure support" {
	$customerFile = "customers.csv"

	Scenario "Access a variable" {
		[ref] $count = 0

		Given {
			## Customer records
            $customers = @(
                @{ CustomerId = 1; Name = "John Smith"; }
                @{ CustomerId = 2; Name = "Robert Johnson"; }
            )

            ## Write the records to the csv file.
            $customers | 
                % { Write-Output (New-Object PSObject -Property $_) } | 
                Export-Csv -NoTypeInformation -Path $customerFile	
		}.GetNewClosure()

        When {
            $value = 0;
            ## Count the records in the file.
            Import-Csv -Path $customerFile | % { $value += 1 }
            
            ## Update the ref value with the count.
            $count.value = $value
            
		}.GetNewClosure()
        
        Then {
            ## Check that the file contained the right number of rows.
            Assert-Equal 2 $count.value
            
            ## Clean up.
            Remove-Item $customerFile
        }.GetNewClosure()	
	}
}
```

NB: if you want to modify a variable you should declare it as _[ref]_ since closures copy by value.

# Running Tests #

Most of posh-gwen is contained in a Powershell module but there is also a folder suite runner that will pipe all the .ps1 files in a specified folder to the test runner:

```Powershell
PS> .\gwen.ps1 -suitePath .\Specs
```

If you want more control over which tests are run and how the output is processed you need to Invoke-Gwen directly.

The contents of gwen.ps1 are a good guide to calling Invoke-Gwen directly. Basically you should pipe the tests you are interested in to the Invoke-Gwen function which will in turn output a set of test results for you to process:

```Powershell
$results = @()
$failureCount = 0

Get-ChildItem $suitePath -Filter $filter | Invoke-Gwen | % {
    $results += $_
    
    ## This supports the internal testing framework.
    if ($_.File.EndsWith("_should_fail.ps1")) {
        $_.Failed = -not $_.Failed
    }
    
    if ($_.Failed) {
        $failureCount += 1
        Write-Host "F" -ForeGroundColor Red -NoNewLine
    } else {
        Write-Host "." -ForeGroundColor Green -NoNewLine
    }
}

Write-Host ""

$results | % {
    if ($_.Failed) {
        Write-Host "$($_.feature) - $($_.scenario)...failed" -ForegroundColor Red
        $_.Errors | % { Write-Host $_ -ForegroundColor Red }
    } else {
        Write-Host "$($_.feature) - $($_.scenario)...passed" -ForegroundColor Green
    }
}
```
