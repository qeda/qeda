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
    @symbol =
      style: 'default'
      units: 'mil'
      gridSize: 50 # mil
      fontSize: # Grid units
        default: 1
        refDes: 1
        name: 1
        pinNumber: 1
        pinName: 1
      lineWidth: # Grid units
        default: 0.3
      space: # Grid units
        pinName: 1
    @pattern =
      style: 'default'
      densityLevel: 'N' # Nominal
      decimals: 3
      polarityMark: 'dot'
      tolerance:
        default: 0.1
        fabrication: 0.1
        placement: 0.1
      clearance:
        padToSilk: 0.2
        padToPad: 0.2
        padToMask: 0.05
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
    def = @load element
    if def.abstract
      console.error "'#{element}': Cannot add abstract component, use it only as base for others"
      process.exit 1
    res = []
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
      if suffixes.length > 1
        aliases = []
        if def.alias?
          aliases.concat def.alias.replace(/\s+/g, '').split(',')
        aliases.concat(suffixes.map (a) => name + a)
        def.aliases = aliases
      newElement = new QedaElement(this, def)
      @elements.push newElement
      res.push newElement
    res

  #
  # Calculate patterns' dimensions according to settings
  #
  calculate: ->
    @_calculated ?= false
    if @_calculated then return

    for element in @elements
      element.render()

    for prop of @symbol.fontSize
      @symbol.fontSize[prop] *= @symbol.gridSize
    for prop of @symbol.lineWidth
      @symbol.lineWidth[prop] *= @symbol.gridSize
    for prop of @symbol.space
      @symbol.space[prop] *= @symbol.gridSize

    for element in @elements
      for symbol in element.symbols
        symbol.resize @symbol.gridSize
    @_calculated = true

  #
  # Generate library in given format
  #
  generate: (name) ->
    log.start "Render library '#{name}'"
    @calculate()
    log.ok()
    generator = null
    switch @output
      when 'kicad' then generator = new KicadGenerator(this)
    if generator
      log.start "Generate output for '#{name}'"
      generator.generate name
      log.ok()

  #
  # Load element description from remote repository
  #
  load: (element, force = false) ->
    elementYaml = element.toLowerCase() + '.yaml'
    localFile = './library/' + elementYaml
    if (not fs.existsSync localFile) or force
      log.start "Load '#{element}'"
      elementYaml = elementYaml.split('/').map((a) -> encodeURIComponent(a)).join('/')
      try
        res = request 'GET', 'https://raw.githubusercontent.com/qeda/library/master/' + elementYaml,
          timeout: 3000
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
    if def.base?
      unless typeof def.base is 'string' then def.base = def.base.toString()
      bases = def.base.replace(/\s+/g, '').split(',')
      delete def.base # We do not need this information now
      for base in bases
        baseElement = base
        if path.dirname(baseElement) is '.' then baseElement = path.dirname(element) + '/' + baseElement
        baseDef = @load baseElement
        if baseDef.abstract then delete baseDef.abstract # In order to not merge into def
        @mergeObjects baseDef, def
        def = baseDef
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

module.exports = QedaLibrary
