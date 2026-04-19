; rest
; hi this is rest its cool yea awesome

; pre initialization

#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreads 255
#MaxThreadsPerHotkey 1
A_HotkeyInterval := 0
SetKeyDelay(-1)
SetMouseDelay(-1)
InstallMouseHook
ProcessSetPriority "Realtime", "AutoHotKey64.exe"

; global variables

; module variables
global lastNumber := 0
global lastNumberTime := 0
global lastMacroTime := 0
global isHoldAiming := false
global isARFiring := false

; theme variables
global font := "cascadia code"
global accent := "88C0D0"
global text := "D8DEE9"
global danger := "ff4538"
global interfaceBg := "2E3440"
global groupBg := "3B4252"
global objectBg := "434C5E"
global border := "232127"
global groupGrad := "434C5E"
global interfaceGrad := "3B4252"
global hintColor := "88C0D0"
global topTextColor := "D8DEE9"

; update variables
global version := "v1"
global changelogDisplay := 0
global currentVersionText := 0
global latestVersionText := 0
global isListeningForBind := false
global bindListenerCallback := ""
global latestVersion := ""
global downloadUrl := ""
global latestChangelog := ""
global updater := 0, progress := 0, titleText := 0, watermarkText := 0, versionText := 0

; settins and ini stuff

iniPath := A_ScriptDir "\restdefaultconfig.ini"

arrayToIniString(arr) {
    s := ""
    for i, v in arr
        s .= (i > 1 ? "," : "") . String(v)
    return s
}

iniStringToArray(val) {
    if (val = "")
        return []
    arr := []
    for part in StrSplit(val, ",")
        arr.Push(Trim(part))
    return arr
}

setSetting(key, value) {
    settings.%key% := value
    section := (SubStr(key, 1, 6) = "custom") ? "Custom" : "Settings"
    if (Type(value) = "Array")
        IniWrite(arrayToIniString(value), iniPath, section, key)
    else
        IniWrite(String(value), iniPath, section, key)
}

loadSettings() {
    global settings
    for key, value in settings.OwnProps() {
        section := (SubStr(key, 1, 6) = "custom") ? "Custom" : "Settings"
        try {
            val := IniRead(iniPath, section, key)
            if (Type(value) = "Array")
                settings.%key% := iniStringToArray(val)
            else if (IsInteger(value))
                settings.%key% := Integer(val)
            else if (IsFloat(value))
                settings.%key% := Float(val)
            else if (value = true || value = false)
                settings.%key% := (val = "1" || val = "true")
            else
                settings.%key% := val
        } catch {
            if (Type(value) = "Array")
                IniWrite(arrayToIniString(value), iniPath, section, key)
            else
                IniWrite(String(value), iniPath, section, key)
        }
    }
}

settings := {
    ; Sniper
    sniperQuickscope: false,
    sniperQuickscopeKeybind: "RButton",
    sniperQuickscopeRequip: true,
    sniperHoldAim: false,
    sniperHoldAimKeybind: "RButton",
    sniperFirstPerson: true,
    sniperRequireRoblox: true,
    sniperEquipDelay: 1200,
    sniperChamberDelay: 1250,
    sniperBufferDelay: 2,
    ; Hotbar
    hotbar: true,
    hotbarRequireRoblox: true,
    hotbarSniperSlots: "3,4",
    hotbarShield: false,
    hotbarShieldSlots: "5",
    hotbarShieldDelay: 100,
    sniperBindMerge: false,
    ; Custom
    customPrefix: "",
    customThemeName: "",
    customThemeDark: "",
    customThemeLight: "",
    customThemeGradients: true,
    customFont: "",
    customAboutHeader: "",
    customAboutBody: "",
    customNotify: "",
    ; Theme
    interfaceTheme: "Nord",
    interfaceDarkMode: true,
    interfaceGradients: true,
    interfaceGradientResolution: 2,
    interfaceFont: "cascadia code",
    interfaceNotifications: true,
    interfaceHints: true,
    interfaceGameDetection: true,
    ; Updates
    updateAutomatically: true,
    updatePreserveVersion: true,
    ; Keybinds
    keybindsOpenClose: "RShift",
    keybindsRequireRoblox: false,
    keybindsExit: "HOME",
    keybindsXButton1: "None",
    keybindsXButton2: "None",
    keybindsMButton: "None"
} 

loadSettings()

; custom stuff

parseCustomTheme(themeStr) {
    obj := {}
    for part in StrSplit(themeStr, ",") {
        kv := StrSplit(part, ":")
        if (kv.Length >= 2)
            obj.%Trim(kv[1])% := Trim(kv[2])
    }
    return obj
}

themeList := ["Nord", "Gruvbox", "Kanagawa", "Rose Pine", "Everforest", "Solarized", "Catppuccin", "Ayu Mirage", "Material"]
if (settings.customThemeName != "") {
    customName := settings.customThemeName
    configName := "[CONFIG] " customName
    customDark := settings.customThemeDark
    customLight := settings.customThemeLight
    
    if (customDark != "" && customLight != "") {
        Rest.customThemes[configName] := parseCustomTheme(customDark)
        Rest.customThemes[configName " Light"] := parseCustomTheme(customLight)
        Rest.darkToLight[configName] := configName " Light"
    } else if (customDark != "") {
        Rest.customThemes[configName] := parseCustomTheme(customDark)
    } else if (customLight != "") {
        Rest.customThemes[configName] := parseCustomTheme(customLight)
    } else {
        Rest.customThemes[configName] := parseCustomTheme("interfaceBg:181818,groupBg:212121,objectBg:383838,accent:90caf9,text:e0e0e0,hint:e0e0e0,groupGrad:383838,interfaceGrad:212121,topText:e0e0e0")
        Rest.customThemes[configName " Light"] := parseCustomTheme("interfaceBg:f5f5f5,groupBg:ffffff,objectBg:e0e0e0,accent:90caf9,text:181818,hint:181818,groupGrad:e0e0e0,interfaceGrad:ffffff,topText:181818")
        Rest.darkToLight[configName] := configName " Light"
    }
    themeList.Push(configName)
}

Rest.prefix := settings.customPrefix != "" ? settings.customPrefix : "Rest"
if (Rest.mainGui && Rest.HasProp("titleTxt"))
    Rest.titleTxt.Value := Rest.prefix . " " . version

Rest.darkMode := settings.interfaceDarkMode
Rest.gradientsEnabled := settings.interfaceGradients
Rest.gradientRes := settings.interfaceGradientResolution
Rest.setTheme(settings.interfaceTheme)
Rest.setFont(settings.interfaceFont)

fontList := ["cascadia code", "arial", "calibri", "candara", "comic sans ms", "consolas", "corbel", "segoe ui", "tahoma", "times new roman", "verdana"]
if (settings.customFont != "") {
    fontList.Push("[CONFIG] " settings.customFont)
}

foundTheme := false
for t in themeList {
    if (settings.interfaceTheme = t) {
        foundTheme := true
        break
    }
}
if (!foundTheme) {
    setSetting("interfaceTheme", "Nord")
    Rest.setTheme("Nord")
}

foundFont := false
for f in fontList {
    if (settings.interfaceFont = f) {
        foundFont := true
        break
    }
}
if (!foundFont) {
    setSetting("interfaceFont", "cascadia code")
    Rest.setFont("cascadia code")
}

; main gui

restInterface := Rest.gui(version, 600, 890)

Rest.tabs(restInterface, 20, 50, ["macro", "options", "about"], "macro")

Rest.group(restInterface, "Sniper", 10, 90, 285, 445, "macro")
Rest.toggle(restInterface, 25, 130, "Quickscope", settings.sniperQuickscope, "macro", (v) => setSetting("sniperQuickscope", v), "Automates sniper quickscoping to mimic old sniper accuracy.")
Rest.keybind(restInterface, 210, 130, settings.sniperQuickscopeKeybind, "macro", (v) => updateSniperQuickscopeBind(v), "Key used to trigger quickscoping.")
Rest.toggle(restInterface, 25, 160, "Requip", settings.sniperQuickscopeRequip, "macro", (v) => setSetting("sniperQuickscopeRequip", v), "Uses alternative quickscoping method which is more consistent.")
Rest.toggle(restInterface, 25, 190, "Bind Merging", settings.sniperBindMerge, "macro", (v) => setSetting("sniperBindMerge", v), "Support for drawing tablets, and Mouse remapping. Merges sniper quickscoping and firing of automatic weapons.")
Rest.slider(restInterface, 25, 220, 255, "Buffer Delay", 0, 10, settings.sniperBufferDelay, "macro", (v) => setSetting("sniperBufferDelay", v), "Delay in ms between switching and clicking.")
Rest.slider(restInterface, 25, 270, 255, "Equip Delay", 0, 3000, settings.sniperEquipDelay, "macro", (v) => setSetting("sniperEquipDelay", v), "Delay in ms to wait after equipping the sniper.")
Rest.slider(restInterface, 25, 320, 255, "Chamber Delay", 0, 1500, settings.sniperChamberDelay, "macro", (v) => setSetting("sniperChamberDelay", v), "Delay in ms to wait before firing the sniper again.")
Rest.toggle(restInterface, 25, 400, "Hold Aim", settings.sniperHoldAim, "macro", (v) => setSetting("sniperHoldAim", v), "Changes the War Tycoon toggle aim to hold aim.")
Rest.keybind(restInterface, 210, 400, settings.sniperHoldAimKeybind, "macro", (v) => updateSniperHoldAimBind(v), "Key used to trigger hold to aim.")
Rest.toggle(restInterface, 25, 460, "First Person", settings.sniperFirstPerson, "macro", (v) => setSetting("sniperFirstPerson", v), "Ensures you're in first person before executing.")
Rest.toggle(restInterface, 25, 490, "Require Roblox", settings.sniperRequireRoblox, "macro", (v) => setSetting("sniperRequireRoblox", v), "Ensures Roblox is the active window before executing.")

Rest.group(restInterface, "Hotbar", 10, 544, 285, 335, "macro")
Rest.toggle(restInterface, 25, 584, "Enabled", settings.hotbar, "macro", (v) => setSetting("hotbar", v), "Tracks your hotbar slots to determine whether you're using a sniper or not.")
Rest.toggle(restInterface, 25, 614, "Require Roblox", settings.hotbarRequireRoblox, "macro", (v) => setSetting("hotbarRequireRoblox", v), "Ensures you're in first person before executing.")
Rest.edit(restInterface, 25, 644, 255, "Sniper Slots", settings.hotbarSniperSlots, "macro", (v) => setSetting("hotbarSniperSlots", v), "Hotbar slots that are set to snipers.")
Rest.toggle(restInterface, 25, 704, "Shield", settings.hotbarShield, "macro", (v) => setSetting("hotbarShield", v), "Immediately equips shield after sniping.")
Rest.edit(restInterface, 25, 734, 255, "Shield Slot", settings.hotbarShieldSlots, "macro", (v) => setSetting("hotbarShieldSlots", v), "Hotbar slot that is set to shield.")
Rest.slider(restInterface, 25, 794, 255, "Shield Time", 100, 1000, settings.hotbarShieldDelay, "macro", (v) => setSetting("hotbarShieldDelay", v), "Delay in ms to wait while the shield is equipped.")

Rest.group(restInterface, "Interface", 10, 90, 285, 355, "options")
Rest.dropdown(restInterface, 25, 130, 255, "Theme", themeList, settings.interfaceTheme, "options", (v) => (setSetting("interfaceTheme", v), Rest.setTheme(v)), "Switches between theme varients.")
Rest.darkToggle := Rest.toggle(restInterface, 25, 180, "Dark Mode", Rest.darkMode, "options", (v) => (setSetting("interfaceDarkMode", v), Rest.toggleDarkMode(v)), "Switches between light and dark mode theme varients.")
Rest.gradToggle := Rest.toggle(restInterface, 25, 210, "Gradients", Rest.gradientsEnabled, "options", (v) => (setSetting("interfaceGradients", v), Rest.toggleGradients(v)), "May be performance intensive.")
Rest.slider(restInterface, 25, 240, 255, "Gradient Resolution", 1, 5, Rest.gradientRes, "options", (v) => (Rest.updateGradientRes(v), setSetting("interfaceGradientResolution", v)), "Resolution of the gradients. Lower number is higher resolution.")
Rest.dropdown(restInterface, 25, 290, 255, "Font", fontList, settings.interfaceFont, "options", (v) => (Rest.setFont(v), setSetting("interfaceFont", v)), "Switches between fonts.")
Rest.toggle(restInterface, 25, 340, "Notifications", settings.interfaceNotifications, "options", (v) => setSetting("interfaceNotifications", v), "Visibility of notification toasts in top right.")
Rest.toggle(restInterface, 25, 370, "Hints", settings.interfaceHints, "options", (v) => (setSetting("interfaceHints", v), Rest.refreshUI(true)), "Visibility of hints when hovering over elements.")
Rest.toggle(restInterface, 25, 400, "Game Detection", settings.interfaceGameDetection, "options", (v) => setSetting("interfaceGameDetection", v), "Detect games that could trigger bans, and prevent them.")

Rest.group(restInterface, "Updates", 305, 90, 285, 355, "options")
Rest.button(restInterface, 320, 130, 255, 30, "Check For Updates", "options", checkForUpdates.Bind(true))
currentVersionText := Rest.text(restInterface, 320, 165, "Current: " version, "options")
latestVersionText := Rest.text(restInterface, 405, 165, "Latest: Null", "options")
latestVersionText.Value := ""
latestVersionText.Opt("c" accent " w80")
changelogDisplay := restInterface.Add("text", "x320 y190 w255 h150 ReadOnly -E0x200 Background" groupBg " c" text, "")
Rest.register(changelogDisplay, "changelog", "options")
Rest.toggle(restInterface, 320, 370, "Check Automatically", settings.updateAutomatically, "options", (v) => setSetting("updateAutomatically", v), "Automatically checks for updates on launch.")
Rest.toggle(restInterface, 320, 400, "Preserve Current Version", settings.updatePreserveVersion, "options", (v) => setSetting("updatePreserveVersion", v), "Preserves the current version instead of deleting after updating.")

Rest.group(restInterface, "Keybinds", 305, 453, 285, 265, "options")
Rest.text(restInterface, 320, 493, "Open/Close", "options")
Rest.keybind(restInterface, 505, 488, settings.keybindsOpenClose, "options", (v) => updateOpenCloseBind(v), "Key used to open/close the GUI.")
Rest.toggle(restInterface, 320, 523, "Require Roblox", settings.keybindsRequireRoblox, "options", (v) => setSetting("keybindsRequireRoblox", v), "Ensures Roblox is the active window before executing.")
Rest.text(restInterface, 320, 553, "Exit", "options")
Rest.keybind(restInterface, 505, 549, settings.keybindsExit, "options", (v) => updateExitBind(v), "Key to exitapp.")
Rest.text(restInterface, 320, 623, "Side Button 1", "options")
Rest.keybind(restInterface, 505, 619, settings.keybindsXButton1, "options", (v) => updateXButton1Bind(v), "Key used to trigger first side button.")
Rest.text(restInterface, 320, 653, "Side Button 2", "options")
Rest.keybind(restInterface, 505, 649, settings.keybindsXButton2, "options", (v) => updateXButton2Bind(v), "Key used to trigger second side button.")
Rest.text(restInterface, 320, 683, "Middle Button", "options")
Rest.keybind(restInterface, 505, 680, settings.keybindsMButton, "options", (v) => updateMButtonBind(v), "Key used to trigger middle button.")

Rest.group(restInterface, "Tools", 10, 453, 285, 265, "options")
Rest.button(restInterface, 25, 493, 255, 20, "Exit", "options", (*) => ExitApp())
Rest.button(restInterface, 25, 523, 255, 20, "Reload", "options", () => Reload())
Rest.button(restInterface, 25, 553, 255, 20, "Recalculate Screen", "options", () => calculateScreenSize(true))
Rest.button(restInterface, 25, 583, 255, 20, "Copy Config", "options", () => (A_Clipboard := FileRead(iniPath), Rest.notify("Settings copied to clipboard!", 1500)))
Rest.button(restInterface, 25, 613, 255, 20, "Open Config Folder", "options", () => Run("explorer.exe /select,`"" . iniPath . "`""))
Rest.button(restInterface, 25, 643, 255, 20, "Reset Config", "options", () => resetSettings())

Rest.group(restInterface, "About Rest", 10, 90, 580, 300, "about")
Rest.text(restInterface, 25, 130, "Advanced War Tycoon AutoHotKey script powered by Rest, Maintained by Mythic.`nSome features may not work as expected, still in active development. `n`nDisclaimer: This script is not affiliated with Roblox, War Tycoon, `nor any in-game faction. It may be bannable to use. Use with caution, `nand at your own risk.`n`nIf you have questions, or want to recieve updates, join the Discord below.`n`nThanks to amazing testers:`nDIO (7minutesisallicangive), Potato (gampl), Wolfie (wolfsbanelikesroses)", "about")
Rest.button(restInterface, 10, 400, 65, 30, "Discord", "about", () => Run("https://discord.gg/NkwtEFJY7r"))
Rest.button(restInterface, 85, 400, 65, 30, "GitHub", "about", () => Run("https://github.com/SillyMythic/Rest"))
Rest.button(restInterface, 160, 400, 65, 30, "License", "about", () => Run("https://github.com/SillyMythic/Rest/blob/main/LICENSE"))
Rest.button(restInterface, 235, 400, 65, 30, "Contact", "about", () => Run("https://discord.com/users/757987898065682512/"))

if (settings.customAboutBody != "") {
    customAboutTitle := "[CONFIG] " (settings.customAboutHeader != "" ? settings.customAboutHeader : (settings.customThemeName != "" ? settings.customThemeName : "Custom Config"))
    Rest.group(restInterface, customAboutTitle, 10, 450, 580, 200, "about")
    customAboutParsed := StrReplace(settings.customAboutBody, "\n", "`n")
    customAboutDisplay := restInterface.Add("Text", "x25 y490 w550 h145 +Wrap +BackgroundTrans +0x2000", customAboutParsed)
    Rest.register(customAboutDisplay, "text", "about")
}

; initalization stuff

Rest.setTheme(settings.interfaceTheme)
restInterface.Show("w600 h890")
calculateScreenSize()
Rest.notify(Rest.prefix . " Initialized")

if (settings.customNotify != "") {
    Rest.notify("[CONFIG]" . " " . settings.customNotify)
}

; start of many many functions

; makes most sense to put calculatescreensize here but it doesnt feel right

calculateScreenSize(manual := false) {
    global centerWidth := A_ScreenWidth / 2
    global centerHeight := A_ScreenHeight / 2

    if (manual) {
        Rest.notify("Recalculated Resolution`n" A_ScreenWidth "x" A_ScreenHeight " " "(" centerWidth "x" centerHeight ")", 1500)
    }
}

; buttons and like needed keybinds

resetSettings() {
    if (Rest.modal("Reset Settings", "Are you sure? This will DELETE YOUR CONFIG and reload.") = "Yes") {
        if FileExist(iniPath)
            FileDelete(iniPath)
        Reload()
    }
}

toggleMenu(*) {
    if (settings.keybindsRequireRoblox)
        if WinActive(version) && !WinActive("Roblox") || !ProcessExist("RobloxPlayerBeta.exe")
        return
    
    static isVisible := true
    isVisible := !isVisible
    if isVisible {
        restInterface.Show()
        if (Rest.dummyFocus)
            Rest.dummyFocus.Focus()
        sleep(200)
    } else
        restInterface.Hide()

}

close(*) {
    try Rest.notify("Closing Rest", 500)
    Sleep(500)
    ExitApp()
}

; bind stuff

updateBind(key, val, cb, prefix := "~*", upCb := "", skipRBtn := false) {
    oldKey := settings.%key%
    if (oldKey != "" && oldKey != val) {
        try Hotkey(prefix . oldKey, cb, "Off")
        if (upCb)
            try Hotkey(prefix . oldKey . " Up", upCb, "Off")
    }
    settings.%key% := val
    IniWrite(String(val), iniPath, "Settings", key)
    if (val = "None")
        return
    if (upCb)
        try Hotkey(prefix . val . " Up", upCb, "On")
    if !(skipRBtn && StrUpper(val) = "RBUTTON")
        try Hotkey(prefix . val, cb, "On")
}

updateSniperHoldAimBind(v) => updateBind("sniperHoldAimKeybind", v, sniperHoldAim, "~*", sniperHoldAimUp, true)
updateSniperQuickscopeBind(v) => updateBind("sniperQuickscopeKeybind", v, sniperQuickscope, "~*", sniperQuickscopeUp)
updateOpenCloseBind(v) => updateBind("keybindsOpenClose", v, toggleMenu, "")
updateExitBind(v) => updateBind("keybindsExit", v, close, "")
updateXButton1Bind(v) {
    settings.keybindsXButton1 := v
    IniWrite(v, iniPath, "Settings", "keybindsXButton1")
}
updateXButton2Bind(v) {
    settings.keybindsXButton2 := v
    IniWrite(v, iniPath, "Settings", "keybindsXButton2")
}
updateMButtonBind(v) => updateBind("keybindsMButton", v, doMButton, "~*")
updateSniperQuickscopeBind(settings.sniperQuickscopeKeybind)
updateSniperHoldAimBind(settings.sniperHoldAimKeybind)
updateOpenCloseBind(settings.keybindsOpenClose)
updateExitBind(settings.keybindsExit)
updateMButtonBind(settings.keybindsMButton)

#HotIf isListeningForBind
~*LButton::
~*RButton::
~*MButton::
~*XButton1::
~*XButton2:: {
    global bindListenerCallback
    btn := StrReplace(StrReplace(A_ThisHotkey, "~"), "*")
    if (bindListenerCallback)
        bindListenerCallback(btn)
}
#HotIf

~*XButton1:: {
    if (settings.keybindsXButton1 != "None") {
        try Send("{" settings.keybindsXButton1 "}")
        setLastNumber(settings.keybindsXButton1)
    }
}
~*XButton2:: {
    if (settings.keybindsXButton2 != "None") {
        try Send("{" settings.keybindsXButton2 "}")
        setLastNumber(settings.keybindsXButton2)
    }
}

doMButton(*) {
    if (settings.keybindsMButton != "None") {
        SendInput "{MButton}"
    }
}

; hotbar tracking stuff

#HotIf settings.hotbar && (!settings.hotbarRequireRoblox || WinActive("Roblox") || ProcessExist("RobloxPlayerBeta.exe"))
~*1::setLastNumber(1)
~*2::setLastNumber(2)
~*3::setLastNumber(3)
~*4::setLastNumber(4)
~*5::setLastNumber(5)
~*6::setLastNumber(6)
~*7::setLastNumber(7)
~*8::setLastNumber(8)
~*9::setLastNumber(9)
~*0::setLastNumber(0)
#HotIf

setLastNumber(num) {
    global lastNumber, lastNumberTime, lastMacroTime
    lastNumber := num
    lastNumberTime := A_TickCount
    lastMacroTime := 0
}

isEquipped(key) {
    for slot in StrSplit(settings.hotbarSniperSlots, ",")
        if (Trim(slot) = String(key))
            return true
    return false
}

; actual module stuff

sniperQuickscope(*) {
    if (settings.sniperRequireRoblox && !WinActive("Roblox") || !ProcessExist("RobloxPlayerBeta.exe"))
        return
        
    global lastMacroTime, isARFiring, isHoldAiming, centerWidth, centerHeight

    isSniper := false
    isAR := false
    isMouse := false

    if (settings.sniperBindMerge) {
        MouseGetPos &x, &y
        
        if (settings.sniperFirstPerson && (x != centerWidth || y != centerHeight)) {
            isMouse := true
        } else if (!settings.hotbar || isEquipped(lastNumber)) {
            isSniper := true
        } else {
            isAR := true
        }

    } else if (settings.sniperQuickscope) {
        isSniper := true
    }

    if (isSniper) {

        if ((settings.hotbar && (A_TickCount - lastNumberTime < settings.sniperEquipDelay || !isEquipped(lastNumber)))
            || A_TickCount - lastMacroTime < settings.sniperChamberDelay)
            return

        if (settings.sniperFirstPerson) {
            MouseGetPos &x, &y
            if (x != centerWidth || y != centerHeight)
                return
        }

        SendInput "{LShift Up}" 
        if (settings.sniperQuickscopeKeybind != "RBUTTON") {
            SendInput "{RButton}"
        }
        Sleep(settings.sniperBufferDelay)
        SendInput "{LButton}"
        lastMacroTime := A_TickCount
        Sleep(settings.sniperBufferDelay)

        
        if (settings.sniperQuickscopeRequip) {
            Sleep(settings.sniperBufferDelay)
            SendInput(lastNumber . lastNumber)
        } else {
            Sleep(settings.sniperBufferDelay)
            SendInput "{RButton}"
        }

        if (settings.hotbarShield) {
            SendInput(settings.hotbarShieldSlots)
            sleep(settings.hotbarShieldDelay)
            SendInput(lastNumber)
        }
        
    } else if (isAR) {
        if (!isARFiring) {
            isARFiring := true
            SendInput "{LButton Down}"
        }
    } else if (isMouse) {
        SendInput "{LButton}"
    }
}

sniperQuickscopeUp(*) {
    global isARFiring
    if (isARFiring) {
        SendInput "{LButton Up}"
        isARFiring := false
    }
}

sniperHoldAim(*) {
    global isHoldAiming

    if (!settings.sniperHoldAim || isHoldAiming)
        return
    if (settings.keybindsRequireRoblox && !WinActive("Roblox") || !ProcessExist("RobloxPlayerBeta.exe"))
        return
    if (settings.sniperFirstPerson) {
        MouseGetPos &x, &y
        if (x != centerWidth || y != centerHeight)
            return
    }
    if (settings.sniperHoldAimKeybind != "RBUTTON")
        SendInput "{RButton}"
    isHoldAiming := true
}

sniperHoldAimUp(*) {
    global isHoldAiming
    if (!settings.sniperHoldAim) {
        isHoldAiming := false
        return
    }
    if (settings.keybindsRequireRoblox && !WinActive("Roblox") || !ProcessExist("RobloxPlayerBeta.exe")) {
        isHoldAiming := false
        return
    }
    if (settings.sniperHoldAimKeybind != "RBUTTON" && !isHoldAiming)
        return
    if GetKeyState("Shift", "P") {
        isHoldAiming := false
    }
    Sleep(3)
    isHoldAiming := false
    SendInput "{RButton}"
}

; put this here as a safeguard for sniper

~*LButton:: {
    global lastMacroTime, isARFiring, centerWidth, centerHeight

    if (settings.sniperRequireRoblox && !WinActive("Roblox") || !ProcessExist("RobloxPlayerBeta.exe"))
        return

    if (!settings.sniperQuickscope)
        return
    
    if ((settings.hotbar && (A_TickCount - lastNumberTime < settings.sniperEquipDelay || !isEquipped(lastNumber)))
        || A_TickCount - lastMacroTime < settings.sniperChamberDelay)
        return
    
    if (settings.sniperFirstPerson) {
        MouseGetPos &x, &y
        if (x != centerWidth || y != centerHeight)
            return
    }

    lastMacroTime := A_TickCount
}

; update stuff

checkForUpdates()
if (Rest.dummyFocus)
    Rest.dummyFocus.Focus()
SetTimer(() => Rest.bannedGameDetection(), 1000)

checkForUpdates(manual := false) {
    global changelogDisplay, latestVersionText, latestVersion, latestChangelog, downloadUrl, version, settings, accent
    if (!manual && !settings.updateAutomatically)
        return
        
    if (manual)
        Rest.notify("Checking for updates...", 500)

    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", "https://api.github.com/repos/SillyMythic/rest/releases/latest", false)
        whr.SetRequestHeader("User-Agent", "AHK-Updater")
        whr.Send()
        
        if (whr.Status = 200) {
            if RegExMatch(whr.ResponseText, '"tag_name":\s*"v?([^"]+)"', &match) {
                latestVersion := match[1]
                if RegExMatch(whr.ResponseText, '"browser_download_url":\s*"(https://[^"]+\.ahk)"', &matchUrl) {
                    downloadUrl := matchUrl[1]
                }
                
                latestChangelog := "No release notes found."
                if RegExMatch(whr.ResponseText, '"body":\s*"(.*?)(?<!\\)"', &matchBody) {
                    changelog := matchBody[1]
                    changelog := StrReplace(changelog, "\r\n", "`r`n")
                    changelog := StrReplace(changelog, "\n", "`r`n")
                    changelog := StrReplace(changelog, "\t", "    ")
                    changelog := StrReplace(changelog, '\"', '"')
                    changelog := StrReplace(changelog, '\\', '\')
                    changelog := RegExReplace(changelog, "<[^>]+>", "")
                    if (changelog != "")
                        latestChangelog := changelog
                }
                
                getVNum(v) {
                    num := 0
                    if RegExMatch(v, "w(\d+)", &m)
                        return Integer(m[1])
                    if RegExMatch(v, "(\d+)(?:\.(\d+))?(?:\.(\d+))?", &m) {
                        num += Integer(m[1]) * 1000000
                        if (m[2] != "")
                            num += Integer(m[2]) * 1000
                        if (m[3] != "")
                            num += Integer(m[3])
                    }
                    return num
                }
                
                isNewer := getVNum(latestVersion) > getVNum(version)

                if (isNewer) {
                    if (changelogDisplay) {
                        changelogDisplay.Value := latestChangelog
                        changelogDisplay.Visible := (Rest.currentTab = "options")
                        if (changelogDisplay.Visible)
                            changelogDisplay.Redraw()
                    }
                    if (latestVersionText) {
                        latestVersionText.Value := "Latest: " . latestVersion
                        latestVersionText.Visible := (Rest.currentTab = "options")
                        if (latestVersionText.Visible)
                            latestVersionText.Redraw()
                    }
                    
                    Rest.notify("Update (" latestVersion ") Available.`nClick to download.", 15000, (*) => (
                        createUpdaterGUI(),
                        startDownload()
                    ))
                } else {
                    if (changelogDisplay && manual) {
                        changelogDisplay.Value := "You are on the latest version (" version ")."
                    }
                    if (latestVersionText) {
                        latestVersionText.Value := ""
                    }
                    if (manual) {
                        Rest.notify("You are on the latest version (" version ")", 3000)
                    }
                }
            } else {
                if (manual) {
                    Rest.notify("Could not find a version tag in the response.", 5000)
                    if (changelogDisplay)
                        changelogDisplay.Value := "Error: No version tag found in the GitHub response."
                }
            }
        } else {
            if (manual) {
                errorMsg := "GitHub Error: " . whr.Status
                if (whr.Status = 404)
                    errorMsg .= " (No releases found)"
                Rest.notify(errorMsg, 5000)
                if (changelogDisplay)
                    changelogDisplay.Value := "Error: " . errorMsg . ""
            }
        }
    } catch as e {
        if (manual) {
            Rest.notify("Update check failed: " . e.Message, 5000)
            if (changelogDisplay)
                changelogDisplay.Value := "Error: " . e.Message
        }
    }
}

createUpdaterGUI() {
    global updater, progress, titleText, watermarkText, versionText, font, interfaceBg, interfaceGrad, accent, text, latestVersion
    updater := Gui("+AlwaysOnTop -Caption +ToolWindow")
    updater.BackColor := interfaceBg
    
    totalW := 400, totalH := 180
    
    if (Rest.gradientsEnabled) {
        res := Rest.gradientRes
        gradH := 60
        r1 := Integer("0x" SubStr(interfaceGrad, 1, 2)), g1 := Integer("0x" SubStr(interfaceGrad, 3, 2)), b1 := Integer("0x" SubStr(interfaceGrad, 5, 2))
        r2 := Integer("0x" SubStr(interfaceBg, 1, 2)), g2 := Integer("0x" SubStr(interfaceBg, 3, 2)), b2 := Integer("0x" SubStr(interfaceBg, 5, 2))
        steps := Floor(gradH / res)
        Loop steps {
            perc := (steps > 1) ? (A_Index - 1) / (steps - 1) : 0
            r := Round(r1 + (r2 - r1) * perc), g := Round(g1 + (g2 - g1) * perc), b := Round(b1 + (b2 - b1) * perc)
            color := Format("{1:02X}{2:02X}{3:02X}", r, g, b)
            updater.Add("Text", "x0 y" ((A_Index - 1) * res) " w" totalW " h" res " Background" color " +Disabled")
        }
    }

    updater.SetFont("s24 c" text " Bold", font)
    updater.Add("Text", "Center x0 y25 w" totalW " +BackgroundTrans", "Rest")
    
    updater.SetFont("s10 c" text " Norm", font)
    versionText := updater.Add("Text", "Center x0 y65 w" totalW " +BackgroundTrans", "Latest: " . latestVersion)
    
    progress := updater.Add("Progress", "x20 y105 w360 h20 Background" objectBg " c" accent, 0)
    
    updater.SetFont("s10 c" accent " Bold", font)
    watermarkText := updater.Add("Text", "Center x0 y135 w" totalW " +BackgroundTrans +Hidden", "Developed by Mythic")
    
    updater.Show("w" totalW " h" totalH)
    OnMessage(0x0201, (wp, lp, msg, hwnd) => (hwnd = updater.Hwnd ? PostMessage(0xA1, 2,,, "A") : ""))
}

startDownload() {
    global downloadUrl, latestVersion, updater, progress, versionText, titleText, watermarkText, font, version
    if !IsSet(downloadUrl) || downloadUrl = "" {
        Rest.modal("Error", "Couldn't find download URL for update.", {onlyOk: true})
        return
    }

    filename := "rest" . latestVersion . ".ahk"
    
    try {
        progress.Value := 20
        Download(downloadUrl, filename)
        
        progress.Value := 100
        versionText.Visible := false
        watermarkText.Visible := true
        progress.Visible := false

        updater.SetFont("s14 c" accent " Bold", font)
        updater.Add("Text", "Center x0 y75 w400 +BackgroundTrans", "Update Complete.")
        
        updater.SetFont("s10 c" text " Norm", font)
        finishMsg := updater.Add("Text", "Center x0 y105 w400 +BackgroundTrans", "Closing in 5...")
        
        loop 5 {
            Sleep(1000)
            finishMsg.Value := "Closing in " . (5 - A_Index) . "..."
        }
        
        Run(filename . " /firstrun")
        
        if (!settings.updatePreserveVersion) {
            currentFilename := "rest" . version . ".ahk"
            if FileExist(currentFilename)
                FileDelete(currentFilename)
            else if FileExist(A_ScriptName)
                FileDelete(A_ScriptName)
        }
            
        ExitApp()
    } catch as e {
        Rest.modal("Error", "Failed to download update.`n" . e.Message, {onlyOk: true})
    }
}

; classes

class Rest {

    ; stupid variables

    static queue := []
    static tabCtrls := Map()
    static currentTab := ""
    static tabLabels := []
    static prefix := "Rest"
    static mainGui := 0
    static dummyFocus := 0
    static darkMode := true
    static gradientsEnabled := true
    static gradientRes := 2
    static darkToggle := 0
    static gradToggle := 0
    static currentBaseTheme := "Nord"
    static guiW := 0, guiH := 0
    static bgLines := []
    static topBarLines := []
    static openDropdowns := []

    ; theme maps

    static themes := Map(
        "Nord",            {interfaceBg:"2E3440", groupBg:"3B4252", objectBg:"434C5E", accent:"88C0D0", text:"D8DEE9", groupGrad:"434C5E", interfaceGrad:"3B4252", hint:"D8DEE9", topText:"D8DEE9"},
        "Nord Light",      {interfaceBg:"ECEFF4", groupBg:"E5E9F0", objectBg:"D8DEE9", accent:"5E81AC", text:"2E3440", groupGrad:"D8DEE9", interfaceGrad:"E5E9F0", hint:"2E3440", topText:"2E3440"},
        "Gruvbox",         {interfaceBg:"282828", groupBg:"3C3836", objectBg:"504945", accent:"FABD2F", text:"EBDBB2", groupGrad:"504945", interfaceGrad:"3C3836", hint:"EBDBB2", topText:"EBDBB2"},
        "Gruvbox Light",   {interfaceBg:"FBF1C7", groupBg:"F2E5BC", objectBg:"EBDBB2", accent:"AF3A03", text:"3C3836", groupGrad:"EBDBB2", interfaceGrad:"F2E5BC", hint:"3C3836", topText:"3C3836"},
        "Kanagawa",        {interfaceBg:"1F1F28", groupBg:"2A2A37", objectBg:"363646", accent:"FFA066", text:"EBDBB2", groupGrad:"363646", interfaceGrad:"2a2a36", hint:"EBDBB2", topText:"dcc6ba"},
        "Kanagawa Light",  {interfaceBg:"F2ECBC", groupBg:"E8E4B0", objectBg:"DCD7BA", accent:"E82424", text:"545464", groupGrad:"DCD7BA", interfaceGrad:"E8E4B0", hint:"545464", topText:"545464"},
        "Rose Pine",       {interfaceBg:"191724", groupBg:"1F1D2E", objectBg:"26233A", accent:"EBBCBA", text:"E0DEF4", groupGrad:"26233A", interfaceGrad:"1F1D2E", hint:"E0DEF4", topText:"E0DEF4"},
        "Rose Pine Light", {interfaceBg:"FAF4ED", groupBg:"FFF1F3", objectBg:"F2E9E1", accent:"D7827E", text:"575279", groupGrad:"F2E9E1", interfaceGrad:"FFF1F3", hint:"575279", topText:"575279"},
        "Everforest",      {interfaceBg:"2D353B", groupBg:"343F44", objectBg:"3D484D", accent:"A7C080", text:"D3C6AA", groupGrad:"3D484D", interfaceGrad:"343F44", hint:"D3C6AA", topText:"D3C6AA"},
        "Everforest Light",{interfaceBg:"FDF6E3", groupBg:"F3EAD3", objectBg:"EAE4CA", accent:"859900", text:"5C6A72", groupGrad:"EAE4CA", interfaceGrad:"F3EAD3", hint:"5C6A72", topText:"5C6A72"},
        "Catppuccin",      {interfaceBg:"181825", groupBg:"1E1E2E", objectBg:"313244", accent:"CBA6F7", text:"CDD6F4", hint:"CDD6F4",},
        "Catppuccin Light",{interfaceBg:"EFF1F5", groupBg:"E6E9EF", objectBg:"CCD0DA", accent:"8839EF", text:"4C4F69", groupGrad:"CCD0DA", interfaceGrad:"E6E9EF", hint:"4C4F69", topText:"4C4F69"},
        "Material",        {interfaceBg:"181818", groupBg:"212121", objectBg:"383838", accent:"90caf9", text:"e0e0e0", hint:"e0e0e0",},
        "Material Light",  {interfaceBg:"f5f5f5", groupBg:"ffffff", objectBg:"e0e0e0", accent:"90caf9", text:"181818", hint:"181818",},
        "Solarized",       {interfaceBg:"002B36", groupBg:"073642", objectBg:"586E75", accent:"268BD2", text:"839496", hint:"839496",},
        "Solarized Light", {interfaceBg:"FDF6E3", groupBg:"EEE8D5", objectBg:"93A1A1", accent:"268BD2", text:"54676e", groupGrad:"93A1A1", interfaceGrad:"c1d1d8", hint:"54676e", topText:"3a4c53"},
        "Ayu Mirage",      {interfaceBg:"212733", groupBg:"242936", objectBg:"2D333F", accent:"FFCC66", text:"D9D7CE", hint:"D9D7CE",},
        "Ayu Mirage Light",{interfaceBg:"FAFAFA", groupBg:"F5F5F5", objectBg:"EDEEF0", accent:"F29718", text:"5C6773", hint:"5C6773",}
        ;"War Tycoon", {interfaceBg:"141C18", groupBg:"2B4637", objectBg:"23392D", accent:"588F70", text:"FFFFFF", groupGrad:"23392D", interfaceGrad:"1E2D26", hint:"FFFFFF", topText:"FFFFFF"}
    )

    static customThemes := Map(
    )

    static darkToLight := Map(
        "Nord", "Nord Light",
        "Gruvbox", "Gruvbox Light",
        "Material", "Material Light",
        "Everforest", "Everforest Light",
        "Solarized", "Solarized Light",
        "Rose Pine", "Rose Pine Light",
        "Kanagawa", "Kanagawa Light",
        "Ayu Mirage", "Ayu Mirage Light",
        "Catppuccin", "Catppuccin Light"
    )

    ; meat and potatoes and class functions

    static toggleDarkMode(state) {
        this.darkMode := state
        this.setTheme(this.currentBaseTheme)
    }

    static toggleGradients(state) {
        this.gradientsEnabled := state
        this.setTheme(this.currentBaseTheme)
    }

    static refreshGradients() {
        if (!this.mainGui)
            return
            
        DllCall("SendMessage", "ptr", this.mainGui.Hwnd, "uint", 0x000B, "ptr", 0, "ptr", 0)

        targetTheme := this.currentBaseTheme
        if (!this.darkMode && this.darkToLight.Has(targetTheme))
            targetTheme := this.darkToLight[targetTheme]
        
        t := this.getThemeObj(targetTheme)
        if (!t)
            return

        this.updateBackground(this.mainGui, interfaceBg, (t.HasProp("bg2") ? t.bg2 : ""))

        this.updateTopBar(interfaceGrad, interfaceBg)

        gradH := 100
        steps := Floor(gradH / this.gradientRes)
        
        r1 := Integer("0x" SubStr(groupGrad, 1, 2)), g1 := Integer("0x" SubStr(groupGrad, 3, 2)), b1 := Integer("0x" SubStr(groupGrad, 5, 2))
        r2 := Integer("0x" SubStr(groupBg, 1, 2)), g2 := Integer("0x" SubStr(groupBg, 3, 2)), b2 := Integer("0x" SubStr(groupBg, 5, 2))
        
        for tabName, ctrls in this.tabCtrls {
            for c in ctrls {
                if (c.RestType = "group_grad") {
                    if (!this.gradientsEnabled || c.GradIndex > steps) {
                        c.Visible := false
                        continue
                    }
                    
                    newY := c.GroupY + (c.GradIndex - 1) * this.gradientRes
                
                    

                    perc := (c.GradIndex - 1) / (steps - 1)
                    r := Round(r1 + (r2 - r1) * perc), g := Round(g1 + (g2 - g1) * perc), b := Round(b1 + (b2 - b1) * perc)
                    color := Format("{1:02X}{2:02X}{3:02X}", r, g, b)
                    
                    c.Opt("Background" color)
                    c.Move(, newY,, this.gradientRes)
                    
                    if (tabName = "all" || tabName = this.currentTab)
                        c.Visible := true
                }
            }
        }
        
        DllCall("SendMessage", "ptr", this.mainGui.Hwnd, "uint", 0x000B, "ptr", 1, "ptr", 0)
        WinRedraw(this.mainGui.Hwnd)
    }

    static updateGradientRes(val) {
        this.gradientRes := val
        this.refreshUI()
    }

    static setFont(name) {
        if (SubStr(name, 1, 9) = "[CONFIG] ")
            name := SubStr(name, 10)
        global font := name
        if !this.mainGui
            return
            
        this.mainGui.SetFont("s9", font)
        for tabName, ctrls in this.tabCtrls {
            for c in ctrls {
                try {
                    fontSize := "s9"
                    fontStyle := "Norm"
                    
                    if (c.RestType = "tab" || c.RestType = "group_title") {
                        fontSize := "s10"
                        fontStyle := "Bold"
                    } else if (c.RestType = "hint") {
                        fontStyle := "Norm"
                    } else if (c.RestType = "slider_text" || c.RestType = "keybind_text") {
                        fontSize := "s8"
                        fontStyle := "Bold"
                    }
                    
                    c.SetFont(fontSize " " fontStyle, font)
                } catch {
                }
            }
        }
    }

    static getThemeObj(name) {
        if this.themes.Has(name)
            return this.themes[name]
        if this.customThemes.Has(name)
            return this.customThemes[name]
        return 0
    }

    static setTheme(name) {
        for d, l in this.darkToLight {
            if (name = l) {
                name := d
                break
            }
        }

        this.currentBaseTheme := name
        targetTheme := name

        if (!this.darkMode) {
            if (this.darkToLight.Has(name)) {
                targetTheme := this.darkToLight[name]
            } else {
                this.darkMode := true
                if (this.darkToggle)
                    this.darkToggle.Value := true
                Rest.notify("Light mode is not available for " name, 1000)
            }
        }

        t := this.getThemeObj(targetTheme)
        if !t
            return

        global interfaceBg := t.interfaceBg, groupBg := t.groupBg, objectBg := t.objectBg, accent := t.accent, text := t.text
        global groupGrad := t.HasProp("groupGrad") ? t.groupGrad : t.objectBg
        global interfaceGrad := t.HasProp("interfaceGrad") ? t.interfaceGrad : t.groupBg
        global hintColor := t.HasProp("hint") ? t.hint : t.accent
        global topTextColor := t.HasProp("topText") ? t.topText : t.text

        if (this.darkToggle) {
            hasLight := this.darkToLight.Has(name)
            this.darkToggle.ctrl.RestDisabled := !hasLight
            this.darkToggle.lbl.RestDisabled := !hasLight
        }

        if (this.gradToggle) {
            configName := "[CONFIG] " (settings.customThemeName != "" ? settings.customThemeName : "Custom")
            canGrad := !(name == configName && !settings.customThemeGradients)
            this.gradToggle.ctrl.RestDisabled := !canGrad
            this.gradToggle.lbl.RestDisabled := !canGrad
            if (!canGrad) {
                this.gradientsEnabled := false
            } else {
                this.gradientsEnabled := settings.interfaceGradients
            }
        }

        this.updateBackground(this.mainGui, t.interfaceBg, t.HasProp("bg2") ? t.bg2 : "")
        this.refreshUI()
    }

    static updateBackground(guiObj, c1, c2 := "") {
        if (!this.mainGui)
            return
        res := Rest.gradientRes
        w := this.guiW, h := this.guiH
        
        if (c2 = "" || !this.gradientsEnabled) {
            for l in this.bgLines
                l.Visible := false
            this.mainGui.BackColor := c1
            return
        }
        
        r1 := Integer("0x" SubStr(c1, 1, 2)), g1 := Integer("0x" SubStr(c1, 3, 2)), b1 := Integer("0x" SubStr(c1, 5, 2))
        r2 := Integer("0x" SubStr(c2, 1, 2)), g2 := Integer("0x" SubStr(c2, 3, 2)), b2 := Integer("0x" SubStr(c2, 5, 2))
        
        steps := Min(this.bgLines.Length, Floor(h / res))
        
        Loop this.bgLines.Length {
            l := this.bgLines[A_Index]
            if (A_Index > steps) {
                l.Visible := false
                continue
            }
            
            perc := (steps > 1) ? (A_Index - 1) / (steps - 1) : 0
            r := Round(r1 + (r2 - r1) * perc), g := Round(g1 + (g2 - g1) * perc), b := Round(b1 + (b2 - b1) * perc)
            color := Format("{1:02X}{2:02X}{3:02X}", r, g, b)
            
            l.Opt("Background" color)
            l.Move(0, (A_Index - 1) * res, w, res)
            l.Visible := true
            l.Redraw()
        }
    }

    static refreshUI(accentOnly := false) {
        if (this.mainGui && !accentOnly)
            this.mainGui.BackColor := interfaceBg
        

        this.updateTopBar(interfaceGrad, interfaceBg)
        
        for tabName, ctrls in this.tabCtrls {
            for c in ctrls {
                try {
                    if (accentOnly) {

                        if (c.RestType = "tab") {
                            new_c := (c.TabName = this.currentTab ? accent : text)
                            c.Visible := false
                            c.Opt("+BackgroundTrans c" new_c)
                            c.Visible := true
                        }

                        else if (c.RestType = "accent") {
                            c.Opt("Background" accent)
                            try (c.SliderUpdate)()
                            c.Redraw()
                        }

                    else if (c.RestType = "hint") {
                        if (c.HasProp("RestDisabled") && c.RestDisabled)
                            c.Opt("c505050")
                        else if (settings.interfaceHints)
                            c.Opt("c" hintColor)
                        else
                            c.Opt("c" text)
                        
                        c.Visible := (tabName = "all" || tabName = this.currentTab)
                        try {
                            if (!settings.interfaceHints && c.Value = "(?)")
                                c.Visible := false
                        } catch {
                        }
                    }

                        else if (c.RestType = "topText") {
                            c.Opt("+BackgroundTrans c" topTextColor), c.Redraw()
                        }

                        else if (c.RestType = "toggle" && c.IsOn) {
                            c.Opt("Background" accent), c.Redraw()
                        }
                        else if (c.RestType = "slider_text" || c.RestType = "keybind_text") {
                            if (c.RestType = "slider_text") {
                                try {
                                    if (!c.IsHiddenBecauseEditing) {
                                        try (c.SliderUpdate)()
                                    }
                                } catch {
                                    try (c.SliderUpdate)()
                                }
                            } else {
                                c.Opt("c" text)
                            }
                            c.Opt("+BackgroundTrans")
                            c.Redraw()
                        }
                        else if (c.RestType = "slider_edit") {
                            c.Opt("Background" objectBg " c" text)
                            c.Redraw()
                        }
                        continue
                    }

                    if (c.RestType = "section") 
                        c.Opt("Background" groupBg)
                    else if (c.RestType = "control" || c.RestType = "slider_edit") 
                        c.Opt("Background" objectBg " c" text)
                    else if (c.RestType = "changelog" || c.RestType = "customAboutBody")
                        c.Opt("Background" groupBg " c" text)
                    else if (c.RestType = "toggle")
                        c.Opt("Background" (c.IsOn ? accent : objectBg))
                    else if (c.RestType = "text" || c.RestType = "group_title" || c.RestType = "keybind_text") {
                        if (c.HasProp("RestDisabled") && c.RestDisabled && c.RestType == "text")
                            c.Opt("c505050 +BackgroundTrans")
                        else
                            c.Opt("c" text " +BackgroundTrans")
                        c.Visible := (tabName = "all" || tabName = this.currentTab)
                    }
                    else if (c.RestType = "slider_text") {
                        try {
                            if (!c.IsHiddenBecauseEditing) {
                                try (c.SliderUpdate)()
                            }
                        } catch {
                            try (c.SliderUpdate)()
                        }
                    }
                    else if (c.RestType = "accent") {
                        c.Opt("Background" accent)
                        try (c.SliderUpdate)()
                        c.Redraw()
                    }
                    else if (c.RestType = "hint") {
                        c.Visible := false
                        if (c.HasProp("RestDisabled") && c.RestDisabled)
                            c.Opt("c505050 +BackgroundTrans")
                        else if (settings.interfaceHints)
                            c.Opt("c" hintColor " +BackgroundTrans")
                        else
                            c.Opt("c" text " +BackgroundTrans")
                        c.Visible := (tabName = "all" || tabName = this.currentTab)
                    }
                    else if (c.RestType = "topText")
                        c.Opt("c" topTextColor " +BackgroundTrans")
                    else if (c.RestType = "tab")
                        c.Opt("c" (c.TabName = this.currentTab ? accent : text) " +BackgroundTrans")
                    else if (c.RestType = "group_grad") {

                    }
                    c.Redraw()
                } catch {
                }
            }
        }
        this.refreshGradients()
        if (!accentOnly) 
            this.updateTabs()
        if (this.mainGui && DllCall("IsWindowVisible", "Ptr", this.mainGui.Hwnd))
            WinRedraw(this.mainGui.Hwnd)
    }

    static updateTopBar(c1, c2) {
        if (!this.mainGui || this.topBarLines.Length = 0)
            return
        
        res := Rest.gradientRes
        w := this.guiW
        
        if (!this.gradientsEnabled) {
            for l in this.topBarLines {
                if (A_Index = 1) {
                    l.Opt("Background" c1)
                    l.Move(0, 0, w, 40)
                    l.Visible := true
                    l.Redraw()
                } else {
                    l.Visible := false
                }
            }
            return
        }
        
        r1 := Integer("0x" SubStr(c1, 1, 2)), g1 := Integer("0x" SubStr(c1, 3, 2)), b1 := Integer("0x" SubStr(c1, 5, 2))
        r2 := Integer("0x" SubStr(c2, 1, 2)), g2 := Integer("0x" SubStr(c2, 3, 2)), b2 := Integer("0x" SubStr(c2, 5, 2))
        
        steps := Min(this.topBarLines.Length, Floor(40 / res))
        
        Loop this.topBarLines.Length {
            l := this.topBarLines[A_Index]
            if (A_Index > steps) {
                l.Visible := false
                continue
            }
            
            perc := (steps > 1) ? (A_Index - 1) / (steps - 1) : 0
            r := Round(r1 + (r2 - r1) * perc), g := Round(g1 + (g2 - g1) * perc), b := Round(b1 + (b2 - b1) * perc)
            color := Format("{1:02X}{2:02X}{3:02X}", r, g, b)
            
            l.Opt("Background" color)
            l.Move(0, (A_Index - 1) * res, w, res)
            l.Visible := true
            l.Redraw()
        }
    }

    static gradient(guiObj, x, y, w, h, startColor, endColor, tabName := "all") {

        r1 := Integer("0x" SubStr(startColor, 1, 2)), g1 := Integer("0x" SubStr(startColor, 3, 2)), b1 := Integer("0x" SubStr(startColor, 5, 2))
        r2 := Integer("0x" SubStr(endColor, 1, 2)), g2 := Integer("0x" SubStr(endColor, 3, 2)), b2 := Integer("0x" SubStr(endColor, 5, 2))
        
        Loop h {
            perc := (A_Index - 1) / (h - 1)
            r := Round(r1 + (r2 - r1) * perc)
            g := Round(g1 + (g2 - g1) * perc)
            b := Round(b1 + (b2 - b1) * perc)
            color := Format("{1:02X}{2:02X}{3:02X}", r, g, b)
            line := guiObj.Add("Text", "x" x " y" (y + A_Index - 1) " w" w " h1 Background" color " +Disabled")
            this.register(line, "gradient", tabName)
        }
    }

    static gui(title, w := 400, h := 400) {
        myGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
        this.mainGui := myGui
        myGui.BackColor := interfaceBg
        this.guiW := w, this.guiH := h
        
        this.dummyFocus := myGui.Add("Button", "x-10 y-10 w0 h0")
        

        this.bgLines := []
        maxBgSteps := 100
        Loop maxBgSteps {
            l := myGui.Add("Text", "x0 y0 w" w " h1 +Disabled +Hidden")
            this.bgLines.Push(l)
        }
        

        this.topBarLines := []
        maxTopBarSteps := 45
        Loop maxTopBarSteps {
            l := myGui.Add("Text", "x0 y0 w" w " h1 +Disabled +Hidden")
            this.topBarLines.Push(l)
        }
        this.updateTopBar(interfaceGrad, interfaceBg)
        
        myGui.SetFont("s9 c" text, font)
        
        padding := 15
        this.titleTxt := myGui.Add("Text", "x" padding " y12 +BackgroundTrans", this.prefix . " " . title)
        this.register(this.titleTxt, "topText", "all")
        
        closeBtnSize := 20
        closeBtn := myGui.Add("Text", "x" (w - padding - closeBtnSize + 5) " y10 w" closeBtnSize " h" closeBtnSize " Center +0x100 +BackgroundTrans", "✕")
        closeBtn.OnEvent("Click", (*) => ExitApp())
        this.register(closeBtn, "topText", "all")
        
        minBtn := myGui.Add("Text", "x" (w - padding - (closeBtnSize * 2) - 5) " y10 w" closeBtnSize " h" closeBtnSize " Center +0x100 +BackgroundTrans", "—")
        minBtn.OnEvent("Click", (*) => myGui.Hide())
        this.register(minBtn, "topText", "all")
        
        OnMessage(0x0201, (wp, lp, msg, hwnd) => (hwnd = myGui.Hwnd ? (Rest.closeAllDropdowns(), PostMessage(0xA1, 2,,, "A")) : ""))

        disableRClick(wParam, lParam, msg, hwnd) {
            try if WinGetClass(hwnd) == "Edit"
                return 0
        }
        OnMessage(0x0204, disableRClick)
        OnMessage(0x0205, disableRClick)

        return myGui
    }

    static tabs(guiObj, x, y, names, defaultTab := "") {
        this.tabLabels := []
        this.currentTab := defaultTab = "" ? names[1] : defaultTab
        for name in names {
            guiObj.SetFont("s10 Bold", font)
            t := guiObj.Add("Text", "x" x " y" y " +BackgroundTrans +0x100", name)
            t.TabName := name
            this.register(t, "tab", "all")
            t.OnEvent("Click", (ctrl, *) => this.switchTab(ctrl.TabName))
            t.GetPos(,, &tw)
            x += tw + 30
            this.tabLabels.Push(t)
            if !this.tabCtrls.Has(name)
                this.tabCtrls[name] := []
        }
        for tab, ctrls in this.tabCtrls {
            for ctrl in ctrls {
                if (tab != "all") {
                    if (ctrl.RestType = "slider_edit")
                        ctrl.Visible := false
                    else
                        ctrl.Visible := (tab = this.currentTab)
                }
            }
        }
        this.updateTabs()
    }

    static switchTab(name) {
        if (name = this.currentTab || !this.mainGui)
            return


        DllCall("SendMessage", "ptr", this.mainGui.Hwnd, "uint", 0x000B, "ptr", 0, "ptr", 0)

        if this.tabCtrls.Has(this.currentTab) {
            for ctrl in this.tabCtrls[this.currentTab]
                ctrl.Visible := false
        }

        this.currentTab := name

        if this.tabCtrls.Has(name) {
            for ctrl in this.tabCtrls[name] {
                if (ctrl.RestType = "group_grad" && !this.gradientsEnabled)
                    continue
                if (ctrl.RestType = "slider_edit")
                    continue
                try {
                    if (ctrl.RestType = "hint" && !settings.interfaceHints && ctrl.Value = "(?)")
                        continue
                } catch {
                }
                
                if (ctrl.RestType = "slider_text") {
                    try {
                        if (ctrl.IsHiddenBecauseEditing)
                            continue
                    } catch {
                    }
                }
                
                ctrl.Visible := true
            }
        }

        this.updateTabs()
        
        if (this.dummyFocus)
            this.dummyFocus.Focus()
            

        DllCall("SendMessage", "ptr", this.mainGui.Hwnd, "uint", 0x000B, "ptr", 1, "ptr", 0)
        WinRedraw(this.mainGui.Hwnd)
    }

    static updateTabs() {
        for t in this.tabLabels {
            t.Opt("c" (t.TabName = this.currentTab ? accent : text))
            t.Redraw()
        }
    }

    static notify(message, lifetime := 3000, action := "") {
        if !settings.interfaceNotifications
            return
        width := 350, barThickness := 8, window := Gui("+AlwaysOnTop -Caption +ToolWindow"), window.BackColor := interfaceBg
        isClickable := IsObject(action) && HasMethod(action)
        
        window.SetFont("s11 Bold", font)
        measureMsg := RegExReplace(message, "([^\s]{15})", "$1 ")
        dummy := window.Add("Text", "x0 y0 w" (width - 70) " +Hidden +Wrap", measureMsg)
        dummy.GetPos(,,,&labelH)
        height := Max(75, 18 + labelH + 15 + barThickness)
        
        if (this.gradientsEnabled) {
            res := this.gradientRes
            gradH := Min(height, 60)
            r1 := Integer("0x" SubStr(interfaceGrad, 1, 2)), g1 := Integer("0x" SubStr(interfaceGrad, 3, 2)), b1 := Integer("0x" SubStr(interfaceGrad, 5, 2))
            r2 := Integer("0x" SubStr(interfaceBg, 1, 2)), g2 := Integer("0x" SubStr(interfaceBg, 3, 2)), b2 := Integer("0x" SubStr(interfaceBg, 5, 2))
            steps := Floor(gradH / res)
            Loop steps {
                perc := (steps > 1) ? (A_Index - 1) / (steps - 1) : 0
                r := Round(r1 + (r2 - r1) * perc), g := Round(g1 + (g2 - g1) * perc), b := Round(b1 + (b2 - b1) * perc)
                color := Format("{1:02X}{2:02X}{3:02X}", r, g, b)
                window.Add("Text", "x0 y" ((A_Index - 1) * res) " w" width " h" res " Background" color " +Disabled")
            }
        }
        
        window.SetFont("s10 c" text " Bold", font)
        closeBtn := window.Add("Text", "x" (width - 25) " y5 w20 h20 Center +BackgroundTrans", "✕")
        window.SetFont("s11 c" (isClickable ? accent : text) " Bold", font)
        label := window.Add("Text", "Left x15 y18 w" (width - 70) " h" labelH " +BackgroundTrans +Wrap +0x2000", message)
        
        progressBar := window.Add("Progress", "x-1 y" (height - barThickness) " w" (width + 1) " h" barThickness " +Smooth c" accent " Background" interfaceBg, 100)
        yOffset := 20
        for item in this.queue {
            yOffset += item.height + 5
        }
        window.Show("x" (A_ScreenWidth - width - 20) " y" yOffset " w" width " h" height " NoActivate")
        notification := { window: window, bar: progressBar, lifetime: lifetime, startedAt: 0, height: height }
        this.queue.Push(notification), closeBtn.OnEvent("Click", (*) => this.handleClick(notification))
        if isClickable {
            label.OnEvent("Click", (*) => (this.handleClick(notification), SetTimer(action, -1)))
        }
        if (this.queue.Length = 1) {
            SetTimer(() => this.tick(), 20)
        }
    }

    static register(ctrl, type := "text", tabName := "") {
        if (tabName = "")
            tabName := (this.currentTab = "") ? "all" : this.currentTab
            
        if !this.tabCtrls.Has(tabName)
            this.tabCtrls[tabName] := []
            
        ctrl.RestType := type
        this.tabCtrls[tabName].Push(ctrl)
        if (tabName != "all") {
            if (type = "slider_edit")
                ctrl.Visible := false
            else
                ctrl.Visible := (tabName = this.currentTab)
        }
        return ctrl
    }

    static group(guiObj, title, x, y, w, h, tabName := "") {

        bgBox := guiObj.Add("Text", "x" x " y" y " w" w " h" h " Background" groupBg)
        this.register(bgBox, "section", tabName)


        Loop 100 {
            l := guiObj.Add("Text", "x" x " y" y " w" w " h2 +Disabled +Hidden")
            l.GradIndex := A_Index, l.GroupY := y
            this.register(l, "group_grad", tabName)
        }

        guiObj.SetFont("s10 c" text " Bold", font)
        lbl := guiObj.Add("Text", "x" (x+15) " y" (y+12) " w" (w-30) " +BackgroundTrans", title)
        this.register(lbl, "group_title", tabName)
        

        this.refreshGradients()
    }

    static attachHint(guiObj, ctrl, hintMsg) {
        if (Type(hintMsg) != "String" || hintMsg = "")
            return

        link := ""
        if RegExMatch(hintMsg, "https?://[^\s]+", &match) {
            link := match[0]
        }

        hintGui := [0]
        checkHover() {
            try {
                if (!settings.interfaceHints) {
                    if (hintGui[1]) {
                        hintGui[1].Destroy()
                        hintGui[1] := 0
                    }
                    return
                }

                if !WinExist(guiObj) {
                    SetTimer(checkHover, 0)
                    if (hintGui[1]) 
                        hintGui[1].Destroy()
                    return
                }
                
                if !ctrl.Visible {
                    if (hintGui[1]) {
                        hintGui[1].Destroy()
                        hintGui[1] := 0
                    }
                    return
                }

                MouseGetPos(,, &id, &controlHwnd, 2)
                if (controlHwnd = ctrl.Hwnd) {
                    if (!hintGui[1]) {
                        hintGui[1] := Gui("+AlwaysOnTop -Caption +ToolWindow")
                        hintGui[1].BackColor := objectBg
                        hintGui[1].MarginX := 10
                        hintGui[1].MarginY := 5
                        hintGui[1].SetFont("s9 c" text " Norm", font)
                        
                        wrappedMsg := ""
                        maxChars := 80
                        i := 1
                        while (i <= StrLen(hintMsg)) {
                            wrappedMsg .= SubStr(hintMsg, i, maxChars) . "`n"
                            i += maxChars
                        }
                        
                        hintGui[1].Add("Text",, RTrim(wrappedMsg, "`n"))
                        if (link) {
                            hintGui[1].SetFont("s8 c" accent " Bold")
                            hintGui[1].Add("Text", "y+2", "Open link in browser")
                        }
                        
                        CoordMode("Mouse", "Screen")
                        MouseGetPos(&mx, &my)
                        hintGui[1].Show("x" (mx + 15) " y" (my + 15) " NoActivate")
                    }
                } else if (hintGui[1]) {
                    hintGui[1].Destroy()
                    hintGui[1] := 0
                }
            } catch {
                SetTimer(checkHover, 0)
            }
        }
        SetTimer(checkHover, 100)
    }

    static toggle(guiObj, x, y, label, initialState := false, tabName := "", callback := "", hintMsg := "") {
        btn := guiObj.Add("Text", "x" x " y" y " w18 h18 Center +0x200 +0x100", "")
        btn.IsOn := initialState
        
        update(ctrl) {
            ctrl.Opt("Background" (ctrl.IsOn ? accent : objectBg))
            ctrl.Redraw()
        }
        update(btn)

        state := { ctrl: btn, cb: callback }
        btn.RestDisabled := false
        state.DefineProp("Value", {
            get: (s) => s.ctrl.IsOn,
            set: (s, v) => (s.ctrl.IsOn := v, update(s.ctrl))
        })
        if (Type(hintMsg) = "String" && hintMsg != "") {
            guiObj.SetFont("s9 c" hintColor " Norm", font)
        } else {
            guiObj.SetFont("s9 c" text " Norm", font)
        }
        lbl := guiObj.Add("Text", "x" (x + 28) " y" (y + 2) " +BackgroundTrans", label)
        lbl.RestDisabled := false
        state.lbl := lbl
        
        this.attachHint(guiObj, lbl, hintMsg)

        handler(*) {
            if (btn.RestDisabled)
                return
            btn.IsOn := !btn.IsOn
            update(btn)
            
            if (Type(hintMsg) = "String" && hintMsg != "" && InStr(hintMsg, "http")) {
                if RegExMatch(hintMsg, "https?://[^\s]+", &match)
                    Run(match[0])
            }

            if state.cb
                (state.cb)(btn.IsOn)
        }

        btn.OnEvent("Click", handler)
        lbl.OnEvent("Click", handler)
        
        this.register(btn, "toggle", tabName)
        this.register(lbl, (Type(hintMsg) = "String" && hintMsg != "" ? "hint" : "text"), tabName)
        
        return state
    }

    static slider(guiObj, x, y, w, label, minVal, maxVal, defaultVal, tabName := "", callback := "", hintMsg := "") {
        if (Type(hintMsg) = "String" && hintMsg != "") {
            guiObj.SetFont("s9 c" hintColor " Norm", font)
        } else {
            guiObj.SetFont("s9 c" text " Norm", font)
        }
        lbl := guiObj.Add("Text", "x" x " y" y " w" w " +BackgroundTrans", label)
        this.attachHint(guiObj, lbl, hintMsg)
        
        if (Type(hintMsg) = "String" && hintMsg != "" && InStr(hintMsg, "http")) {
            if RegExMatch(hintMsg, "https?://[^\s]+", &match) {
                lbl.Opt("+0x100")
                link := match[0]
                lbl.OnEvent("Click", (*) => Run(link))
            }
        }

        track := guiObj.Add("Text", "x" x " y" (y+22) " w" w " h20 Background" objectBg " +0x100")
        fill := guiObj.Add("Text", "x" x " y" (y+22) " w0 h20 Background" accent " +Disabled")
        guiObj.SetFont("s8 Bold c" text, font)
        valDisplay := guiObj.Add("Text", "Center x" x " y" (y+22) " w" w " h20 +BackgroundTrans +0x200", "")
        
        guiObj.SetFont("s9 c" text " Norm", font)
        editBox := guiObj.Add("Edit", "Center x" x " y" (y+22) " w" w " h20 Background" objectBg " c" text " -E0x200 Hidden", "")
        editBox.Visible := false

        this.register(lbl, (Type(hintMsg) = "String" && hintMsg != "" ? "hint" : "text"), tabName)
        this.register(track, "control", tabName)
        this.register(fill, "accent", tabName)
        this.register(valDisplay, "slider_text", tabName)
        this.register(editBox, "slider_edit", tabName)
        
        s := { val: defaultVal, min: minVal, max: maxVal, x: x, w: w, fill: fill, display: valDisplay, cb: callback, isEditing: false }
        s.DefineProp("Value", {
            get: (obj) => Round(obj.val),
            set: (obj, v) => (obj.val := v, update())
        })
        
        update(mx := -1) {
            if (mx != -1) {
                s.val := s.min + (s.max - s.min) * Max(0, Min(1, (mx - s.x) / s.w))
            }
            dv := Round(s.val)
            s.display.Value := dv " / " s.max
            
            perc := (s.max > s.min) ? (dv - s.min) / (s.max - s.min) : 0
            s.display.Opt("c" (perc > 0.55 ? groupBg : text))
            
            s.fill.Move(,, Max(0, Min(s.w, s.w * (dv - s.min) / (s.max - s.min))))
            s.fill.Opt("Background" accent)
            s.fill.Redraw()
            
            if (!s.isEditing) {
                if (s.display.Visible != (tabName = "all" || tabName = Rest.currentTab)) {
                    s.display.Visible := (tabName = "all" || tabName = Rest.currentTab)
                    s.display.Redraw()
                }
            } else {
                s.display.Visible := false
            }
            
            if (s.cb && mx != -1) {
                (s.cb)(dv)
            }
        }
        update()
        
        openEdit(*) {
            s.isEditing := true
            valDisplay.IsHiddenBecauseEditing := true
            editBox.Value := Round(s.val)
            s.display.Visible := false
            editBox.Visible := true
            editBox.Focus()
            SetTimer(checkKeys, 20)
        }
        
        closeEdit(*) {
            SetTimer(checkKeys, 0)
            if (!s.isEditing)
                return
            newVal := editBox.Value
            if (IsNumber(newVal)) {
                s.val := newVal
                update()
                if s.cb
                    (s.cb)(Round(s.val))
            }
            s.isEditing := false
            valDisplay.IsHiddenBecauseEditing := false
            editBox.Visible := false
            
            if (tabName = "all" || tabName = Rest.currentTab) {
                s.display.Visible := true
                s.display.Redraw()
            }
            s.fill.Redraw()
        }
        
        checkKeys() {
            if (!s.isEditing) {
                SetTimer(checkKeys, 0)
                return
            }
            if GetKeyState("Enter", "P") || GetKeyState("NumpadEnter", "P") {
                closeEdit()
                return
            }
            if GetKeyState("Escape", "P") {
                editBox.Value := Round(s.val)
                closeEdit()
                return
            }
            if GetKeyState("LButton", "P") || GetKeyState("RButton", "P") {
                MouseGetPos(,, &id, &controlHwnd, 2)
                if (controlHwnd != editBox.Hwnd) {
                    closeEdit()
                    return
                }
            }
        }
        
        track.OnEvent("Click", slide)
        valDisplay.OnEvent("Click", slide)
        valDisplay.OnEvent("DoubleClick", openEdit)
        valDisplay.OnEvent("ContextMenu", openEdit)
        track.OnEvent("ContextMenu", openEdit)
        editBox.OnEvent("LoseFocus", closeEdit)
        
        slide(*) {
            CoordMode("Mouse", "Window")
            while GetKeyState("LButton", "P") {
                MouseGetPos(&mx)
                update(mx)
                Sleep(10)
            }
        }
        fill.SliderUpdate := update
        valDisplay.SliderUpdate := update
        update()
        return s
    }

    static keybind(guiObj, x, y, defaultKey := "None", tabName := "", callback := "", hintMsg := "") {
        if (Type(hintMsg) = "String" && hintMsg != "") {
            guiObj.SetFont("s9 c" hintColor " Norm", font)
        } else {
            guiObj.SetFont("s9 c" text " Norm", font)
        }
        bgBtn := guiObj.Add("Text", "x" x " y" y " w70 h25 Background" objectBg " Center +0x200 +0x100")
        
        guiObj.SetFont("s8 Bold c" text, font)
        btnText := guiObj.Add("Text", "x" x " y" y " w70 h25 Center +0x200 +BackgroundTrans", StrUpper(defaultKey))
        
        this.attachHint(guiObj, btnText, hintMsg)
        
        this.register(bgBtn, "control", tabName), this.register(btnText, "keybind_text", tabName)
        state := { key: defaultKey, txt: btnText, interfaceBg: bgBtn, listening: false, cb: callback }
        state.DefineProp("Value", {
            get: (s) => s.key,
            set: (s, v) => (s.key := v, s.txt.Value := StrUpper(v))
        })
        
        handler(*) => StartListening()
        bgBtn.OnEvent("Click", handler)
        btnText.OnEvent("Click", handler)

        StartListening(*) {
            Rest.notify("Listening (ESC to unbind)", 2000)
            state.listening := true
            state.txt.Value := "..."
            state.interfaceBg.Opt("Background" danger)
            state.txt.Opt("c" interfaceBg)
            
            ih := InputHook("T5")
            ih.KeyOpt("{All}", "E")
            

            mouseHandler(btn, *) {
                if !state.listening
                    return
                state.key := btn
                ih.Stop()
            }

            global isListeningForBind := true
            global bindListenerCallback := mouseHandler

            ih.OnEnd := (ih) => (KeyFinished(ih), cleanup())
            
            cleanup() {
                global isListeningForBind := false
            }

            ih.Start()
        }
        KeyFinished(ih) {
            state.listening := false
            
            if (ih.EndReason = "EndKey") {
                if (ih.EndKey = "Escape") {
                    state.key := "None"
                } else {
                    state.key := ih.EndKey
                }
            } else if (ih.Input != "") {
                state.key := ih.Input
            }
            state.txt.Value := StrUpper(state.key)
            state.interfaceBg.Opt("Background" objectBg)
            state.txt.Opt("c" text)
            if state.cb 
                (state.cb)(state.key)
        }
        return state
    }

    static dropdown(guiObj, x, y, w, label, options, defaultVal := "", tabName := "", callback := "", hintMsg := "") {
        if (Type(hintMsg) = "String" && hintMsg != "") {
            guiObj.SetFont("s9 c" hintColor " Norm", font)
        } else {
            guiObj.SetFont("s9 c" text " Norm", font)
        }
        lbl := guiObj.Add("Text", "x" x " y" y " w" w " +BackgroundTrans", label)
        this.attachHint(guiObj, lbl, hintMsg)
        
        if (Type(hintMsg) = "String" && hintMsg != "" && InStr(hintMsg, "http")) {
            if RegExMatch(hintMsg, "https?://[^\s]+", &match) {
                lbl.Opt("+0x100")
                link := match[0]
                lbl.OnEvent("Click", (*) => Run(link))
            }
        }

        initialVal := defaultVal = "" ? options[1] : defaultVal

        guiObj.SetFont("s9 c" text " Norm", font)
        bgBtn := guiObj.Add("Text", "x" x " y" (y+20) " w" w " h25 Background" objectBg " +0x200 +0x100")
        valText := guiObj.Add("Text", "x" (x+5) " y" (y+20) " w" (w-25) " h25 +0x200 +BackgroundTrans", initialVal)
        arrow := guiObj.Add("Text", "x" (x+w-20) " y" (y+19) " w15 h25 Center +0x200 +BackgroundTrans", "⌄")

        this.register(lbl, (Type(hintMsg) = "String" && hintMsg != "" ? "hint" : "text"), tabName)
        this.register(bgBtn, "control", tabName)
        this.register(valText, "text", tabName)
        this.register(arrow, "text", tabName)

        state := { val: initialVal, isOpen: false, gui: 0 }
        optCtrls := []
        
        openDropdown(*) {
            if (state.isOpen) {
                closeDropdown()
                return
            }
            Rest.closeAllDropdowns()
            state.isOpen := true
            Rest.openDropdowns.Push(state)
            
            bgBtn.Opt("Background" accent)
            valText.Opt("c" interfaceBg)
            arrow.Opt("c" interfaceBg)
            bgBtn.Redraw()
            valText.Redraw()
            arrow.Redraw()

            state.gui := Gui("+AlwaysOnTop -Caption +ToolWindow")
            state.gui.BackColor := objectBg
            state.gui.MarginX := 0
            state.gui.MarginY := 0
            state.gui.SetFont("s9 c" text " Norm", font)

            WinGetPos(&wx, &wy,,, guiObj.Hwnd)
            ControlGetPos(&cx, &cy, &cw, &ch, bgBtn.Hwnd)
            sx := wx + cx
            sy := wy + cy + ch
            cw := cw + 1

            optCtrls.Length := 0
            for idx, opt in options {
                optBg := state.gui.Add("Text", "x0 y" ((idx-1)*25) " w" cw " h25 Background" objectBg " +0x200 +0x100")
                optTxt := state.gui.Add("Text", "x5 y" ((idx-1)*25) " w" (cw-10) " h25 +0x200 +BackgroundTrans c" (opt = state.val ? accent : text), opt)
                optCtrls.Push({interfaceBg: optBg, txt: optTxt, val: opt})
                optBg.OnEvent("Click", selectOption.Bind(opt))
                optTxt.OnEvent("Click", selectOption.Bind(opt))
            }
            
            state.gui.Show("x" sx " y" sy " w" cw " h" (options.Length * 25) " NoActivate")
            
            SetTimer(checkClickOff, 20)
        }

        lastHoverIdx := 0
        checkClickOff() {
            if !state.isOpen {
                SetTimer(checkClickOff, 0)
                return
            }
            
            MouseGetPos(,, &hoverWin, &hoverCtrl, 2)
            currHoverIdx := 0
            if (state.gui && hoverWin = state.gui.Hwnd) {
                for idx, item in optCtrls {
                    if (hoverCtrl = item.interfaceBg.Hwnd || hoverCtrl = item.txt.Hwnd) {
                        currHoverIdx := idx
                        break
                    }
                }
            }
            
            if (currHoverIdx != lastHoverIdx) {
                if (lastHoverIdx > 0 && lastHoverIdx <= optCtrls.Length) {
                    optCtrls[lastHoverIdx].interfaceBg.Opt("Background" objectBg)
                    optCtrls[lastHoverIdx].interfaceBg.Redraw()
                }
                if (currHoverIdx > 0 && currHoverIdx <= optCtrls.Length) {
                    optCtrls[currHoverIdx].interfaceBg.Opt("Background" groupBg)
                    optCtrls[currHoverIdx].interfaceBg.Redraw()
                }
                lastHoverIdx := currHoverIdx
            }

            if GetKeyState("LButton", "P") || GetKeyState("RButton", "P") {
                MouseGetPos(,, &clickWin, &clickCtrl, 2)
                if (state.gui && clickWin != state.gui.Hwnd && clickCtrl != bgBtn.Hwnd && clickCtrl != valText.Hwnd && clickCtrl != arrow.Hwnd) {
                    closeDropdown()
                    return
                }
            }
            
            if (!bgBtn.Visible || !DllCall("IsWindowVisible", "Ptr", guiObj.Hwnd)) {
                closeDropdown()
                return
            }
        }

        selectOption(val, *) {
            state.val := val
            valText.Value := val
            closeDropdown()
            if callback
                callback(val)
        }

        closeDropdown(*) {
            state.isOpen := false
            if (state.gui) {
                state.gui.Destroy()
                state.gui := 0
            }
            try {
                bgBtn.Opt("Background" objectBg)
                valText.Opt("c" text)
                arrow.Opt("c" text)
                bgBtn.Redraw()
                valText.Redraw()
                arrow.Redraw()
            } catch {
            }
            for i, s in Rest.openDropdowns {
                if (s == state) {
                    Rest.openDropdowns.RemoveAt(i)
                    break
                }
            }
        }
        
        state.closeDropdown := closeDropdown

        bgBtn.OnEvent("Click", openDropdown)
        valText.OnEvent("Click", openDropdown)
        arrow.OnEvent("Click", openDropdown)

        return state
    }

    static closeAllDropdowns() {
        while this.openDropdowns.Length {
            dropdown := this.openDropdowns.RemoveAt(1)
            try dropdown.closeDropdown()
        }
    }

    static edit(guiObj, x, y, w, label, defaultText := "", tabName := "", callback := "", hintMsg := "", allowed := "0-9,") {
        if (Type(hintMsg) = "String" && hintMsg != "") {
            guiObj.SetFont("s9 c" hintColor " Norm", font)
        } else {
            guiObj.SetFont("s9 c" text " Norm", font)
        }
        lbl := guiObj.Add("Text", "x" x " y" y " w" w " +BackgroundTrans", label)
        this.attachHint(guiObj, lbl, hintMsg)
        
        if (Type(hintMsg) = "String" && hintMsg != "" && InStr(hintMsg, "http")) {
            if RegExMatch(hintMsg, "https?://[^\s]+", &match) {
                lbl.Opt("+0x100")
                link := match[0]
                lbl.OnEvent("Click", (*) => Run(link))
            }
        }

        ed := guiObj.Add("Edit", "x" x " y" (y+22) " w" w " h20 Background" objectBg " c" text " -E0x200", defaultText)
        this.register(lbl, (Type(hintMsg) = "String" && hintMsg != "" ? "hint" : "text"), tabName), this.register(ed, "control", tabName)
        
        onChange(ctrl, *) {
            currVal := ctrl.Value
            if (allowed != "") {
                newVal := RegExReplace(currVal, "[^" . allowed . "]", "")
                if (newVal != currVal) {
                    ctrl.Value := newVal
                    SendMessage(0x00B1, -1, -1, ctrl.Hwnd)
                }
            }
            if callback
                callback(ctrl.Value)
        }
        ed.OnEvent("Change", onChange)
        return ed
    }

    static button(guiObj, x, y, w, h, label, tabName := "", callback := "") {
        guiObj.SetFont("s9 c" interfaceBg " Bold", font)
        btn := guiObj.Add("Text", "x" x " y" y " w" w " h" h " Center +0x200 +0x100 Background" accent, label)
        this.register(btn, "accent", tabName)
        if callback
            btn.OnEvent("Click", (*) => callback())
        return btn
    }

    static text(guiObj, x, y, content, tabName := "") {
        guiObj.SetFont("s9 c" text " Norm", font)
        t := guiObj.Add("Text", "x" x " y" y " +BackgroundTrans", content)
        this.register(t, "text", tabName)
        return t
    }

    ; hints like done like this arent used anymore but ill keep it here as extra

    static hint(guiObj, x, y, message, tabName := "") {
        guiObj.SetFont("s9 c" hintColor " Norm Italic", font)
        h := guiObj.Add("Text", "x" x " y" y " +BackgroundTrans +0x100", "(?)")
        this.register(h, "hint", tabName)
        
        this.attachHint(guiObj, h, message)
        
        if (Type(message) = "String" && message != "" && InStr(message, "http")) {
            if RegExMatch(message, "https?://[^\s]+", &match) {
                link := match[0]
                h.OnEvent("Click", (*) => Run(link))
            }
        }
        return h
    }

    static modal(title, message, options := "") {
        options := IsObject(options) ? options : {}
        inst := { result: "No", gui: Gui("+AlwaysOnTop -Caption +ToolWindow") }
        inst.gui.BackColor := interfaceBg
        
        inst.gui.SetFont("s9 c" text " Norm", font)
        dummy := inst.gui.Add("Text", "x10 y60 w280 +Hidden", message)
        dummy.GetPos(,,,&h)
        btnY := Max(115, 60 + h + 15)
        totalH := btnY + 60
        
        if (this.gradientsEnabled) {
            res := this.gradientRes
            gradH := Min(totalH, 60)
            r1 := Integer("0x" SubStr(interfaceGrad, 1, 2)), g1 := Integer("0x" SubStr(interfaceGrad, 3, 2)), b1 := Integer("0x" SubStr(interfaceGrad, 5, 2))
            r2 := Integer("0x" SubStr(interfaceBg, 1, 2)), g2 := Integer("0x" SubStr(interfaceBg, 3, 2)), b2 := Integer("0x" SubStr(interfaceBg, 5, 2))
            steps := Floor(gradH / res)
            Loop steps {
                perc := (steps > 1) ? (A_Index - 1) / (steps - 1) : 0
                r := Round(r1 + (r2 - r1) * perc), g := Round(g1 + (g2 - g1) * perc), b := Round(b1 + (b2 - b1) * perc)
                color := Format("{1:02X}{2:02X}{3:02X}", r, g, b)
                inst.gui.Add("Text", "x0 y" ((A_Index - 1) * res) " w300 h" res " Background" color " +Disabled")
            }
        }
        
        inst.gui.SetFont("s16 c" text " Bold", font)
        inst.gui.Add("Text", "Center x0 y25 w300 +BackgroundTrans", title)
        inst.gui.SetFont("s9 c" text " Norm", font)
        inst.gui.Add("Text", "Center x10 y60 w280 +BackgroundTrans", message)
        
        inst.gui.SetFont("s10 c" text " Bold", font)
        if options.HasProp("onlyOk") && options.onlyOk {
            btnYes := inst.gui.Add("Text", "x100 y" btnY " w100 h35 Center +0x200 Background" objectBg, options.HasProp("okText") ? options.okText : "Ok")
            btnYes.OnEvent("Click", (*) => (inst.result := "Yes", inst.gui.Destroy()))
        } else {
            btnYes := inst.gui.Add("Text", "x40 y" btnY " w100 h35 Center +0x200 Background" objectBg, options.HasProp("yesText") ? options.yesText : "Yes")
            btnNo := inst.gui.Add("Text", "x160 y" btnY " w100 h35 Center +0x200 Background" objectBg, options.HasProp("noText") ? options.noText : "No")
            btnYes.OnEvent("Click", (*) => (inst.result := "Yes", inst.gui.Destroy()))
            btnNo.OnEvent("Click", (*) => (inst.result := "No", inst.gui.Destroy()))
        }
        DragHandler(wp, lp, msg, hwnd) => (hwnd = inst.gui.Hwnd ? PostMessage(0xA1, 2,,, "A") : "")
        OnMessage(0x0201, DragHandler)
        hwnd := inst.gui.Hwnd
        inst.gui.Show("w300 h" totalH)
        while WinExist(hwnd) {
            Sleep(50)
        }
        OnMessage(0x0201, DragHandler, 0)
        return inst.result
    }

    static bannedGameDetection() {
        static bannedGui := 0
        static gameDetectionList := ["FortniteClient-Win64-Shipping.exe", "RainbowSix.exe", "RainbowSix_Vulkan.exe", "RainbowSix_BE.exe", "cs2.exe", "csgo.exe", "Overwatch.exe"]
        if !settings.interfaceGameDetection
            return
        if bannedGui
            return

        detected := ""
        for game in gameDetectionList {
            if ProcessExist(game) {
                detected := game
                break
            }
        }

        if detected {
            try ProcessClose(detected)
            
            bannedGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
            bannedGui.BackColor := danger
            
            bannedGui.SetFont("s80 c" text " Bold", font)
            bannedGui.Add("Text", "Center x0 y120 w1280", "REST")

            bannedGui.SetFont("s48 c" text " Bold", font)
            bannedGui.Add("Text", "Center x0 y260 w1280", "PROHIBITED GAME DETECTED")
            
            bannedGui.SetFont("s12 c" text " Bold", font)
            explanation := "'" . detected . "' WAS TERMINATED. Rest HAS PREVENTED POTENTIAL PUNISHMENT IN THIS GAME."
            bannedGui.Add("Text", "Center x100 y340 w1080", explanation)
            
            bannedGui.SetFont("s18 c" danger " Bold", font)

            btnExit := bannedGui.Add("Text", "x540 y540 w200 h80 Center +0x200 +0x100 Background" text, "EXIT")
            btnExit.OnEvent("Click", (*) => ExitApp())
            
            restInterface.Hide()
            bannedGui.Show("w1280 h720")
        }
    }

    static handleClick(notification) {
        for index, item in this.queue {
            if (item = notification) {
                this.remove(index)
                break
            }
        }
    }

    static remove(index) {
        if (index < 1 || index > this.queue.Length) {
            return
        }
        try {
            this.queue[index].window.Destroy()
        } catch {
        }
        this.queue.RemoveAt(index), currentY := 20
        for i, item in this.queue {
            item.window.Show("x" (A_ScreenWidth - 370) " y" currentY " NoActivate")
            currentY += item.height + 5
        }
        if (!this.queue.Length) {
            SetTimer(() => this.tick(), 0)
        }
    }

    static tick() {
        if (!this.queue.Length) {
            SetTimer(, 0)
            return
        }
        current := this.queue[1]
        if (!current.startedAt) {
            current.startedAt := A_TickCount
        }
        timePassed := A_TickCount - current.startedAt
        remainingPercent := 100 - (timePassed / current.lifetime * 100)
        if (timePassed >= current.lifetime) {
            this.remove(1)
        } else {
            try {
                if (remainingPercent < 30) {
                    current.bar.Opt("+c" danger)
                }
                current.bar.Value := remainingPercent
            } catch {
            }
        }
    }
}

