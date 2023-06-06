If !FileExist(A_ScriptDir "\build" ) {
    DirCreate(A_ScriptDir "\build" )
}

ahk_path:= ""
RunWait ahk_path . "\Compiler\Ahk2Exe.exe"
 . ' /in ' A_ScriptDir . "\EhAria2.ahk"
 . ' /base ' ahk_path . "\v2\AutoHotkey64.exe"
 . ' /compress 2'

 ahk_path:= "C:\Users\Jacques\scoop\apps\autohotkey\current"
 RunWait ahk_path . "\Compiler\Ahk2Exe.exe"
  . ' /in ' A_ScriptDir . "\EhAria2Torrent.ahk"
  . ' /base ' ahk_path . "\v2\AutoHotkey64.exe"
  . ' /compress 2'
 