utils = require '../d3utils'

defaults =
  width: 200
  height: 10
  maxX: null
  colors: null
  fontSize: 16
  lineHeight: 1.2
  onmouseover: null
  onmouseleave: null
  transition: 500

colorGenerator = (colors) ->
  index = -1
  isArray = Array.isArray colors
  ->
    index = index + 1
    if isArray
      colors[index = index % colors.length]
    else
      colors index

module.exports = (array, options) ->
  options = _.extend {}, defaults, options
  unless options.colors
    options.colors = do d3.scale.category10
  getColor = colorGenerator options.colors
  halfHeight = options.height / 2
  id = do utils.getId
  clipperId = "d3bar-clipper-#{id}"
  shadowId = "d3chart-shadow-#{id}"

  sum = d3.sum array
  options.maxX ?= sum
  x = d3.scale.linear()
    .domain [0, options.maxX]
    .range [0, options.width]
  data = _.reduce array, (obj, d, i) ->
      r =
        value: d
        index: i
        x: obj.lastWidth
        dx: x d
      obj.list.push r
      obj.lastWidth += r.dx
      obj
    ,
      list: []
      lastWidth: 0
    .list
  sumX = x sum

  svg = utils.newSVG()
    .attr
      'class': 'd3bar'
      width: options.width
      height: options.height
  utils.addShadowFilter svg, shadowId
  clipper = utils.addClipPath svg, clipperId
  clipper_rect = clipper.append 'rect'
    .attr
      x: 0
      y: 0
      width: 0
      height: options.height
      rx: halfHeight
      ry: halfHeight
  if options.transition
    clipper_rect = clipper_rect.transition()
      .duration options.transition
  clipper_rect.attr 'width', sumX

  wrap = svg.append 'g'
    .attr 'clip-path', "url(##{clipperId})"
  lines = wrap.selectAll 'line'
    .data data
    .enter()
    .append 'line'
    .attr
      'class': 'd3bar-line'
      stroke: -> do getColor
      'stroke-width': options.height
      x1: 0
      x2: 0
      y1: halfHeight
      y2: halfHeight
    .on 'mouseover', ->
      line = d3.select @
      [d] = line.data
      options.onmouseover? d3.event, d
  if options.transition
    lines = lines.transition()
      .duration options.transition
  lines.attr
    x1: (d) -> d.x
    x2: (d) -> d.x + d.dx
  wrap.on 'mouseleave', ->
    options.onmouseleave? d3.event

  svg[0][0]
