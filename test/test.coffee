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


module "Model and Collection"
test "Basic model should work",()->
    class TestModel extends Leaf.Model
        constructor:()->
            super()
            @declare "id"
            @declare "name"
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


module "EnhancedWidget"

test "basic widget test",()->
    widget = new Leaf.Widget("#widget-a")
    ok widget
    ok widget.node.id is "widget-a"
    ok widget.node.
    
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
