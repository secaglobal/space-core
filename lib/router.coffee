fs = require 'fs'
Response = require './response'

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
            new controller(params, new Response(res, output), req).execute(action)

    processControllers: (dir, prefix = '/') ->
        @_readControllersDir dir, prefix

    route: (pattern, action, controller, method = 'get', output = 'FULL') ->
        @_app[method] pattern, @makeHandler(action, controller, output)

    _processController: (prefix, path) ->
        cont = require(path)
        actoins = cont.prototype
        map = cont.map or {}

        for method, conf of map
            @route conf.pattern or "#{prefix}/#{method}", method, cont, conf.method or 'get'

        #html
        @route "#{prefix}", 'index', cont, 'get', 'HTML' if not map.index? and actoins.index?
        @route "#{prefix}/new", 'new', cont, 'get', 'HTML' if not map.new? and actoins.new?
        @route "#{prefix}/:id/edit", 'edit', cont, 'get', 'HTML' if not map.edit? and actoins.edit?

        #api - json
        @route "#{prefix}/list", 'list', cont, 'get' if not map.list? and actoins.list?
        @route "#{prefix}", 'create', cont, 'post' if not map.create? and actoins.create?
        @route "#{prefix}/:id", 'show', cont, 'get' if not map.show? and actoins.show?
        @route "#{prefix}/:id", 'update', cont, 'put' if not map.update? and actoins.update?
        @route "#{prefix}/:id", 'delete', cont, 'delete' if not map.delete? and actoins.delete?

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