Util.createError = (name,args...)->
    args = args.filter (item)->item
    meta = {}
    BaseError = Error
    if args[0] and args[0].prototype and  Error.prototype.isPrototypeOf(args[0].prototype)
        BaseError = args[0]
        if typeof args[1] is "object"
            meta = args[1]
    else if args[0] and typeof args[0] is "object"
        meta = args[0]
    class CustomError extends BaseError
        @name = name
        constructor:(message,props = {})->
            super(message)
            @name = name
            @message = message or meta.message or props.message or name
            for prop of meta
                if meta.hasOwnProperty prop
                    @[prop] = meta[prop]
            for prop of props
                if props.hasOwnProperty prop
                    @[prop] = props[prop]
        name:name
    return CustomError
class ErrorFactory
    constructor:()->
        @errors = {}
    define:(name,base,meta)->
        if typeof base is "string"
            if not @errors[base]
                throw new Error "base error #{base} not found"
            else
                base = @errors[base]
        @errors[name] = Util.createError(name,base,meta)
        return this
    generate:()->
        return @errors
    @create = ()->
        return new ErrorFactory()
Leaf.ErrorFactory = ErrorFactory
