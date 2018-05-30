class window.HeatBranchUI extends HeatBranch
  @BASE_WIDTH: 20
  Object.defineProperties @prototype, @make_object()
  compare_area: ()-> _.each this.children, (child)-> child.compare_area()    
  update: ()->
    scope = this
    @material_update()
    @connect_to_children()
    
    @annotations_update()
    @power_coloring()
    @mode_update()
    
    
  mode_update: ()->
    # if this.mode == Environment.mode then return
    powerball = @get "powerball"
    splitter = @get "splitter"
    lead = @get "lead"   
    power_pad = @get "power_pad"
    ground_pad = @get "ground_pad"
    connectors = @gets "connector"

    switch Environment.mode
      when "circuit"
        hide = [powerball, []]
        show = [power_pad, ground_pad, connectors, splitter, lead, []]
      when "power"
        hide = [power_pad, ground_pad, []]
        show = [powerball, splitter, lead, connectors, []]
      when "simulate"
        hide = [connectors, powerball, splitter, lead, power_pad, ground_pad,[]]        
        show = [[]]
      when "print"
        hide = [powerball, splitter, lead, connectors, []]
        show = [power_pad, ground_pad, []]
      else

        return

    hide = _.flatten(_.compact(hide))
    show = _.flatten(_.compact(show))
    _.each hide, (h)-> h.visible = false
    _.each show, (h)-> h.visible = true
    this[Environment.mode]()

    this.mode = Environment.mode

  circuit: ()->
    power_pad = @get "power_pad"
    connectors = @gets "connector"
    splitter = @get "splitter"
    lead = @get "lead"
    
    # power_pad.set Material.print_fill()
    
    Ea = Environment.thermoreactive_composite.activationEnergy
    p = (Ea/this.max_P) / EnergyScale.MAX
    @colorize power_pad, p, 'both'

    clear = _.flatten([connectors, lead])
    _.each clear, (c)-> 
      c.set
        strokeColor: "#00A8E1"
        strokeWidth: 3
    splitter.set 
      fillColor: "#00A8E1"
    scale = splitter.bounds.height / 6
    splitter.scale(1/scale)

  print: ()->
    power_pad = @get "power_pad"
    power_pad.set Material.print_fill()
    @destroy "splitter"
    @destroy "lead"
    @destroy "connector"
  simulate: ()->
    @destroy "splitter"
    @destroy "lead"
    @destroy "connector"
  power: ()->
   

  construct_ui: ()->
    scope = this
    heat_layer.activate()
    g = new paper.Group
      data: 
        component: true

    power_pad = new paper.Path.Rectangle
      name: "power_pad"
      parent: g
      size: [30, 60]
      radius: 3
      fillColor: 'black'
      position: guide_layer.getItems({name: "gutter"})[0].bounds.center
      visible: @print

    ground_pad = new paper.Path.Rectangle
      name: "ground_pad"
      parent: g
      size: [30, 60]
      radius: 3
      fillColor: 'black'
      position: guide_layer.getItems({name: "gutter"})[1].bounds.center
      visible: @print
      onMouseDown: (e)-> 
        e.stopPropagation()
      onMouseDrag: (e)-> 
        this.position = e.point
        e.stopPropagation()
      onMouseUp: (e)-> 
        e.stopPropagation()


    
    paper.project.importSVG "/icons/immaterial_power_node.svg", 
      insert: false
      expandShapes: true
      applyMatrix: false
      onLoad: (svg)->
        svg = svg.children.power
        svg.set
          parent: g
        svg.position = guide_layer.getItems({name: "gutter"})[0].bounds.center
        svg.name = "powerball"
        scope.interaction()
        scope.update()
      onError: (svg)->
        alertify.error "Could not load power SVG"

    # s = new Spool
    #   properties: 
    #     color: new paper.Color("#21BA45")
    #     scale: 2
    #     fill: 0.5
    # s.ui.set
    #   parent: g
    #   name: "spool"
    #   applyMatrix: true
    #   position: paper.view.center
    # this.spool = s
    return g

  fill: (p)->
    p = 1 - p
    p = p + 0.5
    p = p * -1
    powerball = @get("powerball")
    power_fill = powerball.children.power_container.children[0].children.power_fill
    range =  power_fill.parent.bounds.bottomCenter.y - power_fill.parent.bounds.topCenter.y
    power_fill.position.y = power_fill.parent.bounds.topCenter.y - (range * p) 
    Ea = Environment.thermoreactive_composite.activationEnergy
    p = (Ea/this.max_P) / EnergyScale.MAX
    @colorize power_fill, p, 'both'
    
  
 



  annotations_update: ()->
    if not this.annotations
      annotations = this.ui.getItems
        data: 
          annotation: true
      _.each annotations, (i)-> i.remove()

    else
      power_pad = @get "power_pad"
      lead = @get "lead"

      @destroy "powertime"
      @destroy "current_out"

      # ANOMETER
      if lead
        if not _.isNaN lead.length
          currentString = MaterialLib.units["I"].prep(this.I) 
          anometer = @make_annotation
            style: 
              content: currentString
              fontSize: 10
              fontWeight: 'normal'
            parent: this.ui
            name: "current_out"
            orientation: "r"
            anchor: lead 
            distance: 20
            tie_bar: false

      # POWER METER
      powerString = MaterialLib.units["P"].prep(this.max_P - this.P) + "\nremain"
      meter = @make_annotation
        style: 
          content: powerString
        parent: this.ui
        name: "powertime"
        orientation: "r"
        anchor: power_pad 
        distance: 30  
      @annotations_forward()    


    
  power_coloring: ()->
    mode = this.ui.mode
    scope = this

    power_pad = this.get("power_pad")
    lead = this.get("lead")
    splitter = this.get("splitter")
    powerball = this.get("powerball")

    Ea = Environment.thermoreactive_composite.activationEnergy
    p = (Ea/scope.P) / EnergyScale.MAX
    
    gray = false
    scope.colorize lead, p, 'stroke', gray
    scope.colorize power_pad, p, 'both', gray
    scope.colorize splitter, p, 'both', gray
    


    if powerball
      p = scope.P / scope.max_P
      this.fill 1-p


    # _.each this.children, (child)-> 
    #   child.power_coloring()
          
    
  connect_to_children: ()->
    scope = this
    gray = false
    
    power_pad = scope.get("power_pad")
    if not power_pad then return
    @destroy "lead"
    @destroy "splitter"
    @destroy "connector"

    # AVERAGE NODE
    sum = new paper.Point(0, 0)
    pts = _.map this.children, (child)-> 
      np = child.terminal(power_pad.bounds.center)
      diff = np.subtract(power_pad.position)
      sum = sum.add(diff)
      return np
    sum = sum.divide(this.children.length)
    sum.length = HeatBranchUI.BASE_WIDTH * 2 + 10

    # SPLITTER
    lead = new paper.Path.Line
      name: "lead"
      parent: this.ui
      from: power_pad.position
      to: power_pad.position.add(sum)
      strokeWidth: HeatBranchUI.BASE_WIDTH #* (this.I / this.max_I) + 3

    splitter = new paper.Path.Circle
      name: "splitter"
      parent: this.ui
      radius: lead.strokeWidth / 2
      strokeWidth: 1
      position: lead.lastSegment.point.clone()

    # CONNECTORS
    _.each pts, (np, i)->
      child = scope.children[i]
      child.connect_to_parent(splitter.position)
      child.mode_update()
    splitter.bringToFront()
    lead.sendToBack()
    
    
  interaction: ()->
    scope = this

    @ui.fireTouchGestures()
    @ui.set
      register: ()->
        console.log "BRANCH"
        scope.toString()
        Environment.last_heat_branch = scope
      onHoldStart: (e)->
        @register()
      onBrushTap: ()->
        @register()

      onBrushStart: (e)->
        @register()
        power_overlay = scope.get("power_overlay")
        power_overlay.strokeWidth = power_overlay.strokeWidth + 2
      onBrushDrag: (e)->
        this.translate e.delta
        scope.update()
      onBrushEnd: (e)->
        power_overlay = scope.get("power_overlay")
        power_overlay.strokeWidth = power_overlay.strokeWidth - 2
      onHoldStart: (e)-> @onBrushStart(e)
      onHoldDrag: (e)-> @onBrushDrag(e)
      onHoldEnd: (e)-> @onBrushEnd(e)
    ground_pad = @get "ground_pad"
    ground_pad.set
      onMouseDown: (e)-> 
        e.stopPropagation()
      onMouseDrag: (e)-> 
        this.position = e.point
        e.stopPropagation()
      onMouseUp: (e)-> 
        e.stopPropagation()

