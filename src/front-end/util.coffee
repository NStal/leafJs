((Leaf)->
    #An simple version of eventEmitter
    # only has on/emit or alias bind/trigger
    class EventEmitter
        constructor: () ->
            @events = {}
            #alias
            @trigger = @emit
            @bind = @on
        on: (event,callback,context)->
            handlers = @events[event] = @events[event] || []
            handler = 
                callback:callback
                option:{context:context}
            handlers.push handler
            return this
        emit: (event,params...)->
            if @events[event]
                for handler in @events[event]
                    handler.callback.apply(
                        handler.option and handler.option.context or @,
                        params)
                

    Util = {}
    # judge is template is an HTMLDOMElement
    # from:http://stackoverflow.com/questions/384286/javascript-isdom-how-do-you-check-if-a-javascript-object-is-a-dom-object
    Util.isHTMLElement = (template) ->
        if typeof HTMLElement is "object" and template instanceof HTMLElement or (template and typeof template is "object" and template.nodeType is 1 and typeof template.nodeName is"string" )
            return true
        return false
    Util.isHTMLNode = (o) ->
        return (typeof Node is "object" and o instanceof Node ) or o and typeof o is "object" and typeof o.nodeType is "number" and typeof o.nodeName is "string"
    Util.isMobile = ()->
        if navigator and navigator.userAgent
            return (navigator.userAgent.match(/Android/i) or navigator.userAgent.match(/webOS/i) or navigator.userAgent.match(/iPhone/i) or navigator.userAgent.match(/iPad/i) or navigator.userAgent.match(/iPod/i) or navigator.userAgent.match(/BlackBerry/i) or navigator.userAgent.match(/Windows Phone/i)) and true
        else
            return false 
    Util.getBrowserInfo = ()->
        N= navigator.appName
        ua= navigator.userAgent
        M= ua.match(/(opera|chrome|safari|firefox|msie)\/?\s*(\.?\d+(\.\d+)*)/i);
        tem= ua.match(/version\/([\.\d]+)/i)
        if M and tem isnt null
             M[2]= tem[1]
        M= `M ? [M[1],M[2]] : [N, navigator.appVersion, '-?']`
        return {name:M[0],version:M[1]}
    Util.browser = getBrowserInfo()
    Util.capitalize = (string)-> string.charAt(0).toUpperCase() + string.slice(1);
    class KeyEventManager extends EventEmitter
        constructor:(node)->
            super()
            KeyEventManager.instances.push this
            @isActive = false
            if node
                @attachTo node
        attachTo:(node)->
            @attachment = node
            $(@attachment).keydown (e)=>
                e.capture = ()->
                    @catchEvent = false
                    @preventDefault()
                    @stopImmediatePropagation()
                if @isActive and KeyEventManager.isActive
                    @emit "keydown",e
                    return e.catchEvent
                return e.catchEvent
            $(@attachment).keyup (e)=>
                e.capture = ()->
                    @catchEvent = false
                    @preventDefault()
                    @stopImmediatePropagation()
                if @isActive and KeyEventManager.isActive
                    @emit "keyup",e
                    return e.catchEvent
                return e.catchEvent
        active:()->
            @isActive = true
        deactive:()->
            @isActive = false
        master:()->
            if KeyEventManager.current is this
                console.error "already mastered"
                console.trace()
                return
            @active()
            if KeyEventManager.current
                KeyEventManager.current.deactive()
                KeyEventManager.stack.push KeyEventManager.current
            KeyEventManager.current = this
        unmaster:()->
            if KeyEventManager.current isnt this
                console.error "current input are not in master"
                console.trace()
                return
            
            @deactive()
            prev = null
            if KeyEventManager.stack.length > 0
                prev = KeyEventManager.stack.pop()
                prev.active()
            KeyEventManager.current = prev
    class Observable extends EventEmitter
        #  not implemented
        constructor:()->
            super()
        watch:(property,callback)->
            # using defineSetter to redefine the property
            # and call callbacks
    Util.clone = (x)-> 
        if x is null or x is undefined
            return x;
        if typeof x.clone is "function"
            return x.clone();
        if x.constructor == Array
            r = [];
            for item in x
                r.push Util.clone(item)
            return r; 
        return x;
    Util.compare = (x,y)->
        if x is y
            return true
        
        if x instanceof Array and y instanceof Array
            if x.length isnt y.length
                return false
            for item,index in x
                if not Util.compare item,y[index]
                    return false
            return true
        for p of y 
            if typeof x[p] is 'undefined' then return false; 
        for p of y 
            if y[p] 
                switch typeof y[p] 
                    when 'object'
                        if not Util.compare(y[p],x[p]) then return false
                    when 'function' 
                        if typeof x[p] is 'undefined' or (p isnt 'equals' and y[p].toString() isnt x[p].toString()) 
                            return false;
                    else
                        if y[p] isnt x[p] then return false
            else if x[p]
                return false; 
        for p in x
            if typeof(y[p]) is 'undefined' then return false
        return true
    
    KeyEventManager.instances = []
    KeyEventManager.stack = []
    KeyEventManager.disable = ()->
        @isActive = true
    KeyEventManager.enable = ()->
        @isActive = false
    KeyEventManager.isActive = true
    Key = {}
    Key["0"]=48;
    Key["1"]=49;
    Key["2"]=50;
    Key["3"]=51;
    Key["4"]=52;
    Key["5"]=53;
    Key["6"]=54;
    Key["7"]=55;
    Key["8"]=56;
    Key["9"]=57;
    if Util.browser
        if Util.browser.name is "firefox"
            Key.cmd = 224
        else if Util.browser.name is "opera"
            Key.cmd = 17
        else
            Key.cmd = 91
    Key.a=65;
    Key.b=66;
    Key.c=67;
    Key.d=68;
    Key.e=69;
    Key.f=70;
    Key.g=71;
    Key.h=72;
    Key.i=73;
    Key.j=74;
    Key.k=75;
    Key.l=76;
    Key.m=77;
    Key.n=78;
    Key.o=79;
    Key.p=80;
    Key.q=81;
    Key.r=82;
    Key.s=83;
    Key.t=84;
    Key.u=85;
    Key.v=86;
    Key.w=87;
    Key.x=88;
    Key.y=89;
    Key.z=90;
    Key.space = 32;
    Key.shift = 16;
    Key.ctrl = 17;
    Key.alt = 18;
    Key.left = 37;
    Key.up = 38;
    Key.right = 39;
    Key.down =40;
    Key.enter = 13;
    Key.backspace = 8;
    Key.escape = 27;
    Key.del = Key["delete"] = 46
    Key.esc = 27;
    Key.pageup = 33
    Key.pagedown = 34
    Key.tab = 9;
    Mouse = {}
    Mouse.left = 0
    Mouse.middle = 1
    Mouse.right = 2
    Util.Key = Key
    Leaf.Util = Util
    Leaf.Key = Key
    Leaf.Mouse = Mouse
    Leaf.EventEmitter = EventEmitter
    Leaf.Observable = Observable
    Leaf.KeyEventManager = KeyEventManager
)(this.Leaf)