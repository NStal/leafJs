((Leaf)->
    class Router extends Leaf.EventEmitter
        constructor:()->
            @routes = []
        add:(path,callback)->
            if typeof path isnt "string" or typeof callback isnt "function"
                throw new Error "Route.add need path:string and callback:function as parameter"
            
            @routes.push new Route(path,callback)
        route:(url)->
            for route in @routes
                info = route.match(url)
                if info
                    route.callback(info)
        monitorHash:()->
            window.onhashchange = ()=>
                @applyRouteByHash()
        applyRouteByHash:()->
            @route window.location.hash.replace("#","")
    class Route extends Leaf.EventEmitter
        constructor:(path,callback)->
            console.assert typeof path is "string"
            console.assert typeof callback is "function"
            @path = path
            @callback = callback
            @sensitive = false
            @strict = false
            @parser = @getParser(path)
        match:(url)->
            matches = @parser.regexp.exec url
            if not matches 
                return null
            params = {}
            for key,index in @parser.keys
                params[key] = matches[index+1]
            return {url:url,params:params}

        getParser:(path)->
            strict = @strict
            sensitive = @sensitive
            keyParser = /(\/)?:(\w+)/g
            keys = []
            pathRegStr = path.concat(strict and "" or "/?")
            pathRegStr = pathRegStr.replace keyParser,(_,slash,key)->
                keys.push key
                slash = slash or ""
                return "(?:{slash})([^/]+)".replace("{slash}",slash)
            #escape \/.
            pathRegStr = pathRegStr.replace /[\/.*]/g,"\\$&"
            pathReg = new RegExp("^#{pathRegStr}$",sensitive and "" or "i")
            return {regexp:pathReg,keys:keys}
    Leaf.Router = Router
)(this.Leaf)