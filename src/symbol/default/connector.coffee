ic = require './ic'

module.exports = (symbol, element) ->
  numbers = Object.keys element.pins
  for number in numbers by 2
    symbol.left.push number
  numbers.shift()
  for number in numbers by 2
    symbol.right.push number

  ic symbol, element
  element.refDes = 'J'
