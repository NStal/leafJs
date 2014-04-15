# set/get is generally savior than direct assignment
# the difference is set/get on undeclares model property will throw error
# and also set will force an change event even if the value is the as the old one
# while direct assignment won't
#
# but in general they are the same, assign them a new value will auto trigger a change event
# if the value is really changed
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
        @_silent = false
        @_ref = 0
    has:(name)->
        if @_defines[name]
            return true
        return false
    declare:(name)->
        if name instanceof Array
            for item in name
                @declare item
            return
        if @_defines[name]
            console.warn "already defines model property #{name}"
            return
        obj = {}
        @_defines[name] = obj
        accessor = {
            get:()=>
                if not obj.value
                    return obj.value
                if obj.value instanceof Array
                    return obj.value.slice(0)
                return obj.value
            ,set:(value)=>
                if obj.value is value
                    return value
                obj.value = value
                if @_silent
                    return value
                @emit "change",name,value
                @emit "change/#{name}",value
                return value
            ,enumerable:true
        }
        Object.defineProperty @data,name,accessor
        if typeof this[name] is "undefined"
            Object.defineProperty this,name,accessor
        else
            console.warn "Model property name '#{name}' conflict with an existing property of this model instance, and won't be overwritten. You can access it safely via Model.data.#{name} instead of model.#{name}"
    defaults:(kv)->
        for prop of kv
            if @has prop
                @_defines[prop].default = kv[prop]
                if typeof @get(prop) is "undefined"
                    @set prop,kv[prop]
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
        # set will force change event
        # when data[key] is value the set property listener
        # won't fire change event, so we fire it here to force a change event
        if not @_silent and @data[key] is value
            @emit "change"
            @emit "change/#{key}",value
        @data[key] = value
    sets:(obj)->
        if not obj
            return
        @_silent = true
        for prop of @_defines
            if typeof obj[prop] isnt "undefined"
                value = obj[prop]
                if @get(prop) isnt value
                    @set prop,value
                    @emit "change/#{prop}",value
        @emit "change"
        @_silent = false
    preset:(key,value)->
        if not @_defines[key]
            throw new Error "undefined model property #{key}"
        @_defines[key].old = @data[key]
        @_defines[key].stable = false
        @data[key] = value
    presets:(obj)->
        for prop of obj
            if @has prop
                @preset prop,obj[prop]
    undo:(key)->
        if not key
            for prop of @_defines
                @undo prop
            return
        if not @_defines[key]
            throw new Error "undefined model property #{key}"
        if @_defines[key].stable is false
            @data[key] = @_defines[key].old
            @_defines[key].stable = true
    confirm:(key)->
        if not key
            for prop of @_defines
                @confirm prop
            return
        if @_defines[key].stable is false
            @_defines[key].old = @data[key]
            @_defines[key].stable = true
    destroy:()->
        # prevent recursive
        if @isDestroy
            return
        @isDestroy = true
        @emit "destroy"
        super()
        @_defines = null
    toJSON:(option = {})->
        complete = option.complete
        filter = option.filter
        result = {}
        for prop of @_defines
            if typeof @data[prop] is "undefined" and not complete
                continue
            if filter instanceof Array and prop not in filter
                continue
            result[prop] = @data[prop]
            if result[prop] instanceof Array
                result[prop] = result[prop].map (item)->
                    if item and typeof item.toJSON is "function"
                        return item.toJSON({complete:complete})
                    return item
            else if not result[prop]
                continue
            else if typeof result[prop].toJSON is "function"
                result[prop] = result[prop].toJSON({complete:complete})
            
        return result
    ref:(key)-> 
        if not @_defines[key]
            throw new Error "undefined model property #{key}"
        return @_defines[key].value
    retain:()->
        @_ref++
    release:()->
        @_ref--
        if @_ref <= 0
            @destroy()
Leaf.Model = Model
