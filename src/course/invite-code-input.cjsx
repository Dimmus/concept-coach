React = require 'react'
BS = require 'react-bootstrap'
ENTER = 'Enter'

{CourseListing} = require './listing'
ErrorList = require './error-list'
Course = require './model'
{AsyncButton} = require 'openstax-react-components'

InviteCodeInput = React.createClass

  propTypes:
    title: React.PropTypes.string.isRequired
    course: React.PropTypes.instanceOf(Course)
    validateOnly: React.PropTypes.bool
    currentCourses: React.PropTypes.arrayOf(React.PropTypes.instanceOf(Course))

  startRegistration: ->
    if @props.validateOnly
      @props.course.validate(@refs.input.getValue())
    else
      @props.course.register(@refs.input.getValue())

  onKeyPress: (ev) ->
    return if @props.course.isBusy # double enter
    @startRegistration() if ev.key is ENTER

  renderCurrentCourses: ->
    <div className='text-center'>
      <h3>You are not registered for this course.</h3>
      <p>Did you mean to go to one of these?</p>
      <CourseListing courses={@props.currentCourses}/>
    </div>

  render: ->
    button =
      <AsyncButton
        isWaiting={@props.course.isBusy}
        waitingText={'Registering…'}
        onClick={@startRegistration}
      >
        Enroll
      </AsyncButton>

    <div className="form-group">
      {@renderCurrentCourses() if @props.currentCourses?.length}
      <h3 className="text-center">{@props.title}</h3>
      <hr/>
      <ErrorList course={@props.course} />
      <div className="col-md-6 col-md-offset-3 col-sm-8 col-sm-offset-2 col-xs-12">
        <BS.Input type="text" ref="input" label="Enter the two-word enrollment code"
          placeholder="enrollment code" autoFocus
          onKeyPress={@onKeyPress}
          buttonAfter={button} />
      </div>
    </div>

module.exports = InviteCodeInput
