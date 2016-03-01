class Icon
  constructor: (@symbol, @element) ->
    @schematic = @element.schematic
    @settings = @symbol.settings
    @lineWidth = @settings.lineWidth.thick

module.exports = Icon
