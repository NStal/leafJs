#ApiManager is used to manipulate server api invoke.
APIdefination:
```
name[@url][#method][$body]
```
@url if omitted is equal to ApiManager.path+'name'+ApiManager.suffix;. ApiManager.path default is "api/", suffix is "".defaultMethod is get.

#Usage
```javascript
//suppose current page is /index.html.
var api = new ApiManager();

api.declare("logout");
//Send "GET /api/logout"
api.logout().response(function(err,data){
	//err is not null if network error happend
	//data will be an Object if response content-type
	//is text/json else an string
	...
})
//use placeholder to hold for parameters
api.declare("login@auth/login.php?username={username}&secret={secret}");
//Send GET /auth/login.php?username=NStal&secret=123456
api.login("NStal","123456").response(...);

//call use function parameters to call API directly may be tricky
//under some situation
api.declare("defaultSignup@auth/signup?username={username}&secret={secret}&group={username}");

api.defaultSignup("NStal","123456") //still works
//{username} came earler than {secret}
//so "NStal" is interpreted as username and "123456" as secret
//but preferred
api.defaultSignup({username:"NStal",secret:"123456"})

//omitted parameters will be placed with "" in some situation
api.defaultSignup({username:"NStal"})//it's ok secret=""
api.defaultSignup("username")//will rise an error "Invalid parameters". as well as
api.defaultSignup({})//this will rise an error too.
api.defaultSignup()//this is OK.

//when all arguments is supplied with exact count and first arguments is string or number, then first way is used;
//when first argument is an Object and has at least one required parameter,than interpreted as second way
//otherwise, rise an error


//restful style
api.declare("getArticleById@article/{id}#GET")
api.declare("deleteArticleById@article/{id}#DELETE")
api.declare("createArticle@article#POST")
api.declare("updateArticle@article/{id}#PUT")

//{placeholder} style place holder can also be used in request-body
api.declare("updateArticle@article/{id}#PUT$content={content}")


```