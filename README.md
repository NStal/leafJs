# Introduction
LeafJs is an modern webapp frame work that provide some useful utils to manipulate HTML widgets and AJAX calls.
LeafJs supports only modern browser(say firefox and chrome).IE is not tested.
By the way, it's written in [coffee-script](http://coffeescript.org/).

# Ideas
## Widget
Easy UI access
```html
<div class="id-card">
	<div class="name" data-id="name"></div>
	<div class="age" data-id="age"></div>
	<div class="introduction" data-id="introduction"></div>
</div>
```
A widget class can be attached to this html.
```javascript
 idCard = new Leaf.Widget("#idCard")
 idCard.UI.name.innerHTML = "myname"
 //if jquery is installed
 idCard.UI.name$.text("myname")
 //alias
 idCard.UI.$name.text("myname")
 ```
No mather what $ is, Widget.UI.name$ is $(Widget.UI.name).


Or using an string to manipulates.
```javascript

idCardTemplate='<div class="id-card"> <div class="name" data-id="name"></div> <div class="age" data-id="age"></div> <div class="introduction" data-id="introduction"></div> </div>'

idCard = new Leaf.Widget(idCardTemplate)
//using leafjs's method to manipulates
idCard.appendTo(document.body)
//or accessing the root of the widget
document.body.appendChild(idCard.node)
//or if jquery installed
jdCard.node$.appendTo(document.body)
```
Init widgets using #id or an template string depends on what kind of widget it is. If it's an static element on the page and will always be there(unless hidden),using #id is a good idea, or just using a template string.We will introduce a good string template management scheme later.

Though it can be used as exampled, we suggest program style like this (or other class inherit style)
```javascript
function IdCard(){
	Leaf.Widget.call(this,window.templates.idCard);
}
IdCard.prototype = new Leaf.Widget()
IdCard.prototype.init = function(data){
	this.UI.name$.text(data.name);
	this.UI.age$.text(data.age);
	this.UI.introduction$.text(data.introduction);
}
idCard = new IdCard()
idCard.init(data)
```
Detailed API can be refered [here](doc/widget.md)

# TemplateManager

```javascript
templateManager = new TemplateManager()
templateManager.use "id-card","id-card-list"
templateManager.start()
```

