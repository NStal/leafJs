# set/get is generally savior than direct assignment
# the difference is set/get on undeclares model property will throw error
# and also set will force an change event even if the value is the as the old one
# while direct assignment won't
#
# but in general they are the same, assign them a new value will auto trigger a change event
# if the value is really changed

class Model extends EventEmitter
    constructor:(raw = {})->
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
        # initialize
        if @fields instanceof Array
            for field in @fields
                @declare field
        else if @fields and typeof @fields is "object"
            for field of @fields
                @declare field
            @defaults @fields
        @data = raw
    # has means the field is defined
    # one can always use model.data[field] to get the
    has:(name)->
        if @_defines[name]
            return true
        return false
    undeclare:(name)->
        if name instanceof Array
            for item in name
                @undeclare item
            return
        delete @_defines[name]
        delete @data[name]
        delete @[name]
    declare:(name)->
        if name instanceof Array
            for item in name
                @declare item
            return
        if @_defines[name]
            console and console.warn and console.warn "already defines model property #{name}"
            return
        obj = {}
        @_defines[name] = obj
        accessor = {
            get:()=>
                return obj.value
            ,set:(value)=>
                if obj.value is value
                    return value
                obj.value = value
                if @_silent
                    return value
                change = {}
                change[name] = value
                @emit "change",change
                @emit "change/#{name}",value
                return value
            ,enumerable:true
            ,configurable:true
        }
        Object.defineProperty @data,name,accessor
        if typeof this[name] is "undefined"
            Object.defineProperty this,name,accessor
        else
            console and console.warn and console.warn "Model property name '#{name}' conflict with an existing property of this model instance, and won't be overwritten. You can access it safely via Model.data.#{name} instead of model.#{name}"
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
        _silent = @_silent
        @_silent = true
        @data[key] = value
        @_silent = _silent

        change = {}
        change[key] = value
        @emit "change",change
        @emit "change/#{key}",value
    sets:(obj)->
        if not obj
            return
        change = {}
        changed = false
        for prop of @_defines
            if typeof obj[prop] isnt "undefined"
                value = obj[prop]
                if @get(prop) isnt value
                    changed = true
                    change[prop] = value
                    _silent = @_silent
                    @_silent = true
                    @data[prop] = value
                    @_silent = _silent
                    @emit "change/#{prop}",value
        if changed
            @emit "change",change
    preset:(key,value)->
        if not @_defines[key]
            throw new Error "undefined model property #{key} for #{@constructor.name}"
        if not @_defines[key].unstable
            @_defines[key].old = @data[key]
        @_defines[key].unstable = true
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
            throw new Error "undefined model property #{key} for #{@constructor.name}"
        if @_defines[key].unstable
            @data[key] = @_defines[key].old
            @_defines[key].unstable = false
            delete @_defines[key].old
    confirm:(key)->
        if not key
            for prop of @_defines
                @confirm prop
            return
        if @_defines[key].unstable
            delete @_defines[key].old
            @_defines[key].unstable = false
    toJSON:(option = {})->
        complete = option.complete
        fields = option.fields
        result = {}
        for prop of @_defines
            if typeof @data[prop] is "undefined" and not complete
                continue
            if fields instanceof Array and prop not in fields
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
Leaf.Model = Model
