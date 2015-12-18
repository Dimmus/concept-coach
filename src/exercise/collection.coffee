EventEmitter2 = require 'eventemitter2'
api = require '../api'
steps = {}

user = require '../user/model'
user.channel.on 'change', ->
  steps = {}

channel = new EventEmitter2 wildcard: true

quickLoad = (stepId, data) ->
  steps[stepId] = data
  channel.emit("quickLoad.#{stepId}", {data})

load = (stepId, data) ->
  steps[stepId] = data
  channel.emit("load.#{stepId}", {data})

update = (eventData) ->
  {data} = eventData
  load(data.id, data)

fetch = (stepId) ->
  eventData = {data: {id: stepId}, status: 'loading'}

  channel.emit("fetch.#{stepId}", eventData)
  api.channel.emit("exercise.#{stepId}.send.fetch", eventData)

getCurrentPanel = (stepId) ->
  step = steps[stepId]
  panel = 'free-response'
  if step?.correct_answer_id?
    panel = 'review'
  else if step?.free_response?
    panel = 'multiple-choice'
  panel

get = (stepId) ->
  steps[stepId]

init = ->
  api.channel.on("exercise.*.receive.*", update)

module.exports = {fetch, getCurrentPanel, get, init, channel, quickLoad}
