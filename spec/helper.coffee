global.LIBS_PATH = "#{__dirname}/../lib"


chai = require 'chai'
chai.should()
global.expect = chai.expect
global.sinon = require 'sinon'


