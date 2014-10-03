class Namespace extends Leaf.EventEmitter
    constructor:()->
        super()
        @scope = {}
        @widgets = []
    include:()->
        @register.apply this,arguments
    register:(constructor,name)->
        if not name
            name = constructor.name
        else if constructor not instanceof Leaf.Widget or not name
            throw new Error "invalid namespace register with #{name}"
        if constructor in @widgets
            return
        constructor.scopeName = name
        @scope[constructor.scopeName] = constructor
        @widgets.push constructor
        @selectorCache = null
#    unregister:(constructor)->
#        if constructor.namespace is this
#            constructor.namespace = null
#        @widgets = @widgets.filter (item)->item isnt constructor
#        if constructor.scopeName and @scope[constructor.scopeName] is constructor
#            delete @scope[constructor.scopeName]
#        delete constructor.scopeName
#        @selectorCache = null
    getQuerySelector:(extra...)->
        if not @selectorCache?
            @selectorCache = @widgets.filter((item)->
                # currently don't enable public
                return item.public or true
            ).map((item)->
                return Util.camelToSlug(item.scopeName)
            ).join(",").trim()
        if @selectorCache
            extra.unshift(@selectorCache.trim())
        return extra.join(",")
    createWidgetByElement:(elem)->
        name = Util.capitalize Util.slugToCamel elem.tagName.toLowerCase()
        Constructor = @scope[name]
        if not Constructor
            return null
        param = {}
        for attr in elem.attributes
            if attr.name.indexOf("data-") isnt 0
                param[Util.slugToCamel attr.name] = attr.value
        widget = new Constructor(elem,param)
        # put every thing on elem to the new node
        # class will be overwrite be careful
        for attr in elem.attributes
            widget.node.setAttribute(attr.name,attr.value)
            widget.node[attr.name] = attr.value
        return widget
    setTemplates:(templates)->
        @templates = templates
        # done
        
Leaf.Namespace = Namespace

