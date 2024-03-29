Import-Module Microsoft.PowerShell.Utility

$cwd = (Get-Location).Path
$ahkpath = 'C:\Users\Jacques\scoop\apps\autohotkey\current'
$ahk2exe = $ahkpath + '\Compiler\Ahk2Exe.exe'
$ahk64base = $ahkpath + '\v2\AutoHotkey64.exe'
$command = $ahk2exe + ' /silent verbose ' + ' /base ' + $ahk64base + " /out  $cwd\build\"
$testcommand = $ahk2exe + ' /base ' + $ahk64base + " /out  $cwd\test\"
$version = $args[0]
$env = $args[1]
$appname = $args[2]
$zipname = $appname + '_v' + "$version"
$setversion = ';@Ahk2Exe-SetVersion ' + $version
$globalversion = "Global appVersion := `"" + $version + "`""
Write-Host 'App:' $appname
Write-Host 'Version:' $version
Write-Host 'Environment:' $env

if ($env -eq 'version') {
    Get-ChildItem “$cwd\*.ahk” | ForEach-Object {
        (Get-Content $_) | ForEach-Object { $_ -Replace (';@Ahk2Exe-SetVersion ' + '[0-9]+.[0-9]+.[0-9]+') , $setversion } | Set-Content $_
        (Get-Content $_) | ForEach-Object { $_ -Replace ("Global appVersion := `"" + '[0-9]+.[0-9]+.[0-9]+' + "`"") , $globalversion } | Set-Content $_
    }   
}

if ($env -eq 'prod') {
    if (!(Test-Path -Path "$cwd\build")) {
        mkdir $cwd\build
    }
    Get-ChildItem “$cwd\*.ahk” | ForEach-Object {
        (Get-Content $_) | ForEach-Object { $_ -Replace (';@Ahk2Exe-SetVersion ' + '[0-9]+.[0-9]+.[0-9]+') , $setversion } | Set-Content $_
        (Get-Content $_) | ForEach-Object { $_ -Replace ("Global appVersion := `"" + '[0-9]+.[0-9]+.[0-9]+' + "`"") , $globalversion } | Set-Content $_
    }

    foreach ($file in (Get-ChildItem -Path $cwd\*.ahk)) {
        Write-Host $file.BaseName
        Invoke-Expression($command + " /in $file")
        while ( !(Test-Path -Path "$cwd\build\$($file.BaseName).exe" )) {
            Start-Sleep 1
        }
    }
    if ((Test-Path -Path "$cwd\build\checksums_v$version.txt")) {
        Remove-Item -Path $cwd\build\checksums_v$version.txt
    }
    if ((Test-Path -Path "$cwd\build\$zipname.zip")) {
        Remove-Item -Force -Path $cwd\build\$zipname.zip
    }
    Compress-Archive -Path .\build\*.exe -DestinationPath .\build\$zipname.zip
    $value = (Get-FileHash -Path .\build\$zipname.zip -Algorithm SHA256).Hash + "  $zipname.zip"
    Tee-Object -Append -InputObject $value -FilePath $cwd\build\checksums_v$version.txt
    
    foreach ($file in (Get-ChildItem -Path $cwd\build\*.exe)) {
        Invoke-Expression("Remove-Item -Force -Path $file")
    }
   
}

if ($env -eq 'dev') {
    if (!(Test-Path -Path "$cwd\test")) {
        mkdir $cwd\test
    }
    foreach ($file in (Get-ChildItem -Path $cwd\*.ahk)) {
        Write-Host $file.BaseName
        Invoke-Expression($testcommand + " /in $file")
        while ( !(Test-Path -Path "$cwd\test\$($file.BaseName).exe" )) {
            Start-Sleep 1
        }
    }
}
