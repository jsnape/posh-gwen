$scriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent

Remove-Module gwen -ErrorAction SilentlyContinue
Import-Module (Join-Path $scriptRoot gwen.psm1)

. (Join-Path $scriptRoot utility.ps1)

Set-Location $scriptRoot

Invoke-Gwen (Join-Path $scriptRoot Tests) -Verbose
