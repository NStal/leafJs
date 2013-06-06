# Widget
##constructor
parameter:template

Template can be a snippet of HTML template consist of a single root node or serveral node, or an css id like "#myid".

When construct from #myid ,the widget is attached to the #myid element in the dom tree.


##appendTo(target)
parameter:Widget or HTMLDOMElement

append widget to target

##prependTo(target)
parameter:widget or HTMLDOMElement

prepend widget to target

## replace(target)
parameter:Widget or HTMLDOMElement

replace target with the widget

## remove()
remove the widget

## after(target)
parameter:Widget or HTMLDOMElement
place widget after the target

## before(target)
parameter:Widget or HTMLDOMElement
place widget before the target

## occupy(target)
parameter:Widget or HTMLDOMElement
clear the content of target and append widget to the target



## Widget Event
Widget emit "widget" when a widget is created
Some effect libraries can be invoked here
```javascript
Widget.on("widget",function(widget){
	..apply effect
})
```
