class Collection extends EventEmitter
    constructor:()->
        super()
        @models = []
        @id = null
        @__defineGetter__ "length",()=>
            return @models.length
    exists:(model)->
        if @get model
            return true
        return false
    setId:(id)->
        if @models.length isnt 0
            throw new Error "set id should before collection has any content"
        @id = id
    get:(model)->
        target = null
        @models.some (old)=>
            if @id
                if old.get(@id) is model.get(@id)
                    target = old
                    return true
                return false
            else if model is old
                target = old
                return true
            return false
        if target
            return target
        return null
    add:(model)->
        if not (model instanceof Model)
            throw new Error "add invalid model, not instanceof Leaf.Model"
        # has id and find an old one
        # so we return the old one
        old = @get model
        if old
            old.sets model.data
            return old
        @models.push model
        @_attachModel model
        @emit "add",model
        return model
    empty:()->
        for model in @models
            @_detachModel model
            @emit "remove",model
        @models = []
    remove:(model)->
        target = @get model
        if not target
            return false
        @models = @models.filter (item)->item isnt target
        @_detachModel target
        @emit "remove",target
        return true
    _attachModel:(model)->
        model.listenBy this,"destroy",()=>
            @remove model
            @emit "destroy/model",model
        model.listenBy this,"change",(key,value)=>
            if @id and key is @id
                throw new Error "shouldn't change id #{key} for model inside a the collection"
            @emit "change/model",model
            @emit "change/model/#{key}",model,key,value
    _detachModel:(model)->
        model.stopListenBy this
Leaf.Collection = Collection
