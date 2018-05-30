class window.HeatTwigUI extends HeatTwig
  Object.defineProperties @prototype, @make_object()

  terminal: (pt)-> return @get("powerball").position

  update: ()->
    @material_update()
    @power_coloring()
    @connect_to_children()
    @annotations_update()
    @parent_find()
    if @parent
      @parent.update()
    @mode_update()

   
  annotations_update: ()->
    if not this.annotations
      annotations = this.ui.getItems
        data: 
          annotation: true
      _.each annotations, (i)-> i.remove()

    else
      @destroy "powertime"
      powerball = @get "power_overlay"
      # POWER METER
      powerString = MaterialLib.units["P"].prep(this.P)
      meter = @make_annotation
        style: 
          content: powerString
        parent: this.ui
        name: "powertime"
        orientation: "r"
        anchor: powerball
        distance: 10  
      @annotations_forward()  
  mode_update: ()->
    # if this.mode == Environment.mode then return
    powerball = @get "powerball"
    connectors = this.ui.getItems({name: "connector"})

    # console.log "MODE", Environment.mode
    switch Environment.mode
      when "circuit"
        hide = [powerball,[]]
        show = [this.ui, connectors, []]
        connectors = @gets "connector"
      when "power"
        hide = [[]]
        show = [this.ui, powerball,  connectors, []]
      when "simulate"
        hide = [this.ui, connectors, powerball, []]        
        show = [[]]
      when "print"
        hide = [this.ui, []]
        show = [[]]
      else
        return

    hide = _.flatten(_.compact(hide))
    show = _.flatten(_.compact(show))
    _.each hide, (h)-> h.visible = false
    _.each show, (h)-> h.visible = true
    this[Environment.mode]()
    this.mode = Environment.mode

  circuit: ()->
    connectors = @gets "connector"
    _.each connectors, (c)-> 
      c.set
        strokeColor: "#00A8E1"
        strokeWidth: 3
    # NODE
    @destroy "node"
    if @get "powerball"
      node = new paper.Path.Circle
        parent: this.ui
        name: "node"
        position: @get('powerball').position
        radius: 3
        strokeWidth: 1
        strokeColor: "black"

   
  print: ()->
  simulate: ()->
  power: ()->

  construct_ui: ()->
    scope = this
    heat_layer.activate()
    g = new paper.Group
      data: 
        component: true
      position: guide_layer.getItems({name: "gutter"})[0].bounds.center.add(new paper.Point(80, 0))
    paper.project.importSVG "/icons/immaterial_power_node.svg", 
      insert: false
      expandShapes: true
      applyMatrix: true
      onLoad: (svg)->
        svg = svg.children.power
        svg.set
          parent: g
        svg.position = guide_layer.getItems({name: "gutter"})[0].bounds.center.add(new paper.Point(80, 0))
        svg.name = "powerball"
        scope.update()
        svg.scale(1.7)
      onError: (svg)->
        alertify.error "Could not load power SVG"

    return g
  parent_find: ()->
    scope = this
    powerball = @get("powerball")
    if powerball and not this.parent and not powerball.onMouseDown
      # powerball.scale(1.7)
      color = Environment.pretty_color("#00A8E1")
      powerball.set
        onMouseDown: (e)->
          if not scope.parent
            this.l = new paper.Path.Line
              strokeColor: color.dark
              strokeWidth: 3
              from: this.children.power_overlay.getNearestPoint(e.point)
              to: e.point
            e.stopPropagation()
        onMouseDrag: (e)->
          if not scope.parent
            if this.l
              this.l.firstSegment.point = this.children.power_overlay.getNearestPoint(e.point)
              this.l.lastSegment.point = e.point
            e.stopPropagation()
        onMouseUp: (e)->
          if not scope.parent
            if this.l
              this.l.firstSegment.point = this.children.power_overlay.getNearestPoint(e.point)
              this.l.lastSegment.point = e.point
              branches = paper.project.getItems 
                name: (n)->
                  return _.includes ["HeatBranchUI"], n
                data: (obj)->
                  obj.properties.guid != scope.guid

              branches = _.map branches, (branch)-> branch.self
              b =  _.min branches, (branch)->
                return branch.ui.position.getDistance e.point
              if b
                scope.parent = b
                this.scale(0.8)
                this.set
                  onMouseUp: null
                  onMouseDown: null
                  onMouseDrag: null
              this.l.remove()
            e.stopPropagation()
  connect_to_children: ()->
    @destroy "connector"

    if this.children.length > 0 
      
      ratio = if this.parent then this.I / this.parent.I else 0

      scope = this
      gray = false
      
      divider = scope.get("powerball")
      if not divider then return

      # AVERAGE NODE
      sum = new paper.Point(0, 0)
      pts = _.map this.children, (child)-> 
        np = child.terminal(divider.bounds.center)
        diff = np.subtract(divider.bounds.center)
        sum = sum.add(diff)
        return np
      sum = sum.divide(this.children.length)
      sum.length = HeatBranchUI.BASE_WIDTH * 2 + 5

      # CONNECTORS
      _.each scope.children, (child, i)->
        child.connect_to_parent(divider.position)
      divider.bringToFront()

  power_coloring: ()->
    gray = false
    Ea = Environment.thermoreactive_composite.activationEnergy
    p = (Ea / this.P / EnergyScale.MAX)

    power_fill = @get "power_fill"
    if power_fill
      if this.I == 0
        power_fill.fillColor = "white"
      else
        @colorize power_fill, p, 'both'

  powerball_update: (np)->
    powerball = @get("powerball")
    if np 
      powerball.position = np.clone()
      powerball.bringToFront()

  connect_to_parent: (pt)->
    if this.parent
      heat_layer.activate()
      powerball = this.get("powerball")
      gray = false
      
      Ea = Environment.thermoreactive_composite.activationEnergy
      p = (Ea / this.P / EnergyScale.MAX)
      connector = new paper.Path.Line
        parent: this.parent.ui
        name: "connector"
        from: pt.clone()
        to: powerball.position.clone()
        strokeWidth: HeatBranchUI.BASE_WIDTH * this.alpha + 2
        onMouseDown: ()->
          hittable = paper.project.getItems
            data:
              component: true
          pt = this.lastSegment.point    
          pt.selected = true
          hit = _.min hittable, (h)-> 
            h.self.get("powerball").position.getDistance(pt)
          hit.self.parent.removeChild(hit.self)
          hit.self.parent = null
        deselectAll: ()->
          _.each paper.project.getItems({name: "connector"}), (c)-> c.dashArray = null
        onMouseEnter: ()->
          @deselectAll()
          this.dashArray = [10, 4]
        onMouseMove: ()-> this.dashArray =  [10, 4]
        onMouseLeave: ()-> @deselectAll()

      connector.sendToBack()
      @colorize connector, p, 'stroke', gray

      @powerball_update(this.get("powerball").position.clone())
      
  

  interaction: ()->
    scope = this
    @ui.fireTouchGestures()
    @ui.set
      register: ()->
        console.log "TWIG"
        console.log scope.toString()
        Environment.last_heat_twig = scope
      onBrushTap: ()->
        @register()
      onBrushStart: (e)->
      onBrushDrag: (e)->
        this.translate e.delta
        scope.update()
        if scope.parent
          scope.parent.update()
      onBrushEnd: (e)->
      onHoldStart: (e)->
        @register()
