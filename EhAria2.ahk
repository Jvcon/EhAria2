; --------------------- COMPILER DIRECTIVES --------------------------

;@Ahk2Exe-SetDescription Enhanced Aria2AHK
;@Ahk2Exe-SetVersion 0.2.2
;@Ahk2Exe-SetCopyright Jacques Yip
;@Ahk2Exe-SetMainIcon EhAria2.ico
;@Ahk2Exe-SetOrigFilename EhAria2.exe

; --------------------- INCLUDE --------------------------
#Include <ConfMan>
#Include <WebView2>
#Include <WindowsTheme>
#Include <Github>
#Include <WinHttpRequest>
#Include <Jxon>
#Include <DownloadAsync>
#Include <Aria2Rpc>
#Include <i18n>

#Requires AutoHotkey >=v2.0
#SingleInstance force

FileEncoding "UTF-8-RAW"

Persistent

; --------------------- INITIALIZATION - Configuration --------------------------
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
    , CheckUpdateOnStartup: 1
}
CONF.Setting := {
    Aria2RpcPort: 6800
    , Aria2RpcSecret: ""
    , Aria2Proxy: ""
    , BTTrackersList: "https://cf.trackerslist.com/best.txt"
    , BTTrackers: ""
    , Aria2SessionPath: ""
    , Aria2SessionInterval: 60
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
CONF.Extension := {
    CleanOnComplete: 1
    , CleanOnError: 1
    , CleanOnRemoved: 1
    , CleanOnUnknown: 1
    , DeleteDotAria2: 1
    , DeleteDotTorrent: 1
    , DeleteEmptyDir: 1
    , DeleteExclude: 1
    , ExcludeRegEx: "(.*/)_+(padding)(_*)(file)(.*)(_+)"
    , ExcludeExt: "html|url|lnk|txt|jpg|png"
    , IncludeRegEx: ""
    , IncludeExt: "mp4|mkv|rmvb|mov|avi"
}

CONF.Setting.SetOpts("PARAMS")
CONF.Profile.SetOpts("PARAMS")
CONF.Speed.SetOpts("PARAMS")
CONF.Extension.SetOpts("PARAMS")
If !FileExist(CONF_Path) {
    FileAppend "", CONF_Path
}
If (FileRead(CONF_Path) = "") {
    CONF.WriteFile()
}
CONF.ReadFile()

; --------------------- INITIALIZATION - VARIABLES --------------------------
Global appVersion := "0.2.2"
Global sysThemeMode := RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", "SystemUsesLightTheme")

Global CurrentSpeedName := IniRead(CONF_Path, "Speed", "SpeedName" . CONF.Speed.CurrentSpeed)
Global CurrentSpeedLimit := IniRead(CONF_Path, "Speed", "SpeedLimit" . CONF.Speed.CurrentSpeed)

Global CurrentProfileName := IniRead(CONF_Path, "Profile", "ProfileName" . CONF.Profile.CurrentProfile)
Global CurrentProfilePath := IniRead(CONF_Path, "Profile", "ProfilePath" . CONF.Profile.CurrentProfile)

Global SubMenuProflie := Menu()
Global SubMenuSpeedLimit := Menu()
Global SubMenuAddTask := Menu()
Global SubMenuAddTaskProxy := Menu()

Global EhAria2Tray := A_TrayMenu
Global LanguageList := Array()
Global LangMenu := Menu()

WindowsTheme.SetAppMode(!sysThemeMode)

; --------------------- INITIALIZATION - RESOURCES --------------------------
If (!FileExist(A_ScriptDir . "\aria2.conf")) {
    FileInstall("aria2.conf", "aria2.conf")
}
else {
    If (FileRead(A_ScriptDir . "\aria2.conf") = "") {
        FileInstall("aria2.conf", "aria2.conf", 1)
    }
}

If !FileExist(A_ScriptDir "\lang") {
    DirCreate(A_ScriptDir "\lang")
}

If (A_IsCompiled = 1) {
    FileInstall(".\lang\en_us.ini", "lang\en_us.ini", 1)
    FileInstall(".\lang\zh_cn.ini", "lang\zh_cn.ini", 1)

    FileInstall("index.html", "index.html", 1)
    FileInstall("WebView2Loader.dll", "WebView2Loader.dll", 1)
}

Global Pics:= Array()
if(A_IsCompiled=1){
    Pics.Push(LoadPicture(A_ScriptDir . "\EhAria2.exe",,&imagetype))
    Pics.Push(LoadPicture(A_ScriptDir . "\EhAria2Torrent.exe",,&imagetype))
    Pics.Push(LoadPicture(A_ScriptDir . "\EhAria2Extension.exe",,&imagetype))
}
else{
    Pics.Push(LoadPicture(A_ScriptDir . "\EhAria2.ico",,&imagetype))
    Pics.Push(LoadPicture(A_ScriptDir . "\EhAria2Torrent.ico",,&imagetype))
    Pics.Push(LoadPicture(A_ScriptDir . "\EhAria2Extension.ico",,&imagetype))
}

; --------------------- INITIALIZATION - LANGUAGES --------------------------

Loop Files A_ScriptDir "\lang\*.ini" {
    SplitPath A_LoopFileName, , , , &FileNameNoExt
    LanguageList.Push(FileNameNoExt)
}

InitialLanguage()

; --------------------- INITIALIZATION - DEPENDENCIES --------------------------
If (CONF.Basic.Aria2Path = "") {
    if (FileExist(A_ScriptDir . '\aria2c.exe') and CONF.Basic.CheckUpdateOnStartup) {
        CheckUpdateAria2()
    }
    else if (!FileExist(A_ScriptDir . '\aria2c.exe')) {
        isIntegrated := MsgBox(lMsgItergratedDownload, lMsgNotFoundTitle, "Y/N T5")
        if (isIntegrated = "Yes") {
            InstallAria2()
        }
        else if (isIntegrated = "Timeout") {
            InstallAria2()
        }
        else if (isIntegrated = "No") {
            isCustom := MsgBox(lMsgCustomSelect, lMsgCustomNotFoundTitle, "Y/N")
            if (isCustom = "Yes") {
                SelectPath()
            }
            else {
                MsgBox(lMsgPathError, "O T5")
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

If (CONF.Basic.Aria2DhtEnable = 1 | CONF.Basic.Aria2Dht6Enable = 1) {
    InitialDHT()
}

If (CONF.Setting.BTTrackers = "") {
    UpdateBTTracker()
}

Aria2 := Aria2Rpc("EhAria2", , CONF.Setting.Aria2RpcPort, CONF.Setting.Aria2RpcSecret)
Aria2.__Init(, CurrentProfilePath, CurrentSpeedLimit)

; --------------------- INITIALIZATION - GUI --------------------------
CreateTrayMenu()
ConfigGuiCreate()
LangGuiIntial()
ProfileGuiIntial()
ProxyGuiIntial()
SpeedLimitGuiIntial()

; --------------------- INITIALIZATION - STARTUP --------------------------


StartAria2()

Return

; --------------------- CLASSES & FUNCTIONS - GUI --------------------------
CreateTrayMenu(*) {
    A_IconTip := "Enhanced Aria2"
    If A_IsCompiled = 0
        TraySetIcon "HICON:*" Pics[1]
    EhAria2Tray.Delete
    A_TrayMenu.ClickCount := 1
    EhAria2Tray.Add(lTrayLang, LangMenu)
    EhAria2Tray.Add(lTraySpeedLimit, SubMenuSpeedLimit)
    EhAria2Tray.Add(lTrayProfile, SubMenuProflie)
    EhAria2Tray.Add(lTrayEnableProxy, ProxyMenuHandler)
    EhAria2Tray.Add(lTrayUpdateTrackerList, UpdateBTTracker)
    EhAria2Tray.Add(lTrayUpdateAria2, UpdateAria2)
    EhAria2Tray.Add(lTrayPreference, ConfigGuiShow)
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

ConfigGuiCreate(recreate := 0) {
    if (recreate = 1) {
        ConfigGui.Destroy()
    }
    Global ConfigGui := Gui(, "Preferences ")
    ConfigGui.OnEvent("Close", ConfigGuiClose)
    ConfigGui.SetFont("cWhite")
    WindowsTheme.SetWindowAttribute(ConfigGui, !sysThemeMode)

    Global ConfigTab := ConfigGui.Add("Tab3", "vConfigTab", [lGuiConfigTabBasic, lGuiConfigTabNetwork, lGuiConfigTabExtClean, lGuiConfigTabAbout])

    ConfigTab.UseTab(1)
    ConfigGui.Add("Text", "x20 y42 h16 w84 +Section +Right ", lTrayProfile . ":")
    Global ProfileDDL := ConfigGui.Add("DropDownList", "yp vProfileDDL +Left",)
    ProfileDDL.OnEvent("Change", ProfileGuiHandler)
    ConfigGui.Add("Text", "x20 yp+32 h16 w84 +Right", lTrayLang . ":")
    Global LanguageDDL := ConfigGui.Add("DropDownList", "yp vLanguageDDL +Left",)
    LanguageDDL.OnEvent("Change", LangGuiHandler)
    ConfigGui.Add("Text", "x20 yp+32 h16 w84 +Right", lTrayUpdateAria2 . ":")
    Global CheckUpdateOnStartUpCheckbox := ConfigGui.Add("Checkbox", "yp w180 vCheckUpdateOnStartUpCheckbox", lGuiConfigCheckUpdateOnStartUp)
    CheckUpdateOnStartUpCheckbox.Value := CONF.Basic.CheckUpdateOnStartup
    CheckUpdateOnStartUpCheckbox.OnEvent("Click", CheckUpdateGuiHandler)
    Global Aria2VersionText := ConfigGui.Add("Text", "xs+104 yp+32 vAria2VersionText", CONF.Basic.Aria2Version)
    CheckUpdateButton := ConfigGui.Add("Button", "yp vCheckUpdateButton", lGuiConfigCheckUpdate)
    CheckUpdateButton.OnEvent("Click", CheckUpdateAria2)

    ConfigTab.UseTab(2)
    ConfigGui.Add("GroupBox", "x20 y32 w450 h86 +Section +Wrap", lGuiConfigProxy)
    Global ProxyEnableCheckbox := ConfigGui.Add("CheckBox", "xs+10 ys+20 vProxyEnableCheckbox +Left", lGuiConfigEnable)
    ProxyEnableCheckbox.Value := CONF.Basic.Aria2ProxyEnable
    ProxyEnableCheckbox.OnEvent("Click", ProxyEnableGuiHandler)
    ConfigGui.Add("Text", "xs+10 yp+32 h16 w84 +Right", lGuiConfigProxyUrl . ":")
    Global ProxyUrlEdit := ConfigGui.Add("Edit", "yp r1 w180 vProxyUrlEdit +Left", CONF.Setting.Aria2Proxy)
    ProxyUrlEdit.OnEvent("Change", ProxyUrlGuiHandler)

    ConfigGui.Add("GroupBox", "x20 yp+48 w450 h100 +Section", lTraySpeedLimit)
    ConfigGui.Add("Text", "xs+10 yp+32 h16 w84 +Right", lGuiSpeedMaxLimit . ":")
    Global SpeedLimitDDL := ConfigGui.Add("DropDownList", "yp  vSpeedLimitDDL +Left",)
    SpeedLimitDDL.OnEvent("Change", SpeedLimitGuiHandler)

    ConfigTab.UseTab(3)

    ConfigGui.Add("GroupBox", "x20 y32 w450 h64 +Section +Wrap", lGuiExtCleanOn)
    Global CleanOnCompleteCheckbox := ConfigGui.Add("Checkbox", "xs+10 ys+20 w80 vCleanOnCompleteCheckbox", lGuiStatusComplete)
    Global CleanOnErrorCheckbox := ConfigGui.Add("Checkbox", "yp w80 vCleanOnErrorCheckbox", lGuiStatusError)
    Global CleanOnRemovedCheckbox := ConfigGui.Add("Checkbox", "yp w80 vCleanOnRemovedCheckbox", lGuiStatusRemoved)
    Global CleanOnUnknownCheckbox := ConfigGui.Add("Checkbox", "yp w80 vCleanOnUnknownCheckbox -Section", lGuiStatusUnknown)
    CleanOnCompleteCheckbox.Value := CONF.Extension.CleanOnComplete
    CleanOnErrorCheckbox.Value := CONF.Extension.CleanOnError
    CleanOnRemovedCheckbox.Value := CONF.Extension.CleanOnRemoved
    CleanOnUnknownCheckbox.Value := CONF.Extension.CleanOnUnknown
    CleanOnCompleteCheckbox.OnEvent("Click", ExtCleanGuiHandler)
    CleanOnErrorCheckbox.OnEvent("Click", ExtCleanGuiHandler)
    CleanOnRemovedCheckbox.OnEvent("Click", ExtCleanGuiHandler)
    CleanOnUnknownCheckbox.OnEvent("Click", ExtCleanGuiHandler)

    ConfigGui.Add("GroupBox", "x20 yp+48 w450 h100 +Section", lGuiExtCleanRule)
    ConfigGui.Add("Text", "x32 ys+16 h16 w84 +Right", "*.torrent " . lGuiFiles . ":")
    Global DeleteDotTorrentMode := Map("0", lGuiConfigDisable, "1", lGuiConfigDefault, "2", lGuiConfigEnhanced)
    Global DeleteDotTorrentDDL := ConfigGui.Add("DropDownList", "xp+94 ys+16 vDeleteDotTorrentDDL +Left", [lGuiConfigDisable, lGuiConfigDefault, lGuiConfigEnhanced])
    DeleteDotTorrentDDL.OnEvent("Change", ExtCleanGuiHandler)
    DeleteDotTorrentDDL.Choose(DeleteDotTorrentMode[CONF.Extension.DeleteDotTorrent])
    ConfigGui.Add("Text", "x32 ys+48 h16 w84 +Right", "*.aria2 " . lGuiFiles . ":")
    Global DeleteDotAria2Checkbox := ConfigGui.Add("CheckBox", "xp+94 ys+48 vDeleteDotAria2Checkbox +Left", lGuiConfigEnable)
    DeleteDotAria2Checkbox.Value := CONF.Extension.DeleteDotAria2
    DeleteDotAria2Checkbox.OnEvent("Click", ExtCleanGuiHandler)
    ConfigGui.Add("Text", "x32 ys+64 h16 w84 +Right", lGuiEmptyFolder)
    Global DeleteEmptyDirCheckbox := ConfigGui.Add("CheckBox", "xp+94 ys+64 vDeleteEmptyDirCheckbox +Left", lGuiConfigEnable)
    DeleteEmptyDirCheckbox.Value := CONF.Extension.DeleteEmptyDir
    DeleteEmptyDirCheckbox.OnEvent("Click", ExtCleanGuiHandler)

    ConfigTab.UseTab(4)
    ConfigGui.Add("Picture", "x32 y42 w32 h-1 +Section", "HICON:*" Pics[1])
    AppName := ConfigGui.Add("Text", "xs+44 ys h32 w120 Left vAppName", "EhAria2")
    AppName.SetFont("s18 bold")
    AppVer := ConfigGui.Add("Text", "xp+120 yp+16 h32 w180 vAppVersion", appVersion)
    AppDesc := ConfigGUi.Add("Text", "xs yp+16 h32 wp Left vAppDesc", "Enhanced Aria2AHK")
    AppDesc.SetFont("s11 bold")
    ConfigGui.Add("Text", "xs yp+32 h32 wp vCopyright", "Copyright © Jacques Yip")
    ConfigGui.Add("Text", "xs yp+16 h32 wp vLicense", 'License : GPL-2.0')
    ConfigGui.Add("Link", "xs yp+16 h32 wp vRepo", 'Open Source : <a href="https://github.com/Jvcon/EhAria2">Jvcon/EhAria2</a>')

    WindowsTheme.SetWindowTheme(ConfigGui, !sysThemeMode)

}

ConfigGuiShow(*) {
    ConfigGui.Show()
    return
}

ConfigGuiClose(*)
{
    CONF.WriteFile()
}

LangGuiIntial(*) {
    LangMenu.Delete
    LanguageDDL.Add(LanguageList)
    loop LanguageList.Length
        LangMenu.Add(LanguageList[A_Index], LangMenuHandler)
    LangMenu.Check(CONF.Basic.Language)
    LanguageDDL.Choose(CONF.Basic.Language)
}

LangMenuHandler(ItemName := 0, ItemPos := 0, MyMenu := 0) {
    LangMenu.Uncheck(CONF.Basic.Language)
    CONF.Basic.Language := ItemName
    LangMenu.Check(CONF.Basic.Language)
    LanguageDDL.Choose(CONF.Basic.Language)
    CONF.WriteFile()
    InitialLanguage()
    CreateTrayMenu()
    ConfigGuiCreate(1)
    LangGuiIntial()
    ProfileGuiIntial()
    ProxyGuiIntial()
    SpeedLimitGuiIntial()
    return
}

LangGuiHandler(GuiCtrlObj, Info) {
    LangMenu.Uncheck(CONF.Basic.Language)
    CONF.Basic.Language := GuiCtrlObj.Text
    LangMenu.Check(CONF.Basic.Language)
    CONF.WriteFile()
    InitialLanguage()
    CreateTrayMenu()
    ConfigGuiCreate(1)
    LangGuiIntial()
    ProfileGuiIntial()
    ProxyGuiIntial()
    SpeedLimitGuiIntial()
    ConfigGuiShow()
    return
}

ProfileGuiIntial(*) {
    Global ProfileList := Array()
    Global ProfileMap := Map()
    If (CONF.Profile.ProfileName1 != "") {
        ProfileList.Push(CONF.Profile.ProfileName1)
        ProfileMap[CONF.Profile.ProfileName1] := CONF.Profile.ProfilePath1
    }
    If (CONF.Profile.ProfileName2 != "") {
        ProfileList.Push(CONF.Profile.ProfileName2)
        ProfileMap[CONF.Profile.ProfileName2] := CONF.Profile.ProfilePath2
    }
    If (CONF.Profile.ProfileName3 != "") {
        ProfileList.Push(CONF.Profile.ProfileName3)
        ProfileMap[CONF.Profile.ProfileName3] := CONF.Profile.ProfilePath3
    }
    loop ProfileList.Length {
        SubMenuProflie.Add(ProfileList[A_Index], ProfileMenuHandler)
        SubMenuAddTask.Add(ProfileList[A_Index], AddTaskToMenuHandler)
        SubMenuAddTaskProxy.Add(ProfileList[A_Index], AddTaskToMenuHandler)
    }
    ProfileDDL.Add(ProfileList)
    If (CurrentProfileName != "") {
        SubMenuProflie.Check(CurrentProfileName)
        ProfileDDL.Choose(CurrentProfileName)
    }
    return
}

ProfileMenuHandler(ItemName := 0, ItemPos := 0, MyMenu := 0) {
    SubMenuProflie.UnCheck(CurrentProfileName)
    CONF.Profile.CurrentProfile := ItemPos
    Global CurrentProfileName := ProfileList[ItemPos]
    Global CurrentProfilePath := ProfileMap[CurrentProfileName]
    SubMenuProflie.Check(CurrentProfileName)
    ProfileDDL.Choose(CurrentProfileName)
    CONF.WriteFile()
    Aria2.changeGlobalOption(, dir := CurrentProfilePath)
    return
}

ProfileGuiHandler(GuiCtrlObj, Info) {
    SubMenuProflie.Uncheck(CurrentProfileName)
    CONF.Profile.CurrentProfile := GuiCtrlObj.Value
    Global CurrentProfileName := GuiCtrlObj.Text
    Global CurrentProfilePath := ProfileMap[CurrentProfileName]
    SubMenuProflie.Check(CurrentProfileName)
    CONF.WriteFile()
    Aria2.changeGlobalOption(, dir := CurrentProfilePath)
    return
}

CheckUpdateGuiHandler(GuiCtrlObj, Info) {
    switch GuiCtrlObj.Name {
        case "CheckUpdateOnStartUpCheckbox":
            CONF.Basic.CheckUpdateOnStartup := CheckUpdateOnStartUpCheckbox.Value
            CONF.WriteFile()

        case "":
        default:

    }

}

ProxyGuiIntial(*) {
    ProxyUrlEdit.Value := CONF.Setting.Aria2Proxy
    Aria2.__Init(CONF.Setting.Aria2Proxy)
    If (CONF.Basic.Aria2ProxyEnable = 1) {
        If (!(CONF.Setting.Aria2Proxy = "")) {
            ProxyEnableCheckbox.Value := 1
            EhAria2Tray.Check(lTrayEnableProxy)
        }
        else {
            ProxyEnableCheckbox.Value := 0
            MsgBox lMsgProxyError
        }
    }
    else {
        ProxyEnableCheckbox.Value := 0
        EhAria2Tray.Uncheck(lTrayEnableProxy)
    }
    return
}

ProxyMenuHandler(ItemName := 0, ItemPos := 0, MyMenu := 0) {
    If (CONF.Basic.Aria2ProxyEnable = 1) {
        EhAria2Tray.UnCheck(ItemName)
        ProxyEnableCheckbox.Value := 0
        CONF.Basic.Aria2ProxyEnable := 0
        Aria2.changeGlobalOption(proxyUrl := "")
    }
    else {
        If (!(CONF.Setting.Aria2Proxy = "")) {
            EhAria2Tray.Check(ItemName)
            ProxyEnableCheckbox.Value := 1
            CONF.Basic.Aria2ProxyEnable := 1
            Aria2.changeGlobalOption(proxyUrl := CONF.Setting.Aria2Proxy)
        }
        else {
            MsgBox lMsgProxyError
        }
    }
    CONF.WriteFile()
    return
}

ProxyEnableGuiHandler(GuictrlObj, Info) {
    CONF.Basic.Aria2ProxyEnable := GuiCtrlObj.Value
    if (GuiCtrlObj.Value = 0) {
        ProxyUrlEdit.Opt("+ReadOnly")
        EhAria2Tray.UnCheck(lTrayEnableProxy)
        Aria2.changeGlobalOption(proxyUrl := "")
    } else {
        ProxyUrlEdit.Opt("-ReadOnly")
        EhAria2Tray.Check(lTrayEnableProxy)
        CONF.Setting.Aria2Proxy := ProxyUrlEdit.Value
        If (ProxyUrlEdit.Value = "") {

        }
        else {
            Aria2.changeGlobalOption(proxyUrl := CONF.Setting.Aria2Proxy)
        }
    }
    CONF.WriteFile()
    return
}

ProxyUrlGuiHandler(GuictrlObj, Info) {
    CONF.Setting.Aria2Proxy := ProxyUrlEdit.Value
    If (GuiCtrlObj.Value = "") {
        Aria2.changeGlobalOption(proxyUrl := "")
    }
    else {
        Aria2.changeGlobalOption(proxyUrl := CONF.Setting.Aria2Proxy)
    }
    return
}

SpeedLimitGuiIntial(*) {
    Global SpeedLimitList := Array()
    Global SpeedLimitMap := Map()
    If (CONF.Speed.SpeedName1 != "") {
        SpeedLimitList.Push(CONF.Speed.SpeedName1)
        SpeedLimitMap[CONF.Speed.SpeedName1] := CONF.Speed.SpeedLimit1
    }
    If (CONF.Speed.SpeedName2 != "") {
        SpeedLimitList.Push(CONF.Speed.SpeedName2)
        SpeedLimitMap[CONF.Speed.SpeedName2] := CONF.Speed.SpeedLimit2
    }
    If (CONF.Speed.SpeedName3 != "") {
        SpeedLimitList.Push(CONF.Speed.SpeedName3)
        SpeedLimitMap[CONF.Speed.SpeedName3] := CONF.Speed.SpeedLimit3
    }
    loop SpeedLimitList.Length {
        SubMenuSpeedLimit.Add(SpeedLimitList[A_Index], SpeedLimitMenuHandler)
    }
    SpeedLimitDDL.Add(SpeedLimitList)
    If (CurrentSpeedName != "") {
        SubMenuSpeedLimit.Check(CurrentSpeedName)
        SpeedLimitDDL.Choose(CurrentSpeedName)
    }
    return
}

SpeedLimitMenuHandler(ItemName := 0, ItemPos := 0, MyMenu := 0) {
    SubMenuSpeedLimit.UnCheck(CurrentSpeedName)
    CONF.Speed.CurrentSpeed := ItemPos
    Global CurrentSpeedName := SpeedLimitList[ItemPos]
    Global CurrentSpeedLimit := SpeedLimitMap[CurrentSpeedName]
    SubMenuSpeedLimit.Check(CurrentSpeedName)
    SpeedLimitDDL.Choose(CurrentSpeedName)
    CONF.WriteFile()
    Aria2.changeGlobalOption(, , maxDownloadLimit := CurrentSpeedLimit)
    return
}

SpeedLimitGuiHandler(GuictrlObj, Info) {
    SubMenuSpeedLimit.Uncheck(CurrentProfileName)
    CONF.Speed.CurrentSpeed := GuiCtrlObj.Value
    Global CurrentSpeedName := GuiCtrlObj.Text
    Global CurrentSpeedLimit := SpeedLimitMap[CurrentSpeedName]
    SubMenuSpeedLimit.Check(CurrentSpeedName)
    CONF.WriteFile()
    Aria2.changeGlobalOption(, , maxDownloadLimit := CurrentSpeedLimit)
    return
}

ExtCleanGuiHandler(GuictrlObj, Info) {
    switch GuictrlObj.Name {
        case "CleanOnCompleteCheckbox":
            CONF.Extension.CleanOnComplete := CleanOnCompleteCheckbox.Value

        case "CleanOnErrorCheckbox":
            CONF.Extension.CleanOnError := CleanOnErrorCheckbox.Value

        case "CleanOnRemovedCheckbox":
            CONF.Extension.CleanOnRemoved := CleanOnRemovedCheckbox.Value

        case "CleanOnUnknownCheckbox":
            CONF.Extension.CleanOnUnknown := CleanOnUnknownCheckbox.Value

        case "DeleteDotTorrentDDL":
            CONF.Extension.DeleteDotTorrent := DeleteDotTorrentDDL.Value - 1

        case "DeleteDotAria2Checkbox":
            CONF.Extension.DeleteDotAria2 := DeleteDotAria2Checkbox.Value

        case "DeleteEmptyDirCheckbox":
            CONF.Extension.DeleteEmptyDir := DeleteEmptyDirCheckbox.Value

        default:

    }
    CONF.WriteFile()
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

; --------------------- CLASSES & FUNCTIONS --------------------------

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
        path := ProfileMap[ProfileList[profile]]
    }

    if (uri = "") {
        UriInput(&uri)
        ; uriInput:= InputBox("新建 HTTP / HTTPS / FTP / SFTP / Magnet 任务:", "添加任务", "w320 h240")
    }
    if (uri = "") {
        return
    }
    Aria2.addUri(uri, path, proxy)
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

SelectPath(*) {
    aira2selectpath := DirSelect(, 0, lMsgSelectPathTitle)
    if (aira2selectpath = "") {
        MsgBox(lMsgPathError, "O T5")
        ExitTray()
    }
    else {
        if (FileExist(aira2selectpath . '\aria2c.exe')) {
            CONF.Basic.Aria2Path := aira2selectpath
            CONF.WriteFile()
        }
        else {
            MsgBox(lMsgPathError, "O T5")
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

InitialDHT(ItemName := 0, ItemPos := 0, MyMenu := 0) {
    if (CONF.Setting.Aria2DhtPath = "") {
        if !(FileExist(A_ScriptDir . "\" . "dht.dat")) {
            DownloadDHT()
        }
        if !(FileExist(A_ScriptDir . "\" . "dht6.dat")) {
            DownloadDHT()
        }
    }
    else {
        if !(FileExist(CONF.Setting.Aria2DhtPath . "\" . "dht.dat")) {
            DownloadDHT(CONF.Setting.Aria2DhtPath . "\", "dht.dat")
        }
        if !(FileExist(CONF.Setting.Aria2DhtPath . "\" . "dht6.dat")) {
            DownloadDHT(CONF.Setting.Aria2DhtPath . "\", "dht6.dat")
        }
    }
    return
}

DownloadDHT(path := A_ScriptDir . "\", filename := "dht.dat") {
    try {
        Download "https://github.com/P3TERX/aria2.conf/raw/master/" filename, path . filename
    }
    catch as error {
        downloadError := MsgBox(error, , "RC Default2 T5")
        if (downloadError = "Cancel") {
            FileAppend "", A_ScriptDir . "\" . filename
        }
        else if (downloadError = "Retry") {
            Download "https://github.com/P3TERX/aria2.conf/raw/master/" filename, path . filename
        }
        else if (downloadError = "Timeout") {
            Download "https://github.com/P3TERX/aria2.conf/raw/master/" filename, path . filename
        }
    }
}

StartAria2(*) {
    Global Aria2PID:=""
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
    cmd .= " --save-session-interval=" CONF.Setting.Aria2SessionInterval
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
    If (CONF.Basic.Aria2DhtEnable = 1) {
        cmd .= " --enable-dht=true"
        If (!(CONF.Setting.Aria2DhtPath = "")) {
            cmd .= " --dht-file-path=" . CONF.Setting.Aria2DhtPath . "\dht.dat"
        }
        else {
            cmd .= " --dht-file-path=" . A_ScriptDir . "\dht.dat"
        }
    }
    If (CONF.Basic.Aria2Dht6Enable = 1) {
        cmd .= " --enable-dht6=true"
        If (!(CONF.Setting.Aria2DhtPath = "")) {
            cmd .= " --dht-file-path6=" . CONF.Setting.Aria2DhtPath . "\dht6.dat"
        }
        else {
            cmd .= " --dht-file-path6=" . A_ScriptDir . "\dht6.dat"
        }
    }
    If (A_IsCompiled = 1) {
        cmd .= " --on-download-complete=" . A_ScriptDir . "\EhAria2Extension.exe"
        cmd .= " --on-download-error=" . A_ScriptDir . "\EhAria2Extension.exe"
    }
    else {
        cmd .= " --on-download-complete=" . A_ScriptDir . "\EhAria2Extension.ahk"
        cmd .= " --on-download-error=" . A_ScriptDir . "\EhAria2Extension.ahk"
    }
    Run cmd, , "Hide",&Aria2PID
    return
}

CheckKillAria2()
{
    if (ProcessExist(Aria2PID)!=0){
        Aria2.saveSession()
        ProcessClose("aria2c.exe")
    }
    return
}

RestartAria2(*) {
    CheckKillAria2()
    StartAria2()
    return
}

UpdateAria2(*) {
    CheckUpdateAria2()
    StartAria2()
    return
}

CheckUpdateAria2(*) {
    MonitorGetWorkArea("1", &Left, &Top, &Right, &Bottom)
    ToolTip("Checking Version", Right, Bottom, 1)
    Aria2Repo := Github("aria2", "aria2")
    Aria2LatestVersion := Aria2Repo.Version
    ToolTip(, , , 1)
    if (CONF.Basic.Aria2Version != Aria2LatestVersion) {
        CheckKillAria2()
        InstallAria2()
        CONF.Basic.Aria2Version := Aria2LatestVersion
        ControlSetText(CONF.Basic.Aria2Version, Aria2VersionText)
        CONF.WriteFile()
        ToolTip(, , , 1)
    }
    else {
        ToolTip(, , , 1)
        MsgBox lMsgVersionLatest
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
    TrayTip(Language.Translate("Msg", "installsuccess", CONF.Basic.Aria2Version), , "20")
    return
}

InitialLanguage(*) {
    global Language := i18n("lang", CONF.Basic.Language, !A_IsCompiled)

    global lTrayExit := Language.Translate("Tray", "exit")
    global lTrayRestart := Language.Translate("Tray", "restart")
    global lTrayOpenFolder := Language.Translate("Tray", "openfolder")
    global lTrayOpenAriang := Language.Translate("Tray", "openariang")

    global lTrayLang := Language.Translate("Tray", "lang")
    global lTraySpeedLimit := Language.Translate("Tray", "speedlimit")
    global lTrayProfile := Language.Translate("Tray", "profile")
    global lTrayEnableProxy := Language.Translate("Tray", "enableproxy")
    global lTrayUpdateTrackerList := Language.Translate("Tray", "updatetracker")
    global lTrayUpdateAria2 := Language.Translate("Tray", "updatearia2")
    global lTrayPreference := Language.Translate("Tray", "preference")

    global lTrayAddTorrentTo := Language.Translate("Tray", "addtorrentto")
    global lTrayAddTaskProxyTo := Language.Translate("Tray", "addtaskproxyto")
    global lTrayAddTaskTo := Language.Translate("Tray", "addtaskto")
    global lTrayAddTorrent := Language.Translate("Tray", "addtorrent")
    global lTrayAddTask := Language.Translate("Tray", "addtask")

    global lGuiConfigTabBasic := Language.Translate("GuiConfig", "basic")
    global lGuiConfigTabNetwork := Language.Translate("GuiConfig", "network")
    global lGuiConfigTabExtClean := Language.Translate("GuiConfig", "extclean")
    global lGuiConfigTabAbout := Language.Translate("GuiConfig", "about")
    global lGuiConfigEnable := Language.Translate("GuiConfig", "enable")
    global lGuiConfigDisable := Language.Translate("GuiConfig", "disable")
    global lGuiConfigEnhanced := Language.Translate("GuiConfig", "enhanced")
    global lGuiConfigDefault := Language.Translate("GuiConfig", "default")
    global lGuiConfigProxy := Language.Translate("GuiConfig", "proxy")
    global lGuiConfigProxyUrl := Language.Translate("GuiConfig", "proxyurl")
    global lGuiSpeedMaxLimit := Language.Translate("GuiConfig", "speedmaxlimit")
    global lGuiExtCleanOn := Language.Translate("GuiConfig", "cleanon")
    global lGuiStatusComplete := Language.Translate("GuiConfig", "complete")
    global lGuiStatusError := Language.Translate("GuiConfig", "error")
    global lGuiStatusRemoved := Language.Translate("GuiConfig", "removed")
    global lGuiStatusUnknown := Language.Translate("GuiConfig", "unknown")
    global lGuiExtCleanRule := Language.Translate("GuiConfig", "cleanrule")
    global lGuiFiles := Language.Translate("GuiConfig", "files")
    global lGuiEmptyFolder := Language.Translate("GuiConfig", "emptyfolder")
    global lGuiConfigCheckUpdate := Language.Translate("GuiConfig", "checkupdate")
    global lGuiConfigCheckUpdateOnStartUp := Language.Translate("GuiConfig", "checkupdateonstartup")


    global lGuiUriInputText := Language.Translate("GuiUriInput", "text")
    global lGuiUriInputBtnOK := Language.Translate("GuiUriInput", "btnok")
    global lGuiUriInputBtnCancel := Language.Translate("GuiUriInput", "btncancel")
    global lGuiUriInputTitle := Language.Translate("GuiUriInput", "title")

    global lMsgProxyError := Language.Translate("Msg", "proxyerror")
    global lMsgPathError := Language.Translate("Msg", "patherror")
    global lMsgNotFoundTitle := Language.Translate("Msg", "notfoundtitle")
    global lMsgCustomNotFoundTitle := Language.Translate("Msg", "customnotfoundtitle")
    global lMsgItergratedDownload := Language.Translate("Msg", "integrateddownload")
    global lMsgCustomSelect := Language.Translate("Msg", "customselect")
    global lMsgCustomReselect := Language.Translate("Msg", "customreselect")
    global lMsgSelectPathTitle := Language.Translate("Msg", "selectpathtitle")
    global lMsgVersionLatest := Language.Translate("Msg", "latestversion")
    global lMsgInstallSuccess := Language.Translate("Msg", "installsuccess", CONF.Basic.Aria2Version)

    return
}

ExitTray(*) {
    CheckKillAria2()
    CONF.WriteFile()
    ExitApp
    Return
}
