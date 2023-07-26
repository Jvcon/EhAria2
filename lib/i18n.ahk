/*
    i18n for AutoHotkey
    Version: 1.0.0
    Author: Maël Schweighardt (https://github.com/iammael/i18n-autohotkey)
    License: MIT (https://github.com/iammael/i18n-autohotkey/blob/master/LICENSE)
*/

Class i18n {
    __New(languageFolder, languageFile, devMode := False)
    {
        this.LanguageFolder := languageFolder
        this.LanguageFile := A_ScriptDir "\" languageFolder "\" languageFile ".ini"
        this.DevMode := DevMode
        If !FileExist(this.LanguageFile)
        {
            MsgBox "Couldn't load language file '" . this.LanguageFile . "'. Program aborted.", Error
            ExitApp -1
        }
    }
    ReplaceArgs(textToParse, var, index)
    {
        return StrReplace(textToParse, "{" . index . "}", var)
    }

    Translate(section, key, args*)
    {
        translatedText := this.GetValueFromIni(section, key, this.LanguageFile)
        ;Deal with error
        If (translatedText = "")
        {
            If this.DevMode {
                Loop {
                    If translatedText
                        break
                    transInput := InputBox("Input translate for '" key "':", "Translate", "w320 h240")
                    if (transInput.Value = "") {
                        result := MsgBox("File " this.LanguageFile " is missing string for key {" key "}.`nPress Ignore to continue anyway.", "Dev Mode", "18")
                        if (result = "Abort") {
                            ExitApp
                        }
                        else if (result := "Retry")
                        {

                            translatedText := this.GetValueFromIni(section, key, this.languageFile)
                        }
                        Else {
                            return "{" key "}"
                        }
                    }
                    else {
                        IniWrite(transInput.Value, this.LanguageFile, section, key)
                        translatedText := this.GetValueFromIni(section, key, this.LanguageFile)
                    }
                }
                if (translatedText = "") {
                    return "{" key "}"
                }
            }
        }
        ;check and replace args ({1}, {2}, ...)
        If (args.Length > 0) {
            Loop args.Length
                translatedText := this.ReplaceArgs(translatedText, args[A_Index], A_Index)
        }
        return translatedText
    }
    GetValueFromIni(section, key, languageFile)
    {
        readValue := IniRead(languageFile, section, key, A_Space)

        ; If !readValue
        ;     return readValue

        ; translatedText := readValue

        ; ;Check for multiline message (key2, key3 etc...)
        ; i := 2
        ; Loop {
        ;     readValue := IniRead(languageFile, section, key[i], A_Space)
        ;     If !readValue
        ;         return translatedText
        ;     Else
        ;         translatedText := translatedText . "`n" . readValue
        ;     i++
        ; }
        return readValue
    }
}