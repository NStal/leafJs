class Widget extends Leaf.EventEmitter
    widgetEvents:[]
    _interestingDOMEventNames:["click","mouseup","mousedown","mousemove","mouseleave","mouseenter","mouseover","keydown","keyup","keypress"]
    constructor:(option = null)->
        super()
        # So prototype don't accidentally modified.
        @_interestingDOMEventNames = @_interestingDOMEventNames.slice(0)
        @widgetEvents = @widgetEvents.slice()
        template = null
        if not option
            template = null
        else if typeof option is "string"
            template = option
        else if Util.isHTMLNode option
            template = option
        else if typeof option is "object"
            template = option.node or option.template or null

        @namespace = @namespace or (@constructor and @constructor.namespace) or new Leaf.Namespace()
        @template = template or @template or document.createElement "div"
        @node = null
        @$node = null
        @node$ = null
        @UI = {}
        @initTemplate(@template)
        @_models = []
    include:(widget)->
        @namespace = @namespace or (@constructor and @constructor.namespace) or Widget.ns or new Leaf.Namespace()
        @namespace.include widget
        for name in (widget?.prototype?.widgetEvents or [])
            if name not in @_interestingDOMEventNames
                @_interestingDOMEventNames.push name
    # make template into HTMLElement
    # if template is html strings
    # it will parsed into HTMLElement
    # if template start with #
    # it will be considered as a DOMElement in the current DOM tree
    bubbleDOMEvent:(name,props = {})->
        if name not in (@widgetEvents or [])
            console.error "You should declare CustomDOMEvent \"#{name}\" in @widgetEvents"
        e = new CustomEvent(name,{
            bubbles:true
            cancelable:true
        })
        for prop,value of props
            e[prop] = value
        @node.dispatchEvent e
        return e
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
            else
                tempNode = document.createElement("div");
                tempNode.innerHTML = template.trim()
                @node = tempNode.children[0]
                tempNode.removeChild(@node)
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

        if @node.nodeType is @node.TEXT_NODE
            return
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
        # hide template instead of remove it
        # so it can be captured by child
            if tmpl
                tmpl.style.display = "none"
#            if tmpl.parentElement and @node.contains tmpl
#                tmpl.parentElement.removeChild(tmpl)
            if name
                @templates[name] = template
    expose:(name,remoteName)->
        remoteName = remoteName or name
        # expose method
        if @[name] and typeof @[name] is "function"
            @node.__defineGetter__ remoteName,()=>
                return @[name].bind(this)
        else
        # expose property
            capName = Util.capitalize name
            getterName = "onGet#{capName}"
            setterName = "onSet#{capName}"
            @node.__defineGetter__ remoteName,()=>
                if @[getterName]
                    return @[getterName]("property")
                return @[name]
            @node.__defineSetter__ remoteName,(value)=>
                if @[setterName]
                    @[setterName](value,"property")
                else
                    @[name] = value
#    initDelegates:()->
#        events = ["blur","click","focus","keydown","keyup","keypress","mousemove","mouseenter","mouseleave","mouseover","mouseout","scroll"]

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
            @initSubWidget(elem)
    initSubWidget:(elem)->
        if typeof elem is "string"
            elem = @node.querySelector("[data-widget='#{elem}']")
        if not elem
            return
        elem.dataset ?= {}
        name = elem.dataset.widget
        widget = (@[name] instanceof Widget) and @[name] or @namespace.createWidgetByElement(elem)
        # hasEmbedWidget means some widget placeholder will be given to sub widget.
        # User can manually set this property to prevent error message
        if not widget and not @hasEmbedWidget
            console.warn "#{elem.tagName} has name #{name} but no widget nor namespace present for it."
            return
        # replace is safe even elem is widget.node
        widget.replace elem
        # widget is get from preset instance member
        # namespace will set attr of elem ot it's node
        # so we should manually do it here.
        if @[name] is widget
            for attr in elem.attributes
                if attr.name is "class"
                    for item in elem.classList
                        widget.node.classList.add item
                else
                    widget.node.setAttribute(attr.name,attr.value)
        if name? and not @[name]?
            @[name] = widget
        if elem.dataset.id
            @_bindUI(widget.node,elem.dataset.id)

    initUI:()->
        node = @node
        elems = node.querySelectorAll "[data-id]"
        elems = [].slice.call(elems)
        elems.unshift node
        for subNode in elems
            # don't include widget
            # if subNode.tagName.toLowerCase() is "widget"
            #    continue
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
            return @[fnName](event)
        return true
    initDelegates:()->
        if @disableDelegates
            return
        events = @_interestingDOMEventNames
        for event in events
            do (event)=>
                @node.addEventListener event,(e)=>
                    # don't use e.stopImmediatePropagation()
                    # use prevent default
                    e.capture = ()->
                        e.stopImmediatePropagation()
                        e.preventDefault()
                    source = e.target or e.srcElement
                    if not source
                        return
                    source.dataset ?= {}
                    while source and not e.defaultPrevented
                        e.currentTarget = source
                        if source is @node
                            result = @_delegateTo "self","node",e
                        if source.widget and source.widget isnt this
                            # likely we by any chance
                            # run into others dom space
                            break
                        else if source.uiId
                            result = @_delegateTo "id",source.uiId,e
                        else if source.dataset.group
                            result = @_delegateTo "group",source.dataset.group,e
                        if result is false
                            e.capture()
                            break
                        else
                            if source is @node
                                break
                            source = source.parentElement

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
                        @_delegateTo "id",name,e
    appendTo:(target)->
        if Util.isHTMLNode(target)
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
        if Util.isHTMLNode(target) and target.parentElement
            target.parentElement.removeChild target
            return

    prependTo:(target)->
        if Util.isHTMLNode(target)
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
        if Util.isHTMLNode(target)
            target = target
        else if target instanceof Leaf.Widget
            target = target.node
        else
            console.error "Insert unknow Object",target
            return false
        if not target or not target.parentElement
            console.error "can't insert befere root element "
            return false
        if target.nextSibling
            target.parentElement.insertBefore @node,target.nextSibling
        else
            target.parentElement.appendChild @node
    before:(target)->
        if target is this or target is @node
            return
        if Util.isHTMLNode(target)
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
        if Util.isHTMLElemen(target)
            target.innerHTML = ""
        if target instanceof Leaf.Widget
            target.node.innerHTML = ""
        @appendTo(target)
    destroy:()->
        # destroy are mainly for release DOM resource
        # mostly the image
        @emit "beforeDestroy"
        @isDestroyed = true
        @removeAllListeners()
        # remove image src
        if @node and @node.querySelectorAll
            for item in (@node.querySelectorAll("img") or [])
                item.removeAttribute("src")

#Leaf.setGlobalNamespace = (ns)->
#    Widget.namespace = ns
#    Widget.ns = ns
#Leaf.setGlobalNamespace(new Namespace())
