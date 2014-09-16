class Widget extends Widget
    @attrs = ["text","html","class","value","attribute","src"]
    @namespace = new Namespace()
    @register = @namespace.register.bind(@namespace)
    @unregister = @namespace.unregister.bind(@namespace)
    constructor:(template)->
        super template
        @__defineGetter__ "renderData",()=>
            if @renderDataModel
                return @renderDataModel.data
            else
                return null
        # read-only alias for renderData
        @__defineGetter__ "Data",()=>
            return @renderData
        
        @__defineSetter__ "renderData",(value)=>
            if @renderDataModel
                @renderDataModel.data = value
    initTemplate:(template)->
        oldModel = @renderDataModel
        @renderDataModel = new Model()
        @renderData = @renderDataModel.data
        super template
        @initRenderData()
        if oldModel
            @renderData = oldModel.data
            oldModel.destroy()
    initRenderData:()->
        attrs = Widget.attrs
        selector = (attrs.map (item)->"[data-#{item}]").join(",")
        for node in @nodes
            elems = [].slice.call node.querySelectorAll selector
            elems.push node
            for elem in elems
                @applyRenderRole(elem)
    applyRenderRole:(elem)->
        attrs = Widget.attrs
        for attr in attrs
            if info = elem.getAttribute("data-#{attr}")
                @["_#{attr}Role"](elem,info)
    removeRenderRole:(elem)->
        @renderDataModel.stopListenBy elem
    _textRole:(elem,who)->
        if not @renderDataModel.has who
            @renderDataModel.declare who
        @renderDataModel.listenBy elem,"change/#{who}",(value)=>
            elem.textContent = value
    _htmlRole:(elem,who)->
        if not @renderDataModel.has who
            @renderDataModel.declare who
        @renderDataModel.listenBy elem,"change/#{who}",(value)=>
            elem.innerHTML = value
    _classRole:(elem,whos)->
        whos = whos.split(",").map((item)->item.trim()).filter (item)->item
        for who in whos
            if not @renderDataModel.has who
                @renderDataModel.declare who
            oldClass = "";
            @renderDataModel.listenBy elem,"change/#{who}",(value)=>
                if value and elem.classList.contains value
                    if oldClass and elem.classList.contains oldClass
                        elem.classList.remove oldClass
                    oldClass = value
                    return
                if oldClass
                    elem.classList.remove oldClass
                if value and not elem.classList.contains(value)
                    elem.classList.add value
                oldClass = value
    _attributeRole:(elem,whats="")->
        whats = whats.split(",").map((item)->item.trim().split(":")).filter (pair)->pair.length is 1 or pair.length is 2
        for pair in whats
            do (pair)=>
                name = pair[0]
                who = pair[1] or name
                if not @renderDataModel.has who
                    @renderDataModel.declare who
                @renderDataModel.listenBy elem,"change/#{who}",(value)=>
                    elem.setAttribute name,value
    _valueRole:(elem,who)->
        @_attributeRole(elem,"value:#{who}")
    _srcRole:(elem,who)->
        @_attributeRole(elem,"src:#{who}")
    destroy:()->
        @renderDataModel.destroy()
        @renderDataModel = null
        @renderData = null
        super()

# overwrite the old widget
Leaf.Widget = Widget