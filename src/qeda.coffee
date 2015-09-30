class Qeda
  constructor: () ->

  mixin = (fields) =>
    for name, field of fields
      this::[name] = field
    for name, field of fields
      # Mixin constructor starts with '_init'
      if name.indexOf('_init') is 0 and typeof field is 'function'
        this::[name]()

  mixin require './mixins/element'
  mixin require './mixins/kicad'

module.exports = Qeda
