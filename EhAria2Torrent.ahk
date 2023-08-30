; --------------------- COMPILER DIRECTIVES --------------------------

;@Ahk2Exe-SetDescription Enhanced Aria2Torrent
;@Ahk2Exe-SetVersion 0.2.3
;@Ahk2Exe-SetCopyright Jacques Yip
;@Ahk2Exe-SetMainIcon EhAria2Torrent.ico
;@Ahk2Exe-SetOrigFilename EhAria2Torrent.exe

; --------------------- GLOBAL --------------------------

#Requires AutoHotkey >=v2.0
#SingleInstance force
#NoTrayIcon
#Include <Aria2Rpc>
FileEncoding "UTF-8-RAW"

CONF_Path := ".\EhAria2.ini"
Global Language := IniRead(CONF_Path, "Basic", "Language")

LANG_PATH := A_ScriptDir "\lang\" Language ".ini"
Global lGuiSelectTorrentTitle := IniRead(LANG_PATH, "GuiTorrent", "title")
Global lGuiSelectTorrentExt := IniRead(LANG_PATH, "GuiTorrent", "ext")

Global Aria2RpcPort := IniRead(CONF_Path, "Setting", "Aria2RpcPort")
Global Aria2RpcSecret := IniRead(CONF_Path, "Setting", "Aria2RpcSecret")
Global Aria2ProxyEnable := IniRead(CONF_Path, "Basic", "Aria2ProxyEnable")
Global Aria2Proxy := IniRead(CONF_Path, "Setting", "Aria2Proxy")
Aria2 := Aria2Rpc("EhAria2", "http://127.0.0.1", Aria2RpcPort, Aria2RpcSecret)

If ((Aria2ProxyEnable = 1) and (Aria2Proxy != "")) {
    Aria2.__Init(Aria2Proxy)
}

If (ProcessExist("aria2c.exe") = 0) {
    If (A_IsCompiled = 1) {
        Run A_ScriptDir . "\EhAria2.exe"
    }
    else {
        Run A_ScriptDir . "\EhAria2.ahk"
    }
}

If (A_Args.Has(1) = True)
{
    Global TorrentPN := A_Args[1]
}
else {
    Global TorrentPN := FileSelect(, , lGuiSelectTorrentTitle, lGuiSelectTorrentExt " (*.torrent)")
    If TorrentPN = ""
        Exitapp
}

If (A_Args.Has(2) = True) {
    Global proxy := A_Args[2]
}
else {
    Global proxy := 0
}


Aria2.addTorrent(TorrentPN, , proxy)
Exitapp
Return
