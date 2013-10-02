Q = require 'q'

class WebAPI
    @ACCESS__DENIED: 1
    @ACCESS__GUEST: 2
    @ACCESS__CLIENT: 4
    @ACCESS__ALL: 6

    @METHOD__GET: 'GET'
    @METHOD__POST: 'POST'

    @map: {}

    constructor: (@params, @response, @request) ->
        @self = @constructor

    isAccessAllowed: (action) ->
        return false if not @[action]?

        map = @self.map or {}
        access = WebAPI.ACCESS__ALL
        access = map[action].access if map[action] and map[action].access

        return false if access & WebAPI.ACCESS__DENIED
        return true if not @request.isLoggedIn?
        return true if access & WebAPI.ACCESS__CLIENT and @request.isLoggedIn
        return true if access & WebAPI.ACCESS__GUEST and not @request.isLoggedIn
        return false

    route: (action) ->
        return action

    execute: (action) ->
        action = @route action
        if not @isAccessAllowed(action)
            return @response.error('ACCESS_DENIED').render()

        try
            res = @[action](@params, @response, @request)
            res.fail @_renderErrorResponse.bind(@) if Q.isPromiseAlike res
        catch err
            @_renderErrorResponse(err)

    _renderErrorResponse: (err) ->
        @response.error(err.code || err.message || err).render()

module.exports = WebAPI