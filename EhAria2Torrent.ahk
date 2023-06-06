; --------------------- COMPILER DIRECTIVES --------------------------

;@Ahk2Exe-SetDescription Enhanced Aria2Torrent
;@Ahk2Exe-SetVersion 0.0.0.3
;@Ahk2Exe-SetCopyright Jacques Yip
;@Ahk2Exe-SetMainIcon EhAria2Torrent.ico
;@Ahk2Exe-SetOrigFilename EhAria2Torrent.exe

; --------------------- GLOBAL --------------------------

#Requires AutoHotkey >=v2.0
#SingleInstance force
#NoTrayIcon

FileEncoding "UTF-8"

CONF_Path := ".\EhAria2Ahk.ini"

Global Aria2RpcPort := IniRead(CONF_Path, "Setting", "Aria2RpcPort")
Global Aria2RpcUrl := 'http://127.0.0.1:' . Aria2RpcPort . '/jsonrpc'

Global Aria2RpcSecret := IniRead(CONF_Path, "Setting", "Aria2RpcSecret")

If ProcessExist("aria2c.exe") = 0
    Run A_ScriptDir . "\EhAria2Ahk.exe"

If (A_Args.Has(1) = True)
{
    Global TorrentPN := A_Args[1]
} Else {
    Global TorrentPN := FileSelect(, , "选择 Torrent 文件", "Torrent 文件 (*.torrent)")
    If TorrentPN = ""
        Exitapp
}

RunWait A_ComSpec " /c certutil.exe -encode " . TorrentPN . " Temp.txt", ,"Hide"
TorrentText := FileRead("Temp.txt")
TorrentText := StrReplace(TorrentText, "-----BEGIN CERTIFICATE-----" , "")
TorrentText := StrReplace(TorrentText, "-----END CERTIFICATE-----" , "")
TorrentText := StrReplace(TorrentText, "`n" , "")
if (Aria2RpcSecret= ""){
    Aria2AddTorrnetData := '`{"jsonrpc":"2.0","id":"1","method":"aria2.addTorrent","params":["' . TorrentText . '"]}'
}
else {
    Aria2AddTorrnetData := '`{"jsonrpc":"2.0","id":"1","method":"aria2.addTorrent","params":["token:' . Aria2RpcSecret . '","' . TorrentText . '"]}'
}

HttpPost(Aria2RpcUrl, Aria2AddTorrnetData)
FileDelete "Temp.txt"
Exitapp
Return

HttpPost(URL, PData) {
	Static WebRequest := ComObject("WinHttp.WinHttpRequest.5.1")
	WebRequest.Open("POST", URL, True)
	WebRequest.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
	WebRequest.Send(PData)
	WebRequest.WaitForResponse(-1)
}