#An simple version of eventEmitter
class EventEmitter
    @mixin = (obj)->
        em = new EventEmitter()
        # Don't check overwrite.
        # You ask me to mixin and I'll do so.
        # Go blame your self.
        for prop of em
            obj[prop] = em[prop]
        return obj
    constructor: ()->
        @_events ?= {}
        @_bubbles ?= []
        #alias
#        @trigger ?= @emit
    addListener:(event,callback,context)->
        handlers = @_events[event] = @_events[event] || []
        handler =
            callback:callback
            context:context
        handlers.push handler
        return this
    on:()->
        @addListener.apply(this,arguments)
    removeListener:(event,listener)->
        handlers =  @_events[event]
        if not listener
            return
        if not handlers then return this
        for handler,index in handlers
            if handler.callback is listener
                handlers[index] = null
        @_events[event] = handlers.filter (item)->item
        return this
    removeAllListeners:(event)->
        if event
            @_events[event] = []
        else
            @_events = {}
        return this
    emit: (event,params...)->
        handlers = @_events[event]
        todos = []
        if handlers
            once = false
            for handler,index in handlers
                todos.push handler
                if handler.once
                    once = true
            if once
                @_events[event] = handlers.filter (item)->item.once isnt true
        for handler in todos
            handler.callback.apply(
                handler.context or @,
                params)
        return this
    once:(event,callback,context)->
        handlers = @_events[event] = @_events[event] || []
        handler =
            callback:callback
            context:context
            once:true
        handlers.push handler
        return this
    bubble:(emitter,event,processor)->
        listener = (args...)=>
            if processor
                args = processor.apply(this,args)
            else
                args.unshift event
            @emit.apply this,args
        emitter.on event,listener
        @_bubbles.push {emitter:emitter,event:event,listener:listener}
    stopBubble:(emitter,event)->
        @_bubbles = @_bubbles.filter (item)->
            if item.emitter is emitter
                # remove any event or the same event as user said
                if not event or item.event is event
                    item.emitter.removeListener item.event,item.listener
                    return false
            return true
        return this
    stopAllBubbles:()->
        for item in @_bubbles
            item.emitter.removeListener item.event,item.listener
        @_bubbles.length = 0
        return this
    listenBy:(who,event,callback,context)->
        @_events[event] = @_events[event] or []
        handlers = @_events[event]
        handler =
            callback:callback
            context:context or who
            owner:who
        handlers.push handler
        return this
    listenByOnce:(who,event,callback,context)->
        @_events[event] = @_events[event] or []
        handlers = @_events[event]
        handler =
            callback:callback
            context:context or who
            owner:who
            once:true
        handlers.push handler
        return this
    stopListenBy:(who)->
        for event of @_events
            handlers = @_events[event]
            if not handlers then continue
            for handler,index in handlers
                if handler.owner and handler.owner is who
                    handlers[index] = null
            @_events[event] = handlers.filter (item)->item
        return this
exports.EventEmitter = EventEmitter
