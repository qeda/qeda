class Icon
  constructor: (@symbol, @element) ->
    @schematic = @element.schematic
    @settings = @symbol.settings
    @lineWidth = @settings.lineWidth.thick
    @width = 2 * @symbol.alignToGrid(@width/2, 'ceil')
    @height = 2 * @symbol.alignToGrid(@height/2, 'ceil')

module.exports = Icon
