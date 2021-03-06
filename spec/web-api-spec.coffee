Q = require 'q'
WebAPI = require "#{LIBS_PATH}/web-api"
Response = require "#{LIBS_PATH}/response"
Exception = require "#{LIBS_PATH}/exception"

class TestAPI extends WebAPI
    @map:
        publicAction: {access: WebAPI.ACCESS__ALL, method: WebAPI.METHOD__POST},
        clientAction: {access: WebAPI.ACCESS__CLIENT},
        guestAction: {access: WebAPI.ACCESS__GUEST},
        deniedAction: {access: WebAPI.ACCESS__DENIED | WebAPI.ACCESS__ALL}

    setDeferred: (@deferred) ->

    publicAction: () -> true
    clientAction: () -> true
    guestAction: () -> true
    deniedAction: () -> true
    exceptionAction: () -> throw new Exception 'CODE', 'Comments'
    stringExceptionAction: () -> throw 'CODE'
    systemExceptionAction: () -> throw new Error 'CODE'
    promiseError: () -> @deferred.promise

    route: (action) ->
        if action is 'aliasAction' then 'publicAction' else super


describe '@WebAPI', () ->
    beforeEach () ->
        @deferred = Q.defer()
        @_res = new Response(send: () -> true)
        @_req = {}
        @_contr = new TestAPI({}, this._res, this._req)

        sinon.spy this._contr, 'publicAction'
        sinon.spy this._contr, 'clientAction'
        sinon.spy this._res, 'error'
        sinon.spy this._res, 'render'

    describe '#isAccessAllowed', () ->
        it 'should return false if action is illegal', () ->
            expect(this._contr.isAccessAllowed('fakeAction', {})).be.not.ok

        describe '- authorization not available', () ->
            it 'should return true if authorization not available', () ->
                expect(this._contr.isAccessAllowed('clientAction')).be.ok

            it 'should return false if method denied', () ->
                expect(this._contr.isAccessAllowed('deniedAction')).be.not.ok

        describe '- authorization available', () ->
            describe '- denied methods', () ->
                it 'should return false if user not logged in', () ->
                    this._req.isLoggedIn = false
                    expect(this._contr.isAccessAllowed('deniedAction')).be.not.ok

                it 'should return false if user logged in', () ->
                    this._req.isLoggedIn = true
                    expect(this._contr.isAccessAllowed('deniedAction')).be.not.ok

            describe '- guest methods', () ->
                it 'should return true if user not logged in', () ->
                    this._req.isLoggedIn = false
                    expect(this._contr.isAccessAllowed('guestAction')).be.ok

                it 'should return false if user logged in', () ->
                    this._req.isLoggedIn = true
                    expect(this._contr.isAccessAllowed('guestAction')).be.not.ok

            describe '- client methods', () ->
                it 'should return false if user not logged in', () ->
                    this._req.isLoggedIn = false
                    expect(this._contr.isAccessAllowed('clientAction')).be.not.ok

                it 'should return true if user logged in', () ->
                    this._req.isLoggedIn = true
                    expect(this._contr.isAccessAllowed('clientAction')).be.ok

            describe '- common methods', () ->
                it 'should return true if user not logged in', () ->
                    this._req.isLoggedIn = false
                    expect(this._contr.isAccessAllowed('publicAction')).be.ok

                it 'should return true if user logged in', () ->
                    this._req.isLoggedIn = true
                    expect(this._contr.isAccessAllowed('publicAction')).be.ok

    describe '#route', () ->
        it 'should return same action as received', () ->
            expect(this._contr.route('publicAction', {})).be.equal 'publicAction'

    describe '#execute', () ->
        it 'should get correct action via #route calling', () ->
            this._contr.execute('aliasAction')
            expect(this._contr.publicAction.called).ok

        it 'should close connection if access denied', () ->
            this._contr.execute('deniedAction')
            expect(this._contr.clientAction.called).be.not.ok
            expect(this._res.render.called).be.ok

        it 'should execute action if access allowed', () ->
            this._contr.execute('publicAction')
            expect(this._contr.publicAction.called).be.ok

        it 'should pass correct parameters', () ->
            this._contr.execute('publicAction')
            expect(this._contr.publicAction.calledWith({}, this._res, this._req)).be.ok

        it 'should catch all exceptions and fail request', () ->
            this._contr.execute('exceptionAction')
            expect(@_res.error.calledWith 'CODE').be.ok
            expect(@_res.render.called).be.ok

        it 'should catch all stringified exceptions and fail request', () ->
            this._contr.execute('stringExceptionAction')
            expect(@_res.error.calledWith 'CODE').be.ok
            expect(@_res.render.called).be.ok

        it 'should catch all system exceptions and fail request', () ->
            this._contr.execute('systemExceptionAction')
            expect(@_res.error.calledWith 'CODE').be.ok
            expect(@_res.render.called).be.ok

        it 'should react on fail if returned promise', (done) ->
            this._contr.setDeferred(Q.defer())
            this._contr.execute('promiseError')

            res = @_res
            this._contr.deferred.promise.fin () ->
                try
                    expect(res.error.calledWith 'CODE').be.ok
                    expect(res.render.called).be.ok
                    done()
                catch e
                    done e

            this._contr.deferred.reject new Exception 'CODE', 'Comments'