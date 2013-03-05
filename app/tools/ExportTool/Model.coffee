Tool = require 'chaplin/models/Tool'

module.exports = class ExportTool extends Tool

    defaults:
        'slug': 'export-tool'
        'name': 'ExportTool'
        'title': 'Data Export'
        'description': 'Exporting'
        'type': 'turq'
        'steps': [ 'Choose export format', 'Download exported data' ]