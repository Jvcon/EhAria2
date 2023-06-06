; --------------------- COMPILER DIRECTIVES --------------------------

;@Ahk2Exe-SetDescription Enhanced Aria2AHK
;@Ahk2Exe-SetVersion 0.0.0.4
;@Ahk2Exe-SetCopyright Jacques Yip
;@Ahk2Exe-SetMainIcon EhAria2.ico
;@Ahk2Exe-SetOrigFilename EhAria2.exe

; --------------------- GLOBAL --------------------------

#Include <ConfMan>
#Include <WebView2>

#Requires AutoHotkey >=v2.0
#SingleInstance force

FileEncoding "UTF-8-RAW"

Persistent

CONF_Path := ".\EhAria2.ini"
CONF := ConfMan.GetConf(CONF_Path)
CONF.Setting := {
    Aria2Path: ""
    , Aria2ConfigPath: ""
    , Aria2Config: "aria2.conf"
    , Aria2RpcPort: 6800
    , Aria2RpcSecret: ""
    , Aria2ProxyEnable: 0
    , Aria2Proxy: ""
    , BTTrackersList: "https://cf.trackerslist.com/best.txt"
    , BTTrackers: ""
    , Aria2SessionPath: ""
}
CONF.Profile := {
    CurrentProfile: 1
    , ProfileName1: "Downloads"
    , ProfilePath1: "D:\Downloads"
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
    , SpeedLimit2: "8M"
    , SpeedName3: ""
    , SpeedLimit3: ""
}

CONF.Setting.SetOpts("PARAMS")
CONF.Profile.SetOpts("PARAMS")
CONF.Speed.SetOpts("PARAMS")
If !FileExist(CONF_Path) {
    FileAppend "", CONF_Path
}
If(FileRead(CONF_Path)=""){
    CONF.WriteFile()
}
CONF.ReadFile()

FileInstall("index.html", "index.html", 1)
FileInstall("WebView2Loader.dll", "WebView2Loader.dll", 1)
If (!FileExist(A_ScriptDir . "\aria2.conf")) {
    FileInstall("aria2.conf", "aria2.conf")
}
else{
    If(FileRead(A_ScriptDir . "\aria2.conf")=""){
        FileInstall("aria2.conf", "aria2.conf",1)
    }
}

If (!FileExist(CONF.Setting.Aria2Path . '\aria2c.exe')){
    MsgBox "The aria2 couldn't found, the program will exit."
    ExitTray()
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


Global CurrentSpeedName := IniRead(CONF_Path, "Speed", "SpeedName" . CONF.Speed.CurrentSpeed)
Global CurrentSpeedLimit := IniRead(CONF_Path, "Speed", "SpeedLimit" . CONF.Speed.CurrentSpeed)

Global CurrentProfileName := IniRead(CONF_Path, "Profile", "ProfileName" . CONF.Profile.CurrentProfile)
Global CurrentProfilePath := IniRead(CONF_Path, "Profile", "ProfilePath" . CONF.Profile.CurrentProfile)

Global Aria2RpcUrl := 'http://127.0.0.1:' . CONF.Setting.Aria2RpcPort . '/jsonrpc'

Global SubMenuProflie := Menu()
Global SubMenuSpeed := Menu()
Global SubMenuAddTask := Menu()
Global SubMenuAddTaskProxy := Menu()

Global AriaNg := Gui("Resize")
Global main
Global wvc

; --------------------- Tray --------------------------

A_IconTip := "Enhanced Aria2AHK"
If A_IsCompiled = 0
    TraySetIcon("EhAria2.ico", 1, 1)
EhAria2Tray := A_TrayMenu
EhAria2Tray.Delete
A_TrayMenu.ClickCount := 1

EhAria2Tray.Add("Speed Limit", SubMenuSpeed)
EhAria2Tray.Add("Profile", SubMenuProflie)
EhAria2Tray.Add("Enable Proxy", SwitchProxyStatus)
If (CONF.Setting.Aria2ProxyEnable = 1) {
    EhAria2Tray.Check("Enable Proxy")
}
EhAria2Tray.Add("Update TrackersList", UpdateBTTracker)
EhAria2Tray.Add
EhAria2Tray.Add "Exit", ExitTray
EhAria2Tray.Add "Restart", RestartAria2
EhAria2Tray.Add("Open AriaNG", OpenFronted)
A_TrayMenu.Default := "Open AriaNG"
EhAria2Tray.Add
EhAria2Tray.Add("Add Torrent to...", AddTorrent)

EhAria2Tray.Add("Add Task with Proxy to ...", SubMenuAddTaskProxy)
EhAria2Tray.Add("Add Task to ...", SubMenuAddTask)
EhAria2Tray.Add
EhAria2Tray.Add("Add Torrent", AddTorrent)
EhAria2Tray.Add("Add Task", AddTaskMenuHandler)

CreateProfileMenu()
CreateSpeedMenu()

; --------------------- Intial --------------------------
If (CONF.Setting.BTTrackers = "") {
    UpdateBTTracker()
}

StartAria2()

return

; --------------------- Func --------------------------
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
        AddTask(,ItemPos,1)
    }
    else if (MyMenu = SubMenuAddTask) {
        AddTask(,ItemPos,0)
    }
    return
}

AddTaskMenuHandler(ItemName := 0, ItemPos := 0, MyMenu := 0) {
    AddTask()
}

AddTask(uri:="",profile:="",proxy:=""){
    if (proxy=""){
        proxy := CONF.Setting.Aria2ProxyEnable
    }
    if (profile=""){
        profile := CONF.Profile.CurrentProfile
        path := CurrentProfilePath
    }
    else if (profile>3){
        MsgBox "Couldn't found profile"
        return
    }
    else{
        path:= IniRead(CONF_Path, "Profile", "ProfilePath" . profile)
    }
    if (uri=""){
        uri := InputBox("新建 HTTP / HTTPS / FTP / SFTP / Magnet 任务:", "添加任务", "w320 h240").Value
    }
    if (uri=""){
        return
    }
    if(CONF.Setting.Aria2RpcSecret=""){
        if(proxy !=0){
            Aria2AddTaskData := '`{"jsonrpc":"2.0","id":"1","method":"aria2.addUri","params":[["' . uri . '"],`{"dir":"' . path . '","all-proxy":"' . CONF.Setting.Aria2Proxy . '"}]}'
        }
        else{
            Aria2AddTaskData := "`{`"jsonrpc`":`"2.0`",`"id`":`"1`",`"method`":`"aria2.addUri`",`"params`":[[`"" . uri . "`"],`{`"dir`":`"" . path . "`"`}]`}"
        }
    }
    else{
        if (proxy!=0){
            Aria2AddTaskData := '`{"jsonrpc":"2.0","id":"1","method":"aria2.addUri","params":["token:' . CONF.Setting.Aria2RpcSecret . '",["' . uri . '"],`{"dir":"' . path . '","all-proxy":"' . CONF.Setting.Aria2Proxy . '"}]}'
        }
        else{
            Aria2AddTaskData := "`{`"jsonrpc`":`"2.0`",`"id`":`"1`",`"method`":`"aria2.addUri`",`"params`":[`"token:" . CONF.Setting.Aria2RpcSecret . "`",[`"" . uri . "`"],`{`"dir`":`"" . path . "`"`}]`}"
        }
    }
    HttpPost(Aria2RpcUrl, Aria2AddTaskData)
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

OpenFronted(*) {
    WVInitial()
    main.Show(Format('w{} h{}', A_ScreenWidth * 0.6, A_ScreenHeight * 0.6))
    return
}

WVInitial() {
    global main := Gui('+Resize')
    If !DirExist(A_Temp "\EhAria2\")
        DirCreate(A_Temp "\EhAria2\")
    global wvc := WebView2.create(main.Hwnd, MainInvoke, 0, A_Temp "\EhAria2\")
    main.MarginX := main.MarginY := 0
    main.Title := "AriaNG"
    main.OnEvent('Size', WVGuiSize)
    return
}

MainInvoke(wvc) {
    global
    main.GetClientPos(, , &w, &h)
    ctl := main.AddText('x0 y25 w' w ' h' (h - 25))
    wv := wvc.CoreWebView2
    wv.Navigate('file:///' A_ScriptDir '\index.html')
    return (wvc)
}

WVGuiSize(GuiObj, MinMax, Width, Height) {
    If (MinMax != -1) {
        try ctl.Move(, , Width, Height - 23)
        try wvc.Fill()
    }
    return
}

SwitchSpeedLimit(ItemName := 0, ItemPos := 0, MyMenu := 0) {
    global
    SubMenuSpeed.ToggleCheck(CurrentSpeedName)
    CONF.Speed.CurrentSpeed := ItemPos
    global CurrentSpeedName := IniRead(CONF_Path, "Speed", "SpeedName" . CONF.Speed.CurrentSpeed)
    SubMenuSpeed.ToggleCheck(CurrentSpeedName)
    RestartAria2()
    return
}

SwitchProfile(ItemName := 0, ItemPos := 0, MyMenu := 0) {
    SubMenuProflie.ToggleCheck(CurrentProfileName)
    CONF.Profile.CurrentProfile := ItemPos
    global CurrentProfileName := IniRead(CONF_Path, "Profile", "ProfileName" . CONF.Profile.CurrentProfile)
    SubMenuProflie.ToggleCheck(CurrentProfileName)
    RestartAria2()
    return
}

SwitchProxyStatus(*) {
    If (CONF.Setting.Aria2ProxyEnable = 1) {
        CONF.Setting.Aria2ProxyEnable := 0
    } else {
        CONF.Setting.Aria2ProxyEnable := 1
    }
    EhAria2Tray.ToggleCheck("Enable Proxy")
    return
}

UpdateBTTracker(ItemName := 0, ItemPos := 0, MyMenu := 0)
{
    Download CONF.Setting.BTTrackersList, A_ScriptDir . "\TrackersLists.list"
    Trackers := FileOpen(A_ScriptDir . "\TrackersLists.list", "r").ReadLine()
    IniWrite Trackers, CONF_Path, "Setting", "BTTrackers"
    FileDelete A_ScriptDir . "\TrackersLists.list"
    Reload
    return
}

StartAria2(*) {
    If (CONF.Setting.Aria2Path = "") {
        cmd := A_ScriptDir . "\aria2c.exe"
    }
    else {
        cmd := CONF.Setting.Aria2Path . '\aria2c.exe'
    }
    If (CONF.Setting.Aria2ConfigPath = "") {
        cmd .= " --conf-path=" A_ScriptDir . "\" . CONF.Setting.Aria2Config
    }
    else {
        cmd .= " --conf-path=" CONF.Setting.Aria2ConfigPath . "\" . CONF.Setting.Aria2Config
    }
    If (CONF.Setting.Aria2SessionPath = "") {
        cmd .= " --input-file=" A_ScriptDir . "\aria2.session"
        cmd .= " --save-session=" A_ScriptDir . "\aria2.session"
    }
    else {
        cmd .= " --input-file=" CONF.Setting.Aria2SessionPath . "\aria2.session"
        cmd .= " --save-session=" CONF.Setting.Aria2SessionPath . "\aria2.session"
    }
    If (CONF.Setting.Aria2RpcPort != ""){
        cmd .= " --rpc-listen-port=" CONF.Setting.Aria2RpcPort
    }
    else{
        cmd .= " --rpc-listen-port=6800"
    }
    If (CONF.Setting.Aria2RpcSecret != "") {
        cmd .= " --rpc-secret=" CONF.Setting.Aria2RpcSecret
    }
    cmd .= " --max-overall-download-limit=" . CurrentSpeedLimit
    cmd .= " --max-download-limit=" . CurrentSpeedLimit
    cmd .= " --dir=" . CurrentProfilePath
    cmd .= " --bt-tracker=" . CONF.Setting.BTTrackers
    Run cmd, , "Hide"
    return
}

CheckKillAria2()
{
    If ProcessExist("aria2c.exe") != 0
    ProcessClose("aria2c.exe")
    return
}

RestartAria2(*) {
    CheckKillAria2()
    StartAria2()
    return
}

ExitTray(*) {
    CheckKillAria2()
    CONF.WriteFile()
    ExitApp
    Return
}