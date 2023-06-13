enclosure = require './enclosure'

module.exports = (symbol, element, icon, leftName = 'L', rightName = 'R', bottomName = '') ->
  schematic = element.schematic
  settings = symbol.settings
  pins = element.pins
  schematic.showPinNames ?= false

  # Add pins if no any
  unless Object.keys(element.pinGroups).length
    element.pins[1] = { name: leftName, number: 1 }
    if rightName.length > 0
      element.pins[2] = { name: rightName, number: 2 }
    if bottomName.length > 0
      element.pins[if rightName.length > 0 then 3 else 2] = { name: bottomName, number: if rightName.length > 0 then 3 else 2 }
    element.pinGroups[leftName] = [1]
    if rightName.length > 0
      element.pinGroups[rightName] = [2]
    if bottomName.length > 0
      element.pinGroups[bottomName] = [if rightName.length > 0 then 3 else 2]

  leftRegEx = new RegExp("^" + leftName)
  rightRegEx = new RegExp("^" + rightName)
  bottomRegEx = new RegExp("^" + bottomName)
  groups = symbol.part ? element.pinGroups
  for k, v of groups
    k = k.toUpperCase()
    if k.match leftRegEx
      left = v.map((e) => pins[e])
    else if rightName.length > 0 and k.match rightRegEx
      right = v.map((e) => pins[e])
    else if bottomName.length > 0 and k.match bottomRegEx
      bottom = v.map((e) => pins[e])
    else if k.match /^NC/
      nc = v.map((e) => pins[e])
    else if k is '' # Root group
      continue
    else
      needEnclosure = true

  left ?= [
    name: leftName
    number: 1
  ]

  if rightName.length > 0
    right ?= [
      name: rightName
      number: 2
    ]

  if bottomName.length > 0
    bottom ?= [
      name: bottomName
      number: 3
    ]

  if needEnclosure
    schematic.showPinNames = true
    schematic.showPinNumbers = true
    enclosure symbol, element, icon
    symbol.orientations = [0]
  else
    decorated = (left.length > 1) or (right? and right.length > 1) or (bottom? and bottom.length > 1) or (nc?.length)

    schematic.showPinNumbers ?= if decorated then true else false

    width = icon.width
    height = icon.height

    pinLength2 = symbol.alignToGrid(settings.pinLength ? (if decorated then 5 else 2.5), 'ceil')
    pinLength1 = (2*symbol.alignToGrid(width/2 + pinLength2, 'ceil') - width) / 2
    pinLength3 = (2*symbol.alignToGrid(height/2 + pinLength2, 'ceil') - height) / 2

    pitch = symbol.alignToGrid settings.pitch
    pinAreaHeight = ((if right? then Math.max(left.length, right.length) else left.length) - 1) * pitch

    topY = icon.y1 ? -height/2
    bottomY = icon.y2 ? height/2

    symbol
      .attribute 'refDes',
        x: 0
        y: topY - settings.space.attribute
        halign: 'center'
        valign: 'bottom'
      .attribute 'name',
        x: 0
        y: Math.max(bottomY, pinAreaHeight/2) + settings.space.attribute
        halign: 'center'
        valign: 'top'
    icon.draw 0, 0

    if left.length is 1
      symbol.pin
        number: left[0].number
        name: left[0].name
        x: -width/2 - pinLength1
        y: 0
        length: pinLength1
        orientation: 'right'
        passive: true
    else
      y = -pitch * (left.length - 1) / 2
      symbol
        .line -width/2 - pinLength1, 0, -width/2, 0
        .line -width/2 - pinLength1, y, -width/2 - pinLength1, -y
      for pin in left
        pin.x = -width/2 - pinLength1 - pinLength2
        pin.y = y
        pin.length = pinLength2
        pin.orientation = 'right'
        pin.passive = true
        symbol.pin pin
        y += pitch

    if right?
      if right.length is 1
        symbol.pin
          number: right[0].number
          name: right[0].name
          x: width/2 + pinLength1
          y: 0
          length: pinLength1
          orientation: 'left'
          passive: true
      else
        y = -pitch * (right.length - 1) / 2
        symbol
          .line width/2 , 0, width/2 + pinLength1, 0
          .line width/2 + pinLength1, y, width/2 + pinLength1, -y
        for pin in right
          pin.x = width/2 + pinLength1 + pinLength2
          pin.y = y
          pin.length = pinLength2
          pin.orientation = 'left'
          pin.passive = true
          symbol.pin pin
          y += pitch

    if bottom?
      if bottom.length is 1
        symbol.pin
          number: bottom[0].number
          name: bottom[0].name
          x: 0
          y: height/2 + pinLength1
          length: pinLength1
          orientation: 'up'
          passive: true
      else
        x = -pitch * (bottom.length - 1) / 2
        symbol
          .line 0, height/2, 0, height/2 + pinLength3
          .line x, height/2 + pinLength3, -x, height/2 + pinLength3
        for pin in bottom
          pin.x = x
          pin.y = height/2 + pinLength3 + pinLength2
          pin.length = pinLength2
          pin.orientation = 'up'
          pin.passive = true
          symbol.pin pin
          x += pitch

    if nc?
      for pin, i in nc
        pin.x = (i - (nc.length - 1)/2)*pitch
        pin.y = Math.max(height, pinAreaHeight)/2 + pinLength2
        pin.length = pinLength2
        pin.orientation = 'up'
        pin.nc = true
        pin.invisible = true
        symbol.pin pin
