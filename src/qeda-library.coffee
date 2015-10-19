fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'
request = require 'sync-request'

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
    @symbol =
      textSize: 1.4 # Grid units
      pinNameSpace: 1 # Grid units
      units: 'mm'
      gridSize: 2.5 # mm
    @mergeObjects this, settings

    @symbolDefs = [
      { regexp: /DIL(\d+)/, handler: 'dil' },
    ]
    @patternDefs = [
      { regexp: /SOP(\d+)P(\d+)X(\d+)-(\d+)/, handler: 'sm/soic' },
      { regexp: /SOIC(\d+)P(\d+)X(\d+)-(\d+)/, handler: 'sm/soic' }
    ]
    @outlineDefs = [
      { regexp: /JEDEC-(.*)/, handler: 'jedec' }
    ]
    @elements = []

  #
  # Add element
  #
  add: (element) ->
    def = @load element
    if def.abstract
      console.error "'#{element}': Cannot add abstract component, use it only as base for others"
      process.exit 1
    newElement = new QedaElement this, def
    @elements.push newElement
    return newElement

  #
  # Add pattern definition: regular expression assotiated with handler script
  #
  addPatternDefinition: (regexp, handler) ->
    @patternDefs.push regexp:regexp, handler: handler

  #
  # Calculate patterns' dimensions according to settings
  #
  calculate: ->
    @_calculated ?= false
    if @_calculated then return
    @symbol.textSize *= @symbol.gridSize
    @symbol.pinNameSpace *= @symbol.gridSize
    for e in @elements
      e.calculate @symbol.gridSize
    @_calculated = true

  #
  # Generate library in KiCad format
  #
  generateKicad: (name) ->
    @calculate()
    kicad = new KicadGenerator(this)
    kicad.generate name

  #
  # Load element description from remote repository
  #
  load: (element) ->
    elementJson = element.toLowerCase() + '.json'
    localFile = './library/' + elementJson
    unless fs.existsSync localFile
      res = request 'GET', 'https://raw.githubusercontent.com/qeda/library/master/' + elementJson, timeout: 3000
      if res.statusCode is 200
        mkdirp.sync (path.dirname localFile)
        fs.writeFileSync localFile, res.body
        console.log "Loading '#{element}': OK"
      else
        console.error "Loading '#{element}': Error (#{res.statusCode})"
        process.exit 1
    def = JSON.parse fs.readFileSync(localFile)
    # TODO: JSON Schema validation
    if def.base?
      baseElement = def.base
      delete def.base
      if path.dirname(baseElement) is '.' then baseElement = path.dirname(element) + '/' + baseElement
      baseDef = @load baseElement
      if baseDef.abstract then delete baseDef.abstract
      @mergeObjects baseDef, def
      def = baseDef
    def

  #
  # Merge two objects
  #
  mergeObjects: (dest, src) ->
    for k, v of src
      if typeof v is 'object' and dest.hasOwnProperty k
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
