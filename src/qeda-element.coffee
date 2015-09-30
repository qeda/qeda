class QedaElement
  constructor: (description) ->
    @mergeObjects this, description
    unless Array.isArray @package
      @package = [@package]
    for p in @package
      console.log p

  mergeObjects: (dest, src) ->
    for k, v of src
      if typeof v is 'object' and dest.hasOwnProperty k
        @mergeObjects dest[k], v
      else
        dest[k] = v

module.exports = QedaElement
