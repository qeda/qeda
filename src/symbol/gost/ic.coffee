designators =
  DA: ['analog']
  DC: ['capacitor']
  DD: ['digital']
  DR: ['resistor']

purposes =
  '1': ['invertor', 'repeater', 'or']
  '&': ['and']
  '>': ['opamp']
  'ADC': ['adc']
  'BUF': ['buffer']
  'BUS': ['bus']
  '*C': ['capacitor']
  'CD': ['coder']
  'COMP': ['comparator', 'supervisor', 'reset']
  'CPU': ['cpu']
  'CTR': ['counter']
  '*D': ['diode']
  'DAC': ['dac']
  'DC': ['decoder']
  'DEV': ['device']
  'DIV': ['divider']
  'DM': ['demodulator']
  'DPY': ['display']
  'DRAM': ['ram', 'dram', 'dynamic']
  'DRV': ['driver']
  'DX': ['demultiplexor']
  'FIFO': ['fifo']
  'G': ['generator']
  '*L': ['inductor']
  'M': ['memory']
  'M2': ['xor']
  'MD': ['modulator']
  'MOD': ['modificator']
  'MPU': ['mcu', 'microcontroller', 'microprocessor', 'mpu']
  'MUX': ['multiplexer']
  'NVRAM': ['ram', 'nvram', 'mram', 'fram', 'non-volatile']
  'PLM': ['cpld', 'fpga']
  'PPI': ['interface', 'programmable']
  'PROM': ['rom', 'prom', 'programmable']
  '*R': ['resistor']
  'RAM': ['ram']
  'RG': ['register']
  'ROM': ['rom']
  'RPROM': ['rom', 'rpprom', 'reprogrammable']
  'RTX': ['isolator', 'interface', 'transceiver']
  'SM': ['adder']
  'SRAM': ['ram', 'sram', 'static']
  '*ST': ['regulator', 'stabilizer']
  '*STU': ['ac-dc', 'dc-dc', 'ldo', 'regulator', 'reference']
  'SUB': ['subtractor']
  'SW': ['optocoupler', 'relay', 'switch']
  '*T': ['transistor']
  'TH': ['hysteresis', 'threshold']
  'X/Y': ['converter', 'sensor']

updateElement = (element) ->
  unless element.keywords? then return
  keywords = element.keywords.toLowerCase().replace(/\s+/g, '').split(',')
  refWeight = 0
  for designator, classes of designators
    weight = keywords.filter((a) => classes.indexOf(a) isnt -1).length
    if weight > refWeight
      refWeight = weight
      element.refDes = designator
  purposeWeight = 0
  for purpose, classes of purposes
    weight = keywords.filter((a) => classes.indexOf(a) isnt -1).length
    if weight > purposeWeight
      purposeWeight = weight
      element.purpose = purpose

module.exports = (symbol, element) ->
  element.refDes = 'D'
  element.purpose = ''
  updateElement element

  schematic = element.schematic
  settings = symbol.settings

  schematic.showPinNames ?= true
  schematic.showPinNumbers ?= true

  pitch = symbol.alignToGrid(settings.pitch ? 5)
  pinLength = symbol.alignToGrid(settings.pinLength ? 10)
  pinSpace = schematic.pinSpace ? settings.space.pin
  space = settings.space.default

  left = symbol.left
  if symbol.top.length # Move top pins to the left side
    if left.length then left.push '-'
    left = left.concat symbol.top
  right = symbol.right
  if symbol.bottom.length # Move bottom pins to the right side
    if right.length then right.push '-'
    right = right.concat symbol.bottom

  pins = element.pins

  # Attributes
  symbol
    .attribute 'refDes',
      x: 0
      y: -settings.space.attribute
      halign: 'center'
      valign: 'bottom'
    .attribute 'user',
      x: 0
      y: 2*settings.space.attribute
      halign: 'center'
      valign: 'top'
      text: element.purpose

  textWidth = symbol.textWidth(element.purpose, 'name')

  width = textWidth
  height = pitch * (Math.max(left.length, right.length) + 1)

  if element.parts?
    symbol
      .attribute 'name',
        x: 0
        y: settings.fontSize.name + 4*settings.space.attribute
        halign: 'right'
        valign: 'center'
        orientation: 'vertical'
  else
    symbol
      .attribute 'name',
        x: 0
        y: height + settings.space.attribute
        halign: 'center'
        valign: 'top'

  # Pins on the left side
  x = -width/2
  leftPins = []
  leftYs = []
  y = height/2 - pitch * left.length/2 + pitch/2
  noLeftText = true
  for i in left
    if i is '-'
      unless leftFirst? then leftFirst = leftPins.length - 1
      leftLast = leftPins.length
      leftYs.push y
      y += pitch
      continue
    pin = pins[i]
    unless pin? then continue
    pin.y = y
    pin.length = pinLength
    pin.orientation = 'right'
    leftPins.push pin

    if pin.name.length then noLeftText = false
    w = symbol.textWidth(pin.name, 'pin') + pinSpace
    x1 = -width/2 - w - space
    if x > x1 then x = x1 # Make symbol wider
    y += pitch

  width = Math.max width, -2*x

  # Pins on the right side
  x = width/2
  rightPins = []
  rightYs = []
  y = height/2 - pitch * right.length/2 + pitch/2
  noRightText = true
  for i in right
    if i is '-'
      unless rightFirst? then rightFirst = rightPins.length - 1
      rightLast = rightPins.length
      rightYs.push y
      y += pitch
      continue
    pin = pins[i]
    unless pin? then continue
    pin.y = y
    pin.length = pinLength
    pin.orientation = 'left'
    rightPins.push pin

    if pin.name.length then noRightText = false
    w = symbol.textWidth(pin.name, 'pin') + pinSpace
    x2 = textWidth/2 + w + space
    if x < x2 then x = x2 # Make symbol wider
    y += pitch

  width = Math.max width, 2*x
  width = 2*symbol.alignToGrid(width/2, 'ceil')

  # Box
  symbol
    .lineWidth settings.lineWidth.thick
    .rectangle -width/2, 0, width/2, height, settings.fill
  unless noLeftText then symbol.line -textWidth/2 - space, 0, -textWidth/2 - space, height
  unless noRightText then symbol.line textWidth/2 + space, 0, textWidth/2 + space, height

  # Gap lines
  x1 = width/2
  x2 = textWidth/2 + space
  for y in leftYs
    symbol.line -x1, y, -x2, y

  for y in rightYs
    symbol.line x1, y, x2, y

  # Left pins
  # Align first group to top
  y = pitch
  if leftFirst?
    for i in [0..leftFirst]
      leftPins[i].y = y
      y += pitch

  # Align last group to bottom
  y = height - pitch
  if leftLast?
    for i in [(leftPins.length-1)..leftLast] by -1
      leftPins[i].y = y
      y -= pitch

  for pin in leftPins
    pin.x = -width/2 - pinLength
    symbol.pin pin

  # Right pins
  # Align first group to top
  y = pitch
  if rightFirst?
    for i in [0..rightFirst]
      rightPins[i].y = y
      y += pitch

  # Align last group to bottom
  y = height - pitch
  if rightLast?
    for i in [rightLast..(rightPins.length-1)]
      rightPins[i].y = y
      y -= pitch

  for pin in rightPins
    pin.x = width/2 + pinLength
    symbol.pin pin
