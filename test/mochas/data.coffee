describe "test model",()->
    it "test basic model usage",(done)->
        class Archive extends Leaf.Model
            fields:[
                "name"
                "id"
                "content"
                "author"
            ]
            constructor:(data)->
                super(data)
        archive = new Archive()
        archive.has("name") or throw new Error "declare should works"
        
        archive = new Archive({name:"leaf.js",id:1,content:"doc",author:"miku"})
        archive.data.name is "leaf.js" or throw new Error "init the first element should work"
        archive.get("name") is "leaf.js" or throw new Error "model.get should works"
        archive.data.id is 1 or throw new Error "fail to set data at init"
        archive.get("id") is 1 or throw new Error "fail to set data at init"

        archive.data = {name:"leaf.js.2"}
        archive.data.name is "leaf.js.2" and
        archive.data.id is 1 and
        archive.author is "miku" or
        throw new Error "fail to set data directly"
        done()
    it "test defaults",(done)->
        class Person extends Leaf.Model
            fields:{
                name:null
                ,sex:"female"
                ,avatar:"miku"
            }
        person = new Person()
        person.data.name is null and
        person.data.sex is "female" and
        person.avatar is "miku" or throw new Error "fail to set defaults"
        
        done()
    
    it "test preset/undo",(done)->
        class Archive extends Leaf.Model
            fields:{
                hasRead:false
            }

        archive = new Archive
        
        archive.data.hasRead is false or throw new Error "fail to set fields"
        archive.preset "hasRead",true
        archive.data.hasRead is true or throw new Error "fail to preset"
        archive.undo "hasRead"
        archive.data.hasRead is false or throw new Error "fail to undo"
        
        archive.preset "hasRead",true
        archive.confirm "hasRead"
        archive.undo "hasRead"
        archive.data.hasRead is true or throw new Error "fail to confirm value"
        done()
    it "test to json",(done)->
        class Archive extends Leaf.Model
            fields:{
                title:"untitled"
                ,content:"empty"
                ,author:"miku"
            }
        archive = new Archive
        json = archive.toJSON {fields:["title","content"]}
        Object.keys(json).length is 2 and
        json.title is "untitled" and
        json.content is "empty" or throw new Error "toJSON failed"
        done()
    it "test event",(done)->
        class Archive extends Leaf.Model
            fields:{
                hasRead:false
                ,star:false
            }
        archive = new Archive()
        readChanged = 0
        starValue = 0
        change = 0
        archive.on "change/hasRead",()->
            readChanged++
        archive.on "change/star",(value)->
            starValue = value
        archive.on "change",()->
            change++
        archive.data.hasRead = false
        archive.data.hasRead = true
        archive.star = true

        change is 2 and readChanged is 1 and starValue is true or throw new Error "change event failed"
        done()
describe "test collection",()->
    it "basic tests",(done)->
        class ArchiveList extends Leaf.Collection
            constructor:()->
                super()
                @setId "id"
        class Archive extends Leaf.Model
            fields:["id","title","content","author"]
        a1 = new Archive {id:1,title:"tutorial",content:"foo and bar",author:"miku"}
        a2 = new Archive {id:2,title:"tutorial2",content:"foo and bar2",author:"miku"}
        col = new ArchiveList()
        col.add a1
        col.add a2

        col.length is 2 and
        col.contain(a1) and
        col.contain(a2) and
        col.contain(a1.data.id) or throw new Error "collection fails"

        col.findOne({author:"miku"}).data.title is "tutorial" or throw new Error "fail to find one"
        col.find({author:"miku"}).length is 2 or throw new Error "fail to call collection.find"
        col.remove(a1) and col.length is 1 or throw new Error "fail to remove item"
        col.empty() and col.length is 0 or throw new Error "fail to empty collection"
        done()
    it "test events",(done)->
        col = new Leaf.Collection()
        model = new Leaf.Model()
        model.declare "value","id"
        col.add model

        changeModel =false
        changeValue = false
        col.on "change/model",(_model)->
            if _model isnt model
                throw new Error "fail to listen change model"
            changeModel = true
        col.on "change/model/value",(model,k,v)->
            changeValue = true
            k is "value" and v is 1 or throw new Error "change fails"
        model.data.value = 1
        changeModel and changeValue or throw new Error "collection events fails"
        done()
    