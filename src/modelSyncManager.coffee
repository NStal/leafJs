# recieves backend events to see if we need to update correspoding models
Model = require "model"
App = new App
class ModelSyncManager extends Leaf.EventEmitter
    constructor:()->
        App.initalLoaded ()=>
            @setMessageCenter App.messageCenter
    setMessageCenter:(mc)->
        if @mc
            @mc.stopListenBy this
        @mc = mc
        @mc.listenBy this,"event/source",(source)=>
            @emit "source",new Model.Source(source)
        @mc.listenBy this,"event/archive",(archive)=>
            @emit "archive",new Model.Archive(archive)
module.exports = ModelSyncManager