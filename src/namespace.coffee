class Namespace extends Leaf.EventEmitter
    constructor:()->
        @scope = {}
        @widgets = []
    register:(constructor,name)->
        if not name
            name = constructor.name
        else if constructor not instanceof Leaf.Widget or not name
            throw new Error "invalid namespace register with #{name}"
        if constructor.namespace
            
        constructor.scopeName = name
        @scope[constructor.scopeName] = constructor
        @widgets.push constructor
        @selectorCache = null
        constructor.namespace = this
    unregister:(constructor)->
        if constructor.namespace is this
            constructor.namespace = null
        @widgets = @widgets.filter (item)->item isnt constructor
        if constructor.scopeName and @scope[constructor.scopeName] is constructor
            delete @scope[constructor.scopeName]
        delete constructor.scopeName
        @selectorCache = null
    
    applyTo:(element)->
        if not @selectorCache
            @selectorCache = @widget.map((item)->
                return Util.slugToCamel(item.scopeName)
            ).join(",")
        elems = element.querySelectorAll(@selectorCache)
        for elem in elems
            if elem.children.length > 0
                return
        
Leaf.Namespace = Namespace
    