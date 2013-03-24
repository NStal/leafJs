((Leaf) ->
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
        
    Util.capitalize = (string)-> string.charAt(0).toUpperCase() + string.slice(1);
    class KeyEventManager extends EventEmitter
        constructor:()->
            super()
            KeyEventManager.instances.push this
            @isActive = false
            return
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
                    @emit "keydown",e
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
    Util.Key = Key
    Leaf.Util = Util
    Leaf.Key = Key 
    Leaf.EventEmitter = EventEmitter
    Leaf.KeyEventManager = KeyEventManager
)(this.Leaf)