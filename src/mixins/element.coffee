fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'
request = require 'sync-request'
QedaElement = require '../qeda-element'

module.exports =
  _initElements: () ->
    @symbolDefs = [
      { regexp: /DIL(\d+)/, handler: 'dil' },
    ]
    @patternDefs = [
      { regexp: /SOP(\d+)P(\d+)X(\d+)-(\d+)/, handler: 'sm/soic' },
      { regexp: /SOIC(\d+)P(\d+)X(\d+)-(\d+)/, handler: 'sm/soic' }
    ]
    @elements = []

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
    return def

  add: (element) ->
    def = @load element
    if def.abstract
      console.error "'#{element}': Cannot add abstract component, use it only as base for others"
      process.exit 1
    newElement = new QedaElement this, def
    @elements.push newElement
    return newElement

  addPatternDefinition: (regexp, handler) ->
    @patternDefs.push regexp:regexp, handler: handler
