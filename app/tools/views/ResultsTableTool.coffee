Chaplin = require 'chaplin'

ToolView = require 'chaplin/views/Tool'

module.exports = class ResultsTableTool extends ToolView

    # What does it mean for this tool to serialize?
    serialize: -> 'list': 'A list coming from a results table'