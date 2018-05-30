class window.HeatSpaceUI extends HeatSpace
  Object.defineProperties @prototype, @make_object()
  @unassigned: ()->
    color = Environment.pretty_color("#DDDDDD")
    rtn = 
      fillColor: color.clear
      strokeWidth: 3
      strokeColor: color.dark

  terminal: (pt)->
    boundary = @get("boundary")
    return boundary.getNearestPoint pt
  construct_ui: ()->
    scope = this
    circuit_layer.activate()
    g = new paper.Group
      data: 
        component: true
    if @boundary
      boundary = @boundary.set
        parent: g
        name: "boundary"
    else
      boundary = new paper.Path.Circle
        name: "boundary"
        parent: g
        radius: 30
        position: paper.view.center

    boundary.set HeatSpaceUI.unassigned()
    
    

    # ADD POWERBALL
    if @get("powerball") then return g
    paper.project.importSVG "/icons/immaterial_power_node.svg", 
      insert: false
      expandShapes: true
      applyMatrix: true
      onLoad: (svg)->
        svg = svg.children.power
        svg.set
          parent: g
        svg.position = boundary.bounds.center
        svg.name = "powerball"
        scope.update()
        scope.selected(false)
        tracker.save()
      onError: (svg)->
        alertify.error "Could not load power SVG"
    return g
  

  update: ()->
    scope = this
    @A = @area()
    @material_update()
    @parent_selector()
    
    @annotations_update()
    @powerball_update()
    
    if @parent
      @parent.update()
    @mode_update()
    
  
  mode_update: ()->
    scope = this
    # if this.mode == Environment.mode then return
    powerball = @get "powerball"
    boundary = @get "boundary"
    joule = @get "joule"
    mat = @get "mat"
    spine = @get "spine"
    node = @gets "node"

    switch Environment.mode
      when "circuit"
        hide = [powerball, []]
        show = [joule, node, boundary, mat, spine, []]
      when "power"
        hide = [joule, node, []]
        show = [powerball, boundary, mat, spine, []]
      when "simulate"
        hide = [powerball, node, boundary, mat, spine, []]
        show = [joule, boundary, []]
      when "print"
        hide = [powerball, boundary, mat, spine, []]
        show = [joule, node, []]
      else
        return


    hide = _.flatten(_.compact(hide))
    show = _.flatten(_.compact(show))
    _.each hide, (h)-> h.visible = false
    _.each show, (h)-> h.visible = true
    this[Environment.mode]()
    this.mode = Environment.mode
    # if joule
    #   
    paper.view.update()
  power: ()->
    p = (this.tr / EnergyScale.MAX)
    this.colorize this.get("boundary"), p, 'area', false

  circuit: ()->
    node = @destroy "node"
    @make_joule()
    joule = @get "joule"
    
    p = (this.tr / EnergyScale.MAX)
    this.colorize joule, p, 'stroke', false
    if joule
      joule.visible = this.rendered
    # this.colorize node, p, 'fill', false

    # color = Environment.pretty_color("white")
    # this.colorize this.get("boundary"), p, 'area', false
    # this.get("boundary").fillColor = color.clear
    # if joule then joule.set Material.print_stroke()
  
  print: ()->
    joule = @get "joule"
    if not joule
      @make_joule()
      joule = @get "joule"
    
    if joule then joule.set Material.print_stroke()
    nodes = @gets "node"
    _.each nodes, (n)-> n.set Material.print_fill()
    if joule
      joule.visible = this.rendered
  simulate: ()->

    @make_joule()
    joule = @get "joule"
    
    p = (this.tr / EnergyScale.MAX)
    this.colorize joule, p, 'stroke', false

    boundary = @gets "boundary"
    boundary.opacity = 0  
    node = @destroy "node"
  
        


  connect_to_parent: (pt)->
    if this.parent
      circuit_layer.activate()
      gray = false 
      p = (this.tr  / EnergyScale.MAX)

      if this.get("spine")
        spine = this.get("spine").children.mat
        p1 = spine.firstSegment.point.clone()
        p2 = spine.lastSegment.point.clone()
        np = _.min [p1, p2], (p)-> pt.getDistance p
      else
        np = @get("boundary").getNearestPoint(pt)

      connector = new paper.Path.Line
        parent: this.parent.ui
        name: "connector"
        from: pt.clone()
        to: np
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
      @powerball_update(np)

  
  powerball_update: (np)->
    powerball = @get "powerball"
    power_fill = @get "power_fill"
    
    if not powerball then return

    # PARENT CUE
    if not this.parent
      @powerball_scale(1)
    if this.parent and this.parent.ui.name == "HeatBranchUI"
      @powerball_scale(2)
    if this.parent and this.parent.ui.name == "HeatTwigUI"
      @powerball_scale(3)

    # POSITION UPDATE
    if np and np.className
      powerball.position = np.clone()
      
    # COLOR UPDATE
    p = (this.tr / EnergyScale.MAX)
    if this.I == 0
      power_fill.fillColor = "white"
    else
      @colorize power_fill, p, 'both'
      
    powerball.bringToFront()
    

  parent_selector: ()->
    scope = this
    powerball = @get "powerball"
    if not powerball then return 
    if this.parent
      @powerball_update()
      powerball.set
        selector_on: false
        onMouseDown: (e)->
        onMouseDrag: (e)->
        onMouseUp: (e)->
    else
      @powerball_update()
      color = Environment.pretty_color("#00A8E1")
      powerball.set
        onMouseDown: (e)->
          e.stopPropagation()
          this.l = new paper.Path.Line
            strokeColor: color.dark
            strokeWidth: 3
            from: this.children.power_overlay.getNearestPoint(e.point)
            to: e.point
        onMouseDrag: (e)->
          e.stopPropagation()
          if not this.l then return
          this.l.firstSegment.point = this.children.power_overlay.getNearestPoint(e.point)
          this.l.lastSegment.point = e.point
          
        onMouseUp: (e)->
          e.stopPropagation()
          if not this.l then return
         
          this.l.firstSegment.point = this.children.power_overlay.getNearestPoint(e.point)
          this.l.lastSegment.point = e.point
          branches = paper.project.getItems
            name: (n)-> n == "HeatBranchUI" or n == "HeatTwigUI"
          branches = _.map branches, (branch)-> branch.self
          b =  _.min branches, (branch)->
            return branch.ui.position.getDistance e.point
          console.log "branches", branches
          if b
            scope.parent = b
          this.l.remove()
          

  annotations_update: ()->
    if this.annotations

      powerball = @get "power_overlay"
      pt = @destroy "power"
      rt = @destroy "resistance"
      
      powerString = MaterialLib.units["P"].prep(this.P)
      resistanceString = MaterialLib.units["R"].prep(this.R)
    
      meter = @make_annotation
        style: 
          content: powerString
        parent: this.ui
        name: "power"
        orientation: "r"
        anchor: powerball 
        distance: 10
      # meter.bringToFront()


    
      ohmmeter = @make_annotation
        style: 
          content: resistanceString
          fontWeight: "normal"
          fontSize: 16
        parent: this.ui
        name: "resistance"
        orientation: "b"
        anchor: powerball 
        distance: 15
        tie_bar: false

      # ohmmeter.bringToFront()

    else
      annotations = this.ui.getItems
        data: 
          annotation: true
      _.each annotations, (i)-> i.remove()

    @annotations_forward()
  



  
  
  
  cut: ()->
    boundary = @get "boundary"
    mat = @get "mat"
    valid = mat and boundary
    if not valid 
      alertify.error "<b>Don't know how to cut.</b> Mark the shape with a construction line."
      return
    p1 = mat.getPointAt(0)
    n1 = mat.getNormalAt(0)
    t1 = mat.getTangentAt(0)
    p2 = mat.getPointAt(mat.length)
    n2 = mat.getNormalAt(mat.length)
    t2 = mat.getTangentAt(mat.length)
    n1.length = 10000
    t1.length = 10000
    n2.length = 10000
    t2.length = 10000

    circuit_layer.activate()
    rectangleA = mat.clone()
    rectangleA.addSegments([p2.add(t2), p2.add(t2).add(n2), p1.subtract(t1).add(n1), p1.subtract(t1)])
    rectangleA.closed = true
    rectangleA.fillColor = "red"
    rectangleA.name = "temp"

    # n1.length = -10000
    # n2.length = -10000
    # rectangleB = mat.clone()
    # rectangleB.addSegments([p2.add(t2), p2.add(t2).add(n2), p1.subtract(t1).add(n1), p1.subtract(t1)])
    # rectangleB.closed = true
    # rectangleB.fillColor = "pink"
    # rectangleB.name = "temp"




    regionA = boundary.intersect rectangleA, 
      insert: false

    regionB = boundary.subtract regionA, 
      insert: false

    rectangleA.remove()
    # rectangleB.remove()

    # # CREATE SUBSPACE
    if regionA
      circuit_layer.addChild(regionA)
      h = new HeatSpaceUI
        boundary: regionA
        properties: 
          parent: this.parent

    if regionB
      circuit_layer.addChild(regionB)
      h = new HeatSpaceUI
        boundary: regionB
        properties: 
          parent: this.parent
        
      this.destroyAll()




  make_joule: ()->
    scope = this

    @destroy "joule"
    spine = @get "spine"
    boundary = @get "boundary"

    valid = spine and boundary
    if not valid 
      boundary.strokeColor = "red"
      boundary.fillColor = "red"
      # alertify.error "The heater couldn't be generated with a direction mark"
      return
    else
      p = (this.tr / EnergyScale.MAX)
      this.colorize boundary, p, 'area', false

      mat = spine.children.mat

      options = 
        parent: this.ui
        boundaries: [boundary]
        source: mat.firstSegment.point.clone()
        sink: mat.lastSegment.point.clone()
        strokeWidth: Ruler.mm2pts(this.w)
        strokeInterval: Ruler.mm2pts(MaterialLib.AgIC.interval_min)
        heatColor: "blue"
        mat: spine.children.mat
        padding: 5

      circuit_layer.activate()
      joule = HeatSketch.spiral options

      p = (this.tr / EnergyScale.MAX)
      # this.colorize joule, p, 'stroke'
      # joule.strokeWidth = 1
      mat.parent.bringToFront()
      if joule and joule.length > 0
        node = new paper.Path.Circle
          parent: this.ui
          name: "node"
          position: joule.firstSegment.point
          
          radius: this.w * 2
          strokeWidth: 1
          strokeColor: "black"


        this.colorize node, p, 'fill', false

  interaction: ()->
    scope = this
    boundary = @get "boundary"
    @ui.set
      minDistance: 15
      is_magnetized: ()-> return $('#magnetize').hasClass('red') 
      register: ()->
        console.log "SPACE"
        console.log scope.toString()
        Environment.last_heat_space = scope
        @bringToFront()

      onMouseDown: (e)->
        @register()
        if Environment.mode == "circuit"
          if @is_magnetized() then  @mdC(e) else  @mdB(e)
        else if @is_magnetized() then  @mdA(e) else  @mdB(e)
        e.stopPropagation()
      onMouseDrag: (e)->
        if Environment.mode == "circuit"
          if @is_magnetized() then  @mdrC(e) else  @mdrB(e)
        else if @is_magnetized() then  @mdrA(e) else  @mdrB(e)
        e.stopPropagation()
      onMouseUp: (e)->
        if Environment.mode == "circuit"
          if @is_magnetized() then  @muC(e) else  @muB(e)
        else if @is_magnetized() then  @muA(e) else  @muB(e)
        e.stopPropagation()

      # C = EFFORT
      supervisor: null
      work: null
      mdC: (e)->
        if scope.rendered 
          joule = scope.get "joule"
          joule.visible = true
          return
        joule = scope.get "joule"
        this.supervisor = new paper.Path
          name: "supervisor"
        this.work = new paper.Path
          name: "work"
        if joule
          this.work.style = joule.style
          joule.visible = false
        this.complete = _.once ()->
          if speaker
            speaker.send
              to: "ipevo"
              service: "play_sound"
              name: "Complete"
      mdrC: (e)->
        if scope.rendered then return
        joule = scope.get "joule"
        if this.supervisor and this.work and joule
          work = this.work
          this.supervisor.addSegment(e)
          l = this.supervisor.length
          curr = this.work.length
          # console.log l, curr
          if l > joule.length 
            grease = _.range(curr, joule.length, 3)
            _.each grease, (g)->
              pt = joule.getPointAt(g)
              work.addSegment pt
            this.complete()
            return
          grease = _.range(curr, l, 3)
          _.each grease, (g)->
            pt = joule.getPointAt(g)
            work.addSegment pt
      muC: (e)->
        if scope.rendered then return
        if not this.supervisor then return
        
        joule = scope.get "joule"

        if this.supervisor.length >= joule.length
          joule.visible = true
          scope.rendered = true

        if this.supervisor
          this.supervisor.remove()
        if this.work
          this.work.remove()
      # A = TRANSLATION
      mdA: (e)->
        @register()
        scope.selected(true)
        boundary.strokeWidth = boundary.strokeWidth * 2
      mdrA: (e)->
        this.translate e.delta
        if scope.parent then scope.parent.update()
      muA: (e)->
        scope.selected(false)
        boundary.strokeWidth = boundary.strokeWidth / 2
      # B = ARROW MAKING
      mdB: (e)->
        if Environment.cutting then return
        clr = boundary.strokeColor.clone()
        clr.brightness = clr.brightness - 0.5
        scope.destroy "spine"
        this.arrow = paper.Path.Arrow
          parent: scope.ui
          name: "spine"
          arrowColor: clr
          arrowWidth: 6
          arrowHead: "solid"
          headScale: 0.6
        this.arrow.addPoint(e.point)
      mdrB: (e)->
        if Environment.cutting then return
        if this.arrow
          this.arrow.addPoint(e.point)
      muB: (e)->
        if Environment.cutting then return
        if this.arrow  
          this.arrow.smooth()
          this.arrow.extend(boundary)
          if scope.parent then scope.parent.update()
          scope.update()
          scope.rendered = false
    # @ui.fireTouchGestures()
    # @ui.set
    #   register: ()->
    #     console.log "SPACE"
    #     console.log scope.toString()
    #     Environment.last_heat_space = scope
    #     @bringToFront()

    #   onHoldStart: (e)->
    #     @register()
    #     scope.selected(true)
    #     boundary.strokeWidth = boundary.strokeWidth * 2
    #     e.stopPropagation()
    #   onHoldDrag: (e)-> 
    #     this.translate e.delta
    #     if scope.parent
    #       scope.parent.update()
    #     e.stopPropagation()
    #   onHoldEnd: (e)->
    #     scope.selected(false)
    #     boundary.strokeWidth = boundary.strokeWidth / 2
    #     e.stopPropagation()


    #   onBrushTap: (e)->
    #     @register()
      
      
    #   onBrushStart: (e)->
    #     @register()
    #     handler = eval("this.onBrushStart"+capitalize(Environment.mode))
    #     if handler
    #       handler(e)
    #     e.stopPropagation()

    #   onBrushDrag: (e)->
    #     handler = eval("this.onBrushDrag"+capitalize(Environment.mode))
    #     if handler
    #       handler(e)
    #     e.stopPropagation()

    #   onBrushEnd: (e)->
    #     handler = eval("this.onBrushEnd"+capitalize(Environment.mode))
    #     if handler
    #       handler(e)
    #     e.stopPropagation()


    #   onBrushStartPower: (e)->
    #     clr = boundary.strokeColor.clone()
    #     clr.brightness = clr.brightness - 0.5
    #     scope.destroy "spine"
    #     this.arrow = paper.Path.Arrow
    #       parent: scope.ui
    #       name: "spine"
    #       arrowColor: clr
    #       arrowWidth: 6
    #       arrowHead: "solid"
    #       headScale: 0.6
    #       onMouseDown: (e)->
    #         this.remove()
    #     this.arrow.addPoint(e.point)
    #   onBrushDragPower: (e)->
    #     if this.arrow
    #       this.arrow.addPoint(e.point)
    #   onBrushEndPower: (e)->
    #     if this.arrow
    #       # this.arrow.smooth()
    #       this.arrow.extend(boundary)
    #       if scope.parent
    #         scope.parent.update()
    #       scope.update()
          


    #   onBrushStartCircuit: (e)->
    #     clr = boundary.strokeColor.clone()
    #     clr.brightness = clr.brightness - 0.5
    #     scope.destroy "spine"
    #     this.arrow = paper.Path.Arrow
    #       parent: scope.ui
    #       name: "spine"
    #       arrowColor: clr
    #       arrowWidth: 6
    #       arrowHead: "solid"
    #       headScale: 0.6
    #       onMouseDown: (e)->
    #         this.remove()
    #     this.arrow.addPoint(e.point)

    #   onBrushDragCircuit: (e)->
    #     if this.arrow
    #       this.arrow.addPoint(e.point)
 
    #   onBrushEndCircuit: (e)->
    #     if this.arrow
    #       # this.arrow.smooth()
    #       this.arrow.extend(boundary)
    #       scope.make_joule()
    #       scope.update()



    

  area_joule: ()->
    joule = @get "joule"
    l = Ruler.pts2mm(joule.length)
    w = Ruler.pts2mm(joule.strokeWidth)
    return l * w
  compare_area: ()->
    joule = @get "joule"
    console.log "W", Ruler.pts2mm(joule.strokeWidth)
    console.log "AJ", @area_joule()
    console.log "A", @area()
    console.log "RATIO", @area_joule()/@area()
  area: ()->
    boundary = @get "boundary"
    area = Math.abs(boundary.area)
    area = Ruler.pts2mm(area)
    area = Ruler.pts2mm(area)
    # ADJUSTMENT
    area = area*0.8175 -111.18
    # area = area*1.0974 -23.802


    if area < 0
      console.warn "AREA UNDER 0"
      area = 0
    return area

  