class KeyEventManager extends EventEmitter
    @stack = []
    @instances = []
    @disable = ()->
        @isActive = true
    @enable = ()->
        @isActive = false
    @isActive = true
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
            console.warn "already mastered"
            console.trace()
            return
        @active()
        if KeyEventManager.current
            KeyEventManager.current.deactive()
            KeyEventManager.stack.push KeyEventManager.current
        KeyEventManager.current = this
    unmaster:()->
        if KeyEventManager.current isnt this
            console.warn "current KeyEventManager are not in master"
            console.trace()
            return false
        
        @deactive()
        prev = null
        if KeyEventManager.stack.length > 0
            prev = KeyEventManager.stack.pop()
            prev.active()
        KeyEventManager.current = prev
        return true
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
Leaf.KeyEventManager = KeyEventManager
Leaf.Key = Key
Leaf.Mouse = Mouse