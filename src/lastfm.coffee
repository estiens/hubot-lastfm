#
# Description:
#   Commands for the Last.fm API -- note all of our spotify songs
#   get scrobbled to Last.fm
#
# Dependencies:
#   htmlToText
#
# Configuration:
#   HUBOT_LASTFM_APIKEY
#   HUBOT_LAST_FM_USERNAME
#
# Commands:
#   hubot what's playing - returns currently playing song/artist
#   hubot top 10 me - returns top ten artists you've played in the last week
#   hubot what's hot in <city>, <country>(optional) - returns top 10 artists on last.fm for a given locale
#   hubot artist info <artist> - displays a summary of artist info from last.fm
#   hubot get concert <city>(optional) - gets a random concert for a city (default city without argument: Minneapolis)
#   hubot find artist <artist_name> - returns some options for artists that match the given artist name
#
# Author:
#   eric@softwareforgood

htmlToText = require('html-to-text');

USER = process.env.HUBOT_LAST_FM_USERNAME
APIKEY = process.env.HUBOT_LAST_FM_KEY
DEFAULT_CITY = "Minneapolis"
DEFAULT_COUNTRY = "United States"

module.exports = (robot) ->
  robot.respond /(what'?s playing?\??|song me|what are we listening to?\??|whats on|what is this|playing)/i, (msg) ->
    getSong msg

  robot.respond /artist info (.*)/i, (msg) ->
    getArtistInfo(msg, msg.match[1])

  robot.respond /top (10|ten) me/i, (msg) ->
    getTopTrackList msg

  robot.respond /(?:what.*hot.*in\s([\w\s]*)(?:\,([\w\s]*))?)$/i, (msg) ->
    getTheHype msg, msg.match[1], msg.match[2]

  robot.respond /get concert.?(\S+)?$/i, (msg) ->
    getEvents msg, msg.match[1]

  robot.respond /find artist (.*)/i, (msg) ->
    searchForArtist msg, msg.match[1]

getSong = (msg) ->
  msg.http('http://ws.audioscrobbler.com/2.0/?')
    .query(method: 'user.getrecenttracks', user: USER, api_key: APIKEY, format: 'json')
    .get() (err, res, body) ->
      results = JSON.parse(body)
      if results.error
        console.log results.message
        return
      song = results.recenttracks.track[0]
      songString = "#{song.name} by #{song.artist['#text']}"
      if song['@attr']["nowplaying"]
        image = song.image.pop()
        msg.send songString + " -- " + image['#text']
      else
        msg.send "We're not listening to anything right now, but the last song we heard was #{songString}"

getTopTrackList = (msg) ->
  msg.http('http://ws.audioscrobbler.com/2.0/?')
    .query(method: 'user.getweeklyartistchart', user: USER, api_key: APIKEY, format: 'json')
    .get() (err, res, body) ->
      results = JSON.parse(body)
      if results.error
        console.log results.message
        return
      artistHash = {}
      playlist = results.weeklyartistchart.artist
      for n in [0..10]
        artistHash[playlist[n]["name"]] = playlist[n]["playcount"]
      msg.send "Last 7 days"
      for k,v of artistHash
        msg.send "#{k}: #{v} plays"

getArtistInfo = (msg, artist) ->
  msg.http('http://ws.audioscrobbler.com/2.0/?')
    .query(method: 'artist.getInfo', artist: artist, api_key: APIKEY, format: 'json')
    .get() (err, res, body) ->
      results = JSON.parse(body)
      if results.error
        console.log results.message
        if results.message == "The artist you supplied could not be found"
          msg.send "Nope, sorry, couldn't find #{artist}"
        return
      bio = htmlToText.fromString(results.artist.bio.summary)
      bio = bio.replace(/Read more(.*)Last.fm/i,"")
      bio = bio.replace(/\[(.*?)\]/g,"").replace(/[\n\r]+/g, ' ').replace(/\s{2,99}/g, ' ')
      if bio
        msg.send bio
      else
        msg.send "Sorry, I don't have much information on #{artist}, but you might try #{results.artist.url}"

searchForArtist = (msg, artist) ->
  msg.http('http://ws.audioscrobbler.com/2.0/?')
    .query(method: 'artist.search', artist: artist, api_key: APIKEY, format: 'json')
    .get() (err, res, body) ->
      results = JSON.parse(body)
      if results.error
        console.log results.message
        return
      artists = []
      if results.results.artistmatches.artist
        for result in results.results.artistmatches.artist
          artists.push(result.name)
      if artists.length > 2
        artist1_fragment = artists[0]
        artist2_fragment = ", " + artists[1] || ""
        artist3_fragment = " or " + artists[2] || ""
        msg.send "Maybe you meant #{artist1_fragment}#{artist2_fragment}#{artist3_fragment}"
      else if artists.length > 0
        msg.send "I think you are looking for #{artists[0]}"
      else
        msg.send "I'm sorry, I couldn't find any artists like #{artist}"

getTheHype = (msg, metro, country) ->
  country = country || DEFAULT_COUNTRY
  msg.http('http://ws.audioscrobbler.com/2.0/?')
    .query(method: 'geo.getmetrohypeartistchart', metro: metro, country: country, api_key: APIKEY, format: 'json')
    .get() (err, res, body) ->
      results = JSON.parse(body)
      if results.error
        console.log results.message
        return
      artists = results.topartists.artist
      artistArray = []
      for n in [0..10]
        artistArray.push(artists[n]["name"])
      msg.send artistArray.join(", ")

getEvents = (msg, city) ->
  city = city || DEFAULT_CITY
  msg.http('http://ws.audioscrobbler.com/2.0/?')
  .query(method: 'geo.getevents', location: city, api_key: APIKEY, format: 'json')
  .get() (err, res, body) ->
    results = JSON.parse(body)
    if results.error
      console.log results.message
      return
    concerts = results.events.event
    random_concert = concerts[Math.floor(Math.random() * concerts.length)]
    title = random_concert.title
    venue = random_concert.venue.name
    date = random_concert.startDate.replace(/\d+[:]\d+[:]\d+/, "?")
    image = random_concert.image.pop()['#text']
    url = random_concert.url
    msg.send "Why don't you go to #{title} at #{venue} on #{date}
    \n#{url}"
