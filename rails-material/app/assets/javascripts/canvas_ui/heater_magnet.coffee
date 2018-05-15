

class window.HeaterMagnet extends UIElement
    name: "heater_magnet"
    strokeWidth: 10
    strokeInterval: Ruler.mm2pts(0.5)
    styles:
      boundary_passive: (scope)->
        heatColor = HeatSim.temperatureColor(scope.getRelationalResistance(), with_white=false, reverse=true)
        heatColor.alpha = 0.5
        heatColorStroke = heatColor.clone()
        heatColorStroke.alpha = 1.0
        style =  
          fillColor: heatColor
          strokeColor: heatColorStroke
          strokeWidth: 4
          closed: true
          strokeCap: "butt"
          strokeJoin: "round"
          miterLimit: 0
      boundary_active: ()->
        style = 
          fillColor: null
          opacity: 1
          strokeColor: "#DDDDDD"
          strokeWidth: 1
      spine_active: ()->
        style =
          visible: false
      spine_passive: ()->
        style = 
          visible: true
      
      source_active: ()->
        style =
          visible: true
          strokeColor: "#DDDDDD"
          strokeWidth: 2
          fillColor: "white"
          shadowColor: new paper.Color(0, 0, 0, 0.8)
          shadowBlur: 5
      source_passive: ()->
        style = 
          visible: false
      source_motion: ()->
        style =
          visible: true
          strokeColor: "#DDDDDD"
          strokeWidth: 4
          fillColor: "white"
     

      sink_passive: ()->
        style = 
          visible: false

      sink_active: (scope)->
        t = HeatSim.temperatureColor(scope.getRelationalResistance(),with_white=false, reverse=true)
        sw = (1 - scope.getRelationalResistance()) * 6 + 1
        blue = new paper.Color "#00A8E1"
        blue.brightness = blue.brightness - 0.2
        style =
          visible: true
          strokeColor: t
          strokeWidth: sw
          fillColor: blue
          shadowColor: new paper.Color(0, 0, 0, 0.8)
          shadowBlur: 5


      sink_motion: (scope)->
        t = HeatSim.temperatureColor(scope.getRelationalResistance(),with_white=false, reverse=true)
        sw = (1 - scope.getRelationalResistance()) * 6 + 1
        style =
          visible: true
          strokeColor: t
          strokeWidth: sw
          fillColor: "#00A8E1"
      meter_active: ()->
        style = 
          fillColor: "#111111"
          visible: true
      meter_passive: ()->
        style = 
          visible: true

      tensioner_active: (scope)->
        t = HeatSim.temperatureColor(scope.getRelationalResistance(),with_white=false, reverse=true)
        style = 
          visible: true
          fillColor: t
          shadowColor: new paper.Color(0, 0, 0, 0.5)
          shadowBlur: 5
      tensioner_passive: (scope)->
        style = 
          visible: false

    create: (options)->
      
      heat_layer.activate()
      boundary = options.boundary
      boundary.name = "boundary"
      

      @setStyle boundary, "passive"
      @addComponents [boundary]
      this.hs = new HeatSpace
        properties:
          parent: b1
          A: @area()
    area: ()->
      boundary = @getComponent "boundary"
      area = Math.abs(boundary.area)
      area = Ruler.pts2mm(area)
      area = Ruler.pts2mm(area)
      return area
    update: ()->
      @makeJouleHeater()
      heat_sim.update()
      @ui.bringToFront()
      boundary = @getComponent "boundary"
      console.log "AREA", @area()
      this.hs.A = @area()

    setStyle: (comp, c)->
      if comp
        style = comp.name + "_" + c
        if @styles[style]
          comp.set @styles[style](this)
    setStyles: (c)->
      scope = this
      comps = @getCollection("components")
      _.each comps, (cp)->
        scope.setStyle(cp, c) 
    activeMode: ()->
      @deleteComponent "spool"
      @deleteComponent "meter"

      source = @getComponent "source"
      sink = @getComponent "sink"
      
      terminals_made = source and sink
      if not terminals_made then @make_terminals()
      
      @makeJouleHeater(true)
      @circuit_status()

      @boundary_interaction_active()
      
      @setStyles "active"
      @generateParallel()
    @RESOLUTION: 5
    generateParallel: ()->
      scope = this
      boundary = @getComponent "boundary"
      spine = @getComponent "spine"
      heat_layer.activate()
    
      if spine and boundary
        spine = spine.children.arrowbody
        extendSpine = (spine, boundary)->
          spine = spine.clone()
          spine.visible = true
          spine.parent = heat_layer
          ## HEAD
          n2 = spine.getPointAt(spine.length-1)
          n1 = spine.getPointAt(spine.length-5)
          n = n2.subtract(n1)
          n.length = 1000000
          spine.addSegment(n2.add(n))
          ixts = spine.getIntersections(boundary)
          spine.lastSegment.point = ixts[0].point
          ## TAIL
          n2 = spine.getPointAt(0)
          n1 = spine.getPointAt(5)
          n = n2.subtract(n1)
          n.length = 1000000
          spine.insertSegment(0, n2.add(n))
          ixts = spine.getIntersections(boundary)
          spine.firstSegment.point = ixts[0].point
          return spine
        extractSubRegion = (r1, r2, spine, boundary)->
          console.log "SR", r1, r2, spine.length
          p1 = spine.getPointAt(r1)
          p2 = spine.getPointAt(r2)
          norm1 = spine.getNormalAt(r1)
          norm2 = spine.getNormalAt(r2)
          norm1.length = 100
          norm2.length = 100

          rectangle = new paper.Path
            segments: [p1, p1.add(norm1), p2.add(norm2), p2, p2.subtract(norm2), p1.subtract(norm1)]
            closed: true
            
          region = boundary.intersect(rectangle)
          region.set
            fillColor: "orange"
            strokeColor: "purple"
            strokeWidth: 2
          rectangle.remove()
          return region



        spine = extendSpine(spine, boundary)
        rails = _.range 0, spine.length + 1, spine.length / HeaterMagnet.RESOLUTION
        console.log "SPINE LENGTH", spine

        _.each rails, (r, i, arr)-> 
          if i + 1 >= arr.length then return
          r1 = r
          r2 = _.min [arr[i + 1], spine.length]
          region = extractSubRegion(r1, r2, spine, boundary)
          h = new HeaterMagnet
            boundary: region
          h.update()
        scope.destroy()
       

    getMode: ()->
      return if @getComponent "joule" then "active" else "passive"
    boundary_interaction_passive: ()->
      scope = this
      boundary = @getComponent "boundary"
      boundary.fireTouchGestures()
      boundary.set
        onBrushStart: (e)->
          scope.deleteComponent "spine"
          this.arrow = paper.Path.Arrow
            name: "spine"
            arrowColor: "purple"
            arrowWidth: 6
            arrowHead: "solid"
            headScale: 0.6
            onMouseDown: (e)->
              scope.deleteComponent "spine"
              this.remove()
          this.arrow.addPoint(e.point)
          scope.addComponent this.arrow
        onBrushDrag: (e)->
          if this.arrow
            this.arrow.addPoint(e.point)
        onBrushEnd: (e)->
        onBrushTap: (e)->
          scope.activeMode()
    boundary_interaction_active: ()->
      scope = this
      boundary = @getComponent "boundary"
      boundary.fireTouchGestures()
      boundary.set
        onBrushStart: (e)->
          console.log "Active boundary md"
        onBrushDrag: (e)->
        onBrushEnd: (e)->
        onBrushTap: (e)->
          scope.activeMode()
    passiveMode: ()->
      # REMOVE ELEMENTS
      @deleteComponent "resistance_ui"
      @deleteComponent "meter"
      @deleteComponent "joule"
      @deleteComponent "spool"

      # LOCAL COMPONENTS
      boundary = @getComponent "boundary"

      ui_layer.activate()
      meter = new PointText
        name: "meter"
        content: @getResistance()
        fillColor: 'black'
        fontFamily: 'Avenir'
        fontWeight: 'bold'
        fontSize: 15

      meter.set
        pivot: meter.bounds.center
        position: boundary.bounds.center.clone()

      @addComponent meter
      @boundary_interaction_passive()
      s = new Spool
        properties:
          color: new paper.Color("#21BA45")
          scale: 4
      s.position = boundary.bounds.topLeft.clone()
      s.connection = boundary.getNearestPoint(s._ui.position)
      s.fill = @getRelationalResistance()
      
      @addComponent s._ui
      # PASSIVE STYLE
      @setStyles "passive"

    interaction: ()->
      scope = this
      if @getMode() == "active"
        @boundary_interaction_active()
      else
        @boundary_interaction_passive()
      
      @joule_interaction()
      @terminal_interaction()
      @tensioner_interaction()
    tensioner_interaction: ()->
      scope = this
      sink = @getComponent "sink"
      if sink
        sink_path = sink.self.getComponent "magnet_component"
        tensioner = @getComponent "tensioner"
        if tensioner
          tensioner.set
            dtheta: 0
            last_point: null
            min: Ruler.mm2pts(0.3)
            max: Ruler.mm2pts(10)
            onMouseDown: (e)->
              this.sw = scope.strokeWidth
              this.dtheta = 0
              this.last_point = null
              Magnet.hide()
              playSound("Tiny-Glitch")
            onMouseDrag: (e)->
              this.position = sink_path.getNearestPoint this.position.add(e.delta)
              if this.last_point
                center = sink_path.bounds.center.clone()
                a = this.last_point.subtract(center)
                b = this.position.subtract(center)
                this.dtheta = this.dtheta + a.getDirectedAngle(b)
              this.last_point = this.position.clone()

              this.steps = this.dtheta / 180

              sw = this.sw
              sw = sw + (this.steps * 0.3)
              if sw > this.max
                sw = this.max
              if sw < this.min
                sw = this.min

              scope.strokeWidth = sw
              scope.setStyle this, "active"
              scope.setStyle sink, "active"
              scope.update()
            onMouseUp: (e)->
              playSound("Tiny-Glitch")
              

    
    joule_interaction: ()->
      scope = this
      joule = @getComponent "joule"

      if joule
        joule.fireTouchGestures()        
        joule.set
          onBrushTap: ()->
            scope.passiveMode()
    
    terminal_interaction: ()->
      scope = this
      ui = @ui
      boundary = @getComponent "boundary"
      source = @getComponent "source"
      sink = @getComponent "sink"
     
      if source and sink
        _.each [source, sink], (terminal)->
          # SEE NOTEBOOK.COFFEE
          terminal.fireTouchGestures()
          terminal.set   
            getBoundaryPosition: (point)->
              point = boundary.getNearestPoint(point)
              offset = boundary.getOffsetOf(point)
              normal = boundary.getNormalAt(offset)
              normal.length = -15
              return point.clone().add(normal)
            # BRUSH GESTURE
            onBrushTap: (e)->
              Magnet.hide()
              scope.update()
            onBrushStart: (e)->
              Magnet.hide()
              tensioner = scope.getComponent "tensioner"
              if tensioner
                tensioner.visible = false
              this.m_down(e)
              sink = scope.getComponent "sink"
              scope.setStyles "motion"
              this.position = this.getBoundaryPosition(this.position)
              scope.update()
            onBrushDrag: (e)->
              this.m_drag(e)
              this.position = this.getBoundaryPosition(this.position)
              scope.update()
            onBrushEnd: (e)->
              tensioner = scope.getComponent "tensioner"
              sink = scope.getComponent "sink"
      
              this.m_up(e)
              scope.setStyles "active"
              this.position = this.getBoundaryPosition(this.position)

              scope.setStyle sink, "active"

              if tensioner
                tensioner.position = sink.children.magnet_component.getPointAt(0)
                tensioner.visible = true
              scope.update()  

            # HOLD GESTURE
            onHoldTap: (e)->
              console.log "brush tap"
            onHoldStart: (e)->
              this.strokeWidth = 2
              console.log "brush start"
              this.line_magnet = new LineMagnet
                layer: circuit_layer
                point: e.point
              if this.name == "source"
                magnet = this.line_magnet.getComponent("end_terminal")
              else
                magnet = this.line_magnet.getComponent("start_terminal")
              magnet.self.addConnection(terminal)
              terminal.self.getUIElement().update()
              magnet.position = terminal.position
              scope.update()

            onHoldDrag: (e)->
              console.log "brush drag"
              if this.name == "source"
                this.line_magnet.setStartTrace(e.point)
              else
                this.line_magnet.setEndTrace(e.point)
              ui.bringToFront()
              scope.update()
            onHoldEnd: (e)->
              console.log "brush end"
              ui.bringToFront()
              scope.update()
              # this.line_magnet.setEndTrace(e.point)


    
    
    circuit_status: ()->
      boundary = @getComponent "boundary"
      source = @getComponent "source"
      @deleteComponent "resistance_ui"
      @deleteComponent "meter"

      pt = boundary.getNearestPoint(boundary.bounds.topRight)
      
      offset = new paper.Point(0, 0)
      offset.angle = -45
      offset.length = 60
      
      right_offset = new paper.Point(0, 0)
      right_offset.angle = 0
      right_offset.length = 30

      ui_layer.activate()

      meter = new PointText
        name: "meter"
        content: @getResistance()
        fillColor: 'black'
        fontFamily: 'Avenir'
        fontWeight: 'bold' 
        fontSize: 12
          

      meter.pivot = meter.bounds.center
      meter.position = source.position
      
      # sWControl = @generateControlUI "strokeWidth",
      #   position: meter.bounds.rightCenter.clone().add(right_offset)
      #   min: Ruler.mm2pts(0.3)
      #   max: Ruler.mm2pts(10)
      #   padding: 30

      # right_offset.length = right_offset.length  
      # + sWControl.bounds.width

      # sIControl = @generateControlUI "strokeInterval",
      #   position: meter.bounds.rightCenter.clone().add(right_offset)
      #   min: Ruler.mm2pts(0.3)
      #   max: Ruler.mm2pts(10)
      #   padding: 30

        
      resistance_ui = new paper.Group
        name: "resistance_ui"
        children: [meter]
        data: 
          printable: false
      @addComponent resistance_ui


    # GEOMETRY GENERATION FUNCTIONS
    makeJouleHeater: (update=false)->
      source = @getComponent "source"
      sink = @getComponent "sink"
      joule = @getComponent "joule"
      boundary = @getComponent "boundary"
      
      render_heater = source and sink
      if render_heater or update
        if joule then @deleteComponent "joule"
        params = 
          boundaries: [boundary]
          source: source.position
          sink: sink.position
        joule = @serpentine params
        @joule_interaction()
        boundary.sendToBack()
        @circuit_status()

    make_terminals: ()->     
      boundary = @getComponent "boundary"
      params = 
          boundaries: [boundary]
          source: boundary.getNearestPoint(boundary.bounds.topCenter)
          sink: boundary.getNearestPoint(boundary.bounds.bottomCenter)

      source_normal = boundary.getNormalAt(boundary.getOffsetOf(params.source))
      sink_normal = boundary.getNormalAt(boundary.getOffsetOf(params.sink))
      source_normal.length = -15
      sink_normal.length = -15

      source = new Magnet
        name: "source"
        magnets: ["C"]
        accepts: ["magnet_start_terminal", "magnet_end_terminal"]
        path: new paper.Path.Rectangle
          size: [60, 30]       
          radius: 5       
          magnetClass: "magnet_sink"
          position: params.source.clone().add(source_normal)
          style: @styles.source_active()

      # source_handle = new paper.Path.Circle
      #   radius: 
      sink = new Magnet
        name: "sink"
        magnets: ["C"]
        accepts: ["magnet_start_terminal", "magnet_end_terminal"]
        path: new paper.Path.Circle
          magnetClass: "magnet_sink"
          radius: 15       
          position: params.sink.clone().add(sink_normal)
          style: @styles.sink_active(this)

      sink_path = sink.getComponent "magnet_component"
      tensioner = new paper.Path.Circle
        name: "tensioner"
        position: sink_path.getPointAt(0)
        radius: 10
      @setStyle tensioner, "active"
        
      @addComponents [source.ui, sink.ui, tensioner]
      tensioner.bringToFront()
      @tensioner_interaction()
      @terminal_interaction()
    serpentine: (options)->
      options.strokeWidth = this.strokeWidth
      options.strokeInterval = this.strokeInterval
      options.heatColor = this.getRelationalColor()

      scope = this
      boundary = options.boundaries[0]
      axis_length = Math.abs(options.source.subtract(options.sink).length) 
      if axis_length < 30
        @setStyle boundary, "passive"
        return
      else
        heat_layer.activate()
        joule = HeatSketch.snake options
        if joule
          @setStyle boundary, "active"
          
          @deleteComponent "joule"
          @addComponent joule
          joule.sendToBack()
        else
          @deleteComponent "joule"

      return joule   
    generateControlUI: (field, config)->
      scope = this
      
      ui_layer.activate()

      group = new paper.Group
        name: "control_"+field
        

      text = new PointText
        name: field
        parent: group
        fillColor: 'black'
        fontFamily: 'Avenir'
        fontSize: 15
        content: Ruler.pts2mm(this[field]).toFixed(1) + " mm"
        data:
          value: this[field]
      # console.log text.bounds.topCenter.add(0, -config.padding)
      increase = new paper.Path.Circle
        parent: group
        name: "increase_"+field 
        radius: 15
        fillColor: "black"
        position: text.bounds.topCenter.add(0, -config.padding)
        onMouseDown: ()->
          val = text.data.value
          val = val + 0.3
          if val > config.max
            val = config.max
          text.data.value = val
          text.content = Ruler.pts2mm(val).toFixed(1) + " mm"
          scope[field] = val
          
          scope.update()

      decrease = new paper.Path.Circle
        parent: group
        name: "decrease_"+field        
        radius: 15
        fillColor: "red"
        position: text.bounds.bottomCenter.add(0, config.padding)
        onMouseDown: ()->
          val = text.data.value
          val = val - 0.3
          if val <= config.min
            val = config.min
          text.data.value = val
          text.content = Ruler.pts2mm(val).toFixed(1) + " mm"
          scope[field] = val
          
          scope.update()
      group.position = config.position
      return group

    # CIRCUIT ANALYSIS
    last_resistance_str: "- Ω"
    last_resistance: 0
    getResistance: (string = true)->
      joule = @getComponent "joule"
      if not joule 
        rtn = if string then this.last_resistance_str else this.last_resistance
        return rtn
      length = Ruler.pts2mm(joule.length) 
      cross_sectional = MaterialLib.AgIC.thickness * Ruler.pts2mm(joule.strokeWidth)
      resistance = MaterialLib.AgIC.resistivity * (length / cross_sectional)
      
      this.last_resistance_str = resistance.toFixed(0) + "Ω"
      this.last_resistance = resistance
      
      rtn = if string then this.last_resistance_str else this.last_resistance
      return rtn
    getRelationalResistance: ()->
      p = @getResistance(false)/500
      if p > 1
        return 1
      else if p < 0
        return 0
      else
        return p
    getRelationalColor: ()->
      c = HeatSim.temperatureColor(@getRelationalResistance(),with_white=false, reverse=true)
      return c