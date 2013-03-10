Set-PSDebug -Strict

function Feature {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = 1)] [string] $feature,
        [Parameter(Position = 1, Mandatory = 1)] [scriptblock] $action
    )
	
	Write-Verbose "Feature: $feature"
	
	$context = $gwen.context.Peek()	
	$context.features.Push(@{
		"name" = $feature;
		"scenarios" = New-Object System.Collections.Stack
	})
	
	$action.Invoke()
}

function Scenario {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = 1)] [string] $scenario,
        [Parameter(Position = 1, Mandatory = 1)] [scriptblock] $action
    )

	Write-Verbose "`tScenario: $scenario"

	$feature = Get-CurrentFeature
	
	$feature.scenarios.Push(@{
		"name" = $scenario;
		"given" = @();
		"when" = @();
		"then" = @();
	})

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

function Invoke-Gwen {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Position = 0)] [string] $testPath
    )
	
	try {
		$gwen.context.push(@{
			"features" = New-Object System.Collections.Stack;
			"originalVerbosePreference" = $VerbosePreference
		})
		
		$context = $gwen.context.Peek()
		
		$verbose = $PSBoundParameters["Verbose"]
		
		if ($verbose -and $verbose -eq $true) {
			$VerbosePreference = "Continue"
		}
		
		Get-ChildItem -Path $testPath\* -Include *.feature.ps1 -Recurse | ForEach-Object {
			. $_
		}
		
		foreach ($feature in $context.features) {
			foreach ($scenario in $feature.scenarios) {
				foreach ($given in $scenario.given) {
					$given.Invoke()
				}
			}
		}
		
		foreach ($feature in $context.features) {
			foreach ($scenario in $feature.scenarios) {
				foreach ($when in $scenario.when) {
					$when.Invoke()
				}
			}
		}
		
		foreach ($feature in $context.features) {
			foreach ($scenario in $feature.scenarios) {
				foreach ($then in $scenario.then) {
					$then.Invoke()
				}
			}
		}
		
	} finally {
		$context = $gwen.context.Pop()
		$VerbosePreference = $context.originalVerbosePreference
	}
}

function Get-CurrentContext {
	return $gwen.context.Peek()
}

function Get-CurrentFeature {
	return $gwen.context.Peek().features.Peek()
}

function Get-CurrentScenario {
	return $gwen.context.Peek().features.Peek().scenarios.Peek()
}

$script:gwen = @{
    version = "0.1.0";
    context = New-Object System.Collections.Stack;
    passed = $false;
}

Export-ModuleMember -Function Invoke-Gwen, Feature, Scenario, Given, When, Then -Variable gwen
