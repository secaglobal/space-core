Router = require "#{LIBS_PATH}/router"
WebAPI = require "#{LIBS_PATH}/web-api"

class TestAPI extends WebAPI


describe '@Router', () ->
    beforeEach () ->
        this._res = send: () -> true
        this._req = isLoggedIn: false

        sinon.spy WebAPI.prototype, 'execute'

    afterEach () ->
        WebAPI.prototype.execute.restore()

    describe '#makeHandler', () ->
        it 'should execute action', () ->
            new Router().makeHandler('action', WebAPI)(this._req, this._res)
            expect(WebAPI.prototype.execute.called).be.ok
            expect(WebAPI.prototype.execute.calledWith('action')).be.ok
