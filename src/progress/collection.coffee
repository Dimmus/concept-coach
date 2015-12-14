EventEmitter2 = require 'eventemitter2'
api = require '../api'

local = {}
channel = new EventEmitter2 wildcard: true

apiChannelName = 'courseDashboard'

load = (id, data) ->
  local[id] = data
  channel.emit("load.#{id}", {data})

update = (eventData) ->
  {data} = eventData
  load(data.id, data)

fetch = (id) ->
  eventData = {data: {id: id}, status: 'loading'}

  channel.emit("fetch.#{id}", eventData)
  api.channel.emit("#{apiChannelName}.#{id}.send.fetch", eventData)

get = (id) ->
  local[id]

init = ->
  api.channel.on("#{apiChannelName}.*.receive.*", update)

module.exports = {fetch, get, init, channel}
