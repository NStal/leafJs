# Introduction
LeafJs is a modern webapp frame work that provide some useful utils to manipulate HTML widgets and AJAX calls.
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


Or using a string to manipulates.
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
Init widgets using #id or a template string depends on what kind of widget it is. If it's a static element on the page and will always be there(unless hidden),using #id is a good idea, or just using a template string.We will introduce a good string template management scheme later.

Though it can be used as exampled above, we suggest program styles like this (or other class inherit style)
```javascript
function IdCard(){
	Leaf.Widget.call(this,window.templates["id-card"]);
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
or coffee-script
```coffee-script
class IdCard extends Leaf.Widget
	constructor:()->
		super(window.templates["id-card"]);
	init:(data)->
		@UI.name$.text data.text
		@UI.age$.text data.age
		@UI.introduction$.text data.introduction
```
Detailed API can be refered [here](doc/widget.md)

# TemplateManager

```javascript
templateManager = new TemplateManager()
templateManager.use("id-card","id-card-list")
templateManager.start()
templateManager.on("ready",function(templates){
	window.templates = templates
	...init apps with templates["id-card"] or templates["id-card-list"]
})
//if cares
templateManager.on("error",function(){
	...error handling
})
```
Where to store the templates.Templates will be fetched from "./template/name.html" , which is "./template/id-card.html" and "./template/id-card-list.html" in example.
Different baseUrl and suffix can be assigne before start.
```javascript
templateManager.baseUrl = "template/" //or "custom-template/"
templateManager.suffix = ".xhtml"
templateManager.start()
...
```

The templates can also be retrieved from current page or event mixed with the remote one.
Detailed strategy can be refered [here](doc/templateManager.md)

# APIFactory
Declare and manipulated all apis in one place
```javascript
factory = new Leaf.ApiFactory()
factory.path = "my-api/" // default is "api/"
factory.suffix = "" // default is ""
factory.defaultMethod = "POST" //default is "GET"
factory.declare("signup",["username:string","password:string","email:?"])
factory.declare("signin",["username:string","password:string"])
factory.declare("isSignin",[]) 
factory.declare("sync",["data:string","lastSync:number?","lastUpdate:number?"])
window.API = factory.build()
```javascript
declare APIName,[paramname:type(optional),...]

API URL = path+APIName+ suffix
username:string means username must be a string.
email:? means username is optional.
Currently the only supported types are number and string.
And Invoke

```
API.signup("username","password") //OK
API.signup("username","password","test@gmail.com") //OK
API.signup("username","") //OK
API.signup("username",null) //throw Error
```

Callbacks.
```javascript
APIFactory.forceJson = true  // This is default, or only parsed into json when server return content-type:text/json
...
call = API.signup("username","password")
call.response(function(data){
	...
})
call.fail(function(err,detail){
	//server 403/404 503 or network error 
	...
})
```

If server obey this format

success
```
state:true or false
data:request data
```

fail
```
state:false
error:error description
errorCode: error code
```

Callback can be handle like this
```javascript
call = API.isSignin()
//state:true  means request success
//data:false means not sign in
call.success(function(data){
	//data:true or false
	...
})
call.fail(function(err,detail){
	//error handling
})
```

# Util
## EventEmitter
Leaf.Util.EventEmitter or Leaf.EventEmitter
```javascript
em = new EventEmitter()
em.on("event",callback)
em.emit("event",param1,param2...)
```

## Key and KeyEventManager
Leaf.Util.Key
```javascript
window.onclick(function(e){
	if(e.which === Leaf.Util.Key.space){
		...
	}
})
```
Leaf.Util.KeyEventManager
KeyEventManager is used to manipulates hot complicated hotkeys.
TODO:document it
## Other
Leaf.Util.clone and Leaf.Util.compare
```
deep clone and deep compare the object.
```

Leaf.Util.isHTMLElement(node)
Leaf.Util.isHTMLNode(node)
Leaf.Util.isMobile()
Leaf.Util.browser is {name,version}
