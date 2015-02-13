chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'lastfm', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/lastfm')(@robot)

  it 'registers a respond listener for artist info', ->
    expect(@robot.respond).to.have.been.calledWith(/artist info (.*)/i)

  it 'registers a respond listener for find artist', ->
    expect(@robot.respond).to.have.been.calledWith(/find artist (.*)/i)

  it 'registers a respond listener for get concert', ->
    expect(@robot.respond).to.have.been.calledWith(/get concert.?(\S+)?$/i)

  it 'registers a respond listener for whats hot in X', ->
    expect(@robot.respond).to.have.been.calledWith(/(?:what.*hot.*in\s([\w\s]*)(?:\,([\w\s]*))?)$/i)

  it 'registers a respond listener for top 10 me', ->
    expect(@robot.respond).to.have.been.calledWith(/top (10|ten) me/i)

  it 'registers a respond listener for whats playing', ->
    expect(@robot.respond).to.have.been.calledWith(/(what'?s playing?\??|song me|what are we listening to?\??|whats on|what is this|playing)/i)


