((Leaf)-> 
    class ApiManager extends Leaf.EventEmitter
        constructor:(apis)->
            @apis = {}
            @path = "api/"
            @suffix = ""
            @defaultMethod = "GET"
            @acceptStatus = [200]
            #pass
        declare:(apis...)->
            if apis.length is 1 and typeof apis[0] is "string"
                this.initApiByText(apis[0])
            
            return this
        initApiByText:(apiDeclare)->
            component = @_extractApiComponent(apiDeclare)
            this[component.name] = @_createApiByComponent(component)
        _createApiByComponent:(component)->
            return (params...)=>
                params = params.map (value)->
                    if typeof value is "string"
                        return encodeURIComponent(value)
                    return value
                placeHoldersValue = []
                # check params
                # using arguments as placeholder?
                # in this situation arguments.length should equal placeHolders.length
                if params.length is component.placeHolders.length and ((typeof params[0] in ["undefined","number","string"]) or params[0] instanceof String)
                    placeHoldersValue = params
                # using first arguments as an JSON object
                # in this situation at least one place holder
                # should be found in json
                else if params.length is 1
                    hasValue = false
                    for placeHolder in component.placeHolders
                        if typeof params[0][placeHolder] isnt "undefined"
                            hasValue = true
                            placeHoldersValue.push(params[0][placeHolder].toString())
                        else
                            placeHoldersValue.push("")
                    if not hasValue
                        throw ("invalid Parameter Object sent:"+JSON.stringify(params[0]))
                # no arguments at all is OK
                # all place holder is ""
                else if params.length is 0
                    for placeHolder in component.placeHolders
                        placeHoldersValue.push("")
                else throw "invalid parameters #{params}"
                # apply place holder
                url= component.url
                body = component.body
                # not just using replace
                # to prevent recursive replacement
                lastIndex = 0
                while true
                    index = -1
                    holderIndex = -1
                    for placeHolder,i in component.placeHolders
                        _index = url.indexOf("{#{placeHolder}}",lastIndex)
                        if _index < index and _index >=0
                            index = _index
                            holderIndex = i
                        else if _index < 0 and index < 0
                            index = -1
                        else if _index < 0 and index >= 0
                            index = index
                        else if _index >=0 and index <0
                            index = _index
                            holderIndex = i
                    
                    if index<0 then break
                    url = url.substring(0,index)+placeHoldersValue[holderIndex]+url.substring(index+2+component.placeHolders[holderIndex].length)
                    lastIndex = index+placeHoldersValue[holderIndex].length
                lastIndex = 0
                while true
                    index = -1
                    holderIndex = -1
                    for placeHolder,i in component.placeHolders
                        _index = body.indexOf("{#{placeHolder}}",lastIndex)
                        if _index < index and _index >=0
                            index = _index
                            holderIndex = i
                        else if _index < 0 and index < 0
                            index = -1
                        else if _index < 0 and index >= 0
                            index = index
                        else if _index >=0 and index <0
                            index = _index
                            holderIndex = i
                    if index<0 then break
                    body = body.substring(0,index)+placeHoldersValue[holderIndex]+body.substring(index+2+component.placeHolders[holderIndex].length) 
                    lastIndex = index+placeHoldersValue[holderIndex].length
                lastIndex = 0
                callback = null
                xhr = new XMLHttpRequest
                promise = {
                    success:(callback)->
                        console.assert typeof callback is "function"
                        this._success = callback
                        return this
                    ,fail:(callback)->
                        console.assert typeof callback is "function"
                        this._fail = callback
                        return this
                    ,response:(callback)->
                        console.assert typeof callback is "function"
                        this._response = callback
                        return this
                    ,timeout:(count)->
                        console.assert typeof count is "number"
                        this._timeout = count
                        return this
                }
                xhr.onreadystatechange = (state)=>
                    if xhr.readyState == 4
                        if xhr.status not in @acceptStatus
                            if promise._fail
                                promise._fail({code:xhr.status},null)
                            if promise._response
                                promise._response({error:"Invalid Http Code",code:xhr.status},null)
                            return
                        if xhr.getResponseHeader("content-type") == "text/json" 
                            try
                                json = JSON.parse(xhr.responseText)
                            catch e
                                if promise._fail
                                    promise._fail("Broken Json",{responseText:xhr.responseText})
                                if promise._response
                                    promise._response(null,{error:"Broken Json",responseText:xhr.responseText})
                            json.responseText = xhr.responseText
                            if json.state
                                if promise._success
                                    promise._success(json.data)
                            else
                                if promise._fail
                                    promise._fail(json.error or "Unknown Error",json)
                             if promise._response
                                promise._response(null,json)
                        else
                            callback(null,xhr.responseText);
                xhr.open(component.method,url,true) 
                xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded')
                xhr.send(body)
                return promise
        _extractApiComponent:(apiDeclare)->
            regName = /^\w*/i
            regUrl = /@[\w:?&=\-+\.\/{}]+/i
            regMethod = /#[a-z]+/i
            regBody = /\$[\w:?&=\-+\.\/{}]+/i
            try
                name = regName.exec(apiDeclare)[0]
            catch e
                throw "Invalid API name"
            urlMatch = regUrl.exec(apiDeclare)
            url = if urlMatch then urlMatch[0].substring(1) else
                @path+name+@suffix
            methodMatch = regMethod.exec(apiDeclare)
            method = if methodMatch then methodMatch[0].substring(1) else @defaultMethod
            bodyMatch = regBody.exec(apiDeclare)
            body = if bodyMatch then bodyMatch[0].substring(1) else ""
            #extract place holder
            placeHolders = []
            for string in [url,body]
                flag = false
                flagPos = 0
                length = string.length
                for i in [0..length]
                    if string[i] is "{"
                        if flag is true
                            throw "invalid {} pair #{apiDeclare}"
                        flag = true
                        flagPos = i
                    if string[i] is "}"
                        if flag is false 
                            throw "invalid {} pair #{apiDeclare}"
                        flag = false
                        placeHolder = string.substring(flagPos+1,i)
                        if placeHolder not in placeHolders
                            placeHolders.push(placeHolder)
                if flag is true
                    throw "invalid {} pair #{apiDeclare}"
            return {
                name:name
                ,url:url
                ,method:method
                ,body:body
                ,placeHolders:placeHolders
                }
    Leaf.ApiManager = ApiManager
)(this.Leaf)