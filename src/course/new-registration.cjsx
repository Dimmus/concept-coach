React = require 'react'

Course = require './model'
User = require '../user/model'
ENTER = 'Enter'

InviteCodeInput = require './invite-code-input'
ConfirmJoin = require './confirm-join'
Navigation = require '../navigation/model'
User = require '../user/model'

NewCourseRegistration = React.createClass

  propTypes:
    collectionUUID: React.PropTypes.string.isRequired
    validateOnly: React.PropTypes.bool
    course: React.PropTypes.instanceOf(Course)

  componentWillMount: ->
    course = @props.course or
      User.getCourse(@props.collectionUUID) or
      new Course({ecosystem_book_uuid: @props.collectionUUID})
    course.channel.on('change', @onCourseChange)
    @setState({course})

  componentWillUnmount: ->
    @state.course.channel.off('change', @onCourseChange)

  onComplete: ->
    @state.course.persist(User)
    Navigation.channel.emit('show')

  onCourseChange: ->
    if @state.course.isValidated() or @state.course.isRegistered()
      # wait 1.5 secs so our success message is briefly displayed, then call onComplete
      _.delay(@onComplete, 1500)
    @forceUpdate()

  renderValidated: ->
    <div>
      <h3 className="text-center">
        Course validation is complete.
      </h3>
      <p className="lead">You can now login or signup to start using Concept Coach</p>
    </div>

  renderComplete: (course) ->
    <h3 className="text-center">
      You have successfully joined {course.description()}
    </h3>

  isTeacher: ->
    User.isTeacherForCourse(@props.collectionUUID)

  renderCurrentStep: ->
    {course} = @state
    if course.isValidated()
      @renderValidated()
    else if course.isIncomplete()
      title = if @isTeacher() then '' else 'Register for this Concept Coach course'
      <InviteCodeInput course={course} currentCourses={User.registeredCourses()} title={title} />
    else if course.isPending()
      <ConfirmJoin
        title={"Would you like to join #{@state.course.description()}?"}
        course={course} />
    else
      @renderComplete(course)

  teacherMessage: ->
    <div className="teacher-message">
      <p className="lead">
        Welcome!
      </p><p className="lead">
        To see the student view of your course in Concept Coach,
        enter an enrollment code from one of your sections.
      </p><p>
        We suggest creating a test section for yourself so you can
        separate your Concept Coach responses from those of your students.
      </p>
    </div>

  render: ->
    <div className="-new-registration">
      {@teacherMessage() if @isTeacher()}
      {@renderCurrentStep()}
    </div>

module.exports = NewCourseRegistration
