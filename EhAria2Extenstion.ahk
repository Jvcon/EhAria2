; --------------------- COMPILER DIRECTIVES --------------------------

;@Ahk2Exe-SetDescription Enhanced Aria2Extension
;@Ahk2Exe-SetVersion 0.1.1
;@Ahk2Exe-SetCopyright Jacques Yip
;@Ahk2Exe-SetMainIcon EhAria2Extension.ico
;@Ahk2Exe-SetOrigFilename EhAria2Extension.exe

; --------------------- GLOBAL --------------------------

#Requires AutoHotkey >=v2.0
#NoTrayIcon
#Include <Aria2Rpc>
#Include <i18n>
FileEncoding "UTF-8-RAW"

global CONF_Path := ".\EhAria2.ini"
global Language := i18n("lang", IniRead(CONF_Path, "Basic", "Language"), !A_IsCompiled)

Global Aria2RpcPort := IniRead(CONF_Path, "Setting", "Aria2RpcPort")
Global Aria2RpcSecret := IniRead(CONF_Path, "Setting", "Aria2RpcSecret")
Global Aria2ProxyEnable := IniRead(CONF_Path, "Basic", "Aria2ProxyEnable")
Global Aria2Proxy := IniRead(CONF_Path, "Setting", "Aria2Proxy")

Global Aria2SessionPath := IniRead(CONF_Path, "Setting", "Aria2SessionPath")
Global Aria2SessionInterval := IniRead(CONF_Path, "Setting", "Aria2SessionInterval")

Global CleanOnComplete := IniRead(CONF_Path, "Extension", "CleanOnComplete")
Global CleanOnError := IniRead(CONF_Path, "Extension", "CleanOnError")
Global CleanOnRemoved := IniRead(CONF_Path, "Extension", "CleanOnRemoved")
Global CleanOnUnknown := IniRead(CONF_Path, "Extension", "CleanOnUnknown")

Global ExtDeleteDotAria2 := IniRead(CONF_Path, "Extension", "DeleteDotAria2")
Global ExtDeleteDotTorrent := IniRead(CONF_Path, "Extension", "DeleteDotTorrent")
Global ExtDeleteEmptyDir := IniRead(CONF_Path, "Extension", "DeleteEmptyDir")
Global ExtDeleteExclude := IniRead(CONF_Path, "Extension", "DeleteExclude")

Global ExcludeRegEx := IniRead(CONF_Path, "Extension", "ExcludeRegEx")
Global ExcludeExt := IniRead(CONF_Path, "Extension", "ExcludeExt")
Global IncludeRegEx := IniRead(CONF_Path, "Extension", "IncludeRegEx")
Global IncludeExt := IniRead(CONF_Path, "Extension", "IncludeExt")

Global DeleteDotTorrentMode := Map(0, "Off", 1, "Normal", 2, "Enhanced")

If !FileExist(A_ScriptDir . "\log") {
    DirCreate(A_ScriptDir . "\log")
}
loop files A_ScriptDir . "\log\*.log"{
    SplitPath A_LoopFileFullPath,,,,&namenoext
    if ( DateDiff(FormatTime(A_Now,"yyyyMMdd") ,FormatTime(namenoext,"yyyyMMdd") ,"Days") > 5){
        MsgBox "Cleaning log files"
        FileDelete A_LoopFileFullPath
    }
}
Global LogFile:= A_ScriptDir . "\log\" . FormatTime(,"yyyyMMdd") . ".log"
LogOutput := FileOpen(LogFile, "a")

Global Aria2 := Aria2Rpc("EhAria2", "http://127.0.0.1", Aria2RpcPort, Aria2RpcSecret)

if (Aria2SessionPath = "") {
    Aria2SessionPath := A_ScriptDir . '\aria2.session'
}
MsgBox "Running Extension"
if (A_Args.Length < 1) {
    Global taskGid := ""
    Global fileCount := ""
    Global filePath := ""
    PrintLog("error",Language.Translate("Msg", "extparamerror"))
    MsgBox Language.Translate("Msg", "extparamerror"), , "Iconx T5"
    ExitApp
}
else {
    Global taskGid := A_Args[1]
    Global fileCount := A_Args[2]
    Global filePath := A_Args[3]
}

if (fileCount = 0) {
    PrintLog("info",Language.Translate("Msg", "extmagnet"))
}

Aria2.tellStatus(taskGid, &status, &dir, &infoHash)

if (dir = "") {
    PrintLog("error","Failed to get download directory!.")
    ExitApp
}


if ((status = "error" and CleanOnError = 1) | (status = "removed" and CleanOnRemoved = 1)) {
    if (FileExist(checkDotAria2())) {
        PrintLog("success","Download task " . status . ", deleting files...")
        if (FileGetAttrib(filePath) = "D") {
            DirDelete filePath
        } else {
            FileDelete filePath
        }
        deleteDotAria2()
    }
    else if (FileExist(filePath)) {
        PrintLog("info","Skip delete. Download completed files: " . filePath . ".")
    }
    else {
        PrintLog("error","Skip delete. File does not exist: " . filePath . ".")
    }
}
else if (status = "complete") {
    if (CleanOnComplete = 1) {
        deleteDotAria2()
        deleteDotTorrent()
        deleteExcludeFile()
        deleteEmptyDir()
    }
}
else if (CleanOnUnknown = 1) {
    if (FileExist(checkDotAria2())) {
        PrintLog("success", "Download task force removed, deleting files...")
        if (FileGetAttrib(filePath) = "D") {
            DirDelete filePath
        } else {
            FileDelete filePath
        }
        deleteDotAria2()
    }
    else if (FileExist(filePath)) {
        PrintLog("info","Skip delete. Download completed files: " . filePath . ".")
    }
    else {
        PrintLog("error","Skip delete. File does not exist: " . filePath . ".")
    }
}
else {
    PrintLog("error","Skip. Task status invalid: " . status . ".")
    ExitApp
}

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
        OutputDebug "Couldn't found .aria2 file."
    }
    return dotAria2File
}

deleteDotAria2(*) {
    if (ExtDeleteDotAria2 = 1) {
        dotAria2File := checkDotAria2()
        if (dotAria2File != "" and FileExist(dotAria2File)) {
            OutputDebug "Deleting .aria2 file ..."
            FileDelete dotAria2File
        }
    }
    else {
        OutputDebug "Delete .aria2 file function is disabled."
    }
    return
}

deleteDotTorrent(*) {
    sleep(Aria2SessionInterval + 1)
    if (infoHash = "") {
        OutputDebug "General download task, skipped delete .torrent file."
    }
    else {
        dotTorrentFile := dir . infoHash . ".torrent"
        if (ExtDeleteDotTorrent = 1 | ExtDeleteDotTorrent = 2) {
            if (FileExist(dotTorrentFile)) {
                OutputDebug "Deleting .torrent file ..."
                FileDelete dotTorrentFile
            }
            else {
                OutputDebug ".torrent file may exist but cannot be found. Recommended to enable enhanced mode."
            }
        }
        else if (ExtDeleteDotTorrent = 2) {
            deleteTorrentEh()
        }
        else {
            OutputDebug "Delete .torrent file function is disabled."
        }
    }
}

deleteTorrentEh(*) {
    if (FileExist(Aria2SessionPath)) {
        session := FileRead(Aria2SessionPath)
        loop files dir . '*.torrent', "F"
            if (InStr(session, A_LoopFileName) != "") {
                OutputDebug "Deleting .torrent file (Enhanced) ..."
                FileDelete A_LoopFileFullPath
            }
            else {
                OutputDebug ".torrent file does not exist."
            }
    }
    else {
        OutputDebug "Session file does not exist."
    }
}

deleteExcludeFile(*) {
    deleteFileList := Array()
    saveFileList := Array()
    excludeExtList := StrSplit(ExcludeExt, "|")
    includeExtList := StrSplit(IncludeExt, "|")
    if (FileGetAttrib(filePath) = "D") {
        if (ExtDeleteExclude = 1) {
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
            OutputDebug "Delete exclude/include file function is disabled."
        }
    }
    return
}

checkFileExt(path := "", ext := "", fileList := Array()) {
    loop files path "*." ext, "FD" {
        fileList.Push(A_LoopFileFullPath)
    }
}

deleteEmptyDir(*) {
    if (ExtDeleteEmptyDir = 1) {
        loop files dir, "DR"
            if (A_LoopFileSize = 0) {
                DirDelete A_LoopFileFullPath
            }
    }
}

PrintLog(type:="",message:="",funcName:=""){
    logInfo:=Map()
    logInfo["time"]:=FormatTime(A_NoW,"yyyyMMddHHmmss")
    logInfo["function"]:=funcName
    logInfo["result"]:=type
    logInfo["message"]:=message
    logInfo["task"] := taskGid
    logInfo["taskFileCount"] := fileCount
    logInfo["taskFilePath"] := filePath
    LogOutput.Write(Jxon_Dump(logInfo) . "`n")
}