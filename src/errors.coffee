Util.createError = (name,args...)->
    args = args.filter (item)->item
    meta = {}
    if args.length is 0
        BaseError = Error
        meta = {}
    else if args.length is 1
        if args[0] instanceof Error
            BaseError = args[0]
            meta = {}
        else
            BaseError = Error
            meta = args[0]
    else if args.length is 2
        if args[0] instanceof Error
            BaseError = args[0]
            meta = args[1]
        else
            BaseError = args[1]
            meta = args[0]
    else
        BaseError = Error
    console.debug BaseError,Error
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
        @errors[name] = Util.createError(name,base,meta)
        return this
    generate:()->
        return @errors
    @create = ()->
        return new ErrorFactory()
Leaf.ErrorFactory = ErrorFactory