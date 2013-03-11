Chaplin = require 'chaplin'

Mediator = require 'chaplin/core/Mediator'
View = require 'chaplin/core/View'

NextStepsLandingView = require 'chaplin/views/NextStepsLanding'

Registry = require 'tools/Registry'

root = @

module.exports = class LandingView extends View

    container:       'body'
    containerMethod: 'html'
    autoRender:      true

    getTemplateFunction: -> require 'chaplin/templates/landing'

    attach: ->
        super

        # Load the appropriate Next Steps.
        @views.push new NextStepsLandingView()

        # App search.
        @delegate 'keyup', 'input#search', (e) -> Mediator.publish 'app:search', $(e.target).val()

        # Remove app class if present.
        $('body').removeClass('app')

        # Load the registry of tools as an example of a config.
        $(@el).find('#example').html JSON.stringify Registry['i:onHomepage'][0...2], null, 4
        Rainbow.color()

        @