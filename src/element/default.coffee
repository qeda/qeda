designators =
  C : ['capacitor']
  U: ['ic']
  R: ['resistor']

module.exports = (element) ->
  keywords = element.keywords.replace(/\s+/g, '').split(',').map (a) -> a.toLowerCase()
  refWeight = 0
  for des, classes of designators
    weight = keywords.filter((a) => classes.indexOf(a) isnt -1).length
    if weight > refWeight
      refWeight = weight
      element.refDes = des
