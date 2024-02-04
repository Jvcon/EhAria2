; --------------------- Compiler Directives --------------------------

;@Ahk2Exe-SetDescription Enhanced Aria2Manager
;@Ahk2Exe-SetVersion 0.2.3
;@Ahk2Exe-SetCopyright Jacques Yip
; @Ahk2Exe-SetMainIcon EhAria2Manager.ico
;@Ahk2Exe-SetOrigFilename EhAria2Manager.exe

; --------------------- Global --------------------------

#Requires AutoHotkey v2.0
#SingleInstance Off
#NoTrayIcon
#Include <Aria2Rpc>
#Include <i18n>
FileEncoding "UTF-8-RAW"


global CONF_Path := ".\EhAria2.ini"
global Language := i18n("lang", IniRead(CONF_Path, "Basic", "Language"), !A_IsCompiled)

global Aria2RpcPort := IniRead(CONF_Path, "Setting", "Aria2RpcPort")
global Aria2RpcSecret := IniRead(CONF_Path, "Setting", "Aria2RpcSecret")
global Aria2ProxyEnable := IniRead(CONF_Path, "Basic", "Aria2ProxyEnable")
global Aria2Proxy := IniRead(CONF_Path, "Setting", "Aria2Proxy")

global Aria2SessionPath := IniRead(CONF_Path, "Setting", "Aria2SessionPath")
global Aria2SessionInterval := IniRead(CONF_Path, "Setting", "Aria2SessionInterval")


; --------------------- RPC Session Initial --------------------------

global Aria2 := Aria2Rpc("EhAria2", "http://127.0.0.1", Aria2RpcPort, Aria2RpcSecret)

if (Aria2SessionPath = "") {
    Aria2SessionPath := A_ScriptDir . '\aria2.session'
}

; --------------------- Variables Initial --------------------------
global DebugMode := 0
global event := ""
global taskGid := ""
global filePath := ""
global status := ""
global dir := ""
global infoHash := ""

; --------------------- Handle Arguments --------------------------
if (A_Args.Length = 0) {
    HasKey := RegRead("HKEY_CLASSES_ROOT\aria2", , 0)
    if HasKey {
        Result := MsgBox("aria://协议已注册，尝试修复？", "协议注册", "Icon? Y/N/C T5 Default3")
    } else {
        Result := MsgBox("aria://协议尚未注册，现在注册？", "协议注册", "Icon? Y/N T5 Default1")
    }
    switch Result {
        case "Yes":
            if !A_IsAdmin {
                try {
                    if A_IsCompiled {
                        Run '*RunAs "' A_AhkPath '" /restart'
                    }
                    else {
                        Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
                    }
                }
            }
            else {
                if A_IsCompiled {
                    registerUrlProtocol("aria2", A_AhkPath,)
                }
                else {
                    registerUrlProtocol("aria2", A_AhkPath . " /script " . A_ScriptFullPath,)
                }
                Traytip "注册协议成功", "EhAria2Manager", "Iconi Mute"
                Sleep 3000
                HideTrayTip
                ExitApp
            }
        case "Cancel", "No", "Timeout":
            ExitApp
        default:
            ExitApp
    }
}
else {
    url := StrSplit(A_Args[1], "/")
    params := StrSplit(url[4], "&")
    data := Map()
    for index, param in params {
        kv := StrSplit(param, "=")
        data[kv[1]] := kv[2]
    }
    taskGid := data["id"]
    fileName := data["name"]
    event := url[3]
    eventHandler(event, taskGid, fileName)
}

ExitApp

; --------------------- Check Task Info via RPC --------------------------


eventHandler(event, taskGid, fileName) {
    switch event {
        case "browse":
            Aria2.tellStatus(taskGid, &status, &dir, &infoHash)
            if (dir != "" and DirExist(dir)) {
                if InStr(DirExist(dir . "\" . fileName), "D") {
                    RunWait(dir . "\" . fileName)
                }
                else {
                    RunWait(dir)
                }
            }
            else {
                return
            }

        default:
            return
    }
}

registerUrlProtocol(Protocol, Command, Description := "") {
    keyPath := "HKEY_CLASSES_ROOT\" . Protocol
    RegWrite("URL:" . Protocol, "REG_SZ", keyPath)
    RegWrite("", "REG_SZ", keyPath, "URL Protocol")
    if A_IsCompiled {
        RegWrite(Command, "REG_SZ", keyPath . "\DefaultIcon")
    }
    else {
        RegWrite(A_ScriptDir .
            "\EhAria2.ico", "REG_SZ", keyPath . "\DefaultIcon")
    }
    RegCreateKey keyPath . "\shell\open"
    RegWrite(Command . " %1", "REG_SZ", keyPath . "\shell\open\command")
}

HideTrayTip() {
    TrayTip
    if SubStr(A_OSVersion, 1, 3) = "10." {
        A_IconHidden := true
        Sleep 5000
        A_IconHidden := false
    }
}