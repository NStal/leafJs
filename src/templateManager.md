#TemplateManager
templateManager is used to  manipulate the HTML snippet.
The TemplateManager will try to get the templates in several procesures below:
1.Try to get templates from current content DOM
      a) Extract the content from <noscript id='leaf-templates' type='text/json'></noscript>  as an json ,then consider it as the collection of the templates then TemplateManager.templates = noScriptJson.
      b) Extract the content from <noscript data-tid='id' data-type='template'></noscript> as plain HTML snippet.than assambled togather into an object.The data-tid is specified by TemplateManager.want(tid).The format of an tid should be like "path/path/widgetname", because when data-tid matched what we want,TemplateManager will try to 
2.Try to get templates from server by sending XHR requests to {TemplateManager.baseUrl+tid} to fetch each template.

It's the convinience of development and efficiency for production.You can choose to compile all templates into the HTML or just do real-time fetching for fast development or real-time update.

#example
```javascript
var templateManager = new Leaf.TemplateManager();
templateManager.use([
	"timeline"
	,"setting-panel"
])
//settings .baseUrl and .suffix will help change default fetch url
//see explanation below
//templateManager.baseUrl = "mypath/";
//templateManager.suffix = ".html";
//templateManager.timeout = 5000 ;
templateManager.ready(function(allTemplates){
	console.log(allTemplates)
});
```
In above exampe, TemplateManager will :

1.Try to find noscript with id="leaf-templates" as a Json.And checking is leafTemplates["timeline"] and leafTemplates["setting-panel"] are there,then trigger the "ready" event;This is the case when templates is compiled in to the html. 

2.If any of required templates are not found in json, then try to find noscript with id="leaf-template-tid" for the missing one or two in this example.If both of them are found,then trigger the "ready" event.This is for easy development. You can directly write snippet in the current working html.

3.If any of required templates are not found in <2> .An XHR request will be fired for each template missing.XHR is all fired at once in these version.And the target URL is format like "{TemplateManager.baseURL}/{tid}{TemplateManager.suffix}" which in example may be "template/timeline.html".If all XHR is complete successfully,Then ready will be triggered and response of the XHR is directly used as template for each {tid} without any modification.

4.If any failed again,finally an error was emit(as an event);