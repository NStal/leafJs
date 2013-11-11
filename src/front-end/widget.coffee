((Leaf)->
    Util = Leaf.Util
    class Widget extends Leaf.EventEmitter
        constructor: (@template) ->
            super()
            @node = null 
            @$node = null
            @node$ = null
            @nodes = []
            @UI = {}
            Widget.instances.push this
            if !template then return
            @initTemplate(@template)
        # make template into HTMLElement
        # if template is html strings
        # it will parsed into HTMLElement
        # if template start with #
        # it will be considered as a DOMElement in the current DOM tree
        initTemplate : (template,option) ->
            if not template
                throw "invalid template #{template}"
            @nodes = []
            if typeof template == "string"
                if (template.indexOf "#") is 0
                    @node = document.getElementById template.substring(1)
                    if not @node
                        console.error "template of id",template.substring(1),"not found"
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
                throw "invalid template #{template}"
            if typeof $ is "function"
                @$node = $(@node)
                @node$ = @$node
            @initUI()
            @initData()
            @initSubWidgets()
            Widget.emit "widget",this
        initData:()->
            if not @Data
                @Data = {}
            for name of @Data
                if not @UI[name]
                    console.debug "useless widget data #{name}"
                    continue
                do ()=>
                    value = @Data[name]
                    Object.defineProperty @Data,name,{
                        set:(newValue)=>
                            @_asignValueToDom name,newValue
                            value = newValue
                        get:()=>
                            return value 
                    }
                    # default value or just what ever on HTML
                    if value
                        @Data[name] = value
                    else
                        @Data[name] = @UI[name].innerText
        _asignValueToDom:(name,value)->
            if not @UI[name]
                throw "invalid UI '#{name}'"
            dom = @UI[name]
            # now just set text
            if typeof value is "string" of value instanceof String
                @UI[name].innerText = value
                return
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
                    else if this[name]
                        console.error "Widget named #{name} isnt isn't instanceof Widget"
                        console.trace()
                    else
                        console.error "Widget named",name,"not exists for",widget
                        console.trace()
        initUI:()->
            if not @nodes
                throw "invalid root #{@nodes}"
            for node in @nodes
                elems = node.getElementsByTagName("*")
                _elems = [node]
                for elem in elems
                    _elems.push elem
                elems = _elems
                for subNode in elems
                    if subNode.tagName.toLowerCase() is "widget"
                        continue
                    if id = subNode.getAttribute "data-id"
                        @UI[id] = subNode
                        subNode.widget = this
                        @_delegateEventForControl(id)
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
                ((event)=>
                    node["on"+event] = (e)=>
                        if typeof @["on"+Util.capitalize(event)+Util.capitalize(id)] is "function"
                            return @["on"+Util.capitalize(event)+Util.capitalize(id)](e)
                        return true
                )(event)
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
            if target instanceof Leaf.Widget
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
    class List extends Widget
        constructor:(template,create)->
            super template
            @init create
            Object.defineProperty(this,"length",{
                get:()=>
                    return @_length
                set:(value)=>
                    if value > @_length
                        throw "can't asign length larger than the origin"
                    if value < 0
                        throw "can't asign length lesser than 0"
                    if typeof value isnt "number"
                        throw new TypeError()
                    for index in [value...@length]
                        @[index].remove()
                        delete @[index]
                    @_length = value
                    
            })
        init:(create)->
            @create = create or @create or (item)=>return item
            @_length = 0
            @node.innerHTML = ""
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
            item.parentList = this
            @emit "add",item
            return @_length
        pop:()->
            if @_length is 0
                return null
            @_length -= 1
            item = @[@_length]
            delete @[@_length]
            item.remove()
            @emit "remove",item
            item.parentList = null
            return item
        unshift:(item)->
            item = @create(item)
            @check item
            if @_length is 0
                item.appendTo @node
                @[0] = item
                return 1
            for index in [@_length..1]
                @[index] = @[index-1]
            @[0] = item
            @_length += 1
            item.prependTo @node
            @emit "add",item
            item.parentList = this
            return @_length
        removeItem:(item)->
            index = @indexOf(item)
            if index < 0 then return index
            @splice(index,1)
            item.parentList = null
            @emit "remove",item
            return item
        shift:()->
            result = @[0]
            for index in [0...@_length-1]
                @[index] = @[index+1]
            result.remove()
            @emit "remove",result
            result.parentList = null
            return result
        splice:(index,count,toAdd...)->
            result = []
            # check index
            if typeof count is "undefined" or index + count > @_length
                count = @_length - index
            for offset in [0...count]
                item = @[index+offset]
                item.remove()
                @emit "remove",item
                item.parentList = null
                result.push item
            # make DOM match result
            toAddFinal = (@create item for item in toAdd)
            if index is 0
                for item in toAddFinal
                    @check item
                    item.prependTo @node
                    @emit "add",item
                    item.parentList = this
            else
                achor = @[index-1]
                for item in toAddFinal
                    @check item
                    item.after achor
                    @emit "add",item
                    item.parentList = this
                    
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
            return result
        slice:(from,to)->
            return @toArray().slice(from,to)
        forEach:(handler)->
            for item in this
                handler(item)
        toArray:()->
            return (item for item in this)
        syncWith:(arr,converter = (item)->item)->
            finalArr = []
            for item,index in arr
                _ = converter(item)
                if not (_ instanceof Widget)
                    throw "sync of invalid widget at index:#{index}"
                finalArr.push _
            for index in [0...@_length]
                @emit "remove",this[index]
                this[index].parentList = null
                delete this[index]
            @node.innerHTML = ""
            for item,index in finalArr
                @[index] = item
                item.appendTo @node
                @emit "add",item
                item.parentList = this
            @_length = finalArr.length
            return this
        sort:(judge)->
            @sync @toArray().sort(judge)
    Widget.List = List
    Widget.makeList = (node,create)=>
        return new Widget.List(node,create)
    Widget.Event = new Leaf.EventEmitter()
    Widget.on = ()->
        @Event.on.apply @Event,arguments
    Widget.emit = ()-> 
        @Event.emit.apply @Event,arguments
    Widget.instances = []
    Leaf.Widget = Widget
)(this.Leaf)