fs = require 'fs'
response = require './response'

class Router
    _app = null

    constructor: (app) ->
        @_app = app

    makeHandler: (action, controller, output = 'FULL') ->
        (req, res)->
            params = {}
            params[param] = value for param, value of req.query
            params[param] = value for param, value of req.params
            params[param] = value for param, value of req.body

            controller = require(controller) if typeof controller is 'string'
            controller[action] params, new response(res, output), req

    processControllers: (dir, prefix = '/') ->
        @_readControllersDir dir, prefix

    route: (pattern, action, controller, method = 'get', output = 'FULL') ->
        @_app[method] pattern, @makeHandler(action, controller, output)

    _processController: (prefix, path) ->
        cont = require(path)

        if not cont.api
            cont.api = {}

        for method of cont
            if not cont.api[method]
                continue

            conf = cont.api[method]
            @route conf.pattern or "#{prefix}/#{method}", method, cont, conf.method or 'get'


        #html
        @route "#{prefix}", 'index', cont, 'get', 'HTML' if cont.index? and 'index' not in cont.api
        @route "#{prefix}/new", 'new', cont, 'get', 'HTML' if cont.new? and 'new' not in cont.api
        @route "#{prefix}/:id/edit", 'edit', cont, 'get', 'HTML' if cont.edit? and 'edit' not in cont.api

        #api - json
        @route "#{prefix}/list", 'list', cont, 'get' if cont.list? and 'list' not in cont.api
        @route "#{prefix}", 'create', cont, 'post' if cont.create? and 'create' not in cont.api
        @route "#{prefix}/:id", 'show', cont, 'get' if cont.show? and 'show' not in cont.api
        @route "#{prefix}/:id", 'update', cont, 'put' if cont.update? and 'update' not in cont.api
        @route "#{prefix}/:id", 'delete', cont, 'delete' if cont.delete? and 'delete' not in cont.api

    _readControllersDir: (path, prefix = '', uri = '') ->
        _this = @
        files = fs.readdirSync path
        files.map (file) ->
            newPath = path + '/' + file
            newUri = uri + prefix + '/' + file
            stat = fs.statSync(newPath)

            _this._readControllersDir newPath, '', newUri if stat.isDirectory()

            _this._processController newUri.replace(/\.(?:js|coffee)$/, ''), newPath \
                if stat.isFile() and /\.(?:js|coffee)$/.test(file)

module.exports = (app) ->
    new Router(app)