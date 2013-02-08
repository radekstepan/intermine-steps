module.exports = (match) ->
    match '',                    'landing#index' # landing page
    match 'tool/:slug/new',      'tools#new'     # new tool
    match 'tool/:slug/continue', 'tools#cont'    # continue with a next tool
    match 'tool/:slug/id/:guid', 'tools#old'     # historical tool
    match 'error/404',           'error#404'     # 404