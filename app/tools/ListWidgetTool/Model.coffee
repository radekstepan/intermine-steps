Tool = require 'chaplin/models/Tool'

module.exports = class ListWidgetTool extends Tool

    defaults:
        'slug': 'list-widget-tool'
        'name': 'ListWidgetTool'
        'type': 'deyork'
        'steps': [ 'Choose input', 'See widget' ]