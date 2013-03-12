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

Write-Host "Running posh-gwen specification tests" -ForegroundColor Green

$scriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent

Remove-Module gwen -ErrorAction SilentlyContinue
Import-Module (Join-Path $scriptPath gwen.psm1)

$specs = Get-ChildItem (Join-Path $scriptPath Specs) -Filter *.ps1

foreach ($spec in $specs) {
	try {
		$result = $true

		$failureCount = Invoke-Gwen -testPath $spec
		
		if ($failureCount -gt 0) {
			$result = $false
		}
	}
	catch {
		Write-Host $_.Exception -ForegroundColor Red
		$result = $false
	}
	
	if ($spec.BaseName.EndsWith("_should_fail")) {
		$result = -not $result
	}
	
	if ($result) {
		Write-Host "." -ForeGroundColor Green -NoNewLine
	}
	else {
		Write-Host "F" -ForeGroundColor Red -NoNewLine
	}
}

Write-Host ""
