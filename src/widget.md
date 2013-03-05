# Widget
Widget stand for a part of UI interface,compose with a snippet of HTML with ONLY ONE root element node.
After init from an Element or a string of HTML snippet,We can directly access the sub elements with data-id attached

```javascript
var w = new Widget("<div><span data-id='myid'>Hello</div>")
console.log(w.controls.myid); //an HTML Elment
console.log(w.controls.$myid); //Jquery Object(or what ever $ is) of the myid elements

```