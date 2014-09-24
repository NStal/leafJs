module "basic"
test "leafJs should be loaded",()->
    console.assert Leaf
    console.assert Leaf.Widget
    console.assert Leaf.EventEmitter
    ok !!Leaf


module "EventEmitter"
test "leafJs event emitter should work",()->
    em = new Leaf.EventEmitter();
    recieveEvent = false
    em.on "event",()->
        recieveEvent = true
    em.trigger "event"
    ok recieveEvent

test "leafJs event emitter remove event listemer should work",()->
    em = new Leaf.EventEmitter();
    recieveEvent = false
    handler = ()->
        recieveEvent = true
    em.on "event",handler
    em.trigger "event"
    ok recieveEvent
    recieveEvent = false
    em.removeListener "event",handler
    em.trigger "event"
    ok not recieveEvent

    em.on "eventA",handler
    em.removeAllListeners "eventA"
    em.trigger "event"
    ok not recieveEvent

    em.once "event",handler
    em.trigger "event"
    ok recieveEvent
    recieveEvent = false
    em.trigger "event"
    ok  not recieveEvent

    recieveEvent =false
    emchild = new Leaf.EventEmitter
    em.bubble emchild,"child"
    em.on "child",(a1,a2)->
        recieveEvent = true
        ok a1 is 1
        ok a2 is 2
    emchild.emit "child",1,2
    ok recieveEvent

    recieveEvent = false
    em.stopBubble emchild,"child"
    emchild.emit "child",1,2
    ok not recieveEvent

    someone = {}
    recieveEvent = false
    em.listenBy someone,"event",()->
        recieveEvent = true
    em.emit "event"
    ok recieveEvent
    ok em._events["event"].length is 1
    em.stopListenBy someone
    ok em._events["event"].length is 0
    recieveEvent = false
    em.emit "event"
    ok not recieveEvent

test "EventEmitter.mixin should works as EventEmitter",()->
    obj = {}
    em = Leaf.EventEmitter.mixin(obj)
    recieveEvent = false
    handler = ()->
        recieveEvent = true
    em.on "event",handler
    em.trigger "event"
    ok recieveEvent
    recieveEvent = false
    em.removeListener "event",handler
    em.trigger "event"
    ok not recieveEvent

    em.on "eventA",handler
    em.removeAllListeners "eventA"
    em.trigger "event"
    ok not recieveEvent

    em.once "event",handler
    em.trigger "event"
    ok recieveEvent
    recieveEvent = false
    em.trigger "event"
    ok  not recieveEvent

    recieveEvent =false
    
    obj2 = {}
    emchild = Leaf.EventEmitter.mixin(obj2)
    em.bubble emchild,"child"
    em.on "child",(a1,a2)->
        recieveEvent = true
        ok a1 is 1
        ok a2 is 2
    emchild.emit "child",1,2
    ok recieveEvent

    recieveEvent = false
    em.stopBubble emchild,"child"
    emchild.emit "child",1,2
    ok not recieveEvent

    someone = {}
    recieveEvent = false
    em.listenBy someone,"event",()->
        recieveEvent = true
    em.emit "event"
    ok recieveEvent
    ok em._events["event"].length is 1
    em.stopListenBy someone
    ok em._events["event"].length is 0
    recieveEvent = false
    em.emit "event"
    ok not recieveEvent

module "Util tests"
test "Util tests",()->
    ok Leaf.Util.isHTMLElement document.createElement("div") 
    ok not Leaf.Util.isHTMLElement document.createTextNode("yes!")
    ok is Leaf.Util.isHTMLNode document.createTextNode("yes!")
    ok Leaf.Util.capitalize("abc") is "Abc"
    
    o = {a:5,b:{},c:[1,2,3]}
    c = Leaf.Util.clone o
    ok c.a is o.a
    ok c.b isnt o.b
    ok c.c.length is 3
    
    ok Leaf.Util.compare {a:5,b:[1,2,{k:2}]},{a:5,b:[1,2,{k:2}]}
module "KeyEventManager"
test "KeyEventManager test",()->
    KeyEventManager = Leaf.KeyEventManager
    km = new KeyEventManager()
    km2 = new KeyEventManager()
    input1 = document.createElement("input")
    input2 = document.createElement("input")
    km.attachTo input1
    km2.attachTo input2
    km.master()
    km2.master()
    ok KeyEventManager.stack.length is 1
    ok KeyEventManager.current is km2
    km2.unmaster()
    ok KeyEventManager.stack.length is 0
    ok KeyEventManager.current is km
    km.unmaster()
    
    ok KeyEventManager.stack.length is 0
    ok not KeyEventManager.current
    
    km.master()
    km2.master()
    ok km.isActive = true
    ok km2.isActive = true
    KeyEventManager.disable()
    KeyEventManager.enable()
    # umaster can only be called in an stack way
    ok not km.unmaster()
    
    
module "Model and Collection"
test "Basic model should work",()->
    class TestModel extends Leaf.Model
        constructor:()->
            super()
            @declare ["id","name"]
    model = new TestModel()
    ok model instanceof Leaf.Model
    ok model instanceof TestModel
    error = false
    try
        model.get "undef"
    catch e
        error = true
    ok error
    error = false
    ok typeof (model.get "id")  is "undefined"
    ok (model.get "id","default") is "default"
    model.set "id",5
    ok (model.get "id",6) is 5
    data = model.data
    ok data.id is 5

    recieveEvent = false
    model.on "change/id",(id)->
        recieveEvent = true
    model.set "id",6
    ok data.id is 6
    ok recieveEvent
    recieveEvent = false

    data.id = 7
    ok recieveEvent
    ok model.get("id") is 7

    model.sets {undef:5}
    ok typeof data.undef is "undefined"

    model.sets {id:10,name:"model"}
    ok data.id is 10
    ok data.name is "model"

    model.data = {id:11,name:"modelAgain"}

    ok data.id is 11
    ok data.name is "modelAgain"


    class TestCollection extends Leaf.Collection
        constructor:()->
            super()
    collection = new TestCollection()

    error = false
    try
        collection.add {}
    catch e
        error = true
    ok error

    ok not collection.get {}
    ok not collection.exists {}
    ok not collection.remove {}

    model = new TestModel()
    model.data = {id:5,name:"first"}

    
    recieveEvent = false
    collection.once "add",(who)->
        recieveEvent = true
        ok who is model
    collection.add model
    ok recieveEvent
    ok collection.length is 1
    ok collection.exists model
    ok not collection.exists {id:model.data.id}

    recieveEvent = false
    collection.add model
    ok collection.length is 1
    ok not recieveEvent
    modelSameId = new TestModel()
    modelSameId.data = {id:5,name:"second"}

    collection.add modelSameId
    ok collection.length is 2

    error = false
    try
        collection.setId "id"
    catch e
        error = true
    ok error

    collection.empty()
    ok collection.length is 0

    
    collection.setId "id"
    collection.add model
    ok collection.length is 1
    console.log model.data
    console.log model.toJSON()
    ok model._events["destroy"].length is 1
    ok model.data.id is 5
    ok model.data.name is "first"
    
    ok collection.exists modelSameId
    
    result = collection.add modelSameId
    ok result is model
    ok model.data.id is 5
    ok collection.length is 1
    ok model.data.name is "second"
    
    # test remove and destroy 
    recieveEvent = false
    collection.once "remove",()->
        recieveEvent = true
    collection.remove modelSameId
    ok recieveEvent is true
    ok collection.length is 0
    ok model._events["destroy"].length is 0

    recieveEvent = false
    collection.add model
    collection.once "destroy/model",(target)->
        recieveEvent = true
        ok target is model
    try
        model.destroy()
    catch e
        console.error e
        console.error e.stack
    ok recieveEvent
    ok collection.length is 0

    # test change
    model = new TestModel()
    model.data = {id:10,name:"model"}
    
    collection.add model
    console.log model._defines
    change = false
    changeAgain = false
    collection.once "change/model",(changeModel)->
        change = true
        ok changeModel is model
    collection.once "change/model/name",(changeModel,key,value)->
        changeAgain = true
        ok changeModel is model
        ok key is "name"
        ok value is "newName"
    model.data.name = "newName"
    ok change
    ok changeAgain

    
    model = new TestModel()
    ok not model.data.id
    ok not model.data.name
    model.defaults {id:100,name:"100"}
    ok model.id is 100
    ok model.name is "100"

    model = new TestModel()
    model.id = 99
    model.defaults {id:100,name:"100"}
    ok model.id is 99
    ok model.name is "100"

    model.reset()
    ok model.id is 100
    ok model.name is "100"

    # test default get
    model = new TestModel()
    ok "theName" is model.get "name","theName"

    # set will force an change event
    changed = false
    model.on "change/name",()->
        changed = true
    model.set "name","name"
    ok changed
    changed = false
    model.set "name","name"
    ok changed = true

    changed = false
    model.name = "name"
    ok changed is false

    # preset/undo/confirm
    ok model.name is "name"
    model.preset("name","changedName")
    ok model.name is "changedName"
    model.undo()
    ok model.name is "name"

    model.preset("name","changedName")
    model.preset("id","changedId")
    model.undo("name")

    ok model.name is "name"
    ok model.id is "changedId"

    model.confirm()

    ok model.id is "changedId"
    ok model.name is "name"
    
    model.undo()

    ok model.id is "changedId"
    ok model.name is "name"
    
    json = model.toJSON()
    ok json.id is "changedId"
    ok json.name is "name"
    length = 0
    for prop of json
        length++
    ok length is 2
    model.set "id",[1,2,{toJSON: ->100}]
    console.debug model.id,"yes!"
    json = model.toJSON()
    console.debug json
    ok json.id[2] is 100
    ok json.id.length is 3

    model.retain()
    destroyed = false
    model.on "destroy",()->
        destroyed = true
    model.release()
    ok destroyed
    ok model.isDestroy

    # detailed collection test
    m1 = new TestModel()
    m1.data = {id:1,name:"m1"}
    m2 = new TestModel()
    m2.data = {id:2,name:"m2"}
    m3 = new TestModel()
    collection = new TestCollection()
    
    collection.setId "id"
    collection.add m1
    collection.add m2
    ok collection.get(m1) is m1
    ok collection.get(m1.id) is m1
    ok not collection.get {}
    ok not collection.get m3
    ok collection.find().length is 2
    ok collection.find({}).length is 2
    ok collection.find({id:1}).length is 1
    ok collection.find({invalid:1}).length is 0

    desCounter = 0
    collection.on "remove",()->
        desCounter++
    collection.destroy()
    ok desCounter is 2
    ok collection.length is 0

    model = new TestModel()
    json = model.toJSON()
    length = 0
    for prop of json
        length++
    ok length is 0
    json = model.toJSON({complete:true})
    for prop of json
        length++
    ok length is 2
    obj = {a:5}
    model.id = obj

    
module "EnhancedWidget"
test "basic widget test",()->
    widget = new Leaf.Widget("#widget-a")
    ok widget
    ok widget.node.id is "widget-a"

    strWidget = new Leaf.Widget("<div data-id='self'><div data-id='child'></div></div>")
    ok strWidget.UI.self is strWidget.node
    ok strWidget.UI.child 
    ok strWidget.node.contains strWidget.UI.child
    elemWidget = new Leaf.Widget(document.querySelector("#widget-b"))
    ok elemWidget.node
    ok not (new Leaf.Widget()).isValid
    elemWidget.initTemplate("<div id='widget-b'>text<div data-id='newChild'></div></div>")
    # initTemplate should replace content
    ok elemWidget.node.parentElement is document.body
    ok elemWidget.node$.text() is "text"
    ok elemWidget.UI.newChild

    richWidget = new Leaf.Widget("<div><widget data-widget='childWidget'></widget></div>")
    richWidget.childWidget = new Leaf.Widget()
    richWidget.initSubWidgets()
    ok richWidget.childWidget.node.parentElement is richWidget.node
    richWidget.appendTo elemWidget
    ok richWidget.node.parentElement is elemWidget.node
    richWidget.appendTo document.body
    ok richWidget.node.parentElement is document.body
    richWidget.replace elemWidget
    ok richWidget.node.parentElement is document.body
    ok not elemWidget.node.parentElement

test "enhanced widget test",()->
    template = """<div data-id='root' data-attribute='data-test:test'>
  <div data-id='testClass' class='A B C' data-class='someClass'>
  </div>
  <input data-id='testValue' data-value='someValue'>
  </input>
  <div data-id='testAttributeMulti' data-attribute='a1:a1,a2:a2'>
  </div>
  <div data-id='testHTML' data-html='someHTML'>
  </div>
  <div data-id='testText' data-text='someText'>
  </div>
</div> """
    w = new Leaf.Widget(template)
    ok w
    ok w.renderData
    ok w.renderDataModel
    ok w.renderDataModel.has "test"
    ok w.renderDataModel.has "someClass"
    ok w.renderDataModel.has "someValue"
    ok w.renderDataModel.has "a1"
    ok w.renderDataModel.has "a2"
    ok w.renderDataModel.has "someHTML"
    ok w.renderDataModel.has "someText"

    w.renderData.test = "value"
    ok w.node$.attr("data-test") is "value"

    w.renderData.someClass = "D"
    ok w.UI.testClass.classList.contains "D"
    
    ok w.UI.testClass.classList.contains "A"
    w.renderData.someClass = "E"
    
    ok w.UI.testClass.classList.contains "E"
    ok w.UI.testClass.classList.contains "A"
    ok not w.UI.testClass.classList.contains "D"

    w.renderData.someValue = "someValue"
    ok w.UI.testValue.value is "someValue"

    w.renderData.a1 = "123"
    w.renderData.a2 = "456"
    ok w.UI.testAttributeMulti.getAttribute("a1") is "123"
    ok w.UI.testAttributeMulti.getAttribute("a2") is "456"

    w.renderData.someHTML = "<div id='abc'></div>"
    ok w.node$.find("#abc").length is 1

    w.renderData.someText = "<div id='efg'></div>"
    ok w.node$.find("#efg").length is 0
    ok w.UI.testText$.text() is "<div id='efg'></div>"
    console.log w.node

    w.renderData = {
        a1:"a1"
        ,someClass:"X"
    }
    ok w.renderData.a1 is "a1"
    ok w.renderData.someClass is "X"
    ok w.renderData.a2 is "456"

asyncTest "test RestApiFactory",()->
    factory = new Leaf.RestApiFactory()
    testApi = factory.create({url:"apiResponse.json",method:"GET"})
    expect 2
    testApi {},(err,data)->
        console.assert not err
        console.assert data instanceof Array
        ok true
        
        testApi = factory.create({url:":name/测试",method:"GET"})
        testApi {name:"apiResponse.json"},(err,data)->
            ok err
            start()
test "test Errors",()->
    Errors = Leaf.ErrorFactory.create()
        .define("TestError")
        .generate()
    
    ok Errors.TestError,"has test error"
    error = new Errors.TestError("Just a test!",{name:"hehe~"})
    console.debug error
    ok error instanceof Error,"instanceof Error"
    console.log error
    console.log JSON.parse JSON.stringify error
    ok error.message
    ok error.name is "hehe~"

test "Test sub templates of widget",()->
    templates = "<div><template data-name='listItem'><span class='listItem'></span></template></div>"
    w = new Leaf.Widget(templates)
    ok w.templates.listItem,"template listItem is:"+w.templates.listItem

test "Test namespace of widget",()->
    class PublicButton extends Leaf.Widget
        constructor:()->
            super "<button>public</button>"
            @node$.addClass("button")
    class PrivateButton extends Leaf.Widget
        constructor:()->
            super "<button>private</button>"
            @node$.addClass "private-button"
    class View extends Leaf.Widget
        
        constructor:()->
            @include PublicButton
            super """
<div>
    <public-button data-id='pub'></public-button>
    <private-button data-id='prb'></private-button>
</div>
                """
    view = new View()
    ok view.UI.pub$.text() is "public","public widget should be replaced"
    ok view.UI.prb$.text() isnt "private","private widget shouldn't be replaced"
    ok view.UI.pub.getAttribute("data-id") is "pub","replaced widget's attribute shuold be preserved"
        