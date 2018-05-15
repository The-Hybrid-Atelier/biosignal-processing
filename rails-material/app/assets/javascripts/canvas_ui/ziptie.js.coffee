  # reader = new FileReader()
      # exp = paper.project.exportSVG
      #   asString: true
      #   precision: 5
      # blob = new Blob([exp], {type: 'application/svg'});
      

      # $.ajax
      #   type: "POST"
      #   url:"/notebook/save_file"
      #   data: 
      #     svg: exp
      #   success: (data)->
      #     console.log "SAVE", data
      # _.delay (()->
      #   guide_layer.visible = true
      #   artwork_layer.visible = true
      #   ui_layer.visible = true
      #   paper.view.translate(delta)
      #   window.location = "/test.svg"
      # ), 1000
 # window.translate_tool = new paper.Tool
    #   dom: $('#translate')
    #   name: "translate_tool"

    #   deactivate: (e)->
    #     paper.tool = null
    #     @dom.removeClass('red')
     
    #   hitTest: (e)->
    #     hittable = paper.project.getItems
    #       data: (i)->
    #         return i.ui and i.class != "Magnet"
          
    #     hits = _.filter hittable, (hit)->
    #       return hit.contains(e.point)
    #   highlightHits: (e)->
    #     paper.project.deselectAll()
    #     hits = this.hitTest(e)
    #     _.each hits, (hit)->
    #         hit.selected = true
    #     return hits
    #   onMouseDown: (e)->
    #     @highlightHits(e)

    #   onMouseDrag: (e)->
    #     hits = @highlightHits(e)
    #     _.each hits, (hit)->
    #       debugger;
    #       hit.position.add(e.delta)

    #   onMouseUp: (e)-> 
    #     paper.project.deselectAll()
window.gesture_tool = new paper.Tool
      dom: $('#eraser')
      name: "gesture_tool"
      deactivate: (e)->
        paper.tool = null
        @dom.removeClass('red')
      clear: ()->
        if this.gesture
          this.gesture.remove()
          this.gesture = null 
      analyzeGesture: ()->
        # CLEANING
        this.gesture.simplify()
        this.gesture.smooth()
        # FEATURE EXTRACTION
        overlaps = this.gesture.getIntersections().length
        length = this.gesture.length

        if length > 100 and overlaps == 1
          return "remove"
        else
          return null
      hitTest: (e)->
        hittable = paper.project.getItems
          data: (i)->
            return i.ui and i.class != "Magnet"
          
        hits = _.filter hittable, (hit)->
          return hit.contains(e.point)
      onMouseDown: (e)->
        console.log "hello"
        this.clear()
        ui_layer.activate()
        if this.gesture_active
          if not this.bomb
            this.bomb = new paper.Path.Circle
              radius: 5
              position: e.point
              fillColor: "red"
          
          paper.project.deselectAll()
          hits = this.hitTest(e)
          _.each hits, (hit)->
              hit.selected = true
        else
          this.gesture = new paper.Path
            strokeColor: "#00A8E1"
            strokeWidth: 3
            segments: [e.point]
      onMouseDrag: (e)->
        if this.gesture
          this.gesture.addSegment e.point
        if this.gesture_active
          this.bomb.position = e.point
          paper.project.deselectAll()
          hits = this.hitTest(e)
          _.each hits, (hit)->
              hit.selected = true

      onMouseMove: (e)->
        if this.gesture_active
          this.bomb.position = e.point

      onMouseUp: (e)->
        scope = this
        if this.gesture_active
          paper.project.deselectAll()
          hits = this.hitTest(e)
          _.each hits, (hit)->
              hit.self.destroy()
          this.gesture_active = null
          this.bomb.remove()

        if this.gesture
          gesture = this.analyzeGesture()
          paper.project.deselectAll()
          switch gesture
            when "remove"
              scope.gesture_active = "remove"
              this.bomb = new paper.Path.Circle
                radius: 5
                position: e.point
                fillColor: "red"
            when null
              paper.project.deselectAll()
          this.clear()
          
window.scratchPad = ()->
  paper.zip_tool = new paper.Tool
    hitoptions: 
      stroke: true
      fill: false
      segments: false
      tolerance: 20
    history_max_idx: 0
    history_curr_idx: 0
    # KEYEVENTS
    onKeyDown: (e)->
      scope = this
      console.log "KEY", e.key
      if e.modifiers.shift
        if e.modifiers.command and e.key == "z"
          # REDO
          $('#redo').click()
      else
        if e.modifiers.command and e.key == "d"
          e.preventDefault()
          alertify.success "TODO: DUPLICATE"  
        if e.modifiers.command and e.key == "z"
          # UNDO
          $('#undo').click()
        
        if e.modifiers.command and e.key == "s"
          e.preventDefault()
          # SAVE
          $('#save').click()
        if e.key == "backspace"
          # DELETE SELECTED ELEMENTS
          $('#save').click()
          _.each paper.project.selectedItems, (item)->
            if item
              item = scope.getGroup(item)
              item.remove()
    getGroup: (item)->
      if not item.parent or item.className == "Group"
        return item
      if item.parent.className != "Group"
        return item
      else
        this.getGroup(item.parent)
    
    # MOUSE EVENTS
    onMouseDown: (e)->
      scope = this
      hits = paper.project.hitTestAll e.point, this.hitoptions
      if hits.length == 0
        if e.modifiers.shift
          this.makeZip(e)
        else
          this.makeRail(e)
    onMouseDrag: (e)->
      if this.p
        this.p.lastSegment.point = e.point
    
    onMouseUp: (e)->
      scope = this

      hits = paper.project.hitTestAll e.point, this.hitoptions
      console.log e.delta.length

      if e.delta.length < 5 #SELECTION
        if this.p
          this.p.remove()
        if not e.modifiers.shift
          paper.project.deselectAll()
        _.each hits, (hit)->
          item = scope.getGroup(hit.item)
          item.selected = true
        return

      this.p.lastSegment.point = e.point
      # RAIL INTERACTION
      if this.p.name == "wire"
        rail = this.p
        end = new paper.Path.Circle
          radius: 15
          position: this.p.lastSegment.point.clone()
          strokeColor: "black"
          strokeWidth: 4
          fillColor: "#666666"
          data: 
            guid: guid()
        this.p.set
          data:
            end: end.data.guid

      if this.p.name == "ziptie"
        ziptie = this.p  
        ziptie.set
          data:
            guid: guid()
        # ADD ZIPTIE DISPLAY
        zip = new paper.Path.Circle
          position: ziptie.getPointAt(0)
          fillColor: ziptie.strokeColor
          radius: ziptie.strokeWidth
          data:
            guid: guid()  
        
        ziptie_ui = new paper.Group
          children: [ziptie, zip]
          name: "ziptie_ui"
          data: 
            ziptie: ziptie.data.guid
            zip: zip.data.guid
        console.log "UI", ziptie_ui

        shadow = new Color(0, 0, 0)
        shadow.alpha = 0.3

        ziptie_ui.set 
          opacity: 0.8
          shadowColor: shadow
          shadowBlur: 6
          shadowOffset: new Point(1, 1)

        this.bindZiptieInteraction(ziptie_ui, ziptie, zip)
      
      this.save()
      this.p = null

    
        
    zipColor: "#00A8E1"
    
    makeZip: (e)->
      this.p = new paper.Path
        strokeColor: this.zipColor
        strokeWidth: 20
        segments: [e.point, e.point]
        name: "ziptie"
        strokeCap: "round"
        strokeJoin: "bevel"
        miterLimit: 0
      

    makeRail: (e)->
      
      this.p = new paper.Path
        strokeColor: "black"
        strokeWidth: 10
        radius: 2
        segments: [e.point, e.point]
        name: "wire"

      start = new paper.Path.Circle
        radius: 15
        position: e.point
        strokeColor: "black"
        strokeWidth: 4
        fillColor: "#666666"
        data: 
          guid: guid()

      this.p.set
        data:
          start: start.data.guid
      

    deactivate: ()->
      if this.p
        this.p.remove()
    bindZiptieInteraction: (ziptie_ui, ziptie, zip)->
      scope = this
      wires = paper.project.getItems
        name: "wire"

      # GATHER IXT POINTS
      segments = _.map wires, (wire)->
        ixts = wire.getIntersections(ziptie)
        return _.map ixts, (ixt)->
          idx = ixt.segment.index
          offset_s = ixt.segment.location.offset
          offset = ixt.offset
          if offset > offset_s
            idx = idx + 1

          seg = wire.insert(idx, ixt.point)
          seg.selected = true
          return seg
      segments = _.flatten(segments)

      # DISTRIBUTE EVENLY
      n = segments.length + 1
      step = ziptie.length / n

      ordered_segs = _.sortBy segments, (seg)->
        return ziptie.getLocationOf(seg.point).offset
      
      i = 1
      _.each ordered_segs, (seg)->
        seg.point = ziptie.getPointAt(i * step)
        i = i + 1

    
      ## TRANSLATIONAL CONTROL
      ziptie.set
        onMouseDown: (e)->
          console.log "ZIP"
          paper.tool = null
          ziptie_ui.selected = true
          ziptie_ui.pivot = e.point
        onMouseDrag: (e)->
          console.log "ZIP"
          ziptie_ui.position = e.point
          i = 1
          step = ziptie.length / n
          # UPDATE POSITION OF SEGMENTS
          _.each ordered_segs, (seg)->
            seg.point = ziptie.getPointAt(i * step)
            i = i + 1
        onMouseUp: (e)->
          console.log "ZIP"
          scope.activate()
          ziptie_ui.set
            pivot: ziptie.bounds.center.clone()
          # ziptie_ui.selected = false
      
      ## ANGULAR CONTROL
      snaps = _.range(-90, 91, 15)
      
      zip.set
        ANGLE_MAGNET_STRENGTH: 4 
        onMouseDown: (e)->
          if paper.tool.deactivate
            paper.tool.deactivate()
          paper.tool = null
          ziptie_ui.selected = true
          if e.modifiers.shift
            this.interaction = "rotate"
            this.protractorView(e)
          else
            this.interaction = "scale"
            this.scalingInteraction(e)

          console.log "ZIP Down", this.interaction
        onMouseDrag: (e)->
          console.log "ZIP Drag", this.interaction
          switch this.interaction
            when "rotate"
              this.snapToThetaInteraction(e)
            when "scale"
              this.scalingInteraction(e)
        onMouseUp: (e)->
          if this.protractor
            this.protractor.remove()
            this.protractor = null
          this.interaction = ""
          scope.activate()
          # ziptie_ui.selected = false

        protractorView: (e)->
          z = this
          this.protractor = new paper.Group
              name: "protractor"
          this.snap_circle = new paper.Path.Circle
            parent: this.protractor
            radius: ziptie.length
            position: ziptie.getPointAt(ziptie.length)
            strokeColor: "#CCCCCC"
            strokeWidth: 4
            closed: false
          this.snaps = _.map snaps, (snap)->
            construction_line = new paper.Point(0, 0)
            construction_line.length = ziptie.length
            construction_line.angle = snap - 180
            console.log "SNAP", snap%45 
            return new paper.Path.Circle
              parent: z.protractor
              radius: if snap%45 == 0 then 10 else 5
              fillColor: "#AAAAAA"
              position: z.snap_circle.position.add(construction_line)
          this.snap_circle.rotate -90
          this.snap_circle.removeSegment(3)

        scalingInteraction: (e)->
          v = zip.position.subtract(ziptie.lastSegment.point)
          
          construction_pt = new paper.Point(0, 0)
          construction_pt.length = 10000000
          construction_pt.angle = v.angle

          min_tie_size = new paper.Point(0, 0)
          min_tie_size.length = 45
          min_tie_size.angle = v.angle

          construction_path = new paper.Path.Line
            from: ziptie.lastSegment.point.clone().add(min_tie_size)
            to: construction_pt
            strokeColor: "red"
            strokeWidth: 2
          near = construction_path.getNearestPoint(e.point)
          construction_path.remove()
          zip.position = near.clone()
          ziptie.firstSegment.point = near.clone() 
          this.updateWireBinding()  

        snapToThetaInteraction: (e)->
          near = this.snap_circle.getNearestPoint(e.point)

          min_snap = null
          min_theta = 360
          obj_snap = null
          _.each this.snaps, (snap)->
            theta0 = snap.position.subtract(ziptie.lastSegment.point).angle
            theta1 = near.subtract(ziptie.lastSegment.point).angle
            dtheta = Math.abs(theta1 - theta0)
            if dtheta < min_theta
              min_snap = theta0
              min_theta = dtheta
              obj_snap = snap

          # SNAP TO THETA
          if min_theta < this.ANGLE_MAGNET_STRENGTH
            zip.position = obj_snap.position.clone()
            ziptie.firstSegment.point = obj_snap.position.clone()
          else
            zip.position = near
            ziptie.firstSegment.point = near
          this.updateWireBinding()

        updateWireBinding: ()->
          # UPDATE POSITION OF SEGMENTS
          step = ziptie.length / n
          i = 1
          _.each ordered_segs, (seg)->
            seg.point = ziptie.getPointAt(i * step)
            i = i + 1
        
      


      

      
    dimensions = JSON.parse ws.get(participant_id+"_dimensions")