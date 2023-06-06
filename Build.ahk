#Requires AutoHotkey >=v2.0

If !FileExist(A_ScriptDir "\build" ) {
    DirCreate(A_ScriptDir "\build" )
}

ahk_path:= "C:\Users\Jacques\scoop\apps\autohotkey\current"

RunWait ahk_path . "\Compiler\Ahk2Exe.exe"
. ' /compress 2'
. ' /silent verbose'
. ' /in ' A_ScriptDir . "\EhAria2.ahk"
. ' /base ' ahk_path . "\v2\AutoHotkey64.exe"

RunWait ahk_path . "\Compiler\Ahk2Exe.exe"
. ' /compress 2'
. ' /silent verbose'
. ' /in ' A_ScriptDir . "\EhAria2Torrent.ahk"
. ' /base ' ahk_path . "\v2\AutoHotkey64.exe"
