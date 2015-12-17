_ = require 'underscore'
$ = require 'jquery'
EventEmitter2 = require 'eventemitter2'
helpers = require '../helpers'

restAPI = require '../api'
componentModel = require './model'
navigation = require '../navigation/model'
User = require '../user/model'
exercise = require '../exercise/collection'
progress = require '../progress/collection'
task = require '../task/collection'

{ModalCoach} = require './modal-coach'
{Launcher} = require './launcher'
modalCoachWrapped = helpers.wrapComponent(ModalCoach)
launcherWrapped = helpers.wrapComponent(Launcher)

PROPS = ['moduleUUID', 'collectionUUID', 'cnxUrl', 'processHtmlAndMath']
WRAPPER_CLASSNAME = 'concept-coach-wrapper'

listenAndBroadcast = (componentAPI) ->
  # Broadcast various internal events out to parent
  restAPI.channel.on 'error', (response) ->
    componentAPI.emit('api.error', response)

  restAPI.channel.on 'user.status.receive.fetch', (response) ->
    componentAPI.emit('user.change', response)

  componentModel.channel.on 'coach.mount.success', (eventData) ->
    componentModel.update(eventData.coach)

    componentAPI.emit('open', eventData)
    componentAPI.emit('view.update', navigation.getDataByView(eventData.coach.view))

  componentModel.channel.on 'coach.unmount.success', (eventData) ->
    componentModel.update(eventData.coach)

    componentAPI.emit('close', eventData)
    componentAPI.emit('view.update', navigation.getDataByView('close'))

  componentModel.channel.on 'close.clicked', ->
    componentAPI.emit('ui.close')

  componentModel.channel.on 'launcher.clicked', ->
    componentAPI.emit('ui.launching')

  navigation.channel.on 'show.*', (eventData) ->
    componentAPI.emit('view.update', navigation.getDataByView(eventData.view))

  navigation.channel.on 'close.for.book', (eventData) ->
    componentAPI.emit('book.update', eventData)

  exercise.channel.on 'component.*', (eventData) ->
    componentAPI.emit("exercise.component.#{eventData.status}", eventData)

setupAPIListeners = (componentAPI) ->
  navigation.channel.on "switch.*", (eventData) ->
    {data, view} = eventData
    componentAPI.update(data)
    navigation.channel.emit("show.#{view}", {view})

  componentAPI.on 'show.*', (eventData) ->
    componentAPI.updateToView(eventData.view)

initializeModels = (models) ->
  _.each models, (model) ->
    model.init?()

stopModelChannels = (models) ->
  _.each models, (model) ->
    model.destroy?() or model.channel?.removeAllListeners?()

deleteProperties = (obj) ->
  for property, value of obj
    delete obj[property] unless _.isFunction(obj[property]) or property is 'channel'
    null

class ConceptCoachAPI extends EventEmitter2
  constructor: (baseUrl, navOptions = {}) ->
    super(wildcard: true)

    _.defaults(navOptions, {prefix: '/', base: 'concept-coach/'})

    restAPI.init = _.partial restAPI.initialize, baseUrl
    navigation.init = _.partial navigation.initialize, navOptions

    @models = [restAPI, navigation, User, exercise, progress, task, componentModel]
    initializeModels(@models)

    listenAndBroadcast(@)
    setupAPIListeners(@)
    User.ensureStatusLoaded(true)

  destroy: ->
    @close?()
    stopModelChannels(@models)
    deleteProperties(@models)
    deleteProperties(componentModel)

    @removeAllListeners()

  setOptions: (options) ->
    isSame = _.isEqual(_.pick(options, PROPS), _.pick(componentModel, PROPS))
    options = _.extend({}, options, isSame: isSame)
    componentModel.update(options)

  displayLauncher: (mountNode) ->
    mountNode.classList.add(WRAPPER_CLASSNAME)
    launcherWrapped.render(mountNode)

  open: (mountNode, props) ->
    props = _.clone(props)
    props.defaultView ?= if componentModel.isSame then componentModel.view else 'task'

    componentModel.update(
      mounter: mountNode
      isSame: true
    )

    modalNode = document.createElement('div')
    modalNode.classList.add(WRAPPER_CLASSNAME)
    mountNode.appendChild(modalNode)

    props.close = ->
      componentModel.channel.emit('close.clicked')
      modalCoachWrapped.unmountFrom(modalNode)
      mountNode.removeChild(modalNode) if modalNode.parentNode is mountNode

    # wait until our logout request has been received and the close
    User.channel.once 'logout.received', ->
      props.close()

    @component = modalCoachWrapped.render(modalNode, props)
    @close = props.close

    @component

  openByRoute: (mountNode, props, route) ->
    props = _.clone(props)
    props.defaultView = navigation.getViewByRoute(route)

    if props.defaultView? and props.defaultView isnt 'close'
      @open(mountNode, props)

  updateToView: (view) ->
    if @component?.isMounted()
      if view is 'close'
        @component.props.close()
      else
        navigation.channel.emit("show.#{view}", {view})
    else if componentModel.mounter? and view isnt 'close'
      props = _.pick(componentModel, PROPS)
      props.defaultView = view
      @open(componentModel.mounter, props)

  updateToRoute: (route) ->
    view = navigation.getViewByRoute(route)
    @updateToView(view) if view?

  update: (nextProps) ->
    return unless @component?
    props = _.extend({}, _.pick(nextProps, PROPS))
    @component.setProps(props)

  handleOpened: (eventData, body = document.body) ->
    body.classList.add('cc-opened')

  handleClosed: (eventData, body = document.body) ->
    body.classList.remove('cc-opened')

  handleError: (error) ->
    channel.emit('error', error)
    console.info(error)

module.exports = ConceptCoachAPI
