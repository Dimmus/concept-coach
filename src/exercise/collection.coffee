EventEmitter2 = require 'eventemitter2'
api = require '../api'
steps = {}
freeResponseCache = {}

_ = require 'underscore'

user = require '../user/model'

channel = new EventEmitter2 wildcard: true

STEP_TYPES =
  'free-response': ['free_response']
  'multiple-choice': ['answer_id', 'is_completed']

quickLoad = (stepId, data) ->
  steps[stepId] = data
  channel.emit("quickLoad.#{stepId}", {data})

cacheFreeResponse = (stepId, freeResponse) ->
  freeResponseCache[stepId] = freeResponse

load = (stepId, data) ->
  steps[stepId] = data
  delete freeResponseCache[stepId] if data.free_response?
  channel.emit("load.#{stepId}", {data})

update = (eventData) ->
  {data} = eventData
  load(data.id, data)

fetch = (stepId) ->
  eventData = {data: {id: stepId}, status: 'loading'}

  channel.emit("fetch.#{stepId}", eventData)
  api.channel.emit("exercise.#{stepId}.send.fetch", eventData)

getCurrentPanel = (stepId) ->
  panel = 'review'

  step = steps[stepId]
  question = step?.content?.questions?[0]
  return panel unless question?

  {formats} = question

  _.find(STEP_TYPES, (stepChecks, format) ->
    return false unless format in formats
    isStepCompleted = _.reduce(stepChecks, (isOtherCompleted, currentCheck) ->
      step[currentCheck]? and step[currentCheck] and isOtherCompleted
    , true)

    unless isStepCompleted
      panel = format
      true
  )
  panel

get = (stepId) ->
  cachedFreeResponse = freeResponseCache[stepId]
  _.extend {}, steps[stepId], {cachedFreeResponse}

init = ->
  user.channel.on 'logout.received', ->
    steps = {}

  api.channel.on("exercise.*.receive.*", update)

module.exports = {fetch, getCurrentPanel, get, init, channel, quickLoad, cacheFreeResponse}
