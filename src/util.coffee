Util = {}
# judge is template is an HTMLDOMElement
# from:http://stackoverflow.com/questions/384286/javascript-isdom-how-do-you-check-if-a-javascript-object-is-a-dom-object
Util.isHTMLElement = (template) ->
    if typeof HTMLElement is "object" and template instanceof HTMLElement or (template and typeof template is "object" and template.nodeType is 1 and typeof template.nodeName is"string" )
        return true
    return false
Util.isHTMLNode = (o) ->
    return (typeof Node is "object" and o instanceof Node ) or o and typeof o is "object" and typeof o.nodeType is "number" and typeof o.nodeName is "string"
Util.isMobile = ()->
    if navigator and navigator.userAgent
        return (navigator.userAgent.match(/Android/i) or navigator.userAgent.match(/webOS/i) or navigator.userAgent.match(/iPhone/i) or navigator.userAgent.match(/iPad/i) or navigator.userAgent.match(/iPod/i) or navigator.userAgent.match(/BlackBerry/i) or navigator.userAgent.match(/Windows Phone/i)) and true
    else
        return false 
Util.getBrowserInfo = ()->
    N= navigator.appName
    ua= navigator.userAgent
    M= ua.match(/(opera|chrome|safari|firefox|msie)\/?\s*(\.?\d+(\.\d+)*)/i);
    tem= ua.match(/version\/([\.\d]+)/i)
    if M and tem isnt null
         M[2]= tem[1]
    M= `M ? [M[1],M[2]] : [N, navigator.appVersion, '-?']`
    return {name:M[0],version:M[1],mobile:Util.isMobile()}
Util.browser = Util.getBrowserInfo()
Util.capitalize = (string)-> string.charAt(0).toUpperCase() + string.slice(1);
Util.clone = (x,stack = [])-> 
    if x is null or x is undefined
        return x;
    if typeof x.clone is "function"
        return x.clone();
    if x in stack
        throw new Error "clone recursive object"
    stack.push x
    if x instanceof Array
        r = [];
        for item in x
            r.push Util.clone(item,stack)
        return r; 
    if typeof x is "object"
        obj = {}
        for prop of x
            obj[prop] = Util.clone(x[prop],stack)
        return obj
    return x;
Util.compare = (x,y)->
    if x is y
        return true
    
    if x instanceof Array and y instanceof Array
        if x.length isnt y.length
            return false
        for item,index in x
            if not Util.compare item,y[index]
                return false
        return true
    for p of y 
        if typeof x[p] is 'undefined' then return false; 
    for p of y 
        if y[p] 
            switch typeof y[p] 
                when 'object'
                    if not Util.compare(y[p],x[p]) then return false
                when 'function' 
                    if typeof x[p] is 'undefined' or (p isnt 'equals' and y[p].toString() isnt x[p].toString()) 
                        return false;
                else
                    if y[p] isnt x[p] then return false
        else if x[p]
            return false; 
    for p in x
        if typeof(y[p]) is 'undefined' then return false
    return true


Leaf.Util = Util
Leaf.EventEmitter = EventEmitter