Feature "Batch file generation" {
    Scenario "Generate a file" {
        $customerFile = "customer.csv"
        
        [ref] $count = $null
        
        Given {
            ## Customer records
            $customers = @(
                @{ CustomerId = 1; Name = "John Smith"; }
                @{ CustomerId = 2; Name = "Robert Johnson"; }
            )

            $customers | 
                % { Write-Output (New-Object PSObject -Property $_) } | 
                Export-Csv -NoTypeInformation -Path $customerFile
        }.GetNewClosure()

        When {
            $value = 0;
            Import-Csv -Path $customerFile | % { $value += 1 }
            $count.value = $value
        }.GetNewClosure()
        
        Then {
            Assert-Equal 2 $count.value
            Remove-Item $customerFile
        }.GetNewClosure()
    }
}