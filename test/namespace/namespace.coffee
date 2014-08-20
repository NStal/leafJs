## require style.less
## require root.html as pageRootTemplate
## require header.html as headerTemplate
## require footer.html as footerTemplate

class PageRoot extends Leaf.Widget
    constructor:()->
        @header = new PageHeader()
        @footer = new PageFooter()
        super pageRootTemplate

class PageHeader extends Leaf.Widget
    constructor:()->
        super headerTemplate
    setContent:(text)->
        @node$.text "header:"+text
class PageFooter extends Leaf.Widget
    constructor:()->
        super(footerTemplate)
        
    setContent:(text)->
        @node$.text "footer:"+text
class CurrentTimeLabel extends Leaf.Widget
    @public = true
    constructor:(template,option = {})->
        super(template)
        @expose "color"
        @update()
        @start()
    onSetColor:(color)->
        @color = color
        @node$.css({color:color})
    start:()->
        @timer = setInterval @update.bind(this),100
    update:()-> 
        @node$.text new Date()
    stop:()->
        clearTimeout @timer

Leaf.ns.register PageRoot
Leaf.ns.register PageFooter
Leaf.ns.register PageHeader
Leaf.ns.register CurrentTimeLabel

window.TEST.register ()->
    root = new PageRoot()
    root.appendTo document.body
    root.UI.header$.css({backgroundColor:"blue"})
    root.UI.timer.color = "pink"
