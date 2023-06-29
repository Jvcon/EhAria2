; --------------------- COMPILER DIRECTIVES --------------------------

;@Ahk2Exe-SetDescription Enhanced Aria2AHK
;@Ahk2Exe-SetVersion 0.1.0
;@Ahk2Exe-SetCopyright Jacques Yip
;@Ahk2Exe-SetMainIcon EhAria2.ico
;@Ahk2Exe-SetOrigFilename EhAria2.exe

; --------------------- GLOBAL --------------------------

#Include <ConfMan>
#Include <WebView2>
#Include <WindowsTheme>
#Include <Github>
#Include <WinHttpRequest>
#Include <Jxon>
#Include <DownloadAsync>

#Requires AutoHotkey >=v2.0
#SingleInstance force

FileEncoding "UTF-8-RAW"

Persistent

CONF_Path := ".\EhAria2.ini"
CONF := ConfMan.GetConf(CONF_Path)
CONF.Basic := {
    Language: "en_us"
    , Aria2Version: ""
    , Aria2Path: ""
    , Aria2ConfigPath: ""
    , Aria2Config: "aria2.conf"
    , Aria2ProxyEnable: 0
    , Aria2DhtEnable: 1
    , Aria2Dht6Enable: 0
}
CONF.Setting := {
      Aria2RpcPort: 6800
    , Aria2RpcSecret: ""
    , Aria2Proxy: ""
    , BTTrackersList: "https://cf.trackerslist.com/best.txt"
    , BTTrackers: ""
    , Aria2SessionPath: ""
    , Aria2DhtPath: ""
    , Aria2DhtListenPort: 51413
    , Aria2ListenPort: 51413
}
CONF.Profile := {
    CurrentProfile: 1
    , ProfileName1: "Downloads"
    , ProfilePath1: "D:/Downloads"
    , ProfileName2: ""
    , ProfilePath2: ""
    , ProfileName3: ""
    , ProfilePath3: ""
}
CONF.Speed := {
    CurrentSpeed: 1
    , SpeedName1: "高速-50M"
    , SpeedLimit1: "50M"
    , SpeedName2: "低速-18M"
    , SpeedLimit2: "18M"
    , SpeedName3: ""
    , SpeedLimit3: ""
}

CONF.Setting.SetOpts("PARAMS")
CONF.Profile.SetOpts("PARAMS")
CONF.Speed.SetOpts("PARAMS")
If !FileExist(CONF_Path) {
    FileAppend "", CONF_Path
}
If (FileRead(CONF_Path) = "") {
    CONF.WriteFile()
}
CONF.ReadFile()

If !FileExist(A_ScriptDir "\lang") {
    DirCreate(A_ScriptDir "\lang")
}

If (A_IsCompiled = 1) {
    FileInstall(".\lang\en_us.ini", "lang\en_us.ini", 1)
    FileInstall(".\lang\zh_cn.ini", "lang\zh_cn.ini", 1)

    FileInstall("index.html", "index.html", 1)
    FileInstall("WebView2Loader.dll", "WebView2Loader.dll", 1)
}

InitialLanguage()

If (!FileExist(A_ScriptDir . "\aria2.conf")) {
    FileInstall("aria2.conf", "aria2.conf")
}
else {
    If (FileRead(A_ScriptDir . "\aria2.conf") = "") {
        FileInstall("aria2.conf", "aria2.conf", 1)
    }
}


If (CONF.Basic.Aria2Path = "") {
    if (FileExist(A_ScriptDir . '\aria2c.exe')) {
        CheckUpdateAria2()
    }
    else {
        isIntegrated := MsgBox(lMsgItergratedDownload, lMsgNotFoundTitle, "Y/N T5")
        if (isIntegrated = "Yes") {
            InstallAria2()
        }
        else if (isIntegrated = "Timeout"){
            InstallAria2()
        }
        else if (isIntegrated = "No") {
            isCustom := MsgBox(lMsgCustomSelect, lMsgCustomNotFoundTitle, "Y/N")
            if (isCustom = "Yes") {
                SelectPath()
            }
            else {
                MsgBox(lMsgPathError,"O T5")
            }
        }
    }
}
else {
    if (FileExist(CONF.Basic.Aria2Path . '\aria2c.exe')) {
    }
    else {
        isCustom := MsgBox(lMsgCustomReselect, lMsgCustomNotFoundTitle, "R/N T5")
        if (isCustom = "RETRY") {
            SelectPath()
        }
        else {
            CONF.Basic.Aria2Path := ""
            CONF.WriteFile()
            InstallAria2()
        }
    }
}

If (CONF.Setting.Aria2SessionPath = "") {
    If (!FileExist(A_ScriptDir . "\aria2.session")) {
        FileAppend "", A_ScriptDir . "\aria2.session"
    }
}
else {
    If (!FileExist(CONF.Setting.Aria2SessionPath . "\aria2.session")) {
        FileAppend "", CONF.Setting.Aria2SessionPath . "\aria2.session"
    }
}

If (CONF.Basic.Aria2DhtEnable = 1 | CONF.Basic.Aria2Dht6Enable = 1){
    InitialDHT()
}

Global sysThemeMode := RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", "SystemUsesLightTheme")

Global CurrentSpeedName := IniRead(CONF_Path, "Speed", "SpeedName" . CONF.Speed.CurrentSpeed)
Global CurrentSpeedLimit := IniRead(CONF_Path, "Speed", "SpeedLimit" . CONF.Speed.CurrentSpeed)

Global CurrentProfileName := IniRead(CONF_Path, "Profile", "ProfileName" . CONF.Profile.CurrentProfile)
Global CurrentProfilePath := IniRead(CONF_Path, "Profile", "ProfilePath" . CONF.Profile.CurrentProfile)

Global Aria2RpcUrl := 'http://127.0.0.1:' . CONF.Setting.Aria2RpcPort . '/jsonrpc'

Global SubMenuProflie := Menu()
Global SubMenuSpeed := Menu()
Global SubMenuAddTask := Menu()
Global SubMenuAddTaskProxy := Menu()

Global EhAria2Tray := A_TrayMenu
global LangMenu := Menu()

WindowsTheme.SetAppMode(!sysThemeMode)

CreateTrayMenu()
CreateLangMenu()
CreateProfileMenu()
CreateSpeedMenu()
InitialProxy()

; --------------------- Intial --------------------------
If (CONF.Setting.BTTrackers = "") {
    UpdateBTTracker()
}

StartAria2()

Return

; --------------------- Func --------------------------
CreateTrayMenu(*) {
    A_IconTip := "Enhanced Aria2"
    If A_IsCompiled = 0
        TraySetIcon("EhAria2.ico", 1, 1)
    EhAria2Tray.Delete
    A_TrayMenu.ClickCount := 1
    EhAria2Tray.Add(lTrayLang, LangMenu)
    EhAria2Tray.Add(lTraySpeedLimit, SubMenuSpeed)
    EhAria2Tray.Add(lTrayProfile, SubMenuProflie)
    EhAria2Tray.Add(lTrayEnableProxy, SwitchProxyStatus)
    EhAria2Tray.Add(lTrayUpdateTrackerList, UpdateBTTracker)
    EhAria2Tray.Add
    EhAria2Tray.Add(lTrayExit, ExitTray)
    EhAria2Tray.Add(lTrayRestart, RestartAria2)
    EhAria2Tray.Add(lTrayOpenFolder, OpenFolder)
    EhAria2Tray.Add(lTrayOpenAriang, OpenFronted)
    A_TrayMenu.Default := lTrayOpenAriang
    EhAria2Tray.Add
    EhAria2Tray.Add(lTrayAddTorrentTo, AddTorrent)

    EhAria2Tray.Add(lTrayAddTaskProxyTo, SubMenuAddTaskProxy)
    EhAria2Tray.Add(lTrayAddTaskTo, SubMenuAddTask)
    EhAria2Tray.Add
    EhAria2Tray.Add(lTrayAddTorrent, AddTorrent)
    EhAria2Tray.Add(lTrayAddTask, AddTaskMenuHandler)
    return
}

CreateLangMenu(*) {
    LangMenu.Delete
    Loop Files A_ScriptDir "\lang\*.ini" {
        SplitPath A_LoopFileName, , , , &FileNameNoExt
        LangMenu.Add(FileNameNoExt, SwitchLanguage)
    }
    LangMenu.Check(CONF.Basic.Language)
    return
}

CreateProfileMenu(recreate := 0) {
    If (recreate = 1) {
        SubMenuProflie.Delete
        SubMenuAddTask.Delete
        SubMenuAddTaskProxy.Delete
    }
    If (CONF.Profile.ProfileName1 != "") {
        SubMenuProflie.Add(CONF.Profile.ProfileName1, SwitchProfile)
        SubMenuAddTask.Add(CONF.Profile.ProfileName1, AddTaskToMenuHandler)
        SubMenuAddTaskProxy.Add(CONF.Profile.ProfileName1, AddTaskToMenuHandler)
    }
    If (CONF.Profile.ProfileName2 != "") {
        SubMenuProflie.Add(CONF.Profile.ProfileName2, SwitchProfile)
        SubMenuAddTask.Add(CONF.Profile.ProfileName2, AddTaskToMenuHandler)
        SubMenuAddTaskProxy.Add(CONF.Profile.ProfileName2, AddTaskToMenuHandler)
    }
    If (CONF.Profile.ProfileName3 != "") {
        SubMenuProflie.Add(CONF.Profile.ProfileName3, SwitchProfile)
        SubMenuAddTask.Add(CONF.Profile.ProfileName3, AddTaskToMenuHandler)
        SubMenuAddTaskProxy.Add(CONF.Profile.ProfileName3, AddTaskToMenuHandler)

    }
    If (CurrentProfileName != "") {
        SubMenuProflie.Check(CurrentProfileName)
    }
    return
}

CreateSpeedMenu(recreate := 0) {
    If (recreate = 1) {
        SubMenuSpeed.Delete
    }
    If (CONF.Speed.SpeedName1 != "") {
        SubMenuSpeed.Add(CONF.Speed.SpeedName1, SwitchSpeedLimit)
    }
    If (CONF.Speed.SpeedName2 != "") {
        SubMenuSpeed.Add(CONF.Speed.SpeedName2, SwitchSpeedLimit)
    }
    If (CONF.Speed.SpeedName3 != "") {
        SubMenuSpeed.Add(CONF.Speed.SpeedName3, SwitchSpeedLimit)
    }
    If (CurrentSpeedName != "") {
        SubMenuSpeed.Check(CurrentSpeedName)
    }
    return
}

AddTaskToMenuHandler(ItemName, ItemPos, MyMenu) {
    If (MyMenu = SubMenuAddTaskProxy) {
        AddTask(, ItemPos, 1)
    }
    else if (MyMenu = SubMenuAddTask) {
        AddTask(, ItemPos, 0)
    }
    return
}

AddTaskMenuHandler(ItemName := 0, ItemPos := 0, MyMenu := 0) {
    AddTask()
}

AddTask(uri := "", profile := "", proxy := "") {

    if (proxy = "") {
        proxy := CONF.Basic.Aria2ProxyEnable
    }

    if (profile = "") {
        profile := CONF.Profile.CurrentProfile
        path := CurrentProfilePath
    }
    else if (profile > 3) {
        MsgBox "Couldn't found profile"
        return
    }
    else {
        path := IniRead(CONF_Path, "Profile", "ProfilePath" . profile)
    }

    if (uri = "") {
        UriInput(&uri)
        ; uriInput:= InputBox("新建 HTTP / HTTPS / FTP / SFTP / Magnet 任务:", "添加任务", "w320 h240")
    }
    if (uri = "") {
        return
    }
    if (CONF.Setting.Aria2RpcSecret = "") {
        if (proxy != 0) {
            Aria2AddTaskData := '`{"jsonrpc":"2.0","id":"1","method":"aria2.addUri","params":[["' . uri . '"],`{"dir":"' . path . '","all-proxy":"' . CONF.Setting.Aria2Proxy . '"}]}'
        }
        else {
            Aria2AddTaskData := "`{`"jsonrpc`":`"2.0`",`"id`":`"1`",`"method`":`"aria2.addUri`",`"params`":[[`"" . uri . "`"],`{`"dir`":`"" . path . "`"`}]`}"
        }
    }
    else {
        if (proxy != 0) {
            Aria2AddTaskData := '`{"jsonrpc":"2.0","id":"1","method":"aria2.addUri","params":["token:' . CONF.Setting.Aria2RpcSecret . '",["' . uri . '"],`{"dir":"' . path . '","all-proxy":"' . CONF.Setting.Aria2Proxy . '"}]}'
        }
        else {
            Aria2AddTaskData := "`{`"jsonrpc`":`"2.0`",`"id`":`"1`",`"method`":`"aria2.addUri`",`"params`":[`"token:" . CONF.Setting.Aria2RpcSecret . "`",[`"" . uri . "`"],`{`"dir`":`"" . path . "`"`}]`}"
        }
    }
    HttpPost(Aria2RpcUrl, Aria2AddTaskData)
}

SaveSession(*) {
    if (CONF.Setting.Aria2RpcSecret = "") {
        Aria2SaveSessionData := '{"jsonrpc":"2.0","id":"1","method":"aria2.saveSession"}'
    }
    else {
        Aria2SaveSessionData := '{"jsonrpc":"2.0","id":"1","method":"aria2.saveSession","params":["token:' . CONF.Setting.Aria2RpcSecret . '"]}'
    }
    HttpPost(Aria2RpcUrl, Aria2SaveSessionData)
}

UriInput(&uri) {
    ReturnNow := false
    UriInputGui := Gui("-Theme")
    WindowsTheme.SetWindowAttribute(UriInputGui, !sysThemeMode)
    UriInputGui.Add("Text", "x2 y2 w320 h20", lGuiUriInputText)
    UriInputEdit := UriInputGui.Add("Edit", "vuri x2 y20 w320 h240 r4")
    UriInputBtnOK := UriInputGui.Add("Button", "x2 y90 w149 h30", lGuiUriInputBtnOK)
    UriInputBtnOK.OnEvent("Click", MLI_OK.Bind("Normal"))
    UriInputBtnCancel := UriInputGui.Add("Button", "x159 y90 w149 h30", lGuiUriInputBtnCancel)
    UriInputBtnCancel.OnEvent("Click", MLI_Cancel.Bind("Normal"))
    UriInputGui.Title := lGuiUriInputTitle
    WindowsTheme.SetWindowTheme(UriInputGui, !sysThemeMode)
    UriInputGui.Show("h120 w330")
    MLI_Wait()
    MLI_OK(A_GuiEvent, GuiCtrlObj, Info, *) {
        uri := UriInputEdit.Text
        ReturnNow := true
    }
    MLI_Cancel(A_GuiEvent, GuiCtrlObj, Info, *) {
        uri := ""
        ReturnNow := true
    }
    MLI_Wait(*) {
        while (!ReturnNow) {
            Sleep(100)
        }
    }
    UriInputGui.Destroy
    return uri
}

AddTorrent(ItemName := 0, ItemPos := 0, MyMenu := 0) {
    If (A_IsCompiled = 1) {
        Run A_ScriptDir . "\EhAria2Torrent.exe"
    }
    else {
        Run A_ScriptDir . "\EhAria2Torrent.ahk"
    }
    return
}

HttpPost(URL, PData) {
    Static WebRequest := ComObject("WinHttp.WinHttpRequest.5.1")
    WebRequest.Open("POST", URL, True)
    WebRequest.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
    WebRequest.Send(PData)
    WebRequest.WaitForResponse(-1)
}

OpenFolder(*) {
    Run CurrentProfilePath
    return
}

OpenFronted(*) {
    if (WinExist("AriaNG")) {
        WinActivate "AriaNG"
    } else {
        AriaNGInitial()
        AriaNG.Show(Format('w{} h{}', A_ScreenWidth * 0.6, A_ScreenHeight * 0.6))
    }
    return
}

AriaNGInitial() {
    global AriaNG := Gui('+Resize')
    WindowsTheme.SetWindowAttribute(AriaNG, !sysThemeMode)
    If !DirExist(A_Temp "\EhAria2\")
        DirCreate(A_Temp "\EhAria2\")
    global wvc := WebView2.create(AriaNG.Hwnd, AriaNGInvoke, 0, A_Temp "\EhAria2\")
    AriaNG.MarginX := AriaNG.MarginY := 0
    AriaNG.Title := "AriaNG"
    AriaNG.OnEvent('Size', AriaNGGuiSize)
    WindowsTheme.SetWindowTheme(AriaNG, !sysThemeMode)
    return
}

AriaNGInvoke(wvc) {
    global
    AriaNG.GetClientPos(, , &w, &h)
    ctl := AriaNG.AddText('x0 y25 w' w ' h' (h - 25))
    wv := wvc.CoreWebView2
    wv.Navigate('file:///' A_ScriptDir '\index.html')
    return (wvc)
}

AriaNGGuiSize(GuiObj, MinMax, Width, Height) {
    If (MinMax != -1) {
        try ctl.Move(, , Width, Height - 23)
        try wvc.Fill()
    }
    return
}

SwitchSpeedLimit(ItemName := 0, ItemPos := 0, MyMenu := 0) {
    SubMenuSpeed.ToggleCheck(CurrentSpeedName)
    CONF.Speed.CurrentSpeed := ItemPos
    Global CurrentSpeedName := IniRead(CONF_Path, "Speed", "SpeedName" . CONF.Speed.CurrentSpeed)
    Global CurrentSpeedLimit := IniRead(CONF_Path, "Speed", "SpeedLimit" . CONF.Speed.CurrentSpeed)
    SubMenuSpeed.ToggleCheck(CurrentSpeedName)
    CONF.WriteFile()
    if (CONF.Setting.Aria2RpcSecret = "") {
        Aria2GlobalOptionData := '{"jsonrpc":"2.0","id":"1","method":"aria2.changeGlobalOption","params":[{"max-download-limit":"' . CurrentSpeedLimit . '"}]}'
    }
    else {
        Aria2GlobalOptionData := '{"jsonrpc":"2.0","id":"1","method":"aria2.changeGlobalOption","params":["token:' . CONF.Setting.Aria2RpcSecret . '",`{"max-download-limit":"' . CurrentSpeedLimit . '"}]}'
    }
    HttpPost(Aria2RpcUrl, Aria2GlobalOptionData)
    return
}

SwitchProfile(ItemName := 0, ItemPos := 0, MyMenu := 0) {
    SubMenuProflie.ToggleCheck(CurrentProfileName)
    CONF.Profile.CurrentProfile := ItemPos
    Global CurrentProfileName := IniRead(CONF_Path, "Profile", "ProfileName" . CONF.Profile.CurrentProfile)
    Global CurrentProfilePath := IniRead(CONF_Path, "Profile", "ProfilePath" . CONF.Profile.CurrentProfile)
    SubMenuProflie.ToggleCheck(CurrentProfileName)
    if (CONF.Setting.Aria2RpcSecret = "") {
        Aria2GlobalOptionData := '{"jsonrpc":"2.0","id":"1","method":"aria2.changeGlobalOption","params":[{"dir":"' . CurrentProfilePath . '"}]}'
    }
    else {
        Aria2GlobalOptionData := '{"jsonrpc":"2.0","id":"1","method":"aria2.changeGlobalOption","params":["token:' . CONF.Setting.Aria2RpcSecret . '",`{"dir":"' . CurrentProfilePath . '"}]}'
    }
    CONF.WriteFile()
    HttpPost(Aria2RpcUrl, Aria2GlobalOptionData)
    return
}

SwitchProxyStatus(*) {
    If (CONF.Basic.Aria2ProxyEnable = 1) {
        CONF.Basic.Aria2ProxyEnable := 0
        if (CONF.Setting.Aria2RpcSecret = "") {
            Aria2GlobalOptionData := '{"jsonrpc":"2.0","id":"1","method":"aria2.changeGlobalOption","params":[{"all-proxy":""}]}'
        }
        else {
            Aria2GlobalOptionData := '{"jsonrpc":"2.0","id":"1","method":"aria2.changeGlobalOption","params":["token:' . CONF.Setting.Aria2RpcSecret . '",`{"all-proxy":""}]}'
        }
        HttpPost(Aria2RpcUrl, Aria2GlobalOptionData)
    } else {
        If (!(CONF.Setting.Aria2Proxy = "")) {
            CONF.Basic.Aria2ProxyEnable := 1
            if (CONF.Setting.Aria2RpcSecret = "") {
                Aria2GlobalOptionData := '{"jsonrpc":"2.0","id":"1","method":"aria2.changeGlobalOption","params":[{"all-proxy":"' . CONF.Setting.Aria2Proxy . '"}]}'
            }
            else {
                Aria2GlobalOptionData := '{"jsonrpc":"2.0","id":"1","method":"aria2.changeGlobalOption","params":["token:' . CONF.Setting.Aria2RpcSecret . '",`{"all-proxy":"' . CONF.Setting.Aria2Proxy . '"}]}'
            }
            HttpPost(Aria2RpcUrl, Aria2GlobalOptionData)
        }
        else {
            MsgBox lMsgProxyError
        }
    }
    CONF.WriteFile()
    InitialProxy()
    return
}

InitialProxy(*) {
    If (CONF.Basic.Aria2ProxyEnable = 1) {
        If (!(CONF.Setting.Aria2Proxy = "")) {
            EhAria2Tray.Check(lTrayEnableProxy)
        }
        else {
            MsgBox lMsgProxyError
        }
    }
    else {
        EhAria2Tray.Uncheck(lTrayEnableProxy)
    }
}


SelectPath(*) {
    aira2selectpath := DirSelect(, 0, lMsgSelectPathTitle)
    if (aira2selectpath = "") {
        MsgBox(lMsgPathError,"O T5")
        ExitTray()
    }
    else {
        if (FileExist(aira2selectpath . '\aria2c.exe')) {
            CONF.Basic.Aria2Path := aira2selectpath
            CONF.WriteFile()
        }
        else {
            MsgBox(lMsgPathError,"O T5")
            ExitTray()
        }
    }
    return
}

UpdateBTTracker(ItemName := 0, ItemPos := 0, MyMenu := 0)
{
    Download CONF.Setting.BTTrackersList, A_ScriptDir . "\TrackersLists.list"
    Trackers := ""
    loop read A_ScriptDir . "\TrackersLists.list"
        if (A_LoopReadLine = "") {

        } else {
            Trackers .= A_LoopReadLine ','
        }

    IniWrite Trackers, CONF_Path, "Setting", "BTTrackers"
    FileDelete A_ScriptDir . "\TrackersLists.list"
    Reload
    return
}

InitialDHT(ItemName := 0, ItemPos := 0, MyMenu := 0){
    if (CONF.Setting.Aria2DhtPath=""){
        if !(FileExist(A_Temp . "\EhAria2\" . "dht.dat")){
            DownloadDHT("dht.dat")    
        }
        if !(FileExist(A_Temp . "\EhAria2\" . "dht6.dat")){
            DownloadDHT("dht6.dat")    
        }
    }
    else{

    }
    return
}

DownloadDHT( path:= A_Temp . "\EhAria2\", filename := "dht.dat"){
    try {
        Download "https://github.com/P3TERX/aria2.conf/raw/master/" filename, path . filename
    }
    catch as error{
        downloadError := MsgBox(error,, "RC Default2 T5")
        if (downloadError = "Cancel"){
            FileAppend "", A_ScriptDir . "\" . filename
        }
        else if (downloadError = "Retry"){
            Download "https://github.com/P3TERX/aria2.conf/raw/master/" filename, path . filename
        }
        else if (downloadError = "Timeout"){
            Download "https://github.com/P3TERX/aria2.conf/raw/master/" filename, path . filename   
        }
    }
}

StartAria2(*) {
    If (CONF.Basic.Aria2Path = "") {
        cmd := A_ScriptDir . "\aria2c.exe"
    }
    else {
        cmd := CONF.Basic.Aria2Path . '\aria2c.exe'
    }
    If (CONF.Basic.Aria2ConfigPath = "") {
        cmd .= " --conf-path=" A_ScriptDir . "\" . CONF.Basic.Aria2Config
    }
    else {
        cmd .= " --conf-path=" CONF.Basic.Aria2ConfigPath . "\" . CONF.Basic.Aria2Config
    }
    If (CONF.Setting.Aria2SessionPath = "") {
        cmd .= " --input-file=" A_ScriptDir . "\aria2.session"
        cmd .= " --save-session=" A_ScriptDir . "\aria2.session"
    }
    else {
        cmd .= " --input-file=" CONF.Setting.Aria2SessionPath . "\aria2.session"
        cmd .= " --save-session=" CONF.Setting.Aria2SessionPath . "\aria2.session"
    }
    cmd .= " --enable-rpc=true"
    cmd .= " --rpc-allow-origin-all=true"
    cmd .= " --rpc-listen-all=true"
    If (CONF.Setting.Aria2RpcPort != "") {
        cmd .= " --rpc-listen-port=" CONF.Setting.Aria2RpcPort
    }
    else {
        cmd .= " --rpc-listen-port=6800"
    }
    If (CONF.Setting.Aria2RpcSecret != "") {
        cmd .= " --rpc-secret=" CONF.Setting.Aria2RpcSecret
    }
    If (CONF.Basic.Aria2ProxyEnable = 1) {
        If (!(CONF.Setting.Aria2Proxy = "")) {
            cmd .= " --all-proxy=`"" CONF.Setting.Aria2Proxy "`""
        }
    }
    cmd .= " --max-overall-download-limit=" . CurrentSpeedLimit
    cmd .= " --max-download-limit=" . CurrentSpeedLimit
    cmd .= " --dir=" . CurrentProfilePath
    cmd .= " --bt-tracker=" . CONF.Setting.BTTrackers
    cmd .= " --listen-port=" . CONF.Setting.Aria2ListenPort
    cmd .= " --dht-listen-port=" . CONF.Setting.Aria2DhtListenPort
    If (CONF.Basic.Aria2DhtEnable = 1 ){
        cmd .= " --enable-dht=true"
        If (!(CONF.Setting.Aria2DhtPath = "")){
            cmd .= " --dht-file-path=" . CONF.Setting.Aria2DhtPath . "\dht.dat"
        }
        else {
            cmd .= " --dht-file-path=" . A_Temp . "\EhAria2\dht.dat"
        }
    }
    If (CONF.Basic.Aria2Dht6Enable = 1 ){
        cmd .= " --enable-dht6=true"
        If (!(CONF.Setting.Aria2DhtPath = "")){
            cmd .= " --dht-file-path6=" . CONF.Setting.Aria2DhtPath . "\dht6.dat"
        }
        else {
            cmd .= " --dht-file-path6=" . A_Temp . "\EhAria2\dht.dat"
        }
    }
    Run cmd, , "Hide"
    return
}

CheckKillAria2()
{
    If ProcessExist("aria2c.exe") != 0
        SaveSession()
        ProcessClose("aria2c.exe")
    return
}

RestartAria2(*) {
    CheckKillAria2()
    StartAria2()
    return
}

SwitchLanguage(ItemName, ItemPos, MyMenu) {
    CONF.Basic.Language := ItemName
    CONF.WriteFile()
    InitialLanguage()
    CreateTrayMenu()
    CreateLangMenu()
    return
}

CheckUpdateAria2(*) {
    Aria2Repo := Github("aria2", "aria2")
    Aria2LatestVersion := Aria2Repo.Version
    if (CONF.Basic.Aria2Version != Aria2LatestVersion) {
        InstallAria2()
        CONF.Basic.Aria2Version := Aria2LatestVersion
        CONF.WriteFile()
    }
    return
}

InstallAria2(*) {
    try DirDelete A_ScriptDir "\temp", 1
    try FileDelete A_ScriptDir "\release.zip"
    Aria2Repo := Github("aria2", "aria2")
    Aria2LatestVersion := Aria2Repo.Version
    DownloadUrl := Aria2Repo.searchReleases("win-64bit")
    Aria2Repo.Download(A_ScriptDir "\release.zip", DownloadUrl)
    psExpandArchiveScript := "
        (
            param($src, $dest)
            Expand-Archive -Path $src -DestinationPath $dest
        )"
    src := "release.zip"
    dest := A_ScriptDir "\temp"
    RunWait("PowerShell.exe -Command &{" psExpandArchiveScript "} '" src "' '" dest "'", , "hide")
    loop files, A_ScriptDir "\temp\*.exe", "FR"
        if (InStr(A_LoopFileFullPath, "aria2c.exe")) {
            FileCopy A_LoopFileFullPath, A_ScriptDir "\aria2c.exe", true
            DirDelete A_ScriptDir "\temp", 1
            FileDelete A_ScriptDir "\release.zip"
        }
    CONF.Basic.Aria2Version := Aria2LatestVersion
    CONF.WriteFile()
    return
}

InitialLanguage(*) {
    LANG_PATH := A_ScriptDir "\lang\" CONF.Basic.Language ".ini"

    global lTrayExit := IniRead(LANG_PATH, "Tray", "exit")
    global lTrayRestart := IniRead(LANG_PATH, "Tray", "restart")
    global lTrayOpenFolder := IniRead(LANG_PATH, "Tray", "openfolder")
    global lTrayOpenAriang := IniRead(LANG_PATH, "Tray", "openariang")

    global lTrayLang := IniRead(LANG_PATH, "Tray", "lang")
    global lTraySpeedLimit := IniRead(LANG_PATH, "Tray", "speedlimit")
    global lTrayProfile := IniRead(LANG_PATH, "Tray", "profile")
    global lTrayEnableProxy := IniRead(LANG_PATH, "Tray", "enableproxy")
    global lTrayUpdateTrackerList := IniRead(LANG_PATH, "Tray", "updatetracker")

    global lTrayAddTorrentTo := IniRead(LANG_PATH, "Tray", "addtorrentto")
    global lTrayAddTaskProxyTo := IniRead(LANG_PATH, "Tray", "addtaskproxyto")
    global lTrayAddTaskTo := IniRead(LANG_PATH, "Tray", "addtaskto")
    global lTrayAddTorrent := IniRead(LANG_PATH, "Tray", "addtorrent")
    global lTrayAddTask := IniRead(LANG_PATH, "Tray", "addstask")

    global lGuiUriInputText := IniRead(LANG_PATH, "GuiUriInput", "text")
    global lGuiUriInputBtnOK := IniRead(LANG_PATH, "GuiUriInput", "btnok")
    global lGuiUriInputBtnCancel := IniRead(LANG_PATH, "GuiUriInput", "btncancel")
    global lGuiUriInputTitle := IniRead(LANG_PATH, "GuiUriInput", "title")

    global lMsgProxyError := IniRead(LANG_PATH, "Msg", "proxyerror")
    global lMsgPathError := IniRead(LANG_PATH, "Msg", "patherror")
    global lMsgNotFoundTitle := IniRead(LANG_PATH, "Msg", "notfoundtitle")
    global lMsgCustomNotFoundTitle := IniRead(LANG_PATH, "Msg", "customnotfoundtitle")
    global lMsgItergratedDownload := IniRead(LANG_PATH, "Msg", "integrateddownload")
    global lMsgCustomSelect := IniRead(LANG_PATH, "Msg", "customselect")
    global lMsgCustomReselect := IniRead(LANG_PATH, "Msg", "customreselect")
    global lMsgSelectPathTitle := IniRead(LANG_PATH, "Msg", "selectpathtitle")

    return
}

ExitTray(*) {
    CheckKillAria2()
    CONF.WriteFile()
    ExitApp
    Return
}
