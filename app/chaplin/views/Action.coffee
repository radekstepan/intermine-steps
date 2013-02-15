View = require 'chaplin/core/View'

module.exports = class ActionView extends View

    containerMethod: 'html'
    autoRender:      true
    tagName:         'li'

    getTemplateFunction: -> require 'chaplin/templates/action'

    # Custom data prep.
    getTemplateData: ->
        'slug':   @options.slug
        'type':   @options.type
        'label':  @markup @options.label
        'method': @options.method
        'suffix': @options.suffix

    afterRender: ->
        super

        # Apply class that corresponds to the type of the tool.
        $(@el).addClass @options.type

    # Convert markup with HTML.
    markup: (text) ->
        # Strong.
        text = text.replace /(\*\*|__)(?=\S)([^\r]*?\S[*_]*)\1/g, "<strong>$2</strong>"
        # Emphasis.
        text = text.replace /(\*|_)(?=\S)([^\r]*?\S)\1/g, "<em>$2</em>"