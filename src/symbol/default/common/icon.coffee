class Icon
  constructor: (@symbol, @element) ->
    @schematic = @element.schematic
    @settings = @symbol.settings
    @lineWidth = @settings.lineWidth.thick
    @width *= @settings.factor
    @height *= @settings.factor

module.exports = Icon
