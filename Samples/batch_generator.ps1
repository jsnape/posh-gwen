Feature "Batch file generation" {
    Scenario "Generate a file" {
        $customerFile = "customer.csv"
        
        Given {
            ## Customer records
            $customers = @(
                @{ CustomerId = 1; Name = "John Smith"; }
                @{ CustomerId = 2; Name = "Robert Johnson"; }
            )

            $customers | 
                % { Write-Output (New-Object PSObject -Property $_) } | 
                Export-Csv -NoTypeInformation -Path $customerFile -Append
        }.GetNewClosure()

        When {
            Write-Host (Get-Content $customerFile) -Separator "`n"
        }.GetNewClosure()
        
        Then {
            Remove-Item $customerFile
        }.GetNewClosure()
    }
}