WidgetBase = Widget
class Widget extends Widget
    @namespace = WidgetBase.namespace
    @attrs = ["text","html","class","value","attribute","src"]
    constructor:(template)->
        @_ViewModel = new Model()
        super template
        @__defineGetter__ "Data",()=>
            return @_ViewModel.data
        @__defineGetter__ "VM",()=>
            return @_ViewModel.data
        @__defineSetter__ "VM",(value)=>
            @_ViewModel.data = value
    initTemplate:(template)->
        super template
        @initViewModel()
    initViewModel:()->
        attrs = Widget.attrs
        selector = (attrs.map (item)->"[data-#{item}]").join(",")
        if not @node.querySelectorAll
            return
        elems = [].slice.call @node.querySelectorAll selector
        elems.push @node
        for elem in elems
            @applyRenderRole(elem)
    applyRenderRole:(elem)->
        attrs = Widget.attrs
        for attr in attrs
            if info = elem.getAttribute("data-#{attr}")
                @["_#{attr}Role"](elem,info)
    removeRenderRole:(elem)->
        @_ViewModel.stopListenBy elem
    _textRole:(elem,who)->
        if not @_ViewModel.has who
            @_ViewModel.declare who
        @_ViewModel.listenBy elem,"change/#{who}",(value)=>
            elem.textContent = value
    _htmlRole:(elem,who)->
        if not @_ViewModel.has who
            @_ViewModel.declare who
        @_ViewModel.listenBy elem,"change/#{who}",(value)=>
            elem.innerHTML = value
    _classRole:(elem,whos)->
        whos = whos.split(",").map((item)->item.trim()).filter (item)->item
        for who in whos
            do (who)=>
                who ?= ""
                className = null
                [who,className] = who.split(":")
                if not @_ViewModel.has who
                    @_ViewModel.declare who
                oldClass = ""
                @_ViewModel.listenBy elem,"change/#{who}",(value)=>
                    if className
                        decision = value
                        value = className
                        if not decision
                            value = ""
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
                if not @_ViewModel.has who
                    @_ViewModel.declare who
                @_ViewModel.listenBy elem,"change/#{who}",(value)=>
                    elem.setAttribute name,value
    _valueRole:(elem,who)->
        @_attributeRole(elem,"value:#{who}")
    _srcRole:(elem,who)->
        @_attributeRole(elem,"src:#{who}")

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
    push:(items...)->
        for item in items
            item = @create(item)
            @check item
            @[@_length]=item
            if @_length isnt 0
                item.after @[@_length-1]
            else
                item.appendTo @node
            @_length++
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
            item.prependTo @node
            @[0] = item
            @_length = 1
            @_attach(item)
            return
        for index in [@_length..1]
            @[index] = @[index-1]
        @[0] = item
        @_length += 1
        item.before @[1]
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
        frag = document.createDocumentFragment()
        for item in toAddFinal
            @check item
            frag.appendChild item.node
        if index < @length and @length > 0
            @node.insertBefore frag,@[index].node
        else
            # length is 0(<=0) or index > @length
            @node.appendChild frag
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
        for item in toAddFinal
            @_attach item
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
        @emit "child/add",item
        @emit "child/change"
    _detach:(item)->
        item.parentList = null
        node = item.node
        # One may overwrite the item::remove method
        # to change the DOM behavior other than instant removeChild
        if node and node.parentElement is @node
            @node.removeChild node
        item.stopListenBy this
        @emit "child/remove",item
        @emit "child/change"
    sort:(judge)->
        @sync @toArray().sort(judge)
Widget.List = List
Widget.makeList = (node,create)=>
    return new Widget.List(node,create)

# overwrite the old widget
Leaf.Widget = Widget
