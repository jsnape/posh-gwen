# Copyright (c) 2013 James Snape
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

Set-PSDebug -Strict

function Feature {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = 1)] [string] $feature,
        [Parameter(Position = 1, Mandatory = 1)] [scriptblock] $action
    )
	
	Write-Verbose "Feature: $feature"
	
	$context = Get-CurrentContext	
	$context.Features += New-Feature -name $feature -file $context.CurrentFile
	$action.Invoke()
}

function Scenario {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = 1)] [string] $scenario,
        [Parameter(Position = 1, Mandatory = 1)] [scriptblock] $action
    )

	Write-Verbose "Scenario: $scenario"

	$feature = Get-CurrentFeature
	$feature.Scenarios += New-Scenario -name $scenario
	$action.Invoke()
}

function Given {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)] [scriptblock] $script
    )

	$scenario = Get-CurrentScenario
	
	if ($script) {
		$scenario.given += $script
	}
}

function When {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)] [scriptblock] $script
    )

	$scenario = Get-CurrentScenario
	
	if ($script) {
		$scenario.when += $script
	}
}

function Then {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)] [scriptblock] $script
    )

	$scenario = Get-CurrentScenario
	
	if ($script) {
		$scenario.then += $script
	}
}

function Assert-That {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)] $condition,
		[Parameter(Position = 1)] [string] $messsage = "Test failed"
    )

	if (-not $condition) {
		throw ("Assert " + $message)
	}
}

function Assert-Equal {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)] $expected,
        [Parameter(Position = 1)] $actual,
		[Parameter(Position = 2)] [string] $message = "Test failed"
    )

	if ($expected -ne $actual) {
		throw ("Assert <<$expected>> not equal to <<$actual>> " + $message)
	}
}

function Should-Fail {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)] [scriptblock] $action
    )
    
    try {
        & $action
    }
    catch {
        return
    }
    
    Fail-Test
}

function Fail-Test {
    [CmdletBinding()]
    param (
		[Parameter(Position = 1)] [string] $message = "Test failed"
    )

	throw ($message)
}

function Invoke-Gwen {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)] $testFile
    )
	
	begin {
		$context = Push-Context
		
		$verbose = $PSBoundParameters["Verbose"]
		
		if ($verbose -and $verbose -eq $true) {
			$VerbosePreference = "Continue"
		}
	}
	
	process {
		$context.CurrentFile = $testFile.FullName
		Write-Verbose "Loading: $testFile"
		. $testFile.FullName
	}
	
	end {
		try {
			## Because this is a batch system, all the tests are loaded before running
			Get-Scenarios $context | % { 
				Invoke-ScenarioBlocks -context $context -scenario $_ -blocks $_.Given 
			} | Out-Null
			
			Get-Scenarios $context | % { 
				Invoke-ScenarioBlocks -context $context -scenario $_ -blocks $_.When 
			} | Out-Null
			
			Get-Scenarios $context | % { 
				Invoke-ScenarioBlocks -context $context -scenario $_ -blocks $_.Then 
			} | Out-Null
			
			foreach ($feature in $context.Features) {
				foreach ($scenario in $feature.Scenarios) {
					$failed = $scenario.Errors.Count -gt 0
					
					$result = New-TestResult `
						$feature.File $feature.Name $scenario.Name $failed $scenario.Errors
					
					Write-Output $result
				}
			}
			
		} finally {
			Pop-Context
		}
	}
}

## Internals

function Get-CurrentContext {
	return $gwen.context.Peek()
}

function Get-CurrentFeature {
	$context = Get-CurrentContext
	return $context.features[$context.features.Length - 1]
}

function Get-CurrentScenario {
	$feature = Get-CurrentFeature
	return $feature.scenarios[$feature.scenarios.Length - 1]
}

function Get-Scenarios {
	param (
		[Parameter(Position = 0)] [PSObject] $context
	)

	foreach ($feature in $context.Features) {
		foreach ($scenario in $feature.Scenarios) {
			Write-Output $scenario
		}
	}
}

function Invoke-ScenarioBlocks {
	param (
		[Parameter(Position = 0)] [PSObject] $context,
		[Parameter(Position = 1)] [PSObject] $scenario,
		[Parameter(Position = 2)] [scriptblock[]] $blocks
	)

	foreach ($block in $blocks) {
		try {
			if ($scenario.Errors.Length -eq 0) {
				& $block
			}
		} catch {
			$context.FailureCount += 1
			$scenario.Errors += $_
		}						
	}
}

function Push-Context {
	$context = New-Object PSObject -Property @{
		Features = @();
		OriginalVerbosePreference = $VerbosePreference;
		CurrentFile = $null;
		FailureCount = 0;
	}
	
	$gwen.context.push($context)
	
	return $context
}

function Pop-Context {
	$context = $gwen.context.Pop()
	$VerbosePreference = $context.OriginalVerbosePreference		
}

function New-Feature {
	param (
		[Parameter(Position = 0)] [string] $name,
		[Parameter(Position = 1)] [string] $file
	)
	
	$feature = New-Object PSObject -Property @{
		Name = $name;
		File = $file;
		Scenarios = @()
	}
	
	return $feature
}

function New-Scenario {
	param (
		[Parameter(Position = 0)] [string] $name
	)
	
	$scenario = New-Object PSObject -Property @{
		Name = $name;
		Given = @();
		When = @();
		Then = @();
		Errors = @();
	}
	
	return $scenario
}

function New-TestResult {
	param (
		[Parameter(Position = 0)] [string] $file,
		[Parameter(Position = 1)] [string] $feature,
		[Parameter(Position = 2)] [string] $scenario,
		[Parameter(Position = 3)] [boolean] $failed,
		[Parameter(Position = 4)] $errors
	)
	
	$result = New-Object PSObject -Property @{
		File = $file;
		Feature = $feature;
		Scenario = $scenario;
		Failed = $failed;
		Errors = $errors;
	}
	
	return $result
}

$script:gwen = @{
    version = "0.1.0";
    context = New-Object System.Collections.Stack;
	failureCount = 0;
}

Export-ModuleMember -Function Invoke-Gwen, Feature, Scenario, Given, When, Then, Assert-That, Assert-Equal
