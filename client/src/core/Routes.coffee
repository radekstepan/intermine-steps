module.exports = (match) ->
    match '',                                 'landing#index', name: 'landing' # landing page
    match 'tool/:slug/new',                   'tools#new',     name: 'new'     # new tool
    match 'tool/:slug/:extra/new',            'tools#new',     name: 'new'     # new tool w/ extra params
    match 'tool/:slug/continue/:guid',        'tools#cont',    name: 'cont'    # continue to a next tool
    match 'tool/:slug/:extra/continue/:guid', 'tools#cont',    name: 'cont'    # continue to a next tool w/ extra params
    match 'tool/id/:guid',                    'tools#old',     name: 'old'     # historical tool
    match 'tool/id/:guid/results',            'tools#results', name: 'results' # results of a tool run
    match 'error/404',                        'error#404',     name: '404'     # 404
    match 'error/500',                        'error#500',     name: '500'     # 500
    match 'app/reset',                        'app#reset',     name: 'reset'   # reset the database