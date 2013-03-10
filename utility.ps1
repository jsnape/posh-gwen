function Write-Zip {
	param($path)
	
	if (-not $path.EndsWith('.zip')) {$path += '.zip'} 

	if (-not (test-path $path)) { 
		set-content $path ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18)) 
	} 

	$path = Resolve-Path $path
	$shell = new-object -com shell.application
	$zipFile = $shell.NameSpace("$($path.fullname)") 

	$input | % { $zipfile.CopyHere("$($_.fullname)") }
}