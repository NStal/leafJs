Leaf = window.Leaf 
do (Leaf)->
    class ApiFactory extends Leaf.EventEmitter
        constructor:(apis)->
            @apis = {}
            @path = "api/"
            @suffix = ""
            @defaultMethod = "GET"
            @acceptStatus = [200]
            @infos = []
            #pass
        declare:(name,params,option={})-> 
            console.assert typeof name is "string"
            url = option.url or "#{@path}#{name}#{@suffix}"
            method = option.method or @defaultMethod
            params = params instanceof Array and params  or []
            info = {name:name,url:url,method:method,params:params}
            @infos.push info
            return this
        build:()->
            api = {}
            for info in @infos
                api[info.name] = new Api(info).toFunction()
            return api
    class Api
        constructor:(info)->
            @info = info
            @declares = @buildDeclares()
            @method = @info.method.toUpperCase()
            @name = @info.name
            @url = @info.url
        buildDeclares:()->
            declares = []
            for param in @info.params
                paramInfo = param.split(":").filter (value)->value
                paramName = paramInfo[0]
                shouldBe = paramInfo[1] or "string"
                declare = {name:paramName,optional:false}
                if shouldBe.lastIndexOf("?") is (shouldBe.length-1)
                    declare.optional = true
                shouldBe = shouldBe.replace(/\?/g,"")
                if shouldBe is "string"
                    declare.format = "string"
                else if shouldBe is "number"
                    declare.format = "number"
                else if shouldBe.length is 0
                    declare.format = "string"
                else
                    throw new Error "Unknow Format Declaration In API #{@info.name}:#{shouldBe}"
                declares.push declare
            return declares
        checkParam:(value,declare)->
            if typeof value isnt "number" and not value
                if declare.optional
                    return ""
                else
                    throw new Error "API:#{@info.name}'s parameter:#{declare.name} is required but given:#{value}"
            if typeof value is "number" and isNaN value
                throw new Error "API #{@info.name} parameter:#{declare.name} recieve an NaN"
            if typeof value is declare.format
                return value
            if typeof value is "number" and declare.format is "string"
                console.warn "change param#{declare.name} of API #{@info.name} from number to string"
                return value.toString()
            if typeof value is "string" and declare is "number"
                number = parseFloat(value)
                if isNaN(number)
                    throw new Error "API #{@info.name} parameter:#{declare.name} require an number but given an string"
                else
                    console.warn "change param#{declare.name} of API #{@info.name} from string to number"
                    return value        
        checkParams:(params)->
            if params.length is 1 and typeof params[0] is "object"
                for declare in @declares
                    params[declare.name] = encodeURIComponent(@checkParam(params[declare.name],declare))
                return params
            else
                _result = {}
                for declare,index in @declares
                    _result[declare.name] = @checkParam(params[index],declare)
                return _result
        buildRequest:(paramsDict)->
            queryArray = []
            for key of paramsDict
                queryArray.push [key,paramsDict[key]].join("=")
            query = queryArray.join("&")
            URI = ""
            body = ""
            if @method in ["GET","DELETE","PUT"]
                URI = "#{@url}?#{query}"
            else if @method is "POST"
                URI = @url
                body = query
            else
                console.warn "Unknow Method #{@method},build as if it is GET"

            return {URI:URI,body:body,context:new ApiContext(),method:@method}
        invoke:(params...)->
            params = @checkParams(params)
            requestInfo = @buildRequest(params)
            return new Request(requestInfo).context
        toFunction:()->
            return @invoke.bind(this)
    class Request extends Leaf.EventEmitter
        constructor:(info)->
            @URI = info.URI
            @body = info.body
            @method = info.method
            @context = info.context
            @acceptStatus = [200,302]
            @xhr = new XMLHttpRequest()
            xhr = @xhr
            xhr.open(@method,@URI,true)
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded')
            xhr.send(@body) 
            xhr.onreadystatechange = (state)=>
                if xhr.readyState isnt 4
                    return
                if xhr.status not in @acceptStatus
                    @context._fail("Http Error",@createStatus())
                    return
                if xhr.getResponseHeader("content-type") is "text/json" or ApiFactory.forceJson
                    json = @json()
                    if json
                        if json.state is true
                            @context._success(json.data)
                        else if json.state is false
                            @context._fail(json.error,@createStatus())
                        @context._response(json)
                        
                        
                    else
                        @context._fail("Json Parse Error",@createStatus())
                else
                    @context._response @text()
                    return true
                        
        text:()->
            return @xhr.responseText
        json:()->
            try
                json = JSON.parse @xhr.responseText
            catch e
                return null
            return json
        createStatus:()->
            return {
                httpCode:@xhr.status,
                text:@text(),
                json:@json()
            }
                        
    class ApiContext
        constructor:()->
            @_response = ()->
            @_fail = ()->
            @_success = ()->
            @_time = -1
        response:(callback)->
            console.assert typeof callback is "function"
            @_response = callback
            return this
        fail:(callback)->
            console.assert typeof callback is "function"
            @_fail = callback
            return this
        success:(callback)->
            console.assert typeof callback is "function"
            @_success = callback
            return this
        timeout:(time)->
            console.assert typeof time is "number"
            @_time = time
            return this
    ApiFactory.forceJson = true
    Leaf.ApiFactory = ApiFactory
