fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'
request = require 'sync-request'
yaml = require 'js-yaml'

KicadGenerator = require './kicad-generator'
QedaElement = require './qeda-element'

class QedaLibrary
  #
  # Constructor
  #
  constructor: (settings = {}) ->
    @elementStyle = 'default'
    @symbolStyle = 'default'
    @patternStyle = 'default'
    @output = 'kicad'
    @symbol =
      units: 'mil'
      gridSize: 50 # mil
      fontSize: # Grid units
        default: 1
        refDes: 1
        name: 1
        pinNumber: 1
        pinName: 1
      lineWidth: # Grid units
        default: 0.02
      space: # Grid units
        pinName: 1
    @pattern =
      densityLevel: 'N' # Nominal
      decimals: 3
      tolerance:
        default: 0.1
        fabrication: 0.05
        placement: 0.05
      clearance:
        padToSilk: 0.2
      lineWidth:
        default: 0.2
        silkscreen: 0.2
        assembly: 0.1
      fontSize: # mm
        default: 1
        refDes: 1
        value: 1
    @mergeObjects this, settings

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
    @calculate()
    generator = null
    switch @output
      when 'kicad' then generator = new KicadGenerator(this)
    if generator then generator.generate name

  #
  # Load element description from remote repository
  #
  load: (element) ->
    elementYaml = element.toLowerCase() + '.yaml'
    localFile = './library/' + elementYaml
    unless fs.existsSync localFile
      try
        r = request.defaults proxy:'http://proxy.croc.ru:8000'
        res = request 'GET', 'https://raw.githubusercontent.com/qeda/library/master/' + elementYaml, timeout: 3000
      catch error
        console.error "Loading '#{element}': Error: #{error.message}"
        process.exit 1
      if res.statusCode is 200
        mkdirp.sync (path.dirname localFile)
        fs.writeFileSync localFile, res.body
        console.log "Loading '#{element}': OK"
      else
        console.error "Loading '#{element}': Error: (#{res.statusCode})"
        process.exit 1
    try
      def = yaml.safeLoad fs.readFileSync(localFile)
      # TODO: YAML Schema validation
    catch error
      console.error "Loading '#{element}': Error: #{error.message}"
      process.exit 1
    if def.base?
      bases = def.base.replace(/\s+/g, '').split(',')
      delete def.base # We do not need this information now
      for base in bases
        baseElement = base
        if path.dirname(baseElement) is '.' then baseElement = path.dirname(element) + '/' + baseElement
        baseDef = @load baseElement
        if baseDef.abstract then delete baseDef.abstract # In order to not merge into def
        @mergeObjects baseDef, def
        def = baseDef
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
  # Change element style
  #
  setElementStyle: (style) ->
    style = style.toLowerCase()
    @elementStyle = style
    if @symbolStyle is 'default' or style is 'default' then @symbolStyle = style
    if @patternStyle is 'default' or style is 'default' then @patternStyle = style

  #
  # Change pattern style
  #
  setPatternStyle: (style) ->
    @patternStyle = style.toLowerCase()

  #
  # Change symbol style
  #
  setSymbolStyle: (style) ->
    @symbolStyle = style.toLowerCase()

module.exports = QedaLibrary
