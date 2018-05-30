class window.Spool extends Material
  @THREAD_COUNT: 30
  @override: ["connections"]
  name: "spool"
  @defaults: ()->
    fill: 0
    scale: 1
    guid: guid()
    connection: []
    color: "red"
  _fill: ()->
    if not this.ui then return
    scope = this
    # CHECKS
    if _.isUndefined this.prop.fill or _.isNull this.prop.fill 
      this.prop.fill = 0

    if this.prop.fill > 1
      this.prop.fill = 1


    scope = this
    spindle = this.ui.children.spindle
    h = spindle.bounds.height
    left = spindle.segments[0].point.clone().add(new paper.Point(-1, 0))
    right = spindle.segments[3].point.clone().add(new paper.Point(1, 0))
    
    threads = this.ui.getItems
      name: (n)-> _.contains ["thread", "tail"], n
    _.each threads, (t)-> t.remove()
    ui_layer.activate()
    lines = _.range(0, h * this.prop.fill, h / Spool.THREAD_COUNT)
    _.each lines, (l, i)->
      p = l/h
      color = scope.prop.color.clone()
      if p < 0.5
        color.brightness = 0.8
      f = left.clone().add(new paper.Point(0, -l))
      t = right.clone().add(new paper.Point(0, -l))
      line = new paper.Path.Line
        name: if i == lines.length - 1 then "tail" else "thread"
        parent: scope._ui
        from: f
        to: t
        strokeWidth: h / Spool.THREAD_COUNT
        strokeColor: color
        strokeScaling: true
        # applyMatrix: false
        shadowColor: new paper.Color(0.3)
        shadowBlur: 1
        strokeCap: "round"
      line.segments[0].handleOut = new paper.Point(1.5, 1.5)
      line.segments[1].handleIn = new paper.Point(-1.5, 1.5)
    this.ui.children.top.bringToFront()
    this.ui.children.hole.bringToFront()
    
  construct_ui: ()->
    s = @_spool()
  update: ()->
    @_fill()
    @_draw_connections()
    @_scale()
    
  _spool: ()->
    scope = this
    if this.ui
      spool = this.ui.remove()

    ui_layer.activate()
    spool = new paper.Group
      applyMatrix: false
      name: "spool"
      # onMouseDown: (e)->
      # onMouseDrag: (e)->
      #   this.translate(e.delta)
      #   scope.position = this.position
      #   scope.update()
      # onMouseUp: (e)->
    spindle = new paper.Path.Rectangle
      name: "spindle"
      parent: spool
      size: [10, 15]
      fillColor: new paper.Color(0.6)
    top_spool = new paper.Path.Ellipse
      strokeScaling: true
      name: "top"
      parent: spool
      size: [18, 5]
      fillColor: new paper.Color(0.7)
      strokeColor: new paper.Color(0.6)
      position: spindle.bounds.topCenter
      strokeWidth: 0.2
      shadowColor: new paper.Color(0)
      shadowBlur: 2
    hole = new paper.Path.Ellipse
      name: "hole"
      parent: spool
      size: [3, 1]
      fillColor: new paper.Color(0.3)
      position: top_spool.bounds.center
    bottom_spool = new paper.Path.Ellipse
      strokeScaling: true
      parent: spool
      name: "bottom"
      size: [18, 5]
      fillColor: new paper.Color(0.5)
      strokeColor: new paper.Color(0.4)
      strokeWidth: 0.2
      position: spindle.bounds.bottomCenter
      shadowColor: new paper.Color(0)
      shadowBlur: 0
    bottom_spool.sendToBack()
    spindle.segments[3].handleOut = new paper.Point(-1, 1)
    spindle.segments[0].handleIn = new paper.Point(1, 1)
    return spool
  
  _draw_connections: ()->
    scope = this
    connectors = this.ui.getItems
      name: "connect_thread"
    _.each connectors, (c)-> c.remove()

    _.each this.prop.connections, (pos)->
      scope._draw(pos)

  _draw: (pos)->
    scope = this
    left_or_right = pos.clone().subtract(this.ui.position).angle
    
    is_left = left_or_right > -90 and left_or_right < 90

    tail = this.ui.getItem
      name: "tail"

    if tail
      start = if is_left then tail.segments[1].point.clone().add(new paper.Point(-2, 0)) else tail.segments[0].point.clone().add(new paper.Point(2, 0))
      ui_layer.activate()
      line = new paper.Path.Line
        name: "connect_thread"
        parent: this.ui
        from: start
        to: tail.globalToLocal(pos)
        strokeWidth: 1
        strokeColor: this.prop.color.clone()
        shadowColor: new paper.Color(0.3)
        strokeScaling: true
        shadowBlur: 1 
        strokeCap: "butt"
      line.sendToBack()
      this.ui.children.bottom.sendToBack()    
      this.ui.children.top.bringToFront()    
      this.ui.children.hole.bringToFront()    
  
  _scale: ()->
    # console.log "SCALING", this.prop.scale, this.ui.scaling
    this.ui.scaling = new paper.Point(this.prop.scale, this.prop.scale)
  
  Object.defineProperties @prototype, @make_object()
  Object.defineProperties @prototype,
    connections:
      get: ()->
        @prop.connections
      set: (obj)->
        @prop.connections.push obj
        @update()
  