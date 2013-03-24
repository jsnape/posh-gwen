#requires -version 3

Feature "Batch file generation" {
    Scenario "Generate a file" {
        Given {
            $customerFile = "customer.csv"

            ## Customer records
            $customers = @(
                @{ CustomerId = 1; Name = "John Smith"; }
                @{ CustomerId = 2; Name = "Robert Johnson"; }
            )

            $customers | 
                % { Write-Output (New-Object PSObject -Property $_) } | 
                Export-Csv -NoTypeInformation -Path $customerFile -Append
        }

        When {
            Write-Host (Get-Content "customer.csv") -Separator "`n"
        }
        
        Then {
            Remove-Item "customer.csv"
        }
    }
}