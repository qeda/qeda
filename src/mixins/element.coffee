fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'
request = require 'sync-request'
QedaElement = require '../qeda-element'

module.exports =
  _initElements: () ->
    @symbolDefs = [
      { regexp: /IC2/, handler: 'ic2' },
    ]
    @patternDefs = [
      { regexp: /SOP(\d+)P(\d+)X(\d+)-(\d+)/, handler: 'sm/soic' },
      { regexp: /SOIC(\d+)P(\d+)X(\d+)-(\d+)/, handler: 'sm/soic' }
    ]
    @elements = []

  add: (element) ->
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

    description = JSON.parse fs.readFileSync(localFile)
    newElement = new QedaElement this, description
    @elements.push newElement
    return newElement

  addPatternDefinition: (regexp, handler) ->
    @patternDefs.push regexp:regexp, handler: handler
