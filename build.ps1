Import-Module Microsoft.PowerShell.Utility

Write-Host "Version:" $args
$cwd = (Get-Location).Path
$ahkpath = "C:\Users\Jacques\scoop\apps\autohotkey\current"
$ahk2exe = $ahkpath + "\Compiler\Ahk2Exe.exe"
$ahk64base = $ahkpath + "\v2\AutoHotkey64.exe"
$command = $ahk2exe + " /silent verbose " + " /base " + $ahk64base + " /out  $cwd\build\"

$setversion = ";@Ahk2Exe-SetVersion " + $args

Get-ChildItem “$cwd\*.ahk” | ForEach-Object {
    (Get-Content $_) | ForEach-Object  {$_ -Replace (";@Ahk2Exe-SetVersion " + '[0-9]+.[0-9]+.[0-9]+') , $setversion } | Set-Content $_
}

if (!(Test-Path -Path "$cwd\build")) {
    mkdir $cwd\build
}

foreach ($file in (Get-ChildItem -Path $cwd\*.ahk)) {
    Invoke-Expression($command + " /in $file")
}

while ( !(Test-Path -Path "$cwd\build\EhAria2.exe" )) {
    Start-Sleep 1
}

while (!(Test-Path -Path "$cwd\build\EhAria2Torrent.exe")) {
    Start-Sleep 1
}

if ((Test-Path -Path "$cwd\build\checksums_v$args.txt")) {
    Remove-Item -Path $cwd\build\checksums_v$args.txt
}

if ((Test-Path -Path "$cwd\build\EhAria2_v$args.zip")) {
    Remove-Item -Force -Path $cwd\build\EhAria2_v$args.zip
}

Compress-Archive -Path .\build\*.exe -DestinationPath .\build\EhAria2_v$args.zip

$value = (Get-FileHash -Path .\build\EhAria2_v$args.zip -Algorithm SHA256).Hash + "  EhAria2_v$args.zip"
Tee-Object -Append -InputObject $value -FilePath $cwd\build\checksums_v$args.txt


foreach ($file in (Get-ChildItem -Path $cwd\build\*.exe)) {
    Invoke-Expression("Remove-Item -Force -Path $file")
}
