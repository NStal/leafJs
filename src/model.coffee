class Model extends EventEmitter
    constructor:()->
        super()
        data = {}
        @__defineGetter__ "data",()=>
            return data
        @__defineSetter__ "data",(obj)=>
            @sets obj
        @_defines = {}
        @_idprop = null
    has:(name)->
        if @_defines[name]
            return true
        return false
    declare:(name)->
        if @_defines[name]
            throw new Error "already defines model property #{name}"
        obj = {}
        @_defines[name] = obj
        @data.__defineGetter__ name,()=>
            return obj.value
        @data.__defineSetter__ name,(value)=>
            if obj.value is value
                return value
            obj.value = value
            @emit "change",name,value
            @emit "change/#{name}",value
            return value
    reset:()->
        for prop of @_defines
            @data[prop] = @_defines[prop].default
    get:(key,value)->
        if not @_defines[key]
            throw new Error "undefined model property #{key}"
        result = @data[key]
        if typeof result is "undefined"
            return value
        else
            return result
    set:(key,value)->
        if not @_defines[key]
            throw new Error "undefined model property #{key}"
        @data[key] = value
    sets:(obj)->
        if not obj
            return
        for prop of obj
            if @_defines[prop]
                @set prop,obj[prop]
    destroy:()->
        # prevent recursive
        if @isDestroy
            return
        @isDestroy = true
        console.debug @_events["destroy"]
        @emit "destroy"
        super()
        @_defines = null
    toJSON:()->
        result = {}
        for prop of @_defines
            result[prop] = @data[prop]
        return result

Leaf.Model = Model