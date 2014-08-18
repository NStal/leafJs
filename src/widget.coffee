class Widget extends Leaf.EventEmitter
    constructor:(@template = "<div></div>")->
        super()
        @node = null 
        @$node = null
        @node$ = null
        @nodes = []
        @UI = {}
        @initTemplate(@template)
        @_models = []
    # make template into HTMLElement
    # if template is html strings
    # it will parsed into HTMLElement
    # if template start with #
    # it will be considered as a DOMElement in the current DOM tree
    initTemplate:(template)->
        if not template
            template = "<div></div>"
        @nodes = []
        oldNode = @node
        if typeof template == "string"
            template = template.trim()
            if (template.indexOf "<") isnt 0
                query = template
                @node = document.querySelector query
                if not @node
                    console.error "template of query #{query} not found"
                    return
                @nodes = [@node]
                @node.widget = this
            else
                tempNode = document.createElement("div");
                tempNode.innerHTML = template.trim()
                @node = tempNode.children[0]
                for node in tempNode.children
                    @nodes.push(node)
                    node.widget = this
        else if Util.isHTMLNode(template)
            @node = template
            @node.widget = this
            @nodes.push(template)
        
        # insert tr or td tag into div or something
        # may cause failure to generate elements
        # but we only handle it in latter version
        if not @node
            @isValid = false
            return
        if typeof $ is "function"
            @$node = $(@node)
            @node$ = @$node
        if oldNode and oldNode.parentElement
            for node in @nodes
                oldNode.parentElement.insertBefore node,oldNode
            oldNode.parentElement.removeChild oldNode
        @initUI()
        @initSubWidgets()

    initSubWidgets:()->
        for node in @nodes
            widgets = node.getElementsByTagName("widget")
            # DOM change cause widgets change
            # so we buffered it
            _widgets = []
            for item in widgets
                _widgets.push item
            widgets = _widgets
            
            for widget,index in widgets
                name = widget.getAttribute "data-widget"
                if not name
                    continue
                if this[name] instanceof Widget
                    this[name].replace widget
                    # assign data-widget to newly replace widget element
                    # for easy human reading DOM.
                    this[name].node$.attr("data-widget",name)
                else if this[name]
                    console.warn "Widget named #{name} isnt isn't instanceof Widget"
                    console.trace()
                else
                    console.warn "Widget named",name,"not exists for",widget
                    console.trace()
    initUI:()->
        if not @nodes
            throw "invalid root #{@nodes}"
        for node in @nodes
            elems = node.querySelectorAll "[data-id]"
            elems = [].slice.call(elems)
            elems.unshift node
            for subNode in elems
                if subNode.tagName.toLowerCase() is "widget"
                    continue
                if id = subNode.getAttribute "data-id"
                    @UI[id] = subNode
                    subNode.widget = this
                    @_delegateEventForControl(id)
                    # handy jquery like helper
                    if typeof $ is "function"
                        @UI[id+"$"] = @UI["$"+id] = $(subNode)
        @_delegateEventForControl()
        return true
    _delegateEventForControl:(id)->
        events = ["blur","click","focus","keydown","keyup","keypress","mousemove","mouseenter","mouseleave","mouseover","mouseout","scroll"]
        node = @UI[id]
        if not node
            node = @node
            id = "node"
        for event in events
            do (event)=>
                node["on"+event] = (e)=>
                    if typeof @["on"+Util.capitalize(event)+Util.capitalize(id)] is "function"
                        return @["on"+Util.capitalize(event)+Util.capitalize(id)](e)
                    return true
    appendTo:(target)->
        if Util.isHTMLElement(target)
            for node in @nodes
                target.appendChild(node)
            return true 
        if target instanceof Leaf.Widget
            for node in @nodes
                target.node.appendChild(node)
    replace:(target)->
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
            for node in @nodes
                target.appendChild node
        else
            @nodes.reverse()
            first = target.children[0]
            for node in @nodes
                target.insertBefore(node,first)
            @nodes.reverse()
        return true
    remove:()->
        for node in @nodes
            if node.parentElement
                node.parentElement.removeChild node
    after:(target)->
        if Util.isHTMLElement(target)
            target = target
        else if target instanceof Leaf.Widget
            target = target.node
        else
            console.error "Insert unknow Object",target
            return false
        if not target or not target.parentElement
            console.log target,target.parentElement
            console.error "can't insert befere root element "
            return false
        if target.nextElementSibling
            for node in @nodes
                target.parentElement.insertBefore node,target.nextElementSibling
        else
            for node in @nodes
                target.parentElement.appendChild node
    before:(target)->
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
        for node in @nodes
            target.parentElement.insertBefore(node,target)
        @nodes.reverse()
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
class List extends Widget
    constructor:(template,create)->
        super template
        @init create
        Object.defineProperty(this,"length",{
            get:()=>
                return @_length
            set:(value)=>
                toRemove = []
                if value > @_length
                    throw "can't asign length larger than the origin"
                if value < 0
                    throw "can't asign length lesser than 0"
                if typeof value isnt "number"
                    throw new TypeError()
                for index in [value...@length]
                    toRemove.push @[index]
                    delete @[index]
                @_length = value
                for item in toRemove
                    @_detach(item)
                
        })
    init:(create)->
        @create = create or @create or (item)=>return item
        @_length = 0
        @node.innerHTML = ""
    map:(args...)->
        [].map.apply(this,args)
    some:(args...)->
        [].some.apply(this,args)
    forEach:(args...)->
        [].forEach.apply(this,args)
    check:(item)->
        if item not instanceof Widget
            throw "Leaf List only accept widget as element"
        for child in this
            if child is item
                throw "already exists"
    indexOf:(item)->
        for child,index in this
            if item is child
                return index
        return -1
    push:(item)->
        item = @create(item)
        @check item
        @[@_length]=item
        @_length++
        item.appendTo @node
        @_attach(item)
    pop:()->
        if @_length is 0
            return null
        @_length -= 1
        item = @[@_length]
        delete @[@_length]
        @_detach(item)
        return item
    unshift:(item)->
        item = @create(item)
        @check item
        if @_length is 0
            item.appendTo @node
            @[0] = item
            @_length = 1
            @_attach(item)
            return
        for index in [@_length..1]
            @[index] = @[index-1]
        @[0] = item
        @_length += 1
        item.prependTo @node
        @_attach(item)
        return @_length
    removeItem:(item)->
        index = @indexOf(item)
        if index < 0 then return index
        @splice(index,1)
        return item
    shift:()->
        result = @[0]
        for index in [0...@_length-1]
            @[index] = @[index+1]
        @_length -= 1
        @_detach(result)
        return result
    splice:(index,count,toAdd...)->
        result = []
        toRemoves = []
        # check index
        if typeof count is "undefined" or index + count > @_length
            count = @_length - index
        for offset in [0...count]
            item = @[index+offset]
            toRemoves.push item
            result.push item
        # make DOM match result
        toAddFinal = (@create item for item in toAdd)
        if index is 0
            for item in toAddFinal
                @check item
                item.prependTo @node
                @_attach(item)
        else
            achor = @[index-1]
            for item in toAddFinal
                @check item
                item.after achor
                @_attach item
                
        # now make list match DOM
        # I make the hole left by remove "count" items
        # match the toAdd.length by shifting them one by one
        # That is mount of toAdd.length - count
        # so we can fill them one by one
        increase = toAddFinal.length - count
        if increase < 0
            for origin in [index+count...@_length]
                @[origin+increase] = @[origin]
        else if increase > 0
            for origin in [@_length-1...index+count-1] 
                @[origin+increase] = @[origin]
            
            
        # fill the hole
        for item,offset in toAddFinal
            @[index+offset] = item
        @_length += increase
        for item in toRemoves
            @_detach item
        return result
    slice:(from,to)->
        return @toArray().slice(from,to)
    forEach:(handler)->
        for item in this
            handler(item)
    toArray:()->
        return (item for item in this)
#    syncWith:(arr,converter = (item)->item)->
#        finalArr = []
#        for item,index in arr
#            _ = converter(item)
#            if not (_ instanceof Widget)
#                throw "sync of invalid widget at index:#{index}"
#            finalArr.push _
#        for index in [0...@_length]
#            @_detach(this[index])
#            delete this[index]
#        @node.innerHTML = ""
#        for item,index in finalArr
#            @[index] = item
#            item.appendTo @node
#            @_attach(item)
#        @_length = finalArr.length
#        return this
    _attach:(item)->
        item.parentList = this
        item.listenBy this,"destroy",()=>
            @removeItem item
        @emit "child/add",item
    _detach:(item)->
        item.parentList = null
        for node in item.nodes
            if node and node.parentElement is @node
                @node.removeChild node
        # can use item.remove method
        # because an if remove is overwritten then things won't work
        # and this is likely to be the case
        item.stopListenBy this
        @emit "child/remove",item
    sort:(judge)->
        @sync @toArray().sort(judge)
    destroy:()->
        @length = 0
        super()
Widget.List = List
Widget.makeList = (node,create)=>
    return new Widget.List(node,create)
Leaf.Widget = Widget
