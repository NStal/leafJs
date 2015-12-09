Errors = Leaf.ErrorDoc.create()
    .define("NetworkError")
    .define("ServerError")
    .define("InvalidResponseType")
    .define("Timeout")
    .generate()
class RestApiFactory
    @Errors = Errors
    constructor:()->
        @stateField = "state"
        @dataField = "data"
        @errorField = "error"
        @defaultMethod = "GET"
        @defaultTimeout = 0
    prefix:(prefix)->
        @_prefix = prefix or ""
    suffix:(suffix)->
        @_suffix = suffix or ""
    reset:()->
        @_prefix
    create:(option = {})->
        method = option.method or @defaultMethod or "GET"
        _url = @_prefix + option.url
        if not _url
            throw new Error "API require en URL"
        reg = /:[a-z_][a-z0-9_]*/ig
        # remove : of param name
        routeParams = (_url.match(reg) or []).map (item)->item.substring(1)
        fn = (data,callback = (()->true),config = {})=>
            if option.data
                for prop of option.data
                    if typeof data[prop] is "undefined"
                        data[prop] = option.data[prop]
            url = _url
            for prop of data
                if prop in routeParams
                    url = url.replace(new RegExp(":"+prop,"g"),@escapeRouteParam(data[prop]))
                    delete data[prop]
            reqOption = {
                url:url
                ,method:method
                ,data:data
                ,option:option.option
                ,timeout:option.timeout or config.timeout or @defaultTimeout or 0
            }
            xhr = @request reqOption,callback
            return xhr
    escapeRouteParam:(data)->
        return encodeURIComponent data
    parse:(err,data = {},callback = ()-> true)->
        if err
            callback err
            return
        if data.state
            callback null,data.data
            return
        else
            callback data.error or new Errors.ServerError("server return state false but not return any error information",{raw:data})
            return
    request:(option = {},callback)->
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
        timer = null
        callback = (err,response)=>
            clearTimeout timer
            # disable multiple callback
            callback = ->
            (option.parser or @parse)(err,response,_callback)
        if option.timeout
            timer = setTimeout ()->
                callback = ->
                _callback(new Errors.Timeout("Request timeout after #{option.timeout} sec"),{timeout:option.timeout})
                xhr.abort()
            ,option.timeout * 1000
        xhr.onreadystatechange = ()=>
            if xhr.readyState is 0 and not done
                callback new Errors.NetworkError(),null
                return
            if xhr.readyState is 4
                done = true
                if xhr.responseText
                    try
                        data = JSON.parse(xhr.responseText)
                    catch e
                        callback new Errors.NetworkError "Broken response",{via:new Errors.InvalidResponseType("fail to parse server data",{raw:xhr.responseText})},xhr.responseText
                        return
                    callback null,data
                else
                    callback new Errors.NetworkError "Empty response",{via:Errors.InvalidResponseType("Server return empty response")}
        if method.toLowerCase() isnt "get"
            xhr.send(@_encodeDataPayload(option.data))
        else
            xhr.send()
        return xhr
    _encodeDataPayload:(data = {})->
        return @querify data
    querify:(data)->
        encode = encodeURIComponent
        isolate = (data)->
            if typeof data is "string"
                return [encode data]
            else if typeof data is "number"
                return [encode data]
            else if typeof data instanceof Date
                return data.toString()
            else if not data
                return []
            result = []
            if data instanceof Array
                for item,index in data
                    result.push [index].concat isolate item
                return result
            for prop of data
                part = isolate data[prop]
                for item in part
                    result.push [encode prop].concat item
            return result
        results = isolate data
        querys = []
        for item in results
            if item.length < 2
                continue
            value = item.pop()
            base = item.shift()
            keys = item.map (key)-> "[#{key}]"
            querys.push base + keys.join("") + "=" + value
        return querys.join "&"



exports.RestApiFactory = RestApiFactory
