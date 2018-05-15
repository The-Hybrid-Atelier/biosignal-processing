
class window.Heater extends UIElement
  name: "heater"
  styles:
    boundary: ()->
      style =  
        fillColor: light_green
        strokeColor: "green"
        strokeWidth: 4
        closed: true
        strokeCap: "butt"
        strokeJoin: "round"
        miterLimit: 0
    source: ()->
      style = 
        fillColor: "yellow"
        strokeColor: "orange"
    sink: ()->
      style = 
        fillColor: "purple"
        strokeColor: "blue"
    resolved: ()->
      style = 
        fillColor: "#efefef"
        opacity: 1
        strokeColor: "#DDDDDD"
        strokeWidth: 1
    
  create: (options)->
    @ui.data.components = 
      source: 
        guid: null
        obj: null
      sink: 
        guid: null
        obj: null
      joule: 
        guid: null
        obj: null
      connections: []
    # OBJECT CREATION  
    boundary = options.boundary
    boundary.name = "boundary"

    # STYLING
    boundary.set this.styles.boundary()

    @addComponents [boundary]
  
  interaction: ()->
    scope = this
    boundary = @ui.data.components.boundary.obj
    boundary.set
      onMouseDown: (e)->
        scope.highlight(boundary, true)
      onMouseDrag: (e)->
        boundary.parent.position = boundary.parent.position.add(e.delta)
      onMouseUp: (e)->
        scope.highlight(boundary, false)
    @terminal_behavior()
  update: ()->
    boundary = @getComponent("boundary")
    rails = paper.project.getItems
      name: "rail"  
    # console.log "RAILS", rails
    hits = _.map rails, (rail)->
      trace = rail.self.getComponent("trace")
      ixts = trace.getIntersections(boundary)
      # console.log 'IXTS', ixts
      if ixts.length >= 2 then return trace
    hits = _.compact(hits)
    # console.log "HITS", hits
    
    if hits.length > 1
      alertify.error "Too many rails intersect the heat boundary."
      return
    else if hits.length == 1
      # @removeComponent("source")
      # @removeComponent("sink")
      # @removeComponent("joule")
      trace = hits[0]
      @generateHeater(trace, boundary)
    else
      # @removeComponent("source")
      # @removeComponent("sink")
      # @removeComponent("joule")
      boundary.set @styles.boundary()
  print: ()->
    scope = this
    _.each @ui.data.components, (c, key)->
      if _.isArray c
        return
      if _.includes ["source", "sink"], key
        c.obj.visible = false
      else if key == "boundary"
        c.obj.strokeWidth = 0
        c.obj.fillColor = "white"
       
      else
        if c.obj.closed
          c.obj.set scope._print.fill()
        else 
          c.obj.set scope._print.stroke()
    paper.view.update()
  terminal_behavior: ()->
    scope = this
    source = @getComponent("source")
    sink = @getComponent("sink")
    boundary = @getComponent("boundary")
    if source
      source.set
        onMouseDrag: (e)->
          this.position = boundary.getNearestPoint(e.point)
          scope.update()
        onMouseUp: (e)->
          scope.update()
    if sink
      sink.set
        onMouseDrag: (e)->
          this.position = boundary.getNearestPoint(e.point)
          scope.update()
        onMouseUp: (e)->
          scope.update()
  generateHeater: (trace, boundary)->  
    source = @getComponent("source")
    sink = @getComponent("sink")
    params = 
      boundaries: [boundary]


    terminals_undefined = _.isNull(source) or _.isNull(sink)  
    
    
    if terminals_undefined
      ixts = trace.getIntersections(boundary)  
      _.extend params, 
        source:( _.min ixts, (ixt)-> ixt.offset).point
        sink:  (_.max ixts, (ixt)-> ixt.offset).point
        
      source_ui = new paper.Path.Circle
        name: "source"
        radius: 10       
        position: params.source.clone()
        fillColor: "yellow"
        strokeColor: "orange"

      sink_ui = new paper.Path.Circle
        name: "sink"
        radius: 10        
        position: params.sink.clone()

      source_ui.bringToFront()
      sink_ui.bringToFront()

      source_ui.set @styles.source()
      sink_ui.set @styles.sink()
      boundary.set @styles.resolved()

      @addComponents [source_ui, sink_ui]
    else 
      _.extend params,  
        source: source.position
        sink: sink.position

      
    if Math.abs(params.source.subtract(params.sink).length) < 30 
      boundary.set @styles.boundary()
      return
      
    @removeComponent "joule"
    joule = Heater.serpentine params
    @addComponent joule
    @ui.bringToFront()
    @terminal_behavior()


    # UPDATE RAIL
    
    


  # OPTIONS
  # SOURCE
  # SINK
  # TARGET RESISTANCE
  # MATERIAL SHEET RESISTANCE
  # BOUNDARY

  @serpentine = (options)->
    console.log "SERPENTINE PROCESSING"
    circuit_layer.activate()
    return HeatSketch.snake options
    