fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'
request = require 'sync-request'
yaml = require 'js-yaml'

KicadGenerator = require './kicad-generator'
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

    @symbol =
      style: 'default'
      gridSize: 2.5
      shortPinNames: false
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
      style: 'default'
      densityLevel: 'N' # Nominal
      decimals: 3
      polarityMark: 'dot'
      preferManufacturer: true
      tolerance:
        default: 0.1
        fabrication: 0.1
        placement: 0.1
      clearance:
        padToSilk: 0.2
        padToPad: 0.2
        padToMask: 0.05
        holeOverLead: 0.2
      ratio:
        padToHole: 1.5
      minimum:
        ringWidth: 0.2
        drillDiameter: 0.2
        maskWidth: 0.2
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

    @elements = []

  #
  # Add element
  #
  add: (element) ->
    defs = @load element
    res = []
    for def in defs
      if def.abstract
        console.error "'#{element}': Cannot add abstract component, use it only as base for others"
        process.exit 1
      housings = []
      if typeof def.housing is 'string'
        keys = def.housing.replace(/\s+/g, '').split(',')
        for key in keys
          housing = def[key]
          housing.suffix ?= key
          housings.push housing
      else # Is object
        def.housing.suffix ?= ''
        housings.push def.housing
      name = def.name
      # Create separate element for each housing
      for housing in housings
        suffixes = housing.suffix.replace(/\s+/g, '').split(',')
        def.name = name + suffixes[0]
        def.housing = housing
        aliases = []
        if def.alias?
          for alias in def.alias.replace(/\s+/g, '').split(',')
            aliases = aliases.concat(suffixes.map (v) => alias + v)
        if suffixes.length > 1
          aliases = aliases.concat(suffixes[1..].map (v) => name + v)

        def.aliases = aliases
        newElement = new QedaElement(this, def)
        @elements.push newElement
        res.push newElement
    res

  #
  # Add symbol
  #
  addSymbol: (symbol, name) ->
    def =
      name: name
      schematic:
        symbol: symbol
    newElement = new QedaElement(this, def)
    @elements.push newElement
    newElement

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
    defs = []
    def = @loadYaml element, force

    if def.variation? # Base element
      variations = def.variation.replace(/\s+/g, '').split(',')
      for variation in variations
        variationElement = variation
        if path.dirname(variationElement) is '.' then variationElement = path.dirname(element) + '/' + variationElement
        variationDef = @loadYaml variationElement, force
        defs.push variationDef
    else
      defs.push def

    for def, i in defs
      if def.base?
        unless typeof def.base is 'string' then def.base = def.base.toString()
        bases = def.base.replace(/\s+/g, '').split(',')
        delete def.base # We do not need this information now
        exclude = ['abstract', 'alias', 'variation'] # Exclude these fields from base object
        for base in bases
          baseElement = base
          if path.dirname(baseElement) is '.' then baseElement = path.dirname(element) + '/' + baseElement
          baseDef = @loadYaml baseElement, force
          for e in exclude
            if baseDef[e]? then delete baseDef[e]
          @mergeObjects baseDef, def
          defs[i] = baseDef
    defs

  loadYaml: (element, force = false) ->
    elementYaml = element.toLowerCase() + '.yaml'
    localFile = './library/' + elementYaml
    if (not fs.existsSync localFile) or force
      log.start "Load '#{element}'"
      elementYaml = elementYaml.split('/').map((a) -> encodeURIComponent(a)).join('/')
      try
        res = request 'GET', 'https://raw.githubusercontent.com/qeda/library/master/' + elementYaml,
          timeout: @connection.timeout
      catch error
        log.error error.message
      if res.statusCode is 200
        mkdirp.sync (path.dirname localFile)
        fs.writeFileSync localFile, res.body
        log.ok()
      else
        log.warning res.statusCode
    log.start "Read '#{element}'"
    try
      def = yaml.safeLoad fs.readFileSync(localFile)
      # TODO: YAML Schema validation
    catch error
      log.error "#{error.message}"
    log.ok()
    def

  #
  # Merge two objects
  #
  mergeObjects: (dest, src) ->
    for k, v of src
      if typeof v is 'object' and (not Array.isArray v) and dest.hasOwnProperty k
        @mergeObjects dest[k], v
      else
        dest[k] = v

  #
  # Add power symbol
  #
  power: (name) ->
    @addSymbol 'power', name

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
