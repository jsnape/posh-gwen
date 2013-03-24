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

[CmdletBinding()]
Param ()

$oldVerbosePreference = $VerbosePreference

$verbose = $PSBoundParameters["Verbose"]

if ($verbose -and $verbose -eq $true) {
	$VerbosePreference = "Continue"
}

Write-Host "Running posh-gwen specification tests" -ForegroundColor Green

$scriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
$specPath = Join-Path $scriptPath Specs

Remove-Module gwen -ErrorAction SilentlyContinue -Verbose:$false
Import-Module (Join-Path $scriptPath gwen.psm1) -ErrorAction Stop -Verbose:$false

$results = @()
$failureCount = 0

Get-ChildItem $specPath -Filter *.ps1 | Invoke-Gwen | % {
	$results += $_
	
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
		Write-Host "$($_.feature) - $($_.scenario) failed" -ForegroundColor Red
		$_.Errors | % { Write-Host $_ -ForegroundColor Red }
	} else {
		Write-Host "$($_.feature) - $($_.scenario) passes" -ForegroundColor Green
	}
}

$VerbosePreference = $oldVerbosePreference 
