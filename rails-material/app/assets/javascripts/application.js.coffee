# This is a manifest file that'll be compiled into application.js, which will include all the files
# listed below.
#
# Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
# vendor/assets/javascripts directory can be referenced here using a relative path.
#
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# compiled file. JavaScript code in this file should be added after the last require_* statement.
#
# Read Sprockets README (https:#github.com/rails/sprockets#sprockets-directives) for details
# about supported directives.
#
#= require rails-ujs
#= require jquery
#= require jquery_ujs
#= require semantic-ui
#= require webstorage
#= require alertify
#= require underscore
#= require jquery.easyaudioeffects.min
#= require saveas.min
#= require angular
#= require clipper
window.error_sound = "Quick-Out"
window.take_picture = "Glass-Up"
window.send_picture = "Glass-Down"
window.tap = "Satisfying-Click"
window.heat = "Tiny-Glitch"
window.cool = "Tiny-Glitch"
# window.cool = "Quick-Reverse"
ws = new WebStorage()
window.server_ip = "192.168.1.4"
window.participant_id = "PILOT"

if ws.includes("server_ip")
  window.server_ip = ws.get("server_ip")
else
  ws.set("server_ip", window.server_ip)

if ws.includes("participant_id")
  window.participant_id = ws.get("participant_id")
else
  ws.set("participant_id", window.participant_id)
  
window.YELLOW = "#FF9912"
window.WHITE = "#f5f4f0"
window.BLACK = "#000000"
window.ACTIVE_STATE = YELLOW
window.INACTIVE_STATE = WHITE
window.INACTIVE_STATE_ARROW = BLACK



$ ->
  $('.ui.dropdown').dropdown()
  _.each $('.audio-test-btn'), (btn)->
    btn = $(btn)
    btn.easyAudioEffects
      # ogg : "/audio/"+$(btn).attr('id')+".ogg",
      mp3 : "/all_audio/"+$(btn).attr('file')+".wav"
      eventType : "click"
      playType : "oneShotPolyphonic"
  _.each $('.audio-btn'), (btn)->
    btn = $(btn)
    btn.easyAudioEffects
      # ogg : "/audio/"+$(btn).attr('id')+".ogg",
      mp3 : "/audio/"+$(btn).attr('file')+".wav"
      eventType : "click"
      playType : "oneShotPolyphonic"

  alertify.set('notifier','position', 'bottom-left');
  $("body").append( 
    "<button 
      type='button' 
      class='ui button mini green'
      id='server_ip_config_btn'
      style='position:fixed; margin: 5px; bottom:0; right:10px;z-index:1000;'
    >" + window.server_ip + "</button>"
  )
  $("body").append( 
    "<button 
      type='button' 
      class='ui button mini'
      id='participant_id_config_btn'
      style='position:fixed; margin: 5px; bottom:0; right:110px; z-index:1000;'
    > <i class='icon user'></i><span class='pid'>" + window.participant_id + "</span></button>"
  )

  # https://stackoverflow.com/questions/4460586/javascript-regular-expression-to-check-for-ip-addresses
  validate_ip_address = ((ipaddress) -> 
    if /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/.test(ipaddress)
      return true
    else
      return false
  )

  $("#server_ip_config_btn").click ->
    alertify.prompt('Config', 'Change IP address', window.server_ip,
      (evt, value) -> (() -> 
        if validate_ip_address(value)
          window.server_ip = value
          ws.set("server_ip", window.server_ip)
          alertify.success('IP address updated to: ' + window.server_ip)
          $("#server_ip_config_btn").text(window.server_ip)
        else
          alertify.error('Invalid IP address')
          playSound(window.error_sound)
      )(),
      () -> alertify.error('Cancel') )
  $("#participant_id_config_btn").click ->
    alertify.prompt('Config', 'Change Participant ID?', window.participant_id,
      (evt, value) -> (() -> 
        window.participant_id = value
        ws.set("participant_id", window.participant_id)
        alertify.success('<i class="icon user"></i> ' + window.participant_id)
        $("#participant_id_config_btn").find('.pid').html(window.participant_id)
      )(),
      () -> alertify.error('Cancel') )
window.pad = (n, width, z) ->
  z = z or '0'
  n = n + ''
  if n.length >= width then n else new Array(width - (n.length) + 1).join(z) + n

$(()->
  _.mixin isColorString: (str)->
    return typeof str == 'string' && str[0] == "#" && str.length == 7
  _.mixin zeros: (length)->
    return Array.apply(null, Array(length)).map(Number.prototype.valueOf,0)
  _.mixin fill: (length, v)->
    return Array.apply(null, Array(length)).map(Number.prototype.valueOf,v)
  _.mixin repeat: (func, interval)->
    args = _.last arguments, 2
    return setInterval(_.bind(func, null, args), interval);
  _.mixin sum: (arr)->
    return _.reduce arr, ((memo, num)-> return memo + num ), 0
    
  String.prototype.replaceAll = (search, replacement)->
    target = this
    return target.replace(new RegExp(search, 'g'), replacement)
  
)
window.playSound = (name)->
  # alertify.success "Playing " + name
  $("#" + name).mousedown()
  _.delay (()-> $("#" + name).mouseup()), 400

window.rgb2hex = (rgb) ->
  rgb = rgb.match(/^rgba?[\s+]?\([\s+]?(\d+)[\s+]?,[\s+]?(\d+)[\s+]?,[\s+]?(\d+)[\s+]?/i)
  if rgb and rgb.length == 4 then '#' + ('0' + parseInt(rgb[1], 10).toString(16)).slice(-2) + ('0' + parseInt(rgb[2], 10).toString(16)).slice(-2) + ('0' + parseInt(rgb[3], 10).toString(16)).slice(-2) else ''

window.rgb2hex2 = (rgb) ->
  rgb = rgb.match(/^rgba?[\s+]?\([\s+]?(\d+)[\s+]?,[\s+]?(\d+)[\s+]?,[\s+]?(\d+)[\s+]?/i)
  if rgb and rgb.length == 4 then '0x' + ('0' + parseInt(rgb[1], 10).toString(16)).slice(-2) + ('0' + parseInt(rgb[2], 10).toString(16)).slice(-2) + ('0' + parseInt(rgb[3], 10).toString(16)).slice(-2) else ''
transformToAssocArray = (prmstr) ->
  params = {}
  prmarr = prmstr.split('&')
  i = 0
  while i < prmarr.length
    tmparr = prmarr[i].split('=')
    params[tmparr[0]] = tmparr[1]
    i++
  params
window.GET = ->
  prmstr = window.location.search.substr(1)
  if prmstr != null and prmstr != '' then transformToAssocArray(prmstr) else {}

window.guid = ->
  s4 = ->
    Math.floor((1 + Math.random()) * 0x10000).toString(16).substring 1
  s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4()

window.poly = (a, b, c, x) ->
  x ** 2 * a + x * b + c

window.capitalize = (string)->
  return string.charAt(0).toUpperCase() + string.slice(1)

Math.radians = (degrees) ->
  degrees * Math.PI / 180
Math.degrees = (radians) ->
  radians * 180 / Math.PI

if !Date.now
  Date.now = ->
    (new Date).getTime()

window.DOM = ->

window.DOM.tag = (tag, single) ->
  if single
    $ '<' + tag + '/>'
  else if typeof single == 'undefined'
    $ '<' + tag + '>' + '</' + tag + '>'
  else
    $ '<' + tag + '>' + '</' + tag + '>'

Object.size = (obj) ->
  size = 0
  key = undefined
  for key of obj
    if obj.hasOwnProperty(key)
      size++
  size
window.objectToFormData = (obj, form, namespace) ->
  fd = form or new FormData
  formKey = undefined
  for property of obj
    if obj.hasOwnProperty(property)
      if namespace
        formKey = namespace + '[' + property + ']'
      else
        formKey = property
      # if the property is an object, but not a File,
      # use recursivity.
      if typeof obj[property] == 'object' and !(obj[property] instanceof File)
        objectToFormData obj[property], fd, property
      else
        # if it's a string or a File object
        fd.append formKey, obj[property]
  fd


window.Utility = ->

window.Utility.paperSetup = (id, op) ->
  dom = if typeof id == 'string' then $('#' + id) else id
  # w = dom.parent().height()
  if op and op.width then dom.parent().width(op.width+1)
  if op and op.width then dom.width(op.width+1)
  if op and op.height then dom.parent().height(op.height+1)
  if op and op.height then dom.height(op.height)
  # dom.attr 'height', w
  # dom.attr 'width', '90px'
  paper.install window
  myPaper = new (paper.PaperScope)
  myPaper.setup dom[0]
  # if typeof id == 'string'
  #   console.info 'Paper.js installed on', id, w, 'x', h
  # else
  #   console.info 'Paper.js installed:', w, 'x', h
  myPaper

window.installPaper = (dimensions)->
  # PAPER SETUP
  markup = $('canvas#markup')[0]
  paper.install window
  vizpaper = new paper.PaperScope()
  vizpaper.setup(markup)
  vizpaper.settings.handleSize = 10
  loadCustomLibraries()
  return vizpaper

window.makePaper = (parent)->
  c = $('<canvas></canvas>')
  parent.html(c)
  c.attr
    height: parent.height()
  console.log parent.height()
  p = new paper.PaperScope()
  p.setup(c[0])
  p.settings.handleSize = 10
  new paper.Path.Circle
    radius: 20
    fillColor: "#00A8E1"
    position: paper.view.center
  return p



window.loadCustomLibraries = ->

  ###Map path's perimeter points into jsclipper format
  [[{X:30,Y:30},{X:130,Y:30},{X:130,Y:130},{X:30,Y:130}]]
  ###

  toClipperPoints = (path, offset = 1) ->
    points = _.range(0, path.length, offset)
    points = _.map(points, (i) ->
      p = path.getPointAt(i)
      {
        X: p.x
        Y: p.y
      }
    )
    [ points ]
    # compound paths

  console.log 'Loading custom libraries!'

  paper.project.computeHull = (pts) ->
    `var pts`
    `var pts`
    # in point form; must convert to [[x,y]]
    # console.log("COMPUTING HULL", pts.length, pts)
    pts = _.map(pts, (pt) ->
      [
        pt.x
        pt.y
      ]
    )
    pts = hull(pts, 50)
    pts = _.map(pts, (p) ->
      new (paper.Point)(p[0], p[1])
    )
    new (paper.Path)(pts)

  paper.project.computeOMBB = (hull) ->
    degree_of_rotation = _.range(0, 360, 1)
    cost_table = _.map(degree_of_rotation, (angle, i, arr) ->
      hull.rotation = angle
      pos_ombb = new (paper.Path.Rectangle)(hull.bounds.clone())
      cost = paper.project.computeOMBBCost(hull, pos_ombb)
      return {
        angle: angle
        cost: cost
      }
      pos_ombb.remove()
      return
    )
    # returns the entry, that corresponds to smallest angle
    best_option = _.min(cost_table, (result) ->
      result.cost
    )
    convex.rotation = best_option.angle
    -best_option.angle

  paper.project.computeOMBBCost = (convex, possible_ombb) ->
    convex_area = convex.area
    intersection_area = possible_ombb.area - convex_area
    intersection_area

  paper.project.computeMagnets = (ombb) ->
    points = _.map(ombb.segments, (seg) ->
      seg.point
    )
    referencePoint = points[0]
    firstAndLast = points[0]
    # lines represent the sides of the ombb
    # lines are pushed, starting from the left line, then top, right, and finally bottom line
    lines = []
    i = 1
    while i < points.length
      lines.push new (paper.Path.Line)(
        from: referencePoint
        to: points[i])
      referencePoint = points[i]
      if i == 3
        lines.push new (paper.Path.Line)(
          from: points[i]
          to: firstAndLast)
      i++
    magnets = _.map(lines, (line) ->
      line.getPointAt line.length / 2
    )
    magnets

  paper.Path::calculateOMBB = ->
    scope = this
    pts = _.range(0, @length, 0.5)
    pts = _.map(pts, (pt) ->
      scope.getPointAt pt
    )
    @hull = paper.project.computeHull(pts)
    angle = paper.project.computeOMBB(@hull)
    bb = @hull.clone()
    console.log 'ANGLE', angle
    bb.rotation = -angle
    ombb = new (paper.Path.Rectangle)(rectangle: bb.bounds)
    bb.remove()
    ombb.rotation = angle
    @ombb = ombb
    @hull.visible = false
    @ombb.visible = false
    this

  paper.Path::getMagnets = (ombb) ->
    ombb.rotation = 0
    @magnets = paper.project.computeMagnets(ombb)
    @magnets.west = @magnets[0]
    @magnets.north = @magnets[1]
    @magnets.east = @magnets[2]
    @magnets.south = @magnets[3]
    this

  paper.Path::centroid = ->
    calc_centroid = _.reduce(@segments, ((memo, seg) ->
      memo.add new (paper.Point)(seg.point.x, seg.point.y)
    ), new (paper.Point)(0, 0))
    calc_centroid.divide @segments.length

  paper.Path.Join =
    square: ClipperLib.JoinType.jtSquare
    round: ClipperLib.JoinType.jtRound
    miter: ClipperLib.JoinType.jtMiter
  paper.Path.Alignment =
    interior: -1
    centered: 0
    exterior: 1

  paper.CompoundPath::expand = (o) ->
    cp = new (paper.CompoundPath)(o)
    _.extend o, parent: cp
    _.each @children, (p, i) ->
      p.expand o
      return
    cp

  paper.Group::expand = (o) ->
    _.each @children, (p, i) ->
      p.expand o
      return
    return

  # Usage example 
  # var expanded = diffuser.expand({
  #        strokeAlignment: "exterior", 
  #        strokeWidth: 1,
  #        strokeOffset: 5, 
  #        strokeColor: "black", 
  #        fillColor: "white", 
  #        joinType: "miter", 
  #        parent: result
  #      });
  # expandedStroke = diffuser.expand
  #   strokeAlignment: "exterior" or "interior" or "centered"
  #   joinType: "miter" or "square" or "round"
  #   strokeOffset: 5
  #   miterLimit: 2
  #   arcTolerance: 0.25
  #   scaleFactor: 1000
  #   style: 
  #     parent: someGroup
  #     strokeWidth: 1,
  #     strokeColor: "black" 
  #     fillColor: "white"
  # ...
  paper.Path::expand = (o) ->
    # SETUP
    endType = ClipperLib.EndType.etClosedPolygon
    joinType = paper.Path.Join[o.joinType]

    offset = paper.Path.Alignment[o.strokeAlignment] * o.strokeOffset
    offset = if o.strokeAlignment == "centered" then offset/2 else offset
    deltas = [offset]
    paths = toClipperPoints(this, 1)

    scale = 1000 or o.scaleFactor
    ClipperLib.JS.ScaleUpPaths paths, scale

    # CLIPPER ENGINE
    co = new (ClipperLib.ClipperOffset)
    # constructor
    offsetted_paths = new (ClipperLib.Paths)
    # empty solution
    _.each deltas, (d) ->
      co.Clear()
      co.AddPaths paths, joinType, endType
      co.MiterLimit = 2 or o.miterLimit
      co.ArcTolerance = 0.25 or o.arcTolerance
      co.Execute offsetted_paths, d * scale
      return

    segs = []
    i = 0
    while i < offsetted_paths.length
      j = 0
      while j < offsetted_paths[i].length
        p = new (paper.Point)(offsetted_paths[i][j].X, offsetted_paths[i][j].Y)
        p = p.divide(scale)
        segs.push p
        j++
      i++
    clipperStrokePath = new paper.Path
      segments: segs
      closed: true
    clipperStrokePath.set o.style
    clipperStrokePath

  return

# ---
# generated by js2coffee 2.2.0

