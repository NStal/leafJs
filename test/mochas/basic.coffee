describe "test basic",()->
    it "should have window.Leaf exported",(done)->
        if not window.Leaf
            throw new Error "window.Leaf not exported"
        done()
describe "test event emitter",()->
    it "test basic bind",(done)->
        et = new Leaf.EventEmitter()
        et.on "event",(param,param2)->
            if param isnt "foo" or param2 isnt "bar"
                throw new Error "should be able to emit params correctly"
            done()
        et.emit "event","foo","bar"
    it "test alias addListener",(done)->
        et = new Leaf.EventEmitter()
        et.addListener "event",(param,param2)->
            if param isnt "foo" or param2 isnt "bar"
                throw new Error "should be able to emit params correctly"
            done()
        et.emit "event","foo","bar"
    it "test once",(done)->
        et = new Leaf.EventEmitter()
        et.once "event",(param,param2)->
            if et._events.event.length > 0
                console.debug et._events
                throw new Error "once don't remove listener at callback"
            done()
        et.emit "event"
    it "test remove listener",(done)->
        et = new Leaf.EventEmitter()
        reachHere = false
        et.on "event",()->
            reachHere = true
        
        et.removeListener("event")
        et.emit "event"
        if not reachHere
            throw new Error "removeListener without a second parameter provide should have no effect"
        # we should safely reach here
        et.on "event2",()->false
        et.removeAllListeners("event2")
        if not et._events.event or et._events.event.length isnt 1
            throw new Error "removeAllListener with a event name provided should't effect other event's listeners "
        if et._events.event2 and et._events.event2.length isnt 0
            throw new Error "removeAllListener with a event name provided and matches should have effect"
        et.on "event",()->true
        et.removeAllListeners()
        if et._events.event and et._events.event.length > 0 or et._events.event2 and et._events.event2.length > 0
            console.log et._events
            throw new Error "removeAllListener without a event name should remove all listeners"

        done()

    it "bubble should work",(done)->
        parent = new Leaf.EventEmitter()
        child = new Leaf.EventEmitter()
        parent.bubble child,"click"
        parent.on "click",(event)->
            if not event or event.type isnt "click"
                throw new Error "bubble wrong data"
            done()
        child.emit "click",{type:"click"}
    it "stopBubble should work",(done)->
        parent = new Leaf.EventEmitter()
        child = new Leaf.EventEmitter()
        parent.bubble child,"click"
        parent.on "click",(event)->
            throw new Error "stop bubble should work!"
        parent.stopBubble(child)
        child.emit "click",{type:"click"}

        
        parent.removeAllListeners()
        parent.bubble child,"click" 
        reachHere = false
        parent.on "click",(data)->
            reachHere = true
        parent.stopBubble child,"notClick"
        child.emit "click"
        if not reachHere
            throw new Error "stopBubble with another event shouldn't have effect"

        reachHere = false
        parent.stopBubble child,"click"
        child.emit "click",{type:"click"}
        if reachHere
            throw new Error "stopBubble with correct child and event should have effect"
        done()
    it "stopAllBubbles should work",(done)->
        parent = new Leaf.EventEmitter()
        child = new Leaf.EventEmitter()
        parent.bubble child,"click"
        parent.on "click",(event)->
            throw new Error "stop bubble should work!"
        parent.stopAllBubbles()
        child.emit "click",{type:"click"}
        if parent._bubbles.length > 0
            throw new Error "stopAllBubbles should remove all bubbles"
        done()
        
    it "test listenBy",(done)->
        parent = {
            name:"parent"
            onClick:(event)->
                if @name isnt "parent"
                    throw new Error "invalid context set"
                @hasClick = true
            onTouch:(event)->
                if @name isnt "parent"
                    throw new Error "invalid context set"
                @hasTouch = true
        }
        child = new Leaf.EventEmitter
        child.listenBy parent,"onClick",parent.onClick
        child.listenBy parent,"onTouch",parent.onTouch
        if child._events.onClick.length isnt 1 or child._events.onTouch.length isnt 1
            throw new Error "listenBy should set _events"
        child.emit "onClick"
        child.emit "onTouch"
        if not parent.hasClick or not parent.hasTouch
            throw new Error "listenBy should trigger event listeners with the contexdt"
        child.stopListenBy parent
        if child._events.onClick and child._events.onClick.length isnt 0 or child._events.onTouch and child._events.onTouch.length isnt 0
            throw new Error "stopListenBy should remove all the listen by"
        done()
    it "test mixin",(done)->
        obj = {_events:{value:5}}
        Leaf.EventEmitter.mixin obj
        if not obj._events or not obj.on
            throw new Error "mixin not working"
        if obj._events.value is 5
            throw new Error "mixin should overwrite _events any way."
        done()

Util = Leaf.Util
describe "Util tests",()->
    it "HTML related",(done)->
        TextNode = document.createTextNode("abc")
        Div = document.createElement("div")
        if Util.isHTMLElement TextNode
            throw new Error "TextNode isnt html element"
        if not Util.isHTMLElement Div
            throw new Error "Div is html element"
        if not Util.isHTMLNode TextNode
            throw new Error "TextNode is html node"
        if not Util.isHTMLNode Div
            throw new Error "Div is html node"
        done()
    it "is mobile",(done)->
        done()
    it "string manipulation",(done)->
        camel = "camelCaseIsCodeFriendly"
        slug = "slug-is-readable"
        capitalCamel = Util.capitalize camel
        if camel[0].toUpperCase() isnt capitalCamel[0] or camel.substring(1) isnt capitalCamel.substring(1)
            throw new Error "capitalize failure"
        slugedCamel = Util.camelToSlug camel
        if slugedCamel isnt "camel-case-is-code-friendly"
            throw new Error "invalid camelToSlug"
        cameledSlug = Util.slugToCamel slug
        if cameledSlug isnt "slugIsReadable"
            throw new Error "invalid slugToCamel"
        done()
    it "clone",(done)->
        a = {
            array:[{value:0}]
            ,foo:null
            ,bar:{
                zero:0
                ,string:"abc"
                ,foo:null
            }
        }
        b = Util.clone(a)
        result = true
        
        result &&= b.array[0].value is 0
        result &&= b.array isnt a.array
        result &&= b.foo is null
        result &&= b.bar.zero is 0
        result &&= b.bar isnt a.bar
        result &&= b.bar.string is "abc"
        result &&= b.bar.foo is null
        if not result
            throw new Error "clone failed"
        done()
    it "compare",(done)->
        a = {
            array:[{value:0}]
            ,foo:null
            ,bar:{
                zero:0
                ,string:"abc"
                ,foo:null
            }
        }
        b = Util.clone a
        if not Util.compare a,b
            throw new Error "invalid compare"
        b.array[0].value = 1
        if Util.compare a,b
            throw new Error "fail to compare value in deep array"
        done()

describe "error doc",()->
    it "test Error doc",(done)->
        Errors = Leaf.ErrorDoc.create()
            .define("IOError")
            .define("LogicError")
            .define("NetworkError","IOError")
            .define("InvalidParameter","LogicError",{message:"You are so stupid to provide a valid parameters I guess",code:5})
            .define("NetworkTimeout","NetworkError")
            .generate()
        ioError = new Errors.IOError("message")
        invalidParameter = new Errors.InvalidParameter(null,{code:10})
        nto = new Errors.NetworkTimeout()
        if ioError.message isnt "message"
            throw new Error "bad message set"
        networkError = new Errors.NetworkError("message",{via:{name:"hehe"}})
        if networkError.via.name isnt "hehe"
            throw new Error "invalid meta set"
        if networkError not instanceof Errors.IOError
            throw new Error "fail to inherit errors"
        if invalidParameter instanceof Errors.IOError
            throw new Error "invalid parameter should be logic error"
        if invalidParameter.message isnt "You are so stupid to provide a valid parameters I guess"
            throw new Error "predefined meta no take effect"
        if invalidParameter.code isnt 10
            console.debug invalidParameter
            throw new Error "fail to overwrite predefined error props"
        if nto not instanceof Errors.IOError
            throw new Error "inherit twice not working"
        done()
