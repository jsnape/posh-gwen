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

	$feature = Get-CurrentFeature
	
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
					try {
						if ($scenario.errors.length -eq 0) {
							$given.Invoke()
						}
					} catch {
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
						$scenario.errors += $_
					}
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

Export-ModuleMember -Function Invoke-Gwen, Feature, Scenario, Given, When, Then, Assert -Variable gwen
