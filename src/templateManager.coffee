class TemplateManager extends Leaf.EventEmitter
    constructor: ()->
        super()
        @tids = [];
        @baseUrl = "template/"
        @templates = {}
        @suffix = ".html"
        @timeout = 10000 #default timeout
        @enableCache = false
        # Always add a random params to the request
        # thus disabled the backend history.
        # Since we are already capable of caching
        # template in frontend, backend cache are
        # more likely to cause problem.
        @randomQuery = true
        @cacheName = "templateManagerCache"
    use: (tids...) ->
        @tids.push.apply @tids,tids
    start:()->
        setTimeout @_start.bind(this),0
    clearCache:()->
        if window.localStorage
            window.localStorage.removeItem @cacheName
    _start:() ->
        if @enableCache
            caches = @_fromCacheAll()
            for tid in @tids
                @templates[tid] = caches[tid]
            if @_isRequirementComplete()
                @_ready()
                return this

        all = @_fromDomAll()
        for tid in @tids
            @templates[tid] = all[tid]
        if @_isRequirementComplete()
            @_ready()
            return this

        remain = @_getNotCompleteRequirements()
        remainTemplates = @_fromDomForEach(remain)
        for tid in remain
            @templates[tid] = remainTemplates[tid]
        if @_isRequirementComplete()
            @_ready()
            return this

        remain = @_getNotCompleteRequirements()
        @_fromXHRForEach remain,(err,tid,template)=>
            if err?
                @emit("error",err)
                return
            @templates[tid] = template
            if @_isRequirementComplete()
                @_ready()
    _ready:()->
        if @isReady
            return
        @isReady = true
        if @enableCache and window.localStorage
            window.localStorage.setItem @cacheName,JSON.stringify @templates
        @templates = @_extendNestedTemplates(@templates)
        @emit "ready",@templates
    _extendNestedTemplates:(templates)->
        result = {}
        for prop of templates
            pathes = prop.split("/")
            # also attatch the full path as a single property
            result[prop] = templates[prop]
            root = result
            for part,index in pathes
                if index is pathes.length - 1
                    # conflict with object
                    if typeof root[part] is "object"
                        root["root"] = templates[prop]
                    # conflict with other must be "string"
                    # just overwrite
                    else if root[part]
                        root[part] = templates[prop]
                    # not exists
                    else
                        root[part] = templates[prop]
                else
                    if typeof root[part] is "string"
                        value = root[part]
                        root[part] = {}
                        root[part].root = value
                    else if typeof root[part] is "object"
                        # do nothing
                        true
                    else
                        root[part] = {}
                root = root[part]
        return result

    _getNotCompleteRequirements:()->
        (tid for tid in @tids when !@templates[tid])
    _isRequirementComplete: ()->
        for tid in @tids
            if not @templates[tid]
                return false
        return true
    #return templatesJson or {} if not found
    _fromCacheAll:()->
        if not window.localStorage
            return {}
        info = window.localStorage.getItem(@cacheName)
        if not info
            return {}
        try
            templates = JSON.parse(info)
            return templates
        catch e
            return {}

    _fromDomAll:()->
        try
            return JSON.parse(document.querySelector("[data-json-templates]").innerHTML)
        catch e
            return {}
    #return templatesJson with member of tid that are found in DOM
    _fromDomForEach:(tids)->
        templates = {}
        for tid in tids
            templateNode = document.querySelector("[data-template-name='#{tid}']");
            templates[tid] = if templateNode then templateNode.innerHTML else undefined
        templates
    #callback err,tid,
    _fromXHRForEach:(tids,callback)->
        for tid in tids
            if tid.indexOf(".") >=1
                targetURI = @baseUrl+tid
            else
                targetURI = @baseUrl+tid+@suffix
            if @randomQuery and targetURI
                if targetURI.indexOf("?") >= 0
                    targetURI += "&r=#{Math.random()}"
                else
                    targetURI += "?r=#{Math.random()}"
            (()=>
                XHR = new XMLHttpRequest()
                XHR.open("GET",targetURI,true)
                XHR.send(null)
                XHR.tid = tid
                XHR.terminator = setTimeout(()=>
                    callback("timeout",XHR.tid,null)
                    XHR.done = true
                    XHR.abort()
                ,@timeout)
                XHR.onreadystatechange = ()->
                    if @done
                        return
                    if @readyState is 0
                        callback new Error "fail to load template"
                        return
                    if @readyState is 4
                        @done = true
                        if not @status or @status in [200,302,304]
                            callback(null,@tid,@responseText)
                        else
                            callback(@status,@tid,null)

            )()
        return null
exports.TemplateManager = TemplateManager
