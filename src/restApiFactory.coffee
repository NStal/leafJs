class RestApiFactory
    @Error = {
        NetworkError:"NetworkError"
        ,ServerError:"ServerError"
        ,InvalidDataType:"InvalidDataType"
    }
    constructor:()->
        @stateField = "state"
        @dataField = "data"
        @errorField = "error"
        @defaultMethod = "GET"
    prefix:(prefix)->
        @_prefix = prefix or ""
    suffix:(suffix)->
        @_suffix = suffix or ""
    reset:()->
        @_prefix
    create:(option = {})->
        method = option.method or @defaultMethod or "GET"
        _url = option.url
        if not _url
            throw new Error "API require en URL"
        reg = /:[a-z][a-z0-9]*/ig
        # remove : of param name
        routeParams = (_url.match(reg) or []).map (item)->item.substring(1)
        return (data,callback = ()->true )=>
            url = _url
            for prop of data
                if prop in routeParams
                    url = url.replace(new RegExp(":"+prop,"g"),encodeURIComponent(data[prop]))
                    delete data[prop]
            reqOption = {
                url:url
                ,method:method
                ,data:data
                ,option:option.option
            }
            xhr = @request reqOption,callback
            return xhr
    parse:(err,data = {},callback = ()-> true)->
        if err
            callback err
            return
        if data.state
            callback null,data.data
            return
        else
            callback data.error or RestApiFactory.Error.ServerError
            return
    request:(option,callback)->
        method = option.method || "GET";
        if method.toLowerCase() is "get"
            url = option.url + "?" + @_encodeDataPayload(option.data)
        else
            url = option.url
        xhr = new XMLHttpRequest()
        xhr.open(method,url,true)
        xhr.setRequestHeader("Content-Type","application/x-www-form-urlencoded")
        #xhr.responseType = option.dataType or "json"
        done = false
        _callback = callback
        callback = (err,response)=>
            (option.parser or @parse)(err,response,_callback)
        xhr.onreadystatechange = ()=>
            if xhr.readyState is 0 and not done
                callback RestApiFactory.Error.NetworkError,null
                return
            if xhr.readyState is 4
                done = true
                if xhr.responseText
                    try
                        data = JSON.parse(xhr.responseText)
                    catch e
                        callback RestApiFactory.Error.InvalidDataType,xhr.responseText
                        return
                    callback null,data
                else
                    callback RestApiFactory.Error.InvalidDataType
        if method.toLowerCase() isnt "get"
            xhr.send(@_encodeDataPayload(option.data))
        else
            xhr.send()
        return xhr
    _encodeDataPayload:(data = {})->
        result = []
        for prop of data
            kv = [prop,encodeURIComponent(data[prop])].join("=")
            result.push kv
        return result.join("&")
                    
exports.RestApiFactory = RestApiFactory
