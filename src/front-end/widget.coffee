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
        # template can be only a single Node
        # or only the first node is used
        initTemplate : (template,option) ->
            if not template
                throw "invalid template #{template}"
            @nodes = []
            if typeof template == "string"
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
            @emit("ready")
            Widget.emit "widget",this
            
        initUI:()->
            if not @nodes
                throw "invalid root #{@nodes}"
            for node in @nodes
                elems = node.getElementsByTagName("*")
                subNode = node
                if id = subNode.getAttribute "data-id"
                    @UI[id] = subNode
                    subNode.widget = this
                    @_delegateEventForControl(id)
                    if typeof $ is "function"
                        @UI[id+"$"] = @UI["$"+id] = $(subNode)

                for subNode in elems
                    if id = subNode.getAttribute "data-id"
                        @UI[id] = subNode
                        subNode.widget = this
                        @_delegateEventForControl(id)
                        if typeof $ is "function"
                            @UI[id+"$"] = @UI["$"+id] = $(subNode)
            @_delegateEventForControl()
            return true
        _delegateEventForControl:(id)->
            events = ["blur","click","focus","keydown","keyup","keypress"]
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
            @emit("remove")
        before:(target)->
            if Util.isHTMLElement(target)
                target = target
            else if target instanceof Leaf.Widget
                target = target.node
            else
                console.error "Insert unknow Object,target"
                return false
            if not target or not target.parentElement
                console.log target,target.parentElement
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
                
    Widget.Event = new Leaf.EventEmitter()
    Widget.on = ()->
        @Event.on.apply @Event,arguments
    Widget.emit = ()-> 
        @Event.emit.apply @Event,arguments
    Widget.instances = []
    Leaf.Widget = Widget
)(this.Leaf)