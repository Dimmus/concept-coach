React = require 'react'
BS = require 'react-bootstrap'
ENTER = 'Enter'

Course = require './model'
ErrorList = require './error-list'
{AsyncButton} = require 'openstax-react-components'

ConfirmJoin = React.createClass

  propTypes:
    title: React.PropTypes.string.isRequired
    course: React.PropTypes.instanceOf(Course)
    optionalStudentId: React.PropTypes.bool

  startConfirmation: ->
    @props.course.confirm(@refs.input.getValue())

  onKeyPress: (ev) ->
    @startConfirmation() if ev.key is ENTER

  onConfirmKeyPress: (ev) ->
    @startConfirmation() if ev.key is ENTER

  cancelConfirmation: ->
    @props.course.resetToBlankState()

  render: ->
    label = if @props.optionalStudentId
      <span>
        Update school issued ID<br/>
        (<i>leave blank to leave unchanged</i>):
        </span>
    else
      "Enter your school issued ID:"

    <div className="form-group">
      <h3 className="text-center">
        {@props.title}
      </h3>
      <ErrorList course={@props.course} />
      <div className="col-md-6 col-md-offset-3 col-sm-8 col-sm-offset-2 col-xs-12">

        <BS.Input type="text" ref="input" label={label}
          placeholder="School issued ID" autoFocus
          onKeyPress={@onKeyPress}
        />

        <div className="text-center">
          <button className="btn"
            onClick={@cancelConfirmation}>Cancel</button>

           <AsyncButton
             className="btn btn-success"
             isWaiting={@props.course.isBusy}
             waitingText={'Confirming…'}
             onClick={@startConfirmation}
             style={marginLeft: '3rem'}
           >
            Confirm
          </AsyncButton>
        </div>
      </div>
    </div>

module.exports = ConfirmJoin
