class Icon
  constructor: (@symbol, @element, width, height) ->
    @schematic = @element.schematic
    @settings = @symbol.settings
    @lineWidth = @settings.lineWidth.thick
    @width = width * @settings.factor
    @height = height * @settings.factor

module.exports = Icon
