
class TemplateManager extends Leaf.EventEmitter
    constructor: ()->
        super()
        @tids = [];
        @baseUrl = "template/"
        @templates = {}
        @suffix = ".html"
        @timeout = 10000 #default timeout
        @enableCache = false
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
        @_fromXHRForEach(remain,
            (err,tid,template)=>
                if err?
                    @emit("error",err)
                    return 
                @templates[tid] = template
                if @_isRequirementComplete()
                    @_ready()
        )
    _ready:()->
        if @enableCache and window.localStorage
            window.localStorage.setItem @cacheName,JSON.stringify @templates
        @emit "ready",@templates
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
            return JSON.parse(document.getElementById("leaf-templates").innerHTML)
        catch e
            return {}
    #return templatesJson with member of tid that are found in DOM
    _fromDomForEach:(tids)->
        templates = {}
        for tid in tids
            templateNode = document.getElementById("leaf-templates-#{tid}");
            templates[tid] = if templateNode then templateNode.innerHTML else undefined
        templates
    #callback err,tid,
    _fromXHRForEach:(tids,callback)->
        for tid in tids
            if tid.indexOf(".") >=1
                targetURI = @baseUrl+tid
            else
                targetURI = @baseUrl+tid+@suffix
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