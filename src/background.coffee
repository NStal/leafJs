class IPCConnection extends EventEmitter
    constructor:(@target)->
        super()
        @target.addEventListener "message",(e)=>
            @emit "message",e.data
    send:(message)->
        @target.postMessage message

class ReceiverLayer extends EventEmitter
    constructor:(@worker)->
        super()
        @connection = new IPCConnection(@worker)
        @messageCenter = new MessageCenter()
        @messageCenter.setConnection(@connection)
        new Subscribable(this)
        new IPCDataDenormalizable(this)
        new ModelReceivable(this)
        new BackgroundAPIBuilder(this)
        new ReadyAware(this)
    debug:()->
        @isDebug = true
    invokeRawApi:(name,data,callback)->
        if @isDebug
            console.debug "Invoke Raw API",name,data
        @messageCenter.invoke "#{name}",data,(args...)=>
            if @isDebug
                console.debug "API #{name} return",args...,"EOA"
            callback args...
class ReadyAware extends Trait
    isReady:false
    initialize:()->
        @messageCenter.once "event/ready",()=>
            @isReady = true
            @emit "ready"
    whenReady:(callback)->
        if @isReady
            callback()
        else
            @once "ready",callback
class BackgroundAPIBuilder extends Trait
    API:{}
    initialize:()->
        @messageCenter.registerApi "addAPI",(option = {},callback)=>
            if @API[option.name]
                console.error "API Conflict",option.name
                callback new Error "APIConflict"
                return
            if @isDebug
                console.debug "Declare API #{option.name}"
            @API[option.name] = (args...)=>
                @invokeRawApi "backgroundAPI/#{option.name}",args...
            callback()
class IPCDataDenormalizable extends Trait
    initialize:()->
        @messageCenter.customDenormalize = @customDenormalize.bind(this)
        @customDenormalizeHandlers = []
    customDenormalize:(data)->
        for handler in @customDenormalizeHandlers
            if result  = handler(data)
                return result
        return null
    registerCustomDenormalize:(handler)->
        @customDenormalizeHandlers.push handler

class Subscribable extends Trait
    initialize:()->
        @messageCenter.listenBy this,"remoteEvent",(name,params)->
            if name is "publish"
                @_handlePublish params...
    subscribeBy:(who,name,handler)->
        @listenBy who,"publish/#{name}",handler
    subscribeByOnce:(who,name,handler)->
        @listenByOnce who,"publish/#{name}",handler
    unsubscribeBy:(who,name,handler)->
        @stopListenBy who,"publish/#{name}",handler
    _handlePublish:(detail)->
        @emit "publish/#{detail.name}",detail.args
class ForegroundModel extends Leaf.Model
    @idIndex = 100000
    constructor:(@layer,modelId,model)->
        super()
        # Only model with modelId may have chance can trace back to a background model
        @_foregroundModelId = ForegroundModel.idIndex++
        @_initAt = new Date()
        if modelId
            @_modelId = modelId
            @_isConnected = true
        else
            @_modelId = null
            @_isConnected = false
        for field in model.fields
            @declare field
            @[field] = model[field]
        @watchState = new WatchState(this)
        @__defineGetter__ "isWatching",()=>
            return @watchState.data.isWatching
        # We maintain watch/unwatch callback in a same queue.
        # All matching the
    watchBy:(who,callback = ->)->
        # TODO implement this fn
        @watch callback
    unwatchBy:(who,callback = ->)->
        # TODO implement this fn
        @watch callback
    watch:(callback = ->)->
        @watchState.feed "watchSignal",true,callback
    unwatch:(callback = ->)->
        @watchState.feed "watchSignal",true,callback
    class WatchState extends States
        constructor:(@fm)->
            @layer = @fm.layer
            super()
            #@debug()
            @setState "standBy"
        atPanic:()->
            @recover()
            @data.watchStateCallback?()
            @setState "standBy"
        atStandBy:()->
            @consumeWhenAvailable "watchSignal",(shouldWatch,callback)=>
                @data.watchStateCallback
                @data.shouldWatch = shouldWatch
                if @data.shouldWatch
                    @setState "watching"
                else
                    @setState "unwatching"
        atWatching:()->
            if @data.isWatching
                @setState "watchSuccess"
                return
            @layer.messageCenter.invoke "modelProvider/watch",{id:@fm._modelId,watcher:@fm._foregroundModelId},(err)=>
                if err
                    @error err
                else
                    @setState "watchSuccess"
        atWatchSuccess:()->
            if not @data.isWatching
                @data.isWatching = true
                @layer.addWatchedModel(@fm)
                @emit "watchStateChange"
            @data.watchStateCallback?()
            @setState "standBy"
        atUnwatchSuccess:()->
            if @data.isWatching
                @data.isWatching = false
                @layer.removeWatchedModel(@fm)
                @emit "watchStateChange"
            @data.watchStateCallback?()
            @setState "standBy"
        atUnwatching:()->
            @layer.messageCenter.invoke "modelProvider/unwatch",{id:@fm._modelId,watcher:@fm._foregroundModelId},(err)=>
                if err
                    @error  err
                else
                    @setState "unwatchSuccess"

class DummyModel extends Leaf.Model
    constructor:()->
        super()
        @_watcher = []
    install:(model)->
        if model not instanceof Leaf.Model
            return false
        if model is @srcModel
            return true
        if @srcModel
            @uninstall()
        @srcModel = model
        for name of model._defines
            @declare name
        @srcModel.listenBy this,"change",()=>
            @sets @srcModel.data
        @sets @srcModel.data
        @_syncSrcWatching()
        return true
    isInstalled:()->
        return @srcModel?
    uninstall:()->
        if not @srcModel
            return
        for name of @_defines
            @undeclare(name)
        if @srcModel instanceof ForegroundModel and @_isSrcModelWatching
            @srcModel.unwatchBy this
        @srcModel.stopListenBy this
        @_isSrcModelWatching = false
        @srcModel = null
    watchBy:(who,callback = ->)->
        if who in @_watcher
            callback()
            return
        @_watcher.push who
        if @_isWatching
            callback()
            return
        @_isWatching = true
        @_syncSrcWatching()
    unwatchBy:(who,callback = ->)->
        if who not in @_watcher
            callback()
            return
        if not @_isWatching
            callback()
            return
        @_watcher = @_watcher.filter (item)->item isnt who
        if @_watcher.length is 0
            @_isWatching = false
        @_syncSrcWatching(callback)
    _syncSrcWatching:(callback = ->)->
        if @srcModel not instanceof ForegroundModel
            return
        if @_isWatching and not @_isSrcModelWatching
            @_isSrcModelWatching = true
            @srcModel?.watchBy this,callback
        else if not @_isWatching and @_isSrcModelWatching
            @_isSrcModelWatching = false
            @srcModel?.unwatchBy this,callback
        else
            callback()

class ProviderLayer extends EventEmitter
    constructor:(@parent)->
        super()
        @connection = new IPCConnection(@parent)
        @messageCenter = new MessageCenter()
        @messageCenter.setConnection(@connection)
        new Publishable(this)
        new IPCDataNormalizable(this)
        new ModelProvidable(this)
    debug:()->
        @isDebug = true
    registerAPI:(name,handler,callback = ->)->
        if @isDebug
            console.debug "Try registering API",name
        @messageCenter.invoke "addAPI",{name},(err)=>
            if err
                console.error err
                callback err
                return
            if @isDebug
                console.debug "API registered",name
            @messageCenter.registerApi "backgroundAPI/#{name}",(args...)=>
                handler args...
            callback()
    ready:()->
        @messageCenter.fireEvent "ready"

class IPCDataNormalizable extends Trait
    initialize:()->
        @messageCenter.customNormalize = @customNormalize.bind(this)
        @customNormalizeHandlers = []
    customNormalize:(data)->
        for handler in @customNormalizeHandlers
            if result  = handler(data)
                return result
        return null
    registerCustomNormalize:(handler)->
        @customNormalizeHandlers.push handler
class Publishable extends Trait
    publish:(name,args...)->
        @messageCenter.fireEvent "publish",{
            name,args
        }


class ModelReceivable extends Trait
    modelClasses:null
    watchingForegroundModels:null
    initialize:()->
        @modelClasses = {}
        @watchingForegroundModels = {}
        @registerCustomDenormalize @denormalizeModel.bind(this)
        @messageCenter.listenBy ModelReceivable,"event/model/change",(id,changes)=>
            fms = @watchingForegroundModels[id] or {}
            for fid,fm of fms
                fm.sets changes
    denormalizeModel:(data)->
        if not data or not data.__mc_type
            return null
        if not (info = @modelClasses[data.__mc_type])
            return null
        model = new info.Model(data.props)
        return new ForegroundModel(this,data.modelId,model)
    addWatchedModel:(fm)->
        fms = @watchingForegroundModels[fm._modelId] ?= {}
        fms[fm._foregroundModelId] = fm
    removeWatchedModel:(fm)->
        fms = @watchingForegroundModels[fm._modelId] ?= {}
        delete fms[fm._foregroundModelId]
    registerModel:(Model,name)->
        name ?= Model.name
        name = "Model/#{name}"
        @modelClasses[name] = {
            name,Model
        }
class ModelProvidable extends Trait
    providerModelManager:null
    @modelClasses:null
    initialize:()->
        @registerCustomNormalize @normalizeModel.bind(this)
        @providerModelManager = new ProviderModelManager(this)
        @modelClasses = {}
    registerModel:(_Model,name)->
        name ?= _Model.name
        name = "Model/#{name}"
        @modelClasses[name] = {
            name,Model:_Model
        }
        _Model::__mc_type = name
    normalizeModel:(model)->
        if model not instanceof Leaf.Model
            return null
        if not model.__mc_type
            return null
        @providerModelManager.manage(model)
        return {
            __mc_type:model.__mc_type
            props:model.toJSON()
            modelId:model._modelId
        }


class ProviderModelManager
    modelIdIndex:10000
    constructor:(@layer)->
        @models = {}
        @setup()
    setup:()->
        @layer.messageCenter.registerApi "modelProvider/get",(id,callback)=>
            if modelInfo = @models[detail.id]
                callback null,modelInfo.model.toJSON()
            else
                callback new Error "Not Found"
        @layer.messageCenter.registerApi "modelProvider/unwatch",(detail = {},callback)=>
            if modelInfo = @models[detail.id]
                @_modelStopWatchBy detail.watcher,modelInfo
            else
                callback new Error "Not Found"
        @layer.messageCenter.registerApi "modelProvider/watch",(detail = {},callback)=>
            if modelInfo = @models[detail.id]
                @_modelWatchBy(detail.watcher,modelInfo)
                callback()
            else
                callback new Error "Not Found"
    _modelWatchBy:(who,modelInfo)->
        if who not in modelInfo.watches
            modelInfo.watches.push who
            modelInfo.watchRef += 1
            # first
            if modelInfo.watchRef is 1
                @bubbleModelToForeground(modelInfo)
                return
    _modelStopWatchBy:(who,modelInfo)->
        if (index = modelInfo.watches.indexOf(who)) >= 0
            modelInfo.watches.splice(index,1)
            modelInfo.watchRef -= 1
            if modelInfo.watchRef <= 0
                @stopBubbleModelToForeground(modelInfo)
                return
    bubbleModelToForeground:(modelInfo)->
        if modelInfo.bubbling
            return
        modelInfo.bubbling = true
        modelInfo.model.listenBy this,"change",(changes)=>
            @layer.messageCenter.fireEvent "model/change",modelInfo.id,changes
    stopBubbleModelToForeground:(modelInfo)->
        if not modelInfo.bubbling
            return
        modelInfo.bubbling = false
        modelInfo.model.stopListenBy this
    manage:(model)->
        if not model._modelId
            model._modelId = (@modelIdIndex++).toString()
        info = @models[model._modelId]
        if not info
            @models[model._modelId] = {
                watchRef:0
                watches:[]
                model:model
                id:model._modelId
            }
    revoke:()->
        if not model._modelId
            return
        info = @models[model._modelId]
        if not info
            return false
        info.count -= 1
        if info.count <= 0
            @models[model._modelId] = null
        return true
Leaf.DummyModel = DummyModel
Leaf.Background = {
    ReceiverLayer
    ProviderLayer
    IPCConnection
}
