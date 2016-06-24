class Trait
    constructor:(target = {},params...)->
        blacklist = ["constructor","initialize"]
        for prop of this
            if (@__proto__.hasOwnProperty(prop) or @hasOwnProperty(prop)) and prop not in blacklist
                if typeof target[prop] isnt "undefined"
                    throw new Error "Conflict Trait property for #{target.constructor.name}.#{prop}"
                else
                    if typeof @[prop] is "function"
                        target[prop] = @[prop]
                    else
                        target[prop] = Util.clone(@[prop])
        if @initialize
            @initialize.apply(target,params)
        return target
Leaf.Trait = Trait
