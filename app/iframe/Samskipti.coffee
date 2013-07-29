root = this

# Define functions we can call on the child here.
functions = [ 'apps', 'imtables' ]

# My name is Skipti... Sam Skipti.
module.exports = class Samskipti

    # Prefix string for callbacks that get fake serialized.
    prefix: '__function__'

    constructor: (name, opts, cb) ->
        self = @

        # A new Sam is born!
        self.id = 'Samskipti::' + name

        # Error handler? Just throw it.
        cb = ( (err) -> throw err ) unless _.isFunction cb
        @err = (err) -> cb self.id + ' ' + err

        # Init the id counter.
        self.idCounter = 0

        # Build an internal channel.
        self.channel = root.Channel.build opts

        # Init our fn maps.
        self.invoke = {}
        self.listenOn = {}
        self.callbacks = {}

        # We know these functions...
        for fn in functions.concat [ self.prefix ] then do (fn) ->
            # We can invoke them.
            self.invoke[fn] = (opts...) ->
                # So we can make sure the other side got all of the callbacks.
                callbacks = []
                # Replace function callbacks.
                defunc = (obj) ->
                    if _.isFunction obj
                        # This is your new id.
                        callbacks.push id = self.prefix + ++self.idCounter
                        # Save the fn callback.
                        self.callbacks[id] = obj
                        # Return the handle.
                        return id
                    else
                        # Iterate over it.
                        if _.isArray obj
                            return obj.map defunc
                        if _.isObject obj
                            ( obj[key] = defunc(value) for key, value of obj )
                            return obj
                    
                        # Hopefully can get serialized.
                        return obj

                # Defunctionalize the params and serialize them (aka my god you stupid zilla people).
                json = JSON.stringify defunc opts

                # Make the actual call.
                self.channel.call
                    'method': fn
                    'params': [ json ]
                    'success': (thoseCallbacks) ->
                        # Trouble?
                        self.err 'Not all callbacks got recognized' unless _.areArraysEqual callbacks, thoseCallbacks
                    # Needs to be defined or things go pear shaped.
                    'error': (type, message) ->
                        console.log arguments
                        self.err(message)

            # We listen to them.
            self.channel.bind fn, (trans, [ json ]) ->
                # So we can tell the sender we got it.
                callbacks = []
                # Do we need to construct any callbacks on our end?
                makefunc = (obj) ->
                    # Iterate over it.
                    if _.isArray obj
                        return obj.map makefunc
                    if _.isObject obj
                        ( obj[key] = makefunc(value) for key, value of obj )
                        return obj

                    # Maybe a cb?
                    if _.isString obj
                        if obj.match new RegExp '^' + self.prefix + '\\d+$'
                            # New callback then.
                            callbacks.push obj
                            # When we get called...
                            return ->
                                # ... call the fn over the channel.
                                self.invoke[self.prefix].apply(null, [ 'call::' + obj, arguments ])

                    # A proper good value.
                    return obj

                # Can we exec locally?
                if self.listenOn[fn] and _.isFunction self.listenOn[fn]
                    # Functionalize.
                    self.listenOn[fn].apply null, makefunc(JSON.parse(json))
                    # Return back the list of callbacks.
                    return callbacks

                # Trouble.
                self.err "Why u no define `#{fn}`?"


        # Dogfooding the callbacks.
        @listenOn[self.prefix] = (call, obj) ->
            # We better be a call.
            if _.isString(call) and matches = call.match new RegExp '^call::(' + self.prefix + '\\d+)$'
                # Do we know it?
                if (fn = self.callbacks[matches[1]]) and _.isFunction fn
                    # Convert args.
                    args = ( value for key, value of obj )

                    # Invoke.
                    fn.apply(null, args)
                    return

                # Trouble.
                return self.err "Unrecognized function `#{matches[1]}`"
            
            # Trouble.
            self.err 'Why `call` malformed?'

# Mini Underscore.
_ = {}

# Returns a sorted list of the names of every method in an object - that
#  is to say, the name of every function property of the object.
_.functions = (obj) -> ( key for key of obj when _.isFunction obj[key] )

# Retrieve the values of an object's properties.
_.values = (obj) -> ( obj[key] for key of obj when Object::hasOwnProperty.call(obj, key) )

# Returns true if object is a `type`.
for type in [ 'Function', 'Array', 'String' ] then do (type) ->
    _["is#{type}"] = (obj) -> Object::toString.call(obj) is "[object #{type}]"

_.isObject = (obj) -> obj is Object obj

_.areArraysEqual = (a, b) -> not (a < b or b < a)
