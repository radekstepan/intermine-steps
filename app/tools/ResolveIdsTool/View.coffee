Mediator = require 'chaplin/core/Mediator'
ToolView = require 'chaplin/views/Tool'

{ config } = require 'tools/config'

root = @

module.exports = class ResolveIdsToolView extends ToolView

    # Form the query constraining on a list.
    queryForList = ({ input, list, query }) ->
        'from': input.type
        'select': [ '*' ]
        'constraints': [ [ input.type, 'IN', list ] ]

    attach: ->
        super

        self = @

        switch @step

            # Input.
            when 1
                # Pass the following to the App from the client.
                opts =
                    'mine': config.root # which mine to connect to
                    'token': config.token # token so we can access private lists
                    'type': 'many' # one OR many
                    # Status messages and when user receives resolved identifiers.
                    'cb': (err, working, out) ->
                        # Has error happened?
                        throw err if err
                        # Have input?
                        if out and out.query
                            # Save the input proper.
                            self.model.set 'data', out
                            # Update the history, we are set.
                            Mediator.publish 'history:add', self.model

                # Do we have input already?
                opts.provided = @model.get('data')?.input or {} # default is rubbish

                # Build me an iframe with a channel.
                channel = @makeIframe '.iframe.app.container', (err) ->
                    throw err if err

                # Make me an app.
                channel.invoke.apps 'identifier-resolution', opts

            # Output.
            when 2
                guid = @model.get('guid')

                # Show a minimal Results Table.
                opts = _.extend {}, config,
                    'type': 'minimal'
                    'query': queryForList @model.get('data')
                    'events':
                        # Fire off new context on cell selection.
                        'imo:click': (type, id) ->
                            Mediator.publish 'context:new', [
                                'have:list'
                                "type:#{type}"
                                'have:one'
                            ], guid, id

                # Build me an iframe with a channel.
                channel = @makeIframe '.iframe.app.container', (err) ->
                    throw err if err

                # Make me the table.
                channel.invoke.imtables opts

                # We have a list!
                Mediator.publish 'context:new', [
                    'have:list'
                    "type:#{type}"
                ], guid

        @