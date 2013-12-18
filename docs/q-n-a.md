#Questions & Answers

##How would I get steps for my own mine?

Edit the following properties in a `tools/config.coffee` file:

```coffeescript
exports.config =
    # Root URL for all mine requests (for now we only work with 1 mine).
    'mine': 'http://www.flymine.org/query/'
    # A token so we can be creating lists in the background (throwaway account).
    'token': 'n1s3AaY1DcXbj3X740S5qbAMzYU'
```

Currently these point to FlyMine and use a throwaway account token.

Now **rebuild** the client source files and refresh your browser.

#How would I get some tools for my mine?

Let us assume you have a JavaScript file somewhere that you'd like to load as a Tool in Steps.

##1. Fetch dependencies

First you need to specify where to get your app from, including its vendor dependencies. We are using [Bower](http://bower.io/) for that.

Edit the `bower.json` file adding your app name and version (if published on Bower), or you can just point it to an http address:

```json
"dependencies": {
    "published-on-bower": "version",
    "not-published-on-bower": "http://some.js"
}
```

Do the same for all vendor libraries your app depends on. Now you want to run the following task to actually fetch the files:

```bash
$ bower install
```

You will now have these new libraries saved in the `client/vendor` folder.

##2. Make a package

Currently, all apps and their dependencies need to be packaged up into a single CSS/JS file. We use [Grunt](http://gruntjs.com/) for that.

Edit the `Gruntfile.coffee` file in the `concat` section:

```coffeescript
    concat:
        my_app:
            src: [ 'some.js', 'another.js' ]
            dest: 'client/build/myapp.js'
```

Run the built task now:

```bash
$ grunt
```

Now we will have these built files in a place where Steps can *reach* them.

##3. Make a tool

Tool packages up (presumably) 1+ packages that you have now created. You can imagine to have one package to show an input form and another to display the results. We do this when uploading a list for example.

To make a tool first create a config for it in `tools/config.coffee`:

```coffeescript
exports.registry = [
    {
        # An identifier that can be used as a URL.
        'slug': 'my-tool'
        'labels': [
            {
                'label': 'Do something interesting'
                'weight': 10
                'place': 'home'
            }
        ]
    }
]
```

What we have now done is added a tool that will always show a link on the homepage under the text "Do something interesting".

Now [PascalCase](http://c2.com/cgi/wiki?PascalCase) the `slug` and create a folder in the `tools` folder with the following files. Once you are done, do not forget to run the `Grunt` task again.

###3.1 Model

A model represents the *data* of a tool.

```coffescript
Tool = require '/steps/client/src/models/Tool'

module.exports = class MyTool extends Tool

    defaults:
        'slug': 'my-tool'
        'name': 'MyTool'
        'title': 'This is my tool'
        'description': 'It does tool-y things'
        'type': 'goldentainoi'
```

###3.2 Templates

Templates represent the UI of your tool. They setup the stage for it.

Create two files: `step-1.eco` and `step-2.eco` for input/output respectively.

You can use the [Eco](https://github.com/sstephenson/eco) templating language. Since we are creating a sandboxed tool, save just this html inside:

```html
<div class="iframe app container"></div>
```

###3.3 View

View is a component that glues everything together. It will need to say to other tools when something interesting has happened and respond to a user-passed input.

I present you with a `View.coffee` file for list upload tool:

```coffeescript
Mediator = require '/steps/client/src/core/Mediator'
ToolView = require '/steps/client/src/views/Tool'

{ config } = require '../config'

root = @

module.exports = class ResolveIdsToolView extends ToolView

    # Form the query constraining on a list.
    queryForList = ({ input, list, query }) ->
        'from': input.type
        'select': [ '*' ]
        'constraints': [ [ input.type, 'IN', list ] ]

    # Turn a query to be into a list and call back with its name.
    queryToList = (obj, cb) ->
        service = new intermine.Service
            'root': config.mine
            'token': config.token
            'errorHandler': cb

        service.query obj, (q) ->
            q.saveAsList
                'name': +new Date
                'tags': [ 'app', 'identifier-resolution' ]
            , ({ name }) ->
                cb null, name

    attach: ->
        super

        self = @

        switch @step

            # Input.
            when 1
                # Pass the following to the App from the client.
                opts =
                    'mine': config.mine # which mine to connect to
                    'token': config.token # token so we can access private lists
                    'type': 'many' # one OR many
                    # The default identifers in FlyMine.
                    'provided':
                        'identifiers': [ 'CG9151', 'FBgn0000099', 'CG3629', 'TfIIB', 'Mad', 'CG1775', 'CG2262', 'TWIST_DROME', 'tinman', 'runt', 'E2f', 'CG8817', 'FBgn0010433', 'CG9786', 'CG1034', 'ftz', 'FBgn0024250', 'FBgn0001251', 'tll', 'CG1374', 'CG33473', 'ato', 'so', 'CG16738', 'tramtrack', 'CG2328', 'gt' ]
                        'type': 'Gene'
                        'organism': 'D. melanogaster'
                    
                    # Status messages and when user receives resolved identifiers.
                    'cb': (err, working, out) ->
                        # Has error happened?
                        throw err if err
                        # Have output?
                        if out and out.query
                            # Make it into a list (will get deleted anyway...).
                            queryToList out.query, (err, name) ->
                                throw err if err
                                out.list = name
                                # Save the input proper.
                                self.model.set 'data', out
                                # Update the history, we are set.
                                Mediator.publish 'history:add', self.model

                # Do we have input already?
                opts.provided = @model.get('data')?.input or opts.provided # default is rubbish

                # Build me an iframe with a channel.
                channel = @channel {
                    'target': '.iframe.app.container'
                    'scope': 'apps-a'
                }

                # Make me an app.
                channel.trigger 'load', 'identifier-resolution', opts

            # Output.
            when 2
                # This is a new instance, need to get data from Model only.
                guid = @model.get('guid')
                data = @model.get('data')

                # Show a minimal Results Table.
                opts = _.extend {}, config,
                    'type': 'minimal'
                    'query': queryForList data
                    'events':
                        # Fire off new context on cell selection.
                        'imo:click': (type, id, obj) ->
                            Mediator.publish 'context:new', [
                                'have:list'
                                "type:#{type}"
                                'have:one'
                            ], guid, id

                # Build me an iframe with a channel.
                channel = @channel {
                    'target': '.iframe.app.container'
                    'scope': 'imtables'
                }

                # Make me the table.
                channel.trigger 'show', opts

                # We have a list!
                Mediator.publish 'context:new', [
                    'have:list'
                    "type:#{data.input.type}"
                ], guid

        @
```

What we can see is that each tool is split into two steps, input & output. Every time we visit either of these, `attach` function is called.

Inside `attach` we have access to the property `@step` which is either `1` or `2` for input/output.

The following line fetches data from a tool that has already been executed:

```coffeescript
opts.provided = @model.get('data')?.input or opts.provided
```

This happens when we, for example, upload a list and we want to go back in history and see what the input for that list was. In our case we have decided to save and data to the `data` property.

We are using [Backbone.js](http://documentcloud.github.io/backbone/) and the operations you can do on a Model are [described here](http://documentcloud.github.io/backbone/#Model).

Next we are using a concept of a *channel*. This is a fancy way for creating an `iframe` so that our app is sandboxed from the rest:

```coffeescript
    # Build me an iframe with a channel.
    channel = @channel {
        'target': '.iframe.app.container'
        'scope': 'apps-a'
    }

    # Make me an app.
    channel.trigger 'load', 'identifier-resolution', opts
```

You will notice that `target` is the DOM element we have created in the **templates** above. The scope is up to you. You want to use something like `myapp`.

The last line, then, follows the [Pomme.js API](https://github.com/radekstepan/pomme.js#methods). We are passing all our config to an iframe that will setup our app from the other end. One of the options passed was a callback `cb`. Somehow, you need to tell Steps when the user has provided input and you want to go to the results step, 2.

You first save user input on a **model** and then you publish a message through a **mediator**:

```coffeescript
    # Save the input proper.
    self.model.set 'data', out
    # Update the history, we are set.
    Mediator.publish 'history:add', self.model
```

An alternative, on step 2, is to say that the context of Steps needs to change. This happens when you have seen the results and now you want to do "more". User may have clicked on something in your app and you want to redirect to another tool. The **mediator** syntax for that is as follows:

```coffeescript
    guid = @model.get('guid')
    data = @model.get('data')
    
    # We have a list!
    Mediator.publish 'context:new', [
        'have:list'
        "type:#{data.input.type}"
    ], guid
```

We have triggered a change of context passing an array of strings. If any tool matches this combination of strings, as defined in `tools/config.coffee`, it will be shown in a menu to the right. In our case we are saying we have a list and that this list is of type *gene*. List widgets will be listening for this context and show up their labels so one can click on them.

###3.4 iframe

We haven't shown anything yet though. We need to load the actual app that *shows* something.

Remember the `scope` property that you provided to a channel? Visit the `client/src/templates/iframe` folder and you will see a bunch of [Eco](https://github.com/sstephenson/eco) templates there. If you pass in scope such as `widgets`, the template `widgets.eco` will be loaded for you in the iframe that sandboxes your app.

As an example let us take a look at the `widget.eco` iframe source:

```html
<!doctype html>
<html>
<head>
    <meta charset="utf-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
    <link rel="stylesheet" href="/iframe/im.widgets.bundle.css" />
    <script src="/iframe/im.widgets.bundle.js"></script>
</head>
<body>
    <script>
    (function() {
        var Pomme = require('pomme.js');
        var channel = new Pomme({ 'scope': 'widgets' });
        channel.on('show', function(config) {
            var ListWidgets = require('list-widgets'),
                widgets = new ListWidgets({
                'root': config.mine + '/service/',
                'token': config.token
            });
            widgets[config.type](config.id, config.list, 'body', {});
        });
    })();
    </script>
</body>
</html>
```

In the `</head>` section we are loading some CSS and JS. These are the files you built using the `Grunt` task.

Then we are saying to require the `Pomme` library (the library that makes iframe communication possible) and are listening for a `show` event.

This is the event that one triggers from `View.coffee` like so:

```coffeescript
channel.trigger 'show', config
```

Inside the function we are bootstrapping the library passing it config which we passed above.