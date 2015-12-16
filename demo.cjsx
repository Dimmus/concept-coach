ConceptCoachAPI = require './src/concept-coach'

api = require './src/api'
AUTOSHOW = false

SETTINGS =
  STUBS:
    API_BASE_URL: ''
    COLLECTION_UUID: 'C_UUID'
    MODULE_UUID: 'm_uuid'
    CNX_URL: ''
  LOCAL:
    API_BASE_URL: 'http://localhost:3001'
    COLLECTION_UUID: 'f10533ca-f803-490d-b935-88899941197f'
    MODULE_UUID: '7636a3bf-eb80-4898-8b2c-e81c1711b99f'
    CNX_URL: 'http://localhost:8000'
  SERVER:
    API_BASE_URL: 'https://tutor-dev.openstax.org'
    COLLECTION_UUID: 'f10533ca-f803-490d-b935-88899941197f'
    MODULE_UUID: '7636a3bf-eb80-4898-8b2c-e81c1711b99f'
    CNX_URL: 'https://dev.cnx.org'

settings = SETTINGS.LOCAL

loadApp = ->
  unless document.readyState is 'interactive'
    return false

  mainDiv = document.getElementById('react-root-container')
  buttonA = document.getElementById('launcher')
  buttonB = document.getElementById('launcher-other-course')
  buttonC = document.getElementById('launcher-intro')

  demoSettings =
    collectionUUID: settings.COLLECTION_UUID
    moduleUUID: settings.MODULE_UUID
    cnxUrl: settings.CNX_URL

  initialModel = _.clone(demoSettings)
  initialModel.mounter = mainDiv

  conceptCoachDemo = new ConceptCoachAPI(settings.API_BASE_URL)
  conceptCoachDemo.setOptions(initialModel)

  conceptCoachDemo.on 'open', conceptCoachDemo.handleOpened
  conceptCoachDemo.on 'ui.close', conceptCoachDemo.handleClosed

  show = ->
    conceptCoachDemo.open(mainDiv, demoSettings)
    true

  showOtherCourse = ->
    otherCourseSettings =
      collectionUUID: 'FAKE_COLLECTION'
      moduleUUID: 'FAKE_MODULE'
      cnxUrl: settings.CNX_URL

    conceptCoachDemo.open(mainDiv, otherCourseSettings)
    true

  showIntro = ->
    introSettings = _.extend({}, demoSettings, moduleUUID: 'e98bdaec-4060-4b43-ac70-681555a30e22')

    conceptCoachDemo.open(mainDiv, introSettings)
    true

  conceptCoachDemo.displayLauncher(buttonA)

  buttonB.addEventListener 'click', showOtherCourse
  buttonC.addEventListener 'click', showIntro

  conceptCoachDemo.on 'ui.launching', show

  # Hook in to writing view updates to history api
  conceptCoachDemo.on 'view.update', (eventData) ->
    if eventData.route isnt location.pathname
      history.pushState(eventData.state, null, eventData.route)

  # listen to back/forward and broadcasting to coach navigation
  window.addEventListener 'popstate', (eventData) ->
    conceptCoachDemo.updateToRoute(location.pathname)


  window.addEventListener 'resize', (eventData) ->
    conceptCoachDemo.handleResize()

  # open to the expected view right away if view in url
  conceptCoachDemo.openByRoute(mainDiv, demoSettings, location.pathname) if location.pathname?

  if AUTOSHOW
    setTimeout( show, 300)
  true

loadApp() or document.addEventListener('readystatechange', loadApp)
