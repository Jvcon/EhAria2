; --------------------- Compiler Directives --------------------------

;@Ahk2Exe-SetDescription Enhanced Aria2Extension
;@Ahk2Exe-SetVersion 0.3.0
;@Ahk2Exe-SetCopyright Jacques Yip
;@Ahk2Exe-SetMainIcon EhAria2Extension.ico
;@Ahk2Exe-SetOrigFilename EhAria2Extension.exe

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

global CleanOnComplete := IniRead(CONF_Path, "Extension", "CleanOnComplete")
global CleanOnError := IniRead(CONF_Path, "Extension", "CleanOnError")
global CleanOnRemoved := IniRead(CONF_Path, "Extension", "CleanOnRemoved")
global CleanOnUnknown := IniRead(CONF_Path, "Extension", "CleanOnUnknown")

global ExtDeleteDotAria2 := IniRead(CONF_Path, "Extension", "DeleteDotAria2")
global ExtDeleteDotTorrent := IniRead(CONF_Path, "Extension", "DeleteDotTorrent")
global ExtDeleteEmptyDir := IniRead(CONF_Path, "Extension", "DeleteEmptyDir")
global ExtDeleteExclude := IniRead(CONF_Path, "Extension", "DeleteExclude")

global ExcludeRegEx := IniRead(CONF_Path, "Extension", "ExcludeRegEx")
global ExcludeExt := IniRead(CONF_Path, "Extension", "ExcludeExt")
global IncludeRegEx := IniRead(CONF_Path, "Extension", "IncludeRegEx")
global IncludeExt := IniRead(CONF_Path, "Extension", "IncludeExt")

global DeleteDotTorrentMode := Map(0, "Off", 1, "Normal", 2, "Enhanced")

; --------------------- Log --------------------------

If !FileExist(A_ScriptDir . "\log") {
    DirCreate(A_ScriptDir . "\log")
}
loop files A_ScriptDir . "\log\*.log" {
    SplitPath A_LoopFileFullPath, , , , &namenoext
    if (DateDiff(FormatTime(A_Now, "yyyyMMdd"), FormatTime(namenoext, "yyyyMMdd"), "Days") > 5) {
        FileDelete A_LoopFileFullPath
    }
}
global LogFile := A_ScriptDir . "\log\" . FormatTime(, "yyyyMMdd") . ".log"
LogOutput := FileOpen(LogFile, "a")

PrintLog(type := "", message := "", funcName := "", detail := 0) {
    logInfo := Map()
    logInfo["time"] := FormatTime(A_NoW, "yyyyMMddHHmmss")
    logInfo["function"] := funcName
    logInfo["result"] := type
    logInfo["message"] := message
    logInfo["task"] := taskGid
    if (detail = 1) {
        logInfo["taskStatus"] := status
        logInfo["taskFileCount"] := fileCount
        logInfo["taskFilePath"] := filePath
        logInfo["dir"] := dir

    }
    LogOutput.Write(Jxon_Dump(logInfo) . "`n")
}

; --------------------- RPC Session Initial --------------------------

global Aria2 := Aria2Rpc("EhAria2", "http://127.0.0.1", Aria2RpcPort, Aria2RpcSecret)

if (Aria2SessionPath = "") {
    Aria2SessionPath := A_ScriptDir . '\aria2.session'
}

; --------------------- Variables Initial --------------------------
global DebugMode := 0
global taskGid := A_Args[1]
global fileCount := A_Args[2]
global filePath := A_Args[3]
global status := ""
global dir := ""
global infoHash := ""

; --------------------- Debug or Aria2c Passing --------------------------
if (DebugMode) {

}
else {
    if (A_Args.Length < 1) {
        PrintLog("error", Language.Translate("Msg", "extparamerror"))
        MsgBox Language.Translate("Msg", "extparamerror"), , "Iconx T5"
        ExitApp
    }
}

; --------------------- Check Task Info via RPC --------------------------

Aria2.tellStatus(taskGid, &status, &dir, &infoHash)

; --------------------- Handle Aria2c RPC --------------------------

PrintLog("info", , , 1)

if (dir = "") {
    PrintLog("error", Language.Translate("Msg", "getdirerror"))
    ExitApp
}

global dotAria2File := checkDotAria2()
if (dotAria2File = "") {
    PrintLog("info", Language.Translate("Msg", "filenotexist", ".aria2"))
}

if (infoHash != "") {
    global dotTorrentFile := checkDotTorrent()
    if (dotTorrentFile = "") {
        PrintLog("error", Language.Translate("Msg", "filenotexist", ".torrent") . Language.Translate("Msg", "recommendedenhanced"))
    }
}

switch status {
    case "error":
        if (CleanOnError = 1) {
            if (filePath != '') {
                if !FileExist(dotAria2File) and (FileExist(filePath)) {
                    PrintLog("info", Language.Translate("Msg", "skip") . Language.Translate("Msg", "downloadcompleted") . ": " . filePath . ".", , 1)
                }
                else {
                    deleteFileCache()
                    deleteDotAria2()
                    if (infoHash != "") {
                        deleteDotTorrent()
                    }
                }
            }
        }
    case "removed":
        if (CleanOnRemoved = 1) {
            if (filePath != '') {
                if !FileExist(dotAria2File) and (FileExist(filePath)) {
                    PrintLog("info", Language.Translate("Msg", "skip") . Language.Translate("Msg", "downloadcompleted") . ": " . filePath . ".", , 1)
                }
                else {
                    deleteFileCache()
                    deleteDotAria2()
                    if (infoHash != "") {
                        deleteDotTorrent()
                    }
                }
            }
        }
    case "complete":
        if (CleanOnComplete = 1) {
            deleteDotAria2()
            if (infoHash != "") {
                deleteDotTorrent()
            }
            deleteEmptyDir()
        }
    default:
        if !FileExist(dotAria2File) and (FileExist(filePath)) {
            PrintLog("info", Language.Translate("Msg", "skip") . Language.Translate("Msg", "downloadcompleted") . ": " . filePath . ".", , 1)
        }
        else {
            deleteDotAria2()
            if (infoHash != "") {
                deleteDotTorrent()
            }
        }

}

ExitApp

; --------------------- Check File Functions --------------------------

checkDotAria2(*) {
    SplitPath(filePath, &name, &parentDir, , &naneNoExt)
    if (FileExist(filePath . '.aria2')) {
        dotAria2File := filePath . '.aria2'
    }
    else if (FileExist(parentDir . naneNoExt . '.aria2')) {
        dotAria2File := parentDir . naneNoExt . '.aria2'
    }
    else {
        dotAria2File := ""
    }
    return dotAria2File
}

checkDotTorrent(*) {
    dotTorrentFile := dir . infoHash . ".torrent"
    if (!FileExist(dotTorrentFile)) {
        dotTorrentFile := ""
    }
    return dotTorrentFile
}

deleteDotAria2(*) {
    if (ExtDeleteDotAria2 != 1) {
        PrintLog("info", Language.Translate("Msg", "cleanfuncdisabled", ".aria2"))
    }
    else {
        if (dotAria2File != "") {
            FileDelete dotAria2File
        }
    }
}

deleteDotTorrent(*) {
    sleep(Aria2SessionInterval + 1)
    switch ExtDeleteDotTorrent {
        case "1":
            if (dotTorrentFile != "") {
                FileDelete dotTorrentFile
            }
        case "2":
            if (dotTorrentFile != "") {
                FileDelete dotTorrentFile
            }
            else {
                if (!FileExist(Aria2SessionPath)) {
                    PrintLog("info", Language.Translate("Msg", "filenotexist", Aria2SessionPath))
                }
                else {
                    session := FileRead(Aria2SessionPath)
                    loop files dir . '*.torrent', "F"
                        if (InStr(session, A_LoopFileName) != "") {
                            FileDelete A_LoopFileFullPath
                            PrintLog("success", Language.Translate("Msg", "enhancedmode") . Language.Translate("Msg", "filedelete", A_LoopFileFullPath))
                        }
                        else {
                            PrintLog("info", Language.Translate("Msg", "filenotexist", A_LoopFileFullPath))
                        }
                }
            }
        default:
            PrintLog("info", Language.Translate("Msg", "cleanfuncdisabled", ".torrent"))

    }
}


deleteFileCache(*) {
    if (filePath != "") {
        if (InStr(FileGetAttrib(filePath), "D")) {
            DirDelete filePath
        } else {
            FileDelete filePath
        }
    }
}

deleteEmptyDir(*) {
    if (ExtDeleteEmptyDir = 1) {
        PrintLog("info", Language.Translate("Msg", "cleanfuncdisabled", Language.Translate("GuiConfig", "emptyfolder")))
    }
    else {
        loop files dir, "DR"
            if (A_LoopFileSize = 0) {
                try DirDelete A_LoopFileFullPath
            }
    }
}


deleteExcludeFile(*) {
    deleteFileList := Array()
    saveFileList := Array()
    excludeExtList := StrSplit(ExcludeExt, "|")
    includeExtList := StrSplit(IncludeExt, "|")
    if (InStr(FileGetAttrib(filePath), "D")) {
        if (ExtDeleteExclude = 1) {
            if (excludeExtList.Length < 1) {
                return
            }
            Loop Files filePath {
                if (A_LoopFileSize < 10) {
                    deleteFileList.Push(A_LoopFileFullPath)
                }
                if (RegExMatch(filePath, filePath . ExcludeRegEx) >= 1) {
                    deleteFileList.Push(A_LoopFileFullPath)
                }
            }
            for ext in excludeExtList {
                checkFileExt(filePath, ext, deleteFileList)
            }
            for path in deleteFileList {
                FileDelete path
            }
        }
        else if (ExtDeleteExclude = 2) {
            if (includeExtList.Length < 1) {
                return
            }
            Loop Files filePath {
                if (RegExMatch(filePath, filePath . includeExtList) >= 1) {
                    saveFileList.Push(A_LoopFileFullPath)
                }
            }
            for ext in includeExtList {
                checkFileExt(filePath, ext, saveFileList)
            }
            loop Files filePath {
                for k, v in saveFileList
                    if (v == A_LoopFileFullPath) {
                        return hasvalue := true
                    }
                    else {
                        return hasvalue := false
                    }
                if (hasvalue := false) {
                    FileDelete A_LoopFileFullPath
                }
            }
        }
        else {
            PrintLog("info", Language.Translate("Msg", "cleanfuncdisabled", "exclude/include"))
        }
    }
    return
}

checkFileExt(path := "", ext := "", fileList := Array()) {
    loop files path "*." ext, "FD" {
        fileList.Push(A_LoopFileFullPath)
    }
}
