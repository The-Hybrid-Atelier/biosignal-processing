# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

#= require atelier
#= require paper
#= require ruler
#= require arrow
#= require numeric
#= require canvas_ui/matlib
#= require canvas_ui/thermopainting
#= require canvas_ui/material
#= require canvas_ui/environment
#= require canvas_ui/scale
#= require canvas_ui/heat_space
#= require canvas_ui/heat_sim
#= require canvas_ui/collectable
#= require canvas_ui/ui_element
#= require canvas_ui/ui_branch
#= require canvas_ui/ui_space
#= require canvas_ui/ui_twig
#= require canvas_ui/gutter
#= require canvas_ui/tracker
#= require canvas_ui/tree

$ ->
  window.light_red = new paper.Color "red"
  light_red.alpha = 0.5

  window.light_green = new paper.Color "green"
  light_green.alpha = 0.5



paper.Tool.prototype.bindHotKeys = ()->
  this.set
    onKeyUp: (e)->
        if e.key == "shift"
          $('#magnetize').mouseup()
    onKeyDown: (e)->
      scope = this
      if e.modifiers.shift and e.key == "shift"
        $('#magnetize').mousedown()
      if e.modifiers.shift
        if e.modifiers.command and e.key == "z"
          # REDO
          $('#redo').click()
      else
        if e.modifiers.command and e.key == "d"
          # e.preventDefault()
          alertify.success "TODO: DUPLICATE"  
        if e.modifiers.command and e.key == "z"
          # UNDO
          $('#undo').click()
        if e.key == "h"
          $('button.heat[name="heat_tool"]').click()
        if e.key == "e"
          $('button.eraser[name="eraser_tool"]').click()
        if e.key == "c"
          $('button.cut[name="cut_tool"]').click()
        if e.key == "a"
          $('#annotate').click()
        if e.modifiers.command and e.key == "s"
          # e.preventDefault()
          # SAVE
          $('#save').click()
        if e.key == "backspace"
          # DELETE SELECTED ELEMENTS
          $('button.eraser').click()
          # $('#save').click()
          # _.each paper.project.selectedItems, (item)->
          #   if item
          #     item = scope.getGroup(item)
          #     item.remove()

paper.Item.prototype.fireTouchGestures = ()->
  if this.onMouseDown
    return
  this.set
    threshold: 500
    classify: ()->
      this.elapsed_t = performance.now() - @down_t
      return if @elapsed_t > @threshold then "hold" else "brush"

    onMouseDown: (e)->
      # console.log "md", this.name

      this.down_t = performance.now()
      this.elapsed_t = 0
      this.event_type = null
      this.down_event = e
      that = this
      this.timer = _.delay (()-> 
        that.event_type = that.classify()
        switch that.event_type
          when "hold"
            if that.onHoldStart
              that.onHoldStart(that.down_event)
          when "brush"
            if that.onBrushStart
              that.onBrushStart(that.down_event)
      ), @threshold

    onMouseDrag: (e)->
      if not this.event_type
        # stop-timer
        if this.timer 
          clearTimeout(this.timer)
        # force classification
        this.event_type = @classify()
        # FIRE DOWN EVENT
        switch @event_type
          when "hold"
            if @onHoldStart
              @onHoldStart(@down_event)
          when "brush"
            if @onBrushStart
              @onBrushStart(@down_event)

      # DRAG EVENT
      switch @event_type
        when "hold"
          if @onHoldDrag
            @onHoldDrag(e)
        when "brush"
          if @onBrushDrag
            @onBrushDrag(e)

    onMouseUp: (e)->   
      if @event_type
        switch @event_type
          when "hold"
            if @onHoldDrag
              @onHoldEnd(@down_event)
          when "brush"
            if @onBrushDrag
              @onBrushEnd(@down_event)
      else
        if this.timer 
          clearTimeout(this.timer)
        this.event_type = @classify()
        switch @event_type
          when "hold"
            if @onHoldTap
              @onHoldTap(e)
          when "brush"
            if @onBrushTap
              @onBrushTap(e)


window.copyCanvasRegionToBuffer = (canvas, w, h, bufferCanvas) ->
  scale = 2
  if !bufferCanvas
    bufferCanvas = $('<canvas>').attr
      width: w
      height: h
    .appendTo("body")
    .addClass("buffer")
    .addClass("hidden")
    .get(0)
  bufferCanvas.getContext('2d').imageSmoothingEnabled = true
  bufferCanvas.getContext('2d').drawImage canvas, 0, 0, w * scale, h * scale, 0, 0, w, h
  bufferCanvas


window.adjustview = ()->
  p = paper.project.getItem
    name: "paper"

  paper.view.zoom = 1 
  delta = p.bounds.topLeft.clone()
  back_delta = delta.clone().multiply(-1)
  paper.view.translate(back_delta)
  # PRINT SPECIFICS


  paper.view.update()

  # CUT
  bufferCanvas = copyCanvasRegionToBuffer($('#markup')[0], p.bounds.width, p.bounds.height)
  bufferCanvas.toBlob (blob)->
    saveAs(blob, "my_heater.png")

  # REVERT

window.exportPNG = (result, filename, dom) ->
  # result = paper.
  
  console.log 'Exporting PNG...', filename
  result.fitBounds paper.view.bounds.expand(-100)
  result.position = paper.project.view.projectToView(new (paper.Point)(result.strokeBounds.width / 2.0, result.strokeBounds.height / 2.0))
  cut = paper.project.view.projectToView(new (paper.Point)(result.strokeBounds.width * BIAS, result.strokeBounds.height * BIAS))
  paper.view.update()
  
  bufferCanvas = copyCanvasRegionToBuffer($('#markup')[0], 0, 0, cut.x, cut.y)
  dom.attr('href', bufferCanvas.toDataURL('image/png')).attr 'download', filename + '.png'
  # dom.attr('href', $('#main-canvas')[0].toDataURL("image/png"))
  # .attr('download', filename + '.png');
  return

class window.HeatSketch
  constructor: ()->
    console.log "HEAT SKETCHER"

  @spiral: (config)->
    defaults = 
      traceWidth: config.strokeWidth
      traceInterval: config.strokeInterval
      boundary: config.boundaries[0]
      start: config.source
    prop = _.extend defaults, config
    console.log "SPIRAL", prop

    _.each paper.project.getItems({name: "spiral"}), (s)-> s.remove()


    shift_path = (p, pt)->
      nl = p.getNearestLocation(pt)
      segments = p.removeSegments(nl.segment.index + 1)
      p.insertSegments(0, segments)
      return p

    generateOffsets = (start, end, color, areaLimit=100, segMin = 10, iterLimit=500)->
      keep_going = true
      resample_path = (p, i=1, remove=false)->
        np =  new paper.Path
          name: "spiral"
          style: p.style
          innerWidth: p.innerWidth
          innerHeight: p.innerHeight
          segments: _.map _.range(0, p.length, i), (pt)->
            return p.getPointAt(pt)
          closed: true
        if remove then p.remove()
        return np
      nextStroke = resample_path(prop.boundary, 1, false)
      try
        i = 0
        paths = []
        while keep_going 
          sOff = if i == 0 then prop.traceWidth/2 else prop.traceWidth+prop.traceInterval
          nextStroke = nextStroke.expand
            strokeAlignment: "interior"
            joinType: "miter"
            strokeOffset: sOff
            miterLimit: 1
            arcTolerance: 0.25
            scaleFactor: 1000
            style: 
              name: "spiral"
              strokeWidth: prop.traceWidth
              strokeColor: color
              innerWidth: ()-> return this.bounds.width - this.strokeWidth/2 
              innerHeight: ()-> return this.bounds.height - this.strokeWidth/2 

          nextStroke = if nextStroke.segments.length < segMin then resample_path(nextStroke, 1, true) else nextStroke
          # CAN A TRACE FIT IN THE LAST CONTOUR TO ESCAPE THE SPIRAL?
          min_hallway = prop.traceWidth + 2 * prop.traceInterval
          escapable = if nextStroke.length == 0 then false else ((nextStroke.innerWidth() > min_hallway) and (nextStroke.innerHeight() > min_hallway))
          # CHECKS AGAINST INFINITE LOOPS AND CLIPPER ERRORS
          keep_going = (nextStroke.length > 0) and (i < iterLimit) and escapable
          if keep_going then paths.push nextStroke else nextStroke.remove()
          i = i + 1
      catch
        alertify.error "Could not generate a spiral pattern for that geometry. :("
        return [prop.boundary]
      return paths


    paths = generateOffsets(prop.start, prop.end, "red")


    # result = new paper.Path.Line
    #   name: "joule"
    #   parent: prop.parent
    #   to: prop.start
    #   from: prop.sink
    #   strokeWidth: prop.traceWidth
      # strokeWidth: 1.5*prop.traceWidth + 4 * prop.traceInterval
    result = new paper.Path
      parent: config.parent
      name: "joule"
      strokeColor: "magenta"
      strokeWidth: prop.traceWidth
      strokeJoin: "round"
      strokeCap: "butt"
    # HALLWAY TO HEAVEN
    if paths.length > 2
      lastBlob = paths[paths.length-1]
      vec = lastBlob.centroid().subtract(prop.start)

      l = new paper.Path.Line
        name: "joule"
        parent: prop.parent
        to: prop.start
        from: lastBlob.centroid()
        strokeWidth: 1.5*prop.traceWidth + 4 * prop.traceInterval
   
      hallway = new paper.Path.Rectangle
        size: [l.length, l.strokeWidth]
        name: "spiral"
        fillColor: "yellow"
        strokeColor: "black"
        strokeWidth: 1
      hallway.pivot = hallway.bounds.leftCenter
      hallway.set
        position: prop.start
      hallway.rotate(vec.angle)
    
      # SPIRALIZE
      
      _.each paths, (p, i)->
        ixts = p.getIntersections(hallway)
        out_pt = if p.clockwise then ixts[1].point else ixts[0].point
        in_pt = if p.clockwise then ixts[0].point else ixts[1].point
        shift_path(p, out_pt)
        p.strokeWidth = 1
        p.closed = false
        nl = p.getNearestLocation(in_pt)
        # console.log "out-idx", nl.segment.index, p.segments.length
        segments = p.removeSegments(nl.segment.index)
        if i % 2 == 1 then p.reverse()
        result.addSegments(p.segments)
        p.remove()
      result.addSegments(l.segments)

      # # CLEANUP
      _.each paper.project.getItems({name: "spiral"}), (s)-> s.remove()

      # console.log "RESULT", result.length, result
    return result


    
  @snake_tangent: (config) ->
    if not (config.source and config.sink and config.boundaries)
      alertify.error("Heater could not be generated for the area.")
      return null
      
    source = config.source
    sink = config.sink
    boundaries = config.boundaries
    boundary = boundaries[0]
    mat = config.mat
    
    try
      entryWay = boundary.getNearestPoint(source)
      entryOffset = boundary.getOffsetOf(entryWay)
      entryNormalIn = boundary.getNormalAt(entryOffset)
      entryNormalIn.length = 0.01
      entryNormalOut = boundary.getNormalAt(entryOffset)
      entryNormalOut.length =-0.01

      if boundary.contains(entryWay.add(entryNormalOut))
        direction = entryNormalOut
      else if boundary.contains(entryWay.add(entryNormalIn))
        direction = entryNormalIn
     
      direction.length = 0.01

      
      serpentine = new Path
        parent: config.parent
        name: "joule"
        strokeColor: if config.heatColor then config.heatColor else "silver"
        shadowColor: new paper.Color(0, 0, 0, 0.3)
        shadowBlur: 5
        strokeWidth: config.strokeWidth
        segments: [source.clone(), source.add(direction) ]
        strokeInterval: config.strokeInterval
        padding: config.strokeWidth/2 + config.padding 
        strokeJoin: "round"
        strokeCap: "butt"
     

      serpentine.set config.style
      HeatSketch.serpentine_gen serpentine, direction, source, sink, boundaries
      return serpentine
    catch err
      if serpentine
        serpentine.remove()
      return null

  @snake: (config) ->  
    serpentineA = @snake_mat(config)
    serpentineB = @snake_tangent(config)
    if not serpentineA then return serpentineA
    if not serpentineB then return serpentineB
    if serpentineA.length > serpentineB.length
      serpentineB.remove()
      return serpentineA
    else
      serpentineA.remove()
      return serpentineB

  @snake_mat: (config) ->  
    if not (config.source and config.sink and config.boundaries)
      alertify.error("Heater could not be generated for the area.")
      return null
      
    source = config.source
    sink = config.sink
    boundaries = config.boundaries
    boundary = boundaries[0]
    mat = config.mat
    
    try

      entryWay = boundary.getNearestPoint(source)
      entryOffset = boundary.getOffsetOf(entryWay)
      entryNormalIn = boundary.getNormalAt(entryOffset)
      entryNormalIn.length = 0.01
      entryNormalOut = boundary.getNormalAt(entryOffset)
      entryNormalOut.length =-0.01

      # if boundary.contains(entryWay.add(entryNormalOut))
      #   direction = entryNormalOut
      # else if boundary.contains(entryWay.add(entryNormalIn))
      #   direction = entryNormalIn
      # else
      direction = mat.getPointAt(5).subtract(mat.getPointAt(1))
      direction.length = 0.01

      
      serpentine = new Path
        parent: config.parent
        name: "joule"
        strokeColor: if config.heatColor then config.heatColor else "silver"
        shadowColor: new paper.Color(0, 0, 0, 0.3)
        shadowBlur: 5
        strokeWidth: config.strokeWidth
        segments: [source.clone(), source.add(direction) ]
        strokeInterval: config.strokeInterval
        padding: config.strokeWidth/2 + config.padding 
        strokeJoin: "round"
        strokeCap: "butt"
     

      serpentine.set config.style
      HeatSketch.serpentine_gen serpentine, direction, source, sink, boundaries
      return serpentine
    catch err
      if serpentine
        serpentine.remove()
      return null
      


  
  # GO IN THE LATERAL DIRECTION
  # FIND THE IXT
  # PROJECT IN THE DIRECTION OF HEAT - PADDING
  # FIND PROJECT_IXT
  # IF PROJECT_IXT > GAP+STROKE 
  #    ACCEPT
  # ELSE
  #   RECOMPUTE WITH SMALLER PADDING
  # IF LATERAL_PROJECT_LENGTH - PADDING IS < 0
  #    CONNECT TO SINK

  @serpentine_gen: (serp, guide, source, sink, boundaries)->
    scope = this

    sw = serp.strokeWidth
    gap = serp.strokeInterval
    padding = serp.padding

    
    medial_move = guide.normalize()
    medial_move.length = gap + sw


    serp.addSegment serp.lastSegment.point.add(medial_move)
    pt = true
    min_medial_move = sw + gap + padding * 3
    
    while pt
      pt = scope.move_lateral(serp, guide, 1, padding, serp.lastSegment.point, boundaries, min_medial_move, sink)
      if not pt then break
      # serp.addSegment pt

      medial_move = guide.normalize()
      medial_move.length = sw + gap
      serp.addSegment serp.lastSegment.point.add(medial_move)
        
      pt = scope.move_lateral(serp, guide, -1, padding, serp.lastSegment.point, boundaries, min_medial_move, sink)
      if not pt then break
      # serp.addSegment pt

      medial_move = guide.normalize()
      medial_move.length = sw + gap
      serp.addSegment serp.lastSegment.point.add(medial_move)
        
    

   
  @animate: ()->
    anim_snake = new (paper.Path)(
      strokeColor: 'orange'
      strokeWidth: 10)
    ps.add
      name: 'draw_snake'
      onRun: (event) ->
        pts = _.range(0, serpentine.length * event.parameter, 1)
        pts = _.map(pts, (off2) ->
          serpentine.getPointAt off2
        )
        anim_snake.removeSegments()
        anim_snake.addSegments pts
        return
      onKill: (event) ->
      duration: 1000
    return

  @move_lateral: (serp, guide, dir, back_track, source, boundaries, min_medial_move, sink)->
    try
      guide.normalize()
      guide.length = 800
      to = source.add(guide.rotate(dir * 90))
      projectLateral = new paper.Path.Line
        from: source
        to: to
        strokeWidth: 1
        strokeColor: "red"
      
      # CLOSEST INTERSECTION
      ixt = _.chain boundaries
        .map (boundary)->
          return projectLateral.getIntersections boundary
        .flatten()
        .min (hit)->
          hit.offset
        .value()

      # BACKTRACK
      lateral = ixt.offset
      lateral = lateral - back_track

     
      
      candidate = projectLateral.getPointAt(lateral)

      projectMedial = new paper.Path.Line
        from: candidate.clone()
        to: candidate.clone().add(guide)
        strokeWidth: 1
        strokeColor: "blue"

      # CLOSEST INTERSECTION
      ixt = _.chain boundaries
        .map (boundary)->
          return projectMedial.getIntersections boundary
        .flatten()
        .min (hit)->
          hit.offset
        .value()

      medial = ixt.offset

      if lateral < 5
        # console.log "TOO SHORT LATERALLY"
        serp.addSegment projectLateral.getNearestPoint(sink)
        serp.addSegment sink
        projectLateral.remove()
        projectMedial.remove()
        return false
      if medial > min_medial_move / 2
        # console.log "TOO SHORT MEDIALLY"
        projectLateral.remove()
        projectMedial.remove()
        serp.addSegment candidate
        return candidate
      else
        # console.log "SHORTENED, CAN IT FIT NOW?"
        projectLateral.remove()
        projectMedial.remove()
        return @move_lateral(serp, guide, dir, back_track + 3, source, boundaries, min_medial_move, sink)
    catch
      if projectMedial
        projectMedial.remove()
      if projectLateral
        projectLateral.remove()

