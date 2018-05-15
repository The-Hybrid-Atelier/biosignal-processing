class window.Material
  @override: []
  @defaults: ()-> {}
  @print_stroke: ()-> {strokeColor: "black", shadowBlur: 0}
  @print_fill: ()-> {fillColor: "black", strokeWidth: 0, shadowBlur: 0}
  get: (child)-> return if not this.ui then null else this.ui.getItem({name: child})
  gets: (child)-> return if not this.ui then null else this.ui.getItems({name: child})
  to_do: ()-> console.log arguments.callee.name, "not implemented"
  register: ()-> @to_do()
  toString: ()-> MaterialLib.toString(@prop).values
  interaction: ()-> @to_do()
  construct_ui: ()-> @to_do()
  update: ()->
    @material_update()
  
  powerball_scale: (level)->
    powerball = @get "powerball"
    switch level
      when 3
        scale = powerball.bounds.height / 15
        powerball.scale(1/scale)
      when 2
        scale = powerball.bounds.height / 30
        powerball.scale(1/scale)
      when 1
        scale = powerball.bounds.height / 40
        powerball.scale(1/scale)


  destroy: (child)->
    children = this.ui.getItems {name: child}
    _.each children, (child)-> child.remove()
  annotations_forward: ()->
    annotations = paper.project.getItems
      data:
        annotation: true
    _.each annotations, (a)-> a.bringToFront() 
  selected: (highlight = true)-> 
    pw = @get("power_overlay")
    if pw
      if highlight
        pw.shadowBlur = 10
        pw.shadowColor = "#00A8E1"
        pw.strokeWidth = 3
      else
        pw.strokeWidth = 1
        pw.shadowBlur = 0
  constructor: (op={})->
    # object properties
    scope = this
    _.extend this, _.omit op, "properties"
    
    #defaults
    klass = eval(this.constructor.name)
    @prop = klass.defaults()
    # console.log "op", op
    if op.properties and op.properties.guid
      # console.log "SETTING GUID TO", op.properties.guid.slice(0, 2) 
      @prop.guid = op.properties.guid
    
    if not @ui
      this.ui = @construct_ui()
      this.ui.name = this.constructor.name
      this.ui.self = this
      # this.update()
      @resolve(op.properties)
      @register()
    else
      this.ui.self = this
      
  save: ()->
    if @ui
      save_data = {}
      _.each @prop, (v, k)->
        if _.isObject(v)
          v = if _.isArray(v) then _.map v, (x)-> x.guid else [v.guid]  
        save_data[k] = v
      this.ui.data.properties = save_data

  resolve: (properties, preprocess = false)->
    scope = this
    if preprocess
      properties = _.mapObject properties, (v, k)->
        if _.isObject(v)
          try
            v = if _.isArray(v) then _.map v, (x)-> paper.project.getItem({data: {properties: {guid: x}}}).self
          catch err
            console.warn "NULL", scope.name, k
            return null
          if v.length == 1
            v = v[0]
        return v
    _.each properties, (v, k)->
        if not _.isUndefined scope[k] and scope[k]
          scope[k] = v
    @update()
    @interaction()
    @save()


  @make_object: ()->
    scope = this
    # object setter/getters
    properties = _.keys @defaults()
    prototype = {}
    klass = this
    _.each properties, (key)->
      if _.includes klass.override, key then return
      prototype[key] =  
        get: ->
          this.prop[key]
        set: (value)->
          if value == this.prop[key] then return
          this.prop[key] = value
          this.update()
          this.save()
    prototype
  colorize: (ui, p, type, gray = false)->
    if not ui then return
    color = EnergyScale.rainbow(p)
    fill = color.clone()
    fill.alpha = 0.5
    stroke = color.clone()
    stroke.brightness = stroke.brightness - 0.1
    if gray 
      stroke.saturation = 0
      fill.saturation = 0
      color.saturation = 0
    switch type
      when 'area'
        ui.set
          strokeColor: stroke
          fillColor: fill
          opacity: 1
          shadowBlur: 0
          strokeWidth: 3
      when 'both'
        ui.set
          strokeColor: stroke
          fillColor: color.clone()
          opacity: 1
          shadowBlur: 0
      when 'stroke'
        ui.set
          strokeColor: color.clone()
          opacity: 1
          shadowBlur: 0
      when 'fill'
        ui.set
          fillColor: color.clone()
          opacity: 1
          shadowBlur: 0

  Object.defineProperties @prototype, @make_object()
  make_annotation: (op)->
    # CHECKS
    # op:
    #   style:
    # parent:
    # name:  
    # orientation: tr|tl|br|bl|r|l|t|b
    # distance: 30
    # text_padding: 5
    # angle: 
    # anchor:   
    # tie_bar: true
    # tie_bar_length: 5
    
    
    def = 
      distance: 30
      text_padding: 5
      tie_bar: true
      tie_bar_length: 5
    op = _.extend def, op

    # CREATE CONTAINER
    annotationGroup = new paper.Group
      parent: op.parent
      name: op.name
      data:
          annotation: true
    # DEFAULT TEXT STYLE
    pt = 
      parent: annotationGroup
      name: "text"
      fillColor: 'black'
      fontFamily: 'Avenir'
      fontWeight: 'bold' 
      fontSize: 12

    pt = _.extend pt, op.style
    # ADD TEXT ELEMENT
    textElement = new paper.PointText pt
    
    textElement.pivot = textElement.bounds.topRight
    textElement.position = annotationGroup.bounds.topLeft
    

    try

      # WHERE TO PLACE
      switch op.orientation
        when "t"
          direction = new paper.Point(0, -1)
          direction.length = op.distance
          inv = direction.clone()
          inv.length = -5 

          groupAttach = op.anchor.bounds.topCenter.add(direction)
          annotationGroup.position = groupAttach
          textAttach =  annotationGroup.bounds.bottomCenter.add(inv)
          tieSegments = [op.anchor.position.clone(), textAttach]
        when "b"
          direction = new paper.Point(0, 1)
          direction.length = op.distance
          inv = direction.clone()
          inv.length = -5

          groupAttach = op.anchor.bounds.bottomCenter.add(direction)
          annotationGroup.position = groupAttach
          textAttach =  annotationGroup.bounds.topCenter.add(inv)
          # console.log "op.anchor.bounds.bottomCenter", op.anchor.bounds.bottomCenter
          tieSegments = [op.anchor.bounds.bottomCenter, textAttach]
        when "l"
          direction = new paper.Point(-1, 0)
          direction.length = op.distance
          inv = direction.clone()
          inv.length = -5 

          groupAttach = op.anchor.bounds.leftCenter.add(direction)
          annotationGroup.position = groupAttach
          textAttach =  annotationGroup.bounds.rightCenter.add(inv)
          tieSegments = [op.anchor.position.clone(), textAttach]
        when "r"
          direction = new paper.Point(1, 0)
          direction.length = op.distance
          inv = direction.clone()
          inv.length = -5 

          start =  if op.anchor.closed then op.anchor.bounds.rightCenter else op.anchor.getPointAt(op.anchor.length/2 + 10)
          groupAttach = start.add(direction) 
          annotationGroup.pivot = annotationGroup.bounds.leftCenter
          annotationGroup.position = groupAttach

          textAttach =  textElement.bounds.leftCenter.add(inv)
          tieSegments = [start.clone(), textAttach]
       
      tie = new paper.Path
        parent: annotationGroup
        name: "tie"
        strokeColor: 'black'
        strokeWidth: 1
        segments: tieSegments
     

      if op.tie_bar
        switch op.orientation
          when "t"
            tieSegments = [
              tie.lastSegment.point.clone().add(new paper.Point(op.tie_bar_length, 0)),
              tie.lastSegment.point.clone().add(new paper.Point(-op.tie_bar_length, 0))
            ]
          when "b"
            tieSegments = [
              tie.lastSegment.point.clone().add(new paper.Point(op.tie_bar_length, 0)),
              tie.lastSegment.point.clone().add(new paper.Point(-op.tie_bar_length, 0))
            ]
          when "l"
            tieSegments = [
              tie.lastSegment.point.clone().add(new paper.Point(0, op.tie_bar_length)),
              tie.lastSegment.point.clone().add(new paper.Point(0, -op.tie_bar_length))
            ]
          when "r"
            tieSegments = [
              tie.lastSegment.point.clone().add(new paper.Point(0, op.tie_bar_length)),
              tie.lastSegment.point.clone().add(new paper.Point(0, -op.tie_bar_length))
            ]
        

      tieBar = new paper.Path
        parent: annotationGroup
        name: "tie"
        strokeColor: 'black'
        strokeWidth: 1
        segments: tieSegments
    catch err
      return annotationGroup

    annotationGroup.pivot = annotationGroup.bounds.leftCenter
    annotationGroup.bringToFront()
    return annotationGroup
