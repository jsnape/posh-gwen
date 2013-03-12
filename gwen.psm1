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

	$feature = GetCurrentFeature
	
	$feature.scenarios.Push(@{
		"name" = $scenario;
		"given" = @();
		"when" = @();
		"then" = @();
		"errors" = @();
	})

	$action.Invoke()
}

function Given {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)] [scriptblock] $script
    )

	$scenario = GetCurrentScenario
	
	if ($script) {
		$scenario.given += $script
	}
}

function When {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)] [scriptblock] $script
    )

	$scenario = GetCurrentScenario
	
	if ($script) {
		$scenario.when += $script
	}
}

function Then {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)] [scriptblock] $script
    )

	$scenario = GetCurrentScenario
	
	if ($script) {
		$scenario.then += $script
	}
}

function Assert {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)] [boolean] $condition,
		[Parameter(Position = 1)] [string] $messsage
    )

	if (-not $condition) {
		throw ("Assert " + $message)
	}
}

function Invoke-Gwen {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Position = 0)] $testPath,
		[switch] $sequential
    )
	
	$failureCount = 0
	
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
		
		if ($testPath.PSIsContainer) {
			## A folder has been passed so load all the tests.
			Get-ChildItem -Path $testPath\* -Include *.feature.ps1 -Recurse | ForEach-Object {
				. $_
			}
		} else {
			## A single test has been passed so just run it.
			. $testPath.FullName
		}
		
		if ($sequential) {
			RunSequential $context
		} else {
			RunBatch $context
		}
	} finally {
		$context = $gwen.context.Pop()
		$VerbosePreference = $context.originalVerbosePreference
	}
	
	return $context.failureCount
}

## Internals

function GetCurrentContext {
	return $gwen.context.Peek()
}

function GetCurrentFeature {
	return $gwen.context.Peek().features.Peek()
}

function GetCurrentScenario {
	return $gwen.context.Peek().features.Peek().scenarios.Peek()
}

function RunBatch {
    param (
        [Parameter(Position = 0)] $context
	)
	
	foreach ($feature in $context.features) {
		foreach ($scenario in $feature.scenarios) {
			foreach ($given in $scenario.given) {
				try {
					if ($scenario.errors.length -eq 0) {
						$given.Invoke()
					}
				} catch {
					$context.failureCount += 1
					$scenario.errors += $_
				}
			}
		}
	}
	
	foreach ($feature in $context.features) {
		foreach ($scenario in $feature.scenarios) {
			foreach ($when in $scenario.when) {
				try {
					if ($scenario.errors.length -eq 0) {
						$when.Invoke()
					}
				} catch {
					$context.failureCount += 1
					$scenario.errors += $_
				}
			}
		}
	}
	
	foreach ($feature in $context.features) {
		foreach ($scenario in $feature.scenarios) {
			foreach ($then in $scenario.then) {
				try {
					if ($scenario.errors.length -eq 0) {
						$then.Invoke()
					}
				} catch {
					$context.failureCount += 1
					$scenario.errors += $_
				}
			}
		}
	}		
}

function RunSequential {
    param (
        [Parameter(Position = 0)] $context
	)
	
	foreach ($feature in $context.features) {
		foreach ($scenario in $feature.scenarios) {
			try {
				foreach ($given in $scenario.given) {
					$given.Invoke()
				}

				foreach ($when in $scenario.when) {
					$when.Invoke()
				}

				foreach ($then in $scenario.then) {
					$then.Invoke()
				}
			} catch {
				$context.failureCount += 1
				$scenario.errors += $_
			}
		}
	}		
}

$script:gwen = @{
    version = "0.1.0";
    context = New-Object System.Collections.Stack;
    passed = $false;
	failureCount = 0;
}

Export-ModuleMember -Function Invoke-Gwen, Feature, Scenario, Given, When, Then, Assert -Variable gwen
