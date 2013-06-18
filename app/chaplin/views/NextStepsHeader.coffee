Mediator      = require 'chaplin/core/Mediator'

NextStepsView = require 'chaplin/views/NextSteps'

template      = require 'chaplin/templates/next-steps-header'

# Quick access tools like Uploading a list etc.
module.exports = class NextStepsHeaderView extends NextStepsView

    container: '#always-on' # where to render
    method:    'new'        # are we making a new step or continue previous?

    place: 'header'

    labelClass: 'button -steps-ui' # extra class for a label

    getTemplateFunction: -> template