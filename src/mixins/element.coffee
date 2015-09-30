fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'
request = require 'sync-request'

module.exports =
  _initElements: () ->
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

     data = JSON.parse fs.readFileSync(localFile)
     @elements.push data
     console.log data
