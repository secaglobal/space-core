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

        it 'should transmit all required params in required order', () ->
            req =
                send: () -> true,
                params: {param1: 4, param5: 4},
                body: {param1: 3, param4: 3},
                query: {param1: 2, param3: 2},
                cookies: {param1: 1, param2: 1}
                files: {file1: 1, file2: 2}

            expectsParams = {
                param1: 4,
                param2: 1,
                param3: 2,
                param4: 3,
                param5: 4,
                uploadedFiles: {file1: 1, file2: 2}
            }

            new Router().makeHandler('action', WebAPI)(req, this._res)
            expect(WebAPI.prototype.execute.firstCall.thisValue.params).be.deep.equal expectsParams

