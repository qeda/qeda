module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  pattern.name ?= 'CK_' + element.name
