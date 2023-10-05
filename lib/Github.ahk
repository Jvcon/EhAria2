;credit: https://github.com/TheArkive/JXON_ahk2
;credit: https://github.com/thqby/ahk2_lib

/*
    @source https://github.com/samfisherirl/Github.ahk-API-for-AHKv2
    @method Github.latest(Username,Repository_Name)

    return {
        downloadURLs: [
            "http://github.com/release.zip",
            "http://github.com/release.rar"
                    ],
        version: "",
        change_notes: "",
        date: "",
        }
        
    @method Github.historicReleases(Username,Repository_Name)
        array of objects => [{
            downloadURL: "",
            version: "",
            change_notes: "",
            date: ""
        }]
    @func this.Download(url,path)
        improves on download(): 
        - if user provides wrong extension, function will apply proper extension
        - allows user to provide directory 
        example:    Providing A_ScriptDir to Download will throw error
                    Providing A_ScriptDir to Github.Download() will supply Download() with release name 
*/
class Github
{
    static source_zip := ""
    static url := false
    static usernamePlusRepo := false
    static storage := {
        repo: "",
        source_zip: ""
    }
    static data := false

    static build(Username, Repository_Name) {
        Github.usernamePlusRepo := Trim(Username) "/" Trim(Repository_Name)
        Github.source_zip := "https://github.com/" Github.usernamePlusRepo "/archive/refs/heads/main.zip"
        return "https://api.github.com/repos/" Github.usernamePlusRepo "/releases"
        ;filedelete, "1.json"
        ;this.Filetype := data["assets"][1]["browser_download_url"]
    }
    /*
    return {
        downloadURLs: [
            "http://github.com/release.zip",
            "http://github.com/release.rar"
                    ],
        version: "",
        change_notes: "",
        date: "",
        }
    */
    static latest(Username, Repository_Name) {
        url := Github.build(Username, Repository_Name)
        data := Github.processRepo(url)
        return Github.latestProp(data)
    }
    /*
    static processRepo(url) {
        Github.source_zip := "https://github.com/" Github.usernamePlusRepo "/archive/refs/heads/main.zip"
        Github.data := Github.jsonDownload(url)
        data := Github.data
        return Jsons.Loads(&data)
    }
    */
    static processRepo(url) {
        Github.source_zip := "https://github.com/" Github.usernamePlusRepo "/archive/refs/heads/main.zip"
        data := Github.jsonDownload(url)
        return Jsons.Loads(&data)
    }
    /*
    @example
    repoArray := Github.historicReleases()
        repoArray[1].downloadURL => string | link
        repoArray[1].version => string | version data
        repoArray[1].change_notes => string | change notes
        repoArray[1].date => string | date of release
    
    @returns (array of release objects) => [{
        downloadURL: "",
        version: "",
        change_notes: "",
        date: ""
        }]
    */
    static historicReleases(Username, Repository_Name) {
        url := Github.build(Username, Repository_Name)
        data := Github.processRepo(url)
        repo_storage := []
        url := "https://api.github.com/repos/" Github.usernamePlusRepo "/releases"
        data := Github.jsonDownload(url)
        data := Jsons.Loads(&data)
        for release in data {
            for asset in release["assets"] {
                repo_storage.Push(Github.repoDistribution(release, asset))
            }
        }
        return repo_storage
    }
    static latestProp(data) {
        for i in data {
            baseData := i
            assetMap := i["assets"]
            date := i["created_at"]
            if i["assets"].Length > 0 {
                length := i["assets"].Length
                releaseArray := Github.distributeReleaseArray(length, assetMap)
                break
            }
            else {
                releaseArray := ["https://github.com/" Github.usernamePlusRepo "/archive/" i["tag_name"] ".zip"]
                ;source url = f"https://github.com/{repo_owner}/{repo_name}/archive/{release_tag}.zip"
                break
            }
        }
        ;move release array to first if
        ;then add source
        return {
            downloadURLs: releaseArray,
            version: baseData["tag_name"],
            change_notes: baseData["body"],
            date: date
        }
    }
    /*
    loop releaseURLCount {
        assetArray.Push(JsonData[A_Index]["browser_download_url"])
    }
    return => assetArray[]
    */
    /*
    loop releaseURLCount {
        assetMap.Set(jsonData[A_Index]["name"], jsonData[A_Index]["browser_download_url"])
    }
    return => assetMap()
    */
    static jsonDownload(URL) {
        Http := WinHttpRequest()
        Http.Open("GET", URL)
        Http.Send()
        Http.WaitForResponse()
        storage := Http.ResponseText
        return storage ;Set the "text" variable to the response
    }
    static distributeReleaseArray(releaseURLCount, Jdata) {
        assetArray := []
        if releaseURLCount {
            if (releaseURLCount > 1) {
                loop releaseURLCount {
                    assetArray.Push(Jdata[A_Index]["browser_download_url"])
                }
            }
            else {
                assetArray.Push(Jdata[1]["browser_download_url"])
            }
            return assetArray
        }
    }
    /*
    download the latest main.zip source zip
    */
    static Source(Username, Repository_Name, Pathlocal := A_ScriptDir) {
        url := Github.build(Username, Repository_Name)
        data := Github.processRepo(url)

        Github.Download(URL := Github.source_zip, PathLocal)
    }
    /*
    benefit over download() => handles users path, and applies appropriate extension. 
    IE: If user provides (Path:=A_ScriptDir "\download.zip") but extension is .7z, extension is modified for the user. 
    If user provides directory, name for file is applied from the path (download() will not).
    Download (
        @param URL to download
        @param Path where to save locally
    )
    */
    static Download(URL, PathLocal := A_ScriptDir) {
        releaseExtension := Github.downloadExtensionSplit(URL)
        pathWithExtension := Github.handleUserPath(PathLocal, releaseExtension)
        try {
            Download(URL, pathWithExtension)
        } catch as e {
            MsgBox(e.Message . "`nURL:`n" URL)
        }
    }
    static emptyRepoMap() {
        repo := {
            downloadURL: "",
            version: "",
            change_notes: "",
            date: "",
            name: ""
        }
        return repo
    }

    static repoDistribution(release, asset) {
        return {
            downloadURL: asset["browser_download_url"],
            version: release["tag_name"],
            change_notes: release["body"],
            date: asset["created_at"],
            name: asset["name"]
        }
    }
    static downloadExtensionSplit(DL) {
        Arrays := StrSplit(DL, ".")
        filetype := Trim(Arrays[Arrays.Length])
        return filetype
    }

    static handleUserPath(PathLocal, releaseExtension) {
        if InStr(PathLocal, "\") {
            pathParts := StrSplit(PathLocal, "\")
            FileName := pathParts[pathParts.Length]
        }
        else {
            FileName := PathLocal
            PathLocal := A_ScriptDir "\" FileName
            pathParts := StrSplit(PathLocal, "\")
        }
        if InStr(FileName, ".") {
            FileNameParts := StrSplit(FileName, ".")
            UserExtension := FileNameParts[FileNameParts.Length]
            if (releaseExtension != userExtension) {
                newName := ""
                for key, val in FileNameParts {
                    if (A_Index == FileNameParts.Length) {
                        break
                    }
                    newName .= val
                }
                newPath := ""
                for key, val in pathParts {
                    if (A_Index == pathParts.Length) {
                        break
                    }
                    newPath .= val
                }
                pathWithExtension := newPath newName "." releaseExtension
            }
            else {
                pathWithExtension := PathLocal
            }
        }
        else {
            pathWithExtension := PathLocal "." releaseExtension
        }
        return pathWithExtension
    }
}
;;;; AHK v2 - https://github.com/TheArkive/JXON_ahk2
;MIT License
;Copyright (c) 2021 TheArkive
;Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
;The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
;
; originally posted by user coco on AutoHotkey.com
; https://github.com/cocobelgica/AutoHotkey-JSON
class Jsons
{
    static Loads(&src, args*) {
        key := "", is_key := false
        stack := [tree := []]
        next := '"{[01234567890-tfn'
        pos := 0

        while ((ch := SubStr(src, ++pos, 1)) != "") {
            if InStr(" `t`n`r", ch)
                continue
            if !InStr(next, ch, true) {
                testArr := StrSplit(SubStr(src, 1, pos), "`n")

                ln := testArr.Length
                col := pos - InStr(src, "`n", , -(StrLen(src) - pos + 1))

                msg := Format("{}: line {} col {} (char {})"
                    , (next == "") ? ["Extra data", ch := SubStr(src, pos)][1]
                    : (next == "'") ? "Unterminated string starting at"
                        : (next == "\") ? "Invalid \escape"
                            : (next == ":") ? "Expecting ':' delimiter"
                                : (next == '"') ? "Expecting object key enclosed in double quotes"
                                    : (next == '"}') ? "Expecting object key enclosed in double quotes or object closing '}'"
                                        : (next == ",}") ? "Expecting ',' delimiter or object closing '}'"
                                            : (next == ",]") ? "Expecting ',' delimiter or array closing ']'"
                                                : ["Expecting JSON value(string, number, [true, false, null], object or array)"
                                                , ch := SubStr(src, pos, (SubStr(src, pos) ~= "[\]\},\s]|$") - 1)][1]
                                                , ln, col, pos)

                throw Error(msg, -1, ch)
            }

            obj := stack[1]
            is_array := (obj is Array)

            if i := InStr("{[", ch) { ; start new object / map?
                val := (i = 1) ? Map() : Array()    ; ahk v2

                is_array ? obj.Push(val) : obj[key] := val
                stack.InsertAt(1, val)

                next := '"' ((is_key := (ch == "{")) ? "}" : "{[]0123456789-tfn")
            } else if InStr("}]", ch) {
                stack.RemoveAt(1)
                next := (stack[1] == tree) ? "" : (stack[1] is Array) ? ",]" : ",}"
            } else if InStr(",:", ch) {
                is_key := (!is_array && ch == ",")
                next := is_key ? '"' : '"{[0123456789-tfn'
            } else { ; string | number | true | false | null
                if (ch == '"') { ; string
                    i := pos
                    while i := InStr(src, '"', , i + 1) {
                        val := StrReplace(SubStr(src, pos + 1, i - pos - 1), "\\", "\u005C")
                        if (SubStr(val, -1) != "\")
                            break
                    }
                    if !i ? (pos--, next := "'") : 0
                        continue

                    pos := i ; update pos

                    val := StrReplace(val, "\/", "/")
                    val := StrReplace(val, '\"', '"')
                        , val := StrReplace(val, "\b", "`b")
                        , val := StrReplace(val, "\f", "`f")
                        , val := StrReplace(val, "\n", "`n")
                        , val := StrReplace(val, "\r", "`r")
                        , val := StrReplace(val, "\t", "`t")

                    i := 0
                    while i := InStr(val, "\", , i + 1) {
                        if (SubStr(val, i + 1, 1) != "u") ? (pos -= StrLen(SubStr(val, i)), next := "\") : 0
                            continue 2

                        xxxx := Abs("0x" . SubStr(val, i + 2, 4)) ; \uXXXX - JSON unicode escape sequence
                        if (xxxx < 0x100)
                            val := SubStr(val, 1, i - 1) . Chr(xxxx) . SubStr(val, i + 6)
                    }

                    if is_key {
                        key := val, next := ":"
                        continue
                    }
                } else { ; number | true | false | null
                    val := SubStr(src, pos, i := RegExMatch(src, "[\]\},\s]|$", , pos) - pos)

                    if IsInteger(val)
                        val += 0
                    else if IsFloat(val)
                        val += 0
                    else if (val == "true" || val == "false")
                        val := (val == "true")
                    else if (val == "null")
                        val := ""
                    else if is_key {
                        pos--, next := "#"
                        continue
                    }

                    pos += i - 1
                }

                is_array ? obj.Push(val) : obj[key] := val
                next := obj == tree ? "" : is_array ? ",]" : ",}"
            }
        }
        return tree[1]
    }
    static Dump(obj, indent := "", lvl := 1) {
        if IsObject(obj) {
            ;if !obj.__Class = "Map" {
            ;    convertedObject := Map()
            ;    for k, v in obj.OwnProps() {
            ;        convertedObject.Set(k, v)
            ;    }
            ;    obj := convertedObject
            ;}
            ;If !(obj is Array || obj is Map || obj is String || obj is Number)
            ;    throw Error("Object type not supported.", -1, Format("<Object at 0x{:p}>", ObjPtr(obj)))

            if IsInteger(indent)
            {
                if (indent < 0)
                    throw Error("Indent parameter must be a postive integer.", -1, indent)
                spaces := indent, indent := ""

                Loop spaces ; ===> changed
                    indent .= " "
            }
            indt := ""

            Loop indent ? lvl : 0
                indt .= indent

            is_array := (obj is Array)

            lvl += 1, out := "" ; Make #Warn happy
            if (obj is Map || obj is Array) {
                for k, v in obj {
                    if IsObject(k) || (k == "")
                        throw Error("Invalid object key.", -1, k ? Format("<Object at 0x{:p}>", ObjPtr(obj)) : "<blank>")

                    if !is_array ;// key ; ObjGetCapacity([k], 1)
                        out .= (ObjGetCapacity([k]) ? Jsons.Dump(k) : escape_str(k)) (indent ? ": " : ":") ; token + padding

                    out .= Jsons.Dump(v, indent, lvl) ; value
                        . (indent ? ",`n" . indt : ",") ; token + indent
                }
            } else if IsObject(obj)
                for k, v in obj.OwnProps() {
                    if IsObject(k) || (k == "")
                        throw Error("Invalid object key.", -1, k ? Format("<Object at 0x{:p}>", ObjPtr(obj)) : "<blank>")
                    out .= (ObjGetCapacity([k]) ? Jsons.Dump(k) : escape_str(k)) (indent ? ": " : ":") ; token + padding
                    out .= Jsons.Dump(v, indent, lvl) ; value
                        . (indent ? ",`n" . indt : ",") ; token + indent
                }

            ;Error("Object type not supported.", -1, Format("<Object at 0x{:p}>", ObjPtr(obj)))

            if (out != "") {
                out := Trim(out, ",`n" . indent)
                if (indent != "")
                    out := "`n" . indt . out . "`n" . SubStr(indt, StrLen(indent) + 1)
            }

            return is_array ? "[" . out . "]" : "{" . out . "}"

        } Else If (obj is Number)
            return obj
        Else ; String
            return escape_str(obj)

        escape_str(obj) {
            obj := StrReplace(obj, "\", "\\")
            obj := StrReplace(obj, "`t", "\t")
            obj := StrReplace(obj, "`r", "\r")
            obj := StrReplace(obj, "`n", "\n")
            obj := StrReplace(obj, "`b", "\b")
            obj := StrReplace(obj, "`f", "\f")
            obj := StrReplace(obj, "/", "\/")
            obj := StrReplace(obj, '"', '\"')

            return '"' obj '"'
        }
    }
}