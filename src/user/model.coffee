_ = require 'underscore'
React = require 'react'
EventEmitter2 = require 'eventemitter2'
Course = require '../course/model'
api = require '../api'

BLANK_USER =
  is_admin: false
  is_content_analyst: false
  is_customer_service: false
  name: null
  profile_url: null
  courses: []

User =
  isLoaded: false
  channel: new EventEmitter2 wildcard: true

  update: (data) ->
    _.extend(this, data.user)
    @courses = _.compact _.map data.courses, (course) -> new Course(course) if course.is_concept_coach
    @channel.emit('change')

  get: ->
    @

  getCourse: (collectionUUID) ->
    _.findWhere( @courses, ecosystem_book_uuid: collectionUUID )

  findOrCreateCourse: (collectionUUID) ->
    @getCourse(collectionUUID) or (
      course = new Course(ecosystem_book_uuid: collectionUUID)
      @courses.push(course)
      course
    )

  ensureStatusLoaded: (force = false) ->
    api.channel.emit('user.status.send.fetch') if force or not @isLoggedIn()

  isLoggedIn: ->
    !!@profile_url

  onCourseUpdate: (course) ->
    @channel.emit('change')
    @ensureStatusLoaded(true) # re-fetch course list from server


  urlForLogin:  -> @_urlWithReturn('login')
  urlForLogout: -> @_urlWithReturn('logout')

  _urlWithReturn: (type) ->
    self = encodeURIComponent(window.location.href)
    @endpoints[type] + '?parent=' + self

  removeCourse: (course) ->
    index = @courses.indexOf(course)
    @courses.splice(index, 1) unless index is -1
    @channel.emit('change')

  _signalLogoutCompleted: ->
    _.extend(this, BLANK_USER)
    @isLoggingOut = true
    @channel.emit('logout.received')

  init: ->
    api.channel.on 'user.status.receive.*', ({data}) ->
      User.isLoaded = true

      if data.access_token
        api.channel.emit('set.access_token', data.access_token)
      User.endpoints = data.endpoints
      if data.user
        User.update(data)
      else
        _.extend(this, BLANK_USER)
        User.channel.emit('change')

  destroy: ->
    User.channel.removeAllListeners()

    _.each @courses, (course) ->
      course.channel.removeAllListeners()

    delete @courses


# start out as a blank user
_.extend(User, BLANK_USER)


module.exports = User
