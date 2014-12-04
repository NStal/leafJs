describe "test template manager",()->
    it "test load nested template",(done)->
        tm = new Leaf.TemplateManager()
        tm.use "parent/child"
        tm.start()
        tm.on "ready",(templates)->
            console.log templates
            done()
