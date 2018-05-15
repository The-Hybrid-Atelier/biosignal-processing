class window.Rail extends UIElement
  name: "rail"
  styles:
    trace: ()->
      style =  
        strokeColor: "#666666"
        strokeWidth: 10
    trace_connected: ()->
      style =  
        strokeColor: "black"
        strokeWidth: 10
    terminal: ()->
      style =
        strokeColor: "black"
        strokeWidth: 4
        fillColor: "#666666"
    ground_pad_terminal: ()->
      style =
        strokeColor: "#006f95"
        strokeWidth: 4
        fillColor:  "#00A8E1"
    power_pad_terminal: ()->
      style =
        strokeColor: "#880000"
        strokeWidth: 4
        fillColor:  "#ff4d4d"
  
  create: (options)->
    scope = this
    this.ui.data.components = 
      start_terminal_pad: 
        guid: null
        obj: null
      end_terminal_pad: 
        guid: null
        obj: null
      connections: []
    # OBJECT CREATION  
    trace = new paper.Path
      name: "trace"
      segments: [options.point, options.point.add(new paper.Point(100, 0))]
    start = new paper.Path.Circle
      name: "start_terminal"
      position: options.point
      radius: 15      
    end = new paper.Path.Circle
      name: "end_terminal"
      radius: 15
      position:  options.point.add(new paper.Point(100, 0))
    
    # STYLING
    trace.set this.styles.trace()
    _.each [start, end], (terminal)->
      terminal.set scope.styles.terminal()
    
    @addComponents [trace, start, end]
  update: ()->
    scope = this
    ui = @ui
    start_terminal_pad = @getComponent("start_terminal_pad")
    end_terminal_pad = @getComponent("end_terminal_pad")
    trace = @getComponent("trace", true)

    # CONNECTED
    is_connected = start_terminal_pad and end_terminal_pad
    style = if is_connected then this.styles.trace_connected() else this.styles.trace()
    
    # TRACE UPDATE
    trace.set style

    if is_connected
      # DOES IT INTERSECT A HEATER
      heaters = paper.project.getItems
        name: "heater"

      hits = _.map heaters, (heater)->
        boundary = heater.self.getComponent("boundary")
        ixts = trace.getIntersections(boundary)
        
        if ixts.length >= 2 then return heater

      heater_hits = _.compact(hits)
      _.each heater_hits, (heater)->
        console.log "HEAT", heater
        heater.self.update()
        


  connect: (pad, terminal)->
    c = @ui.data.components
    c[terminal.name + "_pad"].guid = pad.ui.data.guid
    c[terminal.name + "_pad"].obj = pad.ui

  disconnect: (terminal)->
    c = @ui.data.components
    c[terminal.name + "_pad"].guid = null
    c[terminal.name + "_pad"].obj = null

  interaction: ()->
    scope = this
    ui = @ui
    start = @ui.data.components.start_terminal.obj
    end = @ui.data.components.end_terminal.obj
    trace = @ui.data.components.trace.obj
    

    _.each [start, end], (terminal)->
      terminal.set
        onMouseDown: (e)->
          this.position = e.point
          if this.name == "start_terminal"
            trace.firstSegment.point = e.point
          else
            trace.lastSegment.point = e.point
        onMouseDrag: (e)->
          this.position = e.point
          if this.name == "start_terminal"
            trace.firstSegment.point = e.point
          else
            trace.lastSegment.point = e.point

          # IF OVER A PAD
          hits = paper.project.hitTestAll e.point, _.extend scope.hitoptions, 
            match: (h)-> 
              return h.item.name == "base"

          # _.each paper.project.getItems({name: "pad"}), (pad)->
          #   pad.self.highlight(pad, false)
          
          # _.each hits, (el)->
          #   pad = UIElement.getUI(el.item)
          #   pad.self.highlight(pad, true)

        onMouseUp: (e)->
          # IF OVER A PAD
          terminal = this
          over_pad = this.isOverPad(e)
          rail = ui.self
          previous_connection = ui.data.components[this.name + "_pad"].obj
          
          # DISCONNECT FROM PREVIOUS CONNECTION
          if previous_connection
            pad = previous_connection.self
            pad.disconnect(terminal)
            rail.disconnect(terminal)

          # UPDATE CONNECTION STATE 
          if over_pad
            over_pad.connect(terminal)
            rail.connect(over_pad, terminal)
            switch over_pad.constructor.name
              when "PowerPad"
                this.set scope.styles.power_pad_terminal()
              when "GroundPad"
                this.set scope.styles.ground_pad_terminal()       
          else
            this.set scope.styles.terminal()

          # UPDATE POSITION
          new_pos = if over_pad then over_pad.ui.bounds.center.clone() else e.point
          this.position = new_pos
          if this.name == "start_terminal"
            trace.firstSegment.point = new_pos
          else
            trace.lastSegment.point = new_pos
          ui.bringToFront()

          scope.update(ui)
        isOverPad: (e)->
          hits = paper.project.hitTestAll e.point, _.extend scope.hitoptions, 
            match: (h)-> 
              return h.item.name == "base"
          return if hits.length > 0 then UIElement.getUI(hits[0].item).self else null

    trace.set
      onMouseDown: (e)->
        scope.highlight(trace, true)
      onMouseDrag: (e)->
        # trace.parent.position = trace.parent.position.add(e.delta) 
        start_pad = ui.data.components["start_terminal_pad"]
        end_pad = ui.data.components["end_terminal_pad"] 
        
        if start_pad and start_pad.obj
          start_pad.obj.self.moveTo(e.delta)
        if end_pad and end_pad.obj
          end_pad.obj.self.moveTo(e.delta)

        if not start_pad.obj
          trace.firstSegment.point = trace.firstSegment.point.add(e.delta)
          start.position = start.position.add(e.delta)
        if not end_pad.obj
          end.position = end.position.add(e.delta)
          trace.lastSegment.point = trace.lastSegment.point.add(e.delta)
      onMouseUp: (e)->
        scope.highlight(trace, false)
      
    
  
    



