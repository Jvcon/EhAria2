#Include Jxon.ahk

class Aria2Rpc {
    /*
    * @param rpcAddress
    * @param rpcPort
    * @param rpcToken
    * @param this.setGlobalProxy
    */
    __New(id, rpcAddress := 'http://127.0.0.1', rpcPort := "6800", rpcToken := "") {
        this.rpcUrl := rpcAddress . ':' . rpcPort . '/jsonrpc'
        this.token := Format('token:{1}', rpcToken)
        this.jsonObj := Map()
        this.jsonObj["jsonrpc"] := "2.0"
        this.jsonObj["id"] := id
        this.paramsArr := Array()
        this.paramsArr.Push(this.token)
    }
    __Init(proxyUrl?, dir?, maxDownloadLimit?) {
        this.optGlobalObj := Map()
        this.optTaskObj := Map()
        if IsSet(proxyUrl) {
            this.optGlobalObj["all-proxy"] := proxyUrl
            this.optTaskObj["all-proxy"] := proxyUrl
        }
        if IsSet(dir) {
            this.optGlobalObj["dir"] := dir
            this.optTaskObj["dir"] := dir
        }
        if IsSet(maxDownloadLimit) {
            this.optGlobalObj["max-download-limit"] := maxDownloadLimit
        }
    }
    changeGlobalOption(proxyUrl?, dir?, maxDownloadLimit?) {
        json := this.jsonObj.Clone()
        params := this.paramsArr.Clone()
        optGlobalObj := this.optGlobalObj.Clone()
        json["method"] := "aria2.changeGlobalOption"
        ; all-proxy
        if (IsSet(proxyUrl) and (proxyUrl = "")) {
            optGlobalObj["all-proxy"] := ""
        }
        else if (IsSet(proxyUrl) and (proxyUrl != "")) {
            optGlobalObj["all-proxy"] := proxyUrl
        }
        else if(optGlobalObj.Has("all-proxy"))
        {
            optGlobalObj.Delete("all-proxy")
        }
        ; dir
        if (IsSet(dir) and (dir = "")) {
            optGlobalObj["dir"] := ""
        }
        else if (IsSet(dir) and (dir != "")) {
            optGlobalObj["dir"] := dir
        }
        else if(optGlobalObj.Has("dir"))
        {
            optGlobalObj.Delete("dir")
        }
        ; max-download-limit
        if (IsSet(maxDownloadLimit) and (maxDownloadLimit = "")) {
            optGlobalObj["max-download-limit"] := ""
        }
        else if (IsSet(maxDownloadLimit) and (maxDownloadLimit != "")) {
            optGlobalObj["max-download-limit"] := maxDownloadLimit
        }
        else if(optGlobalObj.Has("max-download-limit"))
        {
            optGlobalObj.Delete("max-download-limit")
        }
        params.Push(optGlobalObj)
        json["params"] := params
        data := Jxon_dump(json)
        respone := this.httpPost(this.rpcUrl, data)
        this.aria2ExecCallback(json["method"], respone)
        return
    }
    saveSession(*) {
        json := this.jsonObj.Clone()
        json["method"] := "aria2.saveSession"
        json["params"] := this.paramsArr
        data := Jxon_dump(json)
        respone := this.httpPost(this.rpcUrl, data)
        this.aria2ExecCallback(json["method"], respone)
        return
    }
    addTorrent(torrent := "", dir?, proxy := 0) {
        json := this.jsonObj.Clone()
        params := this.paramsArr.Clone()
        optTaskObj := this.optTaskObj.Clone()
        urisArr := Array()
        json["method"] := "aria2.addTorrent"
        RunWait A_ComSpec " /c certutil.exe -encode " . torrent . " temp.txt", , "Hide"
        torrentText := FileRead("temp.txt")
        torrentText := StrReplace(torrentText, "-----BEGIN CERTIFICATE-----", "")
        torrentText := StrReplace(torrentText, "-----END CERTIFICATE-----", "")
        torrentText := StrReplace(torrentText, "`n", "")
        params.Push(torrentText)
        if (proxy != 1) {
            optTaskObj["all-proxy"] := ""
        }
        if IsSet(dir) {
            optTaskObj["dir"] := dir
        }
        params.Push(urisArr)
        params.Push(optTaskObj)
        json["params"] := params
        data := Jxon_dump(json)
        respone := this.httpPost(this.rpcUrl, data)
        this.aria2ExecCallback(json["method"], respone)
        FileDelete "temp.txt"
        return
    }
    addUri(uri := "", dir?, proxy := 0) {
        json := this.jsonObj.Clone()
        params := this.paramsArr.Clone()
        optTaskObj := this.optTaskObj.Clone()
        urisArr := Array()
        json["method"] := "aria2.addUri"
        urisArr.Push(uri)
        if (proxy != 1) {
            optTaskObj["all-proxy"] := ""
        }
        if IsSet(dir) {
            optTaskObj["dir"] := dir
        }
        params.Push(urisArr)
        params.Push(optTaskObj)
        json["params"] := params
        data := Jxon_dump(json)
        respone := this.httpPost(this.rpcUrl, data)
        this.aria2ExecCallback(json["method"], respone)
        return
    }
    addMetalink(uri := "", dir := "", proxy := 0) {

        json := this.jsonObj.Clone()
        params := this.paramsArr.Clone()
        optTaskObj := this.optTaskObj.Clone()
        json["method"] := "aria2.addMetalink"
        params.Push(uri)
        if (proxy != 1) {
            optTaskObj["all-proxy"] := ""
        }
        if (dir != "") {
            optTaskObj["dir"] := dir
        }
        params.Push(optTaskObj)
        json["params"] := params
        data := Jxon_dump(json)
        respone := this.httpPost(this.rpcUrl, data)
        this.aria2ExecCallback(json["method"], respone)
        return
    }
    httpPost(URL, PData) {
        Static WebRequest := ComObject("WinHttp.WinHttpRequest.5.1")
        WebRequest.Open("POST", URL, True)
        WebRequest.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
        WebRequest.Send(PData)
        WebRequest.WaitForResponse()
        response := WebRequest.ResponseText
        return response ;Set the "text" variable to the response
    }
    httpGet(URL) {
        Static WebRequest := ComObject("WinHttp.WinHttpRequest.5.1")
        WebRequest.Open("GET", URL)
        WebRequest.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
        WebRequest.Send()
        WebRequest.WaitForResponse()
        response := WebRequest.ResponseText
        return response ;Set the "text" variable to the response
    }
    aria2ExecCallback(funcName, respone) {
        res := Jxon_Load(&respone)
        if (res.Has("error")) {
            MsgBox ('Method: ' . funcName . '`n'
                . 'Code: ' . res["error"]["code"] . '`n'
                . 'Message: ' . res["error"]["message"] . '`n'),
                "Aria2 RPC Error",
                "ok iconi"
        }
        return
    }
}