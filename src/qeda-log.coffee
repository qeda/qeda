module.exports =
  start: (message) ->
    @_indent()
    console.log message
    ++@_level

  error: (message) ->
    @_indent 'stderr'
    console.error 'Error: ' + message
    process.exit 1

  exception: (obj) ->
    @_indent 'stderr'
    console.error "#{obj}"
    process.exit 1

  ok: ->
    --@_level

  warning: (message) ->
    @_indent 'stderr'
    console.warn 'Warning: ' + message

  _indent: (stream = 'stdout') ->
    @_level ?= 0
    i = 1
    while i <= @_level*2
      process[stream].write ' '
      ++i
