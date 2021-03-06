## A feature is the basic unit of testing.
Feature "Batch file generation" {

    ## A feature can contain many scenarios.
    Scenario "Generate a file" {
    
        ## This is a scenario scoped variable.
        $customerFile = "customer.csv"

        ## This is also a scenario scoped but we want to modify
        ## the value in the gwens so it must be a [ref]
        [ref] $count = $null
        
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
                
        ## So unfortunately, Powershell script blocks are not automatically
        ## closures so if you want to use any scenario or feature variables
        ## then you need to add this .GetNewClosure() call to the end of
        ## the script block.
        }.GetNewClosure()

        When {
            $value = 0;
            ## Count the records in the file.
            Import-Csv -Path $customerFile | % { $value += 1 }
            
            ## Update the ref value with the count.
            $count.value = $value
            
        ## Again with the closure which sucks a little every time you
        ## have to type it. Suggestions for avoiding the call are welcome.
        }.GetNewClosure()
        
        Then {
            ## Check that the file contained the right number of rows.
            Assert-Equal 2 $count.value
            
            ## Clean up.
            Remove-Item $customerFile
        }.GetNewClosure()
    }
}