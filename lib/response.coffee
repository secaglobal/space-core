class Response
    res: null,
    output: 'FULL',
    _defaultOutput: 'full'
    _handlers:
        JSON: [],
        FULL: [],
        HTML: []

    constructor: (@res, output = 'FULL') ->
        @output = output.toUpperCase()

    cookie: () -> @res.cookie.apply @res, arguments,

    setHeader: () -> @res.set.apply @res, arguments,

    getHeader: () -> @res.get.apply @res, arguments,

    render: (params, fn) ->
        fn @_prepareCallback(@renderParams), params if fn?
        @renderParams @output, params unless fn?
        @["render#{@output.toUpperCase()}"]()

    error: (@_error, @_errorDetails) ->
        @

    _prepareCallback: (fn)->
        _this = @
        ()->
            fn.apply _this, arguments

    renderParams: (output) ->
        @_handlers[output.toUpperCase()] = Array.prototype.slice.call arguments, 1

    renderJSON: () ->
        @res.send @_handlers[@output] or @_handlers.JSON[0]

    renderFULL: () ->
        res = status: !@_error
        res.error = @_error if @_error
        res.errorDetails = @_errorDetails if @_errorDetails
        res.response = @_handlers[@output][0] || {} if res.status

        @res.send res or @_handlers.FULL[0]

    renderHTML: () ->
        [template, params] = @_handlers[@output]
        @res.render template or @_handlers.HTML[0], params or @_handlers.HTML[1] or {}

module.exports = Response