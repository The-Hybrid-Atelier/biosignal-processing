class window.LineMagnet extends UIElement
    name: "line_magnet"
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
      trace = new paper.Path
        name: "trace"
        segments: [options.point, options.point.add(new paper.Point(100, 0))]
        style: this.styles.trace()
      start = new Magnet
        name: "start_terminal"
        magnets: ["C"]
        accepts: ["power_pad_magnet", "magnet_sink"]
        path: new paper.Path.Circle
          magnetClass: "magnet_start_terminal"
          position: options.point
          radius: 15     
          style: this.styles.power_pad_terminal()
      end = new Magnet
        name: "end_terminal"
        magnets: ["C"]
        accepts: ["ground_pad_magnet", "magnet_sink"]
        path: 
          new paper.Path.Circle
            magnetClass: "magnet_end_terminal"
            radius: 15
            position:  options.point.add(new paper.Point(100, 0))   
            style: this.styles.ground_pad_terminal()
      @addComponents [trace, start.ui, end.ui]
    update: ()->
      scope = this
      ui = @ui
      start = @getComponent "start_terminal"
      end = @getComponent "end_terminal"
      trace = @getComponent "trace"
      
      # RESOLVE TRACE
      trace.firstSegment.point = start.position
      trace.lastSegment.point = end.position
      # console.log start.self.hasConnections(), end.self.hasConnections()
      if start.self.hasConnections() and end.self.hasConnections()
        trace.set this.styles.trace_connected()
      else
        trace.set this.styles.trace()
      ui.bringToFront()
      heat_sim.update()
    setEndTrace: (point)->
      end = @getComponent "end_terminal"
      end.position = point
      this.update()
    setStartTrace: (point)->
      start = @getComponent "start_terminal"
      start.position = point
      this.update()
    interaction: ()->
      scope = this
      ui = @ui
      start = @getComponent "start_terminal"
      end = @getComponent "end_terminal"
      trace = @getComponent "trace"
      
      _.each [start, end], (terminal)->
        terminal.set
          onMouseDown: (e)->
            this.m_down(e)
            scope.update()
          onMouseDrag: (e)->
            this.m_drag(e)
            scope.update()
          onMouseUp: (e)->   
            this.m_up(e)
            scope.update()
            ui.bringToFront()