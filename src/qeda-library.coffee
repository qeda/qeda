fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'
request = require 'sync-request'
yaml = require 'js-yaml'

KicadGenerator = require './kicad-generator'
Kicad6Generator = require './kicad6-generator'
Kicad7Generator = require './kicad7-generator'
SvgGenerator = require './svg-generator'
GedaGenerator = require './geda-generator'
CoraledaGenerator = require './coraleda-generator'
QedaElement = require './qeda-element'
log = require './qeda-log'

class QedaLibrary
  #
  # Constructor
  #
  constructor: (config = {}) ->
    @output = 'kicad'

    @connection =
      timeout: 5000
      remote: 'https://raw.githubusercontent.com/qeda/library/master/'

    @nodate = false # don't put generated date in library (version control friendly)

    @symbol =
      style: 'default' # Options: default, GOST
      gridSize: 2.5 # Grid cell size
      factor: 1 # Symbol factor
      pitch: 5 # Default pin pitch
      shortPinNames: false # Add alternate pin functions to pin name or not
      pinIcon: true # Add shape next to pin (particularly for connectors)
      fill: 'foreground' # Options: none, background, foreground
      fontSize:
        default: 2.5
        refDes: 2.5
        name: 2.5
        pin: 2.5
      lineWidth:
        default: 0
        thick: 0.6
        thin: 0.2
      space:
        default: 2
        pin: 2
        attribute: 1.5

    @pattern =
      style: 'default' #
      densityLevel: 'N' # Nominal
      decimals: 3
      polarityMark: 'dot'
      preferManufacturer: true
      smoothPadCorners: false # Use ratio.cornerToWidth and maximum.cornerRadius
      tolerance:
        default: 0.1
        fabrication: 0.1
        placement: 0.1
      clearance:
        padToSilk: 0.2
        padToPad: 0.2
        padToMask: 0.05
        leadToHole: 0.1
      ratio:
        padToHole: 1.5
        cornerToWidth: 0.25
      minimum:
        ringWidth: 0.2
        holeDiameter: 0.2
        maskWidth: 0.2
        spaceForIron: 0
      maximum:
        cornerRadius: 0.2
      lineWidth:
        default: 0.2
        silkscreen: 0.12 # IPC-7351C (0.1, 0.12, 0.15)
        assembly: 0.1 # IPC-7351C
        courtyard: 0.05 # IPC-7351C
      fontSize: # mm
        default: 1
        refDes: 1.2  # IPC-7351C (1, 1.2, 1.5)
        value: 1
      ball:
        collapsible: true

    @mergeObjects this, config
    @pattern.minimum.drillDiameter = @pattern.minimum.holeDiameter # TODO: Remove in v1.0

    @elements = []

  #
  # Add element
  #
  add: (element) ->
    objs = @load element
    elements = []

    for obj in objs
      if obj.abstract
        console.warn "'#{element}': Cannot add abstract component, use it only as base for others"
        return elements

      # Suffixes
      obj.housing.suffix ?= ''
      suffixes = obj.housing.suffix.replace(/\s+/g, '').split(',')
      name = obj.name
      obj.name = name + suffixes[0]
      # Aliases
      aliases = []
      if obj.alias?
        for alias in obj.alias.replace(/\s+/g, '').split(',')
          aliases = aliases.concat(suffixes.map (v) => alias + v)
      if suffixes.length > 1
        aliases = aliases.concat(suffixes[1..].map (v) => name + v)
      obj.aliases = aliases

      newElement = new QedaElement(this, obj)
      @elements.push newElement
      elements.push newElement

    elements

  #
  # Add symbol
  #
  addSymbol: (symbol, name, options="") ->
    schematic =
      symbol: symbol
      options: options
    words = name.split('/')
    if words.length > 1
      for i in [0..(words.length-2)]
        schematic[words[i].toLowerCase()] = true
      name = words[words.length - 1]
    def =
      name: name
      schematic: schematic
    newElement = new QedaElement(this, def)
    @elements.push newElement
    newElement

  #
  # Check element description for validity
  #
  check: (obj) ->
    # TODO: Add checking
    return

  #
  # Generate library in given format
  #
  generate: (name) ->
    log.start "Render library '#{name}'"
    @render()
    log.ok()
    generator = null
    switch @output
      when 'kicad' then generator = new KicadGenerator(this)
      when 'kicad6' then generator = new Kicad6Generator(this)
      when 'kicad7' then generator = new Kicad7Generator(this)
      when 'svg' then generator = new SvgGenerator(this)
      when 'geda' then generator = new GedaGenerator(this)
      when 'coraleda' then generator = new CoraledaGenerator(this)
    if generator
      log.start "Generate output for '#{name}'"
      generator.generate name
      log.ok()

  #
  # Add ground symbol
  #
  ground: (name) ->
    @addSymbol 'ground', name

  #
  # Load element description from remote repository
  #
  load: (element, force = false) ->
    [obj, filterVariation] = @loadYaml element, force

    objs = []
    if obj.variations?
      variations = obj.variations.replace(/\s+/g, '').toLowerCase().split(',')
      delete obj.variations
      for variation in variations
        if filterVariation? and (variation isnt filterVariation) then continue
        varObj = {}
        @mergeObjects varObj, obj
        for k, v of varObj
          [param, modifier] = k.replace(/\s+/g, '').split('@')
          if modifier?
            if modifier.toLowerCase() is variation then varObj[param] = v # Replace
            delete varObj[k]
          if typeof v is 'object' and (not Array.isArray v)
            for k2, v2 of varObj[k]
              [param, modifier] = k2.replace(/\s+/g, '').split('@')
              if modifier?
                if modifier.toLowerCase() is variation then varObj[k][param] = v2 # Replace
                delete varObj[k][k2]
        objs.push varObj
    else
      objs.push obj

    objs

  #
  # Load and parse YAML file
  #
  loadYaml: (element, force = false) ->
    element = element.toLowerCase()
    [elementName, filterVariation] = element.split '@'
    elementYaml = elementName + '.yaml'
    localFile = './library/' + elementYaml
    if (not fs.existsSync localFile) or force
      log.start "Load '#{elementName}'"
      elementYaml = elementYaml.split('/').map((v) -> encodeURIComponent(v)).join('/')
      try
        res = request 'GET', @connection.remote + elementYaml,
          timeout: @connection.timeout
      catch error
        log.error error.message
      if res.statusCode is 200
        mkdirp.sync (path.dirname localFile)
        fs.writeFileSync localFile, res.body
        log.ok()
      else
        log.warning res.statusCode
    log.start "Read '#{elementName}'"
    try
      obj = yaml.safeLoad fs.readFileSync(localFile)
      # TODO: YAML Schema validation
    catch error
      log.error "#{error.message}"
    log.ok()

    @check obj

    # Load base description
    if obj.base?
      unless typeof obj.base is 'string' then obj.base = obj.base.toString()
      bases = obj.base.replace(/\s+/g, '').split(',')
      delete obj.base # We do not need this information now
      exclusions = ['abstract', 'alias'] # Exclude these fields from base object
      for base in bases
        baseElement = base
        if path.dirname(baseElement) is '.' then baseElement = path.dirname(element) + '/' + baseElement
        baseObj = (@loadYaml baseElement, force)[0]
        for exclusion in exclusions
          if baseObj[exclusion]? then delete baseObj[exclusion]
        @mergeObjects baseObj, obj
        obj = baseObj

    if element.indexOf('/') isnt -1
      obj.group ?= element.substr(0, element.indexOf('/')).toUpperCase()

    [obj, filterVariation]

  #
  # Merge two objects
  #
  mergeObjects: (dest, src) ->
    for k, v of src
      if typeof v is 'object' and (not Array.isArray v)
        if not dest.hasOwnProperty k
          dest[k] = {}
        @mergeObjects dest[k], v
      else
        dest[k] = v

  #
  # Add power symbol
  #
  power: (name) ->
    @addSymbol 'power', name

  #
  # Add power flag
  #
  powerflag: (name) ->
    @addSymbol 'powerflag', name

  #
  # Add port symbols
  #
  port: () ->
    input = @addSymbol 'port', 'inputExt', 'input'
    output = @addSymbol 'port', 'outputExt', 'output'

  #
  # Render elements
  #
  render: ->
    @_rendered ?= false
    if @_rendered then return
    patterns = {}
    for element in @elements
      element.render()
      # Check for pattern names duplication
      if element.pattern?
        baseName = element.pattern.name
        name = baseName
        keys = Object.keys patterns
        i = 1
        while keys.indexOf(name) isnt -1
          if element.pattern.isEqualTo(patterns[name])
            break
          else
            name = "#{baseName}-#{i++}"
            element.pattern.name = name
        patterns[name] = element.pattern

    @_rendered = true

module.exports = QedaLibrary
