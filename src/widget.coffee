class Widget extends Leaf.EventEmitter
    constructor:(template)->
        super()
        @namespace = @namespace or (@constructor and @constructor.namespace) or new Leaf.Namespace()
        @template = template or @template or = "<div></div>"
        @node = null 
        @$node = null
        @node$ = null
        @UI = {}
        @initTemplate(@template)
        @_models = []
    include:(widget)->
        @namespace = @namespace or (@constructor and @constructor.namespace) or Widget.ns or new Leaf.Namespace()
        @namespace.include widget

    # make template into HTMLElement
    # if template is html strings
    # it will parsed into HTMLElement
    # if template start with #
    # it will be considered as a DOMElement in the current DOM tree
    initTemplate:(template)->
        if not template
            template = "<div></div>"
        oldNode = @node
        if typeof template == "string"
            template = template.trim()
            if (template.indexOf "<") isnt 0
                query = template
                @node = document.querySelector query
                if not @node
                    console.error "template of query #{query} not found"
                    return
                @node.widget = this
            else
                tempNode = document.createElement("div");
                tempNode.innerHTML = template.trim()
                @node = tempNode.children[0]
        else if Util.isHTMLNode(template)
            @node = template
            @node.widget = this
        
        # insert tr or td tag into div or something
        # may cause failure to generate elements
        # but we only handle it in latter version
        if not @node
            @isValid = false
            return
        if typeof $ is "function"
            @$node = $(@node)
            @node$ = @$node
        if oldNode and oldNode.parentElement and oldNode isnt @node
            oldNode.parentElement.insertBefore @node,oldNode
            oldNode.parentElement.removeChild oldNode
        # init UI will listen all predined events on target
        @initSubTemplate()
        @initUI()
        @initSubWidgets()
        @initDelegates()
    initSubTemplate:()->
        @templates = @templates or {}
        templateNodes = @node.querySelectorAll "template"
        # Dom action will cause nodes array change,
        # let me convert it to array first
        templateNodes = [].slice.call(templateNodes,0)
        for tmpl in templateNodes
            template = tmpl.innerHTML
            name = tmpl.getAttribute("data-name")
            if tmpl.parentElement
                tmpl.parentElement.removeChild(tmpl)
            if name
                @templates[name] = template
    expose:(name,remoteName)->
        remoteName = remoteName or name
        if @[name] and typeof @[name] is "function"
            @node.__defineGetter__ remoteName,()=>
                return @[name].bind(this)
        else
            capName = Util.capitalize name
            getterName = "onGet#{capName}"
            setterName = "onSet#{capName}"
            @node.__defineGetter__ remoteName,()=>
                if @[getterName]
                    return @[getterName](value,"property")
                return @[name]
            @node.__defineSetter__ remoteName,(value)=>
                if @[setterName]
                    @[setterName](value,"property") 
                else
                    @[name] = value
    initDelegates:()->
        events = ["blur","click","focus","keydown","keyup","keypress","mousemove","mouseenter","mouseleave","mouseover","mouseout","scroll"]

    initSubWidgets:()->
        if @namespace
            selector = @namespace.getQuerySelector("widget")
        else
            selector = "widget"
        elems = @node.querySelectorAll(selector)
        # DOM change cause widgets change
        # so we buffered it
        elems = [].slice.call(elems,0)
        for elem in elems
            name = elem.dataset.widget
            widget = (@[name] instanceof Widget) and @[name] or @namespace.createWidgetByElement(elem)
            if not widget
                console.warn "#{elem.tagName}has name but no widget and no namespace present for it"
                continue
            # replace is safe even elem is widget.node
            widget.replace elem
            # widget is get from preset instance member
            # namespace will set attr of elem ot it's node
            # so we should manually do it here.
            if @[name] is widget
                for attr in elem.attributes
                    widget.node.setAttribute(attr.name,attr.value)
            if name? and not @[name]?
                @[name] = widget
            if elem.dataset.id
#                console.debug "elem.dataset has id",elem.dataset.id
                @_bindUI(widget.node,elem.dataset.id)
    
    initUI:()->
        node = @node
        elems = node.querySelectorAll "[data-id]"
        elems = [].slice.call(elems)
        elems.unshift node
        for subNode in elems
            # don't include widget
            if subNode.tagName.toLowerCase() is "widget"
                continue
            if id = subNode.getAttribute "data-id"
                @_bindUI(subNode,id)
                @_delegateUnBubbleEvent(id) 
        @_delegateUnBubbleEvent()
        return true
    _bindUI:(node,id)->        
            @UI[id] = node
            node.widget = this
            node.uiId = id
            # handy jquery like helper
            if typeof $ is "function"
                @UI[id+"$"] = @UI["$"+id] = $(node)
    _delegateTo:(type,name,event)->
        fnName = "on#{Util.capitalize event.type}#{Util.capitalize name}"
        if type is "group"
            fnName += "Groups"
        if @[fnName]
            @[fnName](event)
        return
    initDelegates:()->
        if @disableDelegates
            return
        events = ["click","mouseup","mousedown","mousemove","mouseleave","mouseenter","keydown","keyup","keypress"]
        for event in events
            do (event)=>
                @node["on#{event}"] = (e)=>
                    source = e.target or e.srcElement
                    if source.widget isnt this
                        return
                    if source.uiId
                        @_delegateTo "id",source.uiId,e
                    else if source.dataset.group
                        @_delegateTo "group",source.dataset.group,e
                
    _delegateUnBubbleEvent:(name)->
        if @disableDelegates
            return
        if not name
            node = @node
            name = "node"
        else
            node = @UI[name]
        if not node
            return
        delegates = [{
                names:["input","textarea"]
                events:["change","focus","blur","scroll"]
            },{
                names:["form"]
                events:["submit"]
            },{
                events:["scroll"]
            }
        ]
        for option in delegates
            if option.names and node.tagName.toLowerCase() not in option.names
                continue
            for event in option.events
                # don't move this delegated element around!
                # don't move any element with data-id around!
                # the behavior should be unpredictable and unwanted
                do (event)=>
                    node["on#{event}"] = (e)=>
                        @_delegateTo "id",name,event
    appendTo:(target)->
        if Util.isHTMLElement(target)
            target.appendChild(@node)
            return true 
        if target instanceof Leaf.Widget
            target.node.appendChild(@node)
    replace:(target)->
        if target is this or target is @node
            return
        @before target
        if target instanceof Widget
            target.remove()
            return
        if Util.isHTMLElement(target) and target.parentElement
            target.parentElement.removeChild target
            return
            
    prependTo:(target)->
        if Util.isHTMLElement(target)
            target = target
        else if target instanceof Leaf.Widget
            target = target.node
        else
            return false
        if target.children.length is 0
            target.appendChild @node
        else
            first = target.children[0]
            target.insertBefore(@node,first)
        return true
    remove:()->
        if @node.parentElement
            @node.parentElement.removeChild @node
    after:(target)->
        if target is this or target is @node
            return
        if Util.isHTMLElement(target)
            target = target
        else if target instanceof Leaf.Widget
            target = target.node
        else
            console.error "Insert unknow Object",target
            return false
        if not target or not target.parentElement
            console.error "can't insert befere root element "
            return false
        if target.nextElementSibling
            target.parentElement.insertBefore @node,target.nextElementSibling
        else
            target.parentElement.appendChild @node
    before:(target)->
        if target is this or target is @node
            return
        if Util.isHTMLElement(target)
            target = target
        else if target instanceof Leaf.Widget
            target = target.node
        else
            console.error "Insert unknow Object,target"
            return false
        if not target or not target.parentElement
            console.error "can't insert befere root element "
            return false
        target.parentElement.insertBefore(@node,target)
        return true
    occupy:(target)->
        if Util.isHTMLElement(target)
            target.innerHTML = ""
        if target instanceof Leaf.Widget
            target.node.innerHTML = ""
        @appendTo(target)
    use:(model)->
        @_models.push model
        model.listenBy this,"destroy",()=>
            @_models = @_models.filter (item)->item isnt model
        model.retain()
    destroy:()->
        # prevent recursive
        if @isDestroy
            return
        @isDestroy = true
        # emit before clean eventemitter
        @emit "destroy"
        super()
        for model in @_models
            model.release()
            model.stopListenBy(this)
        @UI = null
        @node = null
        @node$ = null
        @$node = null
#Leaf.setGlobalNamespace = (ns)->
#    Widget.namespace = ns
#    Widget.ns = ns
#Leaf.setGlobalNamespace(new Namespace())