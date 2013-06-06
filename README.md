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
username:string means username must be an string.
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

