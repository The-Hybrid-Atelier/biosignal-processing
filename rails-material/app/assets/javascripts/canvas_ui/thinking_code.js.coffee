    # window.b1 = new HeatBranchUI
    #   properties:
    #     V: 12
    #     A: 3
@partition: (regions, node_voltage=12, Ea=63, kappa = 0.42, print = true)->
    total_power = _.sum _.map regions, (r)->
      tr = r.tr
      P = Ea/tr
      return P
    total_resistance = node_voltage**2 / total_power
    total_current = node_voltage/total_resistance
    console.log "NODE", total_power.toFixed(2)+" W", total_current.toFixed(2)+" A", total_resistance.toFixed(2)+" Ω" 
    regions = _.map regions, (r)->
      tr = r.tr
      P = Ea/tr
      R = (node_voltage**2)/P
      w = (kappa * r.A * 1/R)**0.5
      I = (P/R)**0.5
      rtn = 
        tr: tr
        P: P
        I: I
        alpha: I/total_current
        R: R
        w: w
        A: r.A
    if print 
      _.each regions, (r, i)->
        string = MaterialLib.toString r
        if i == 0
          console.log string.header
          console.log "------------------------"
        console.log string.values





  @test_environment: (target_power, branch_voltage, ea)->
    p_total = _.sum target_power
    r_total = branch_voltage**2 / p_total 
    console.log "----- Series Configuration -----"   
    console.log "P_X", (_.map target_power, (x)-> x.toFixed(2)).join(", ")
    console.log "\tP_total", p_total, "W", "• R_total", r_total, "Ω"
    R_X = _.map target_power, (P_X)->
      return (P_X * r_total**2)/branch_voltage**2
    V_X = _.map R_X, (R_X)->
      branch_voltage * R_X / r_total

    console.log "\tR_X", (_.map R_X, (x)-> x.toFixed(2)).join(", ")
    console.log "\tV_X", (_.map V_X, (x)-> x.toFixed(2)).join(", ")
    Thermopainting.subdivide R_X, V_X, target_power, 2, 3
  @subdivide: (heaters, V_X, target_power, rid, n, branch_voltage=12, ea=63)->
    console.log heaters[rid].toFixed(2), "Ω","--->"   
    R_T = heaters.slice(0)
    R_orig = R_T[rid]
    V_orig = V_X[rid]
    delete R_T[rid]
    R_T = _.compact R_T
    R_T = _.sum(R_T)
    console.log "R_T", R_T, "Ω", "R_orig", R_orig, "Ω"
    console.log "V_orig", V_orig, "V"

    search = _.range 1, R_T * n * 100, 0.01
    # console.log "R_X", "R_eq", "P_X", "V_X"
    # console.log "------------------------------"

    search = _.map search, (x)->
      R_eq = x/n
      subheaters = _.range(0, n, 1)
      subheaters = _.map subheaters, (h)-> return {resistance: x}
      buffer = R_orig - R_eq
      R_total = R_eq+buffer+R_T
      V0 = branch_voltage * (R_eq / R_total)
      if buffer< 0
        return {P: 0}
      if V0 > V_orig
        return {P: 0}
      P_X = Thermopainting.parallel_resistor2 subheaters, V0, ea, false
      # console.log x, R_eq.toFixed(2) + " Ω", P_X[0].toFixed(2)+ " W", V0.toFixed(2)+ " V"
      return {R_X: x, P: P_X[0], R_eq: R_eq, V0: V0}
    target = target_power[rid]
    s = _.min search, (s)-> Math.abs(s.P - target)
    console.log "BEST MATCH",s.R_X.toFixed(2)+ " Ω", s.R_eq.toFixed(2) + " Ω", s.P.toFixed(2)+ " W", s.V0.toFixed(2)+ " V"
    
    buffer = (R_orig-s.R_eq)
    console.log "BUFFER RESISTOR", buffer.toFixed(2), " Ω"
    console.log "BUFFER POWER", ((branch_voltage * buffer) / (R_T+R_orig))**2/buffer, "W"


  @test_heaters_p: (heaters, I_0, ea = 63, print=true)->
    heaters = _.map heaters, (h)-> return {resistance: h}
    Thermopainting.parallel_resistor(heaters, I_0, ea, print)


  @test_heaters: (heaters, v=12, ea = 63, print=true)->
    heaters = _.map heaters, (h)-> return {resistance: h}
    @parallel_resistor2(heaters, v, ea, print)
    @series_resistor(heaters, v, ea, print)
  @make_heaters: (min, max, step)->
    heaters = _.range(min, max, step)
    return _.map heaters, (h)->
      return {resistance: h}
  @compare_heaters: (min, max, step)->
    heaters = Thermopainting.make_heaters(min, max, step)
    Thermopainting.parallel_resistor2(heaters, 12, 30)
    Thermopainting.series_resistor(heaters, 12, 30)

  @parallel_resistor2: (heaters, V, Ea, print=true)->
    R_eq = _.reduce heaters, ((memo, h)-> 
      return memo + (1/h.resistance)
    ), 0
    R_eq = 1 / R_eq    
    Thermopainting.parallel_resistor(heaters, V/R_eq, Ea, print)

  @parallel_resistor: (heaters, I_0, Ea, print = true)->
    R_eq = _.reduce heaters, ((memo, h)-> 
      return memo + (1/h.resistance)
    ), 0
    R_eq = 1 / R_eq

    R_T = _.map heaters, (heater, i)->
      inv_sum = 0
      _.each heaters, (h, j)-> 
        if j != i
          inv_sum = inv_sum + 1/h.resistance
      return 1/inv_sum
    I_X = _.map heaters, (heater, i)->
      R_X = heater.resistance
      return R_T[i]/(R_T[i] + R_X) * I_0
    P_X = _.map heaters, (heater, i)->
      R_X = heater.resistance
      return I_X[i]**2 * R_X
    t_X = _.map heaters, (heater, i)->
      return Ea / P_X[i]
    range = _.max(t_X)-_.min(t_X)
    
    if print
      console.log "----- Parallel Grouping -----"   
      console.log "Req", R_eq
      console.log "range", range.toFixed(1), "current", I_0.toFixed(1)
      console.log "t_X", (_.map t_X, (x)-> x.toFixed(1)).join(", ")
      console.log "\tR", (_.map heaters, (x)-> x.resistance.toFixed(1)).join(", ")
      console.log "\tR_T", (_.map R_T, (x)-> x.toFixed(1)).join(", ")
      console.log "\tI_X", (_.map I_X, (x)-> x.toFixed(2)).join(", ")
      console.log "\tP_X", (_.map P_X, (x)-> x.toFixed(1)).join(", ")
      
    return P_X

  @series_resistor: (heaters, V_0, Ea)->
    R_eq = _.reduce heaters, ((memo, h)-> 
      return memo + h.resistance
    ), 0
    current = V_0 / R_eq
    P_X = _.map heaters, (heater)->
      R_X = heater.resistance
      return current * current * R_X
    t_X = _.map heaters, (heater, i)->
      return Ea / P_X[i]
    
    range = _.max(t_X)-_.min(t_X)
    console.log "----- Series Grouping -----"
    console.log "range", range.toFixed(1), "current", current.toFixed(1), "R_eq", R_eq.toFixed(1) 
    console.log "t_X", (_.map t_X, (x)-> x.toFixed(1)).join(", ")
    console.log "\tP_X", (_.map P_X, (x)-> x.toFixed(1)).join(", ")
    
   # # COMPONENT INTERACTIONS
    # ui_magnets = paper.project.getItems
    #   data: 
    #     ui: true
    #     class: "Magnet"

    # _.each ui_magnets, (ui)->
    #   # console.log "LOADING", ui.name, ui.data.class
    #   klass = eval(ui.data.class)
    #   klass.load(ui)
      
    # ui_elements = paper.project.getItems
    #   data: (i)->
    #     return i.ui and i.class != "Magnet"

    # _.each ui_elements, (ui)->
    #   # console.log "LOADING", ui.name, ui.data.class
    #   klass = eval(ui.data.class)
    #   klass.load(ui)


  # parent_selector: ()->
  #   scope = this
  #   if this.parent
  #     @destroy "parent_selector"
  #   else
  #     scope = this
  #     color = Environment.pretty_color("#00A8E1")
  #     ui_layer.activate()

  #     ps = new paper.Group
  #       name: "parent_selector"
  #       parent: this.ui
  #       onMouseDown: (e)->
  #         this.l = new paper.Path.Line
  #           strokeColor: color.dark
  #           strokeWidth: 3
  #           from: this.children.button.getNearestPoint(e.point)
  #           to: e.point
  #         e.stopPropagation()
  #       onMouseDrag: (e)->
  #         if this.l
  #           this.l.firstSegment.point = this.children.button.getNearestPoint(e.point)
  #           this.l.lastSegment.point = e.point
  #         e.stopPropagation()
  #       onMouseUp: (e)->
  #         if this.l
  #           this.l.firstSegment.point = this.children.button.getNearestPoint(e.point)
  #           this.l.lastSegment.point = e.point
  #           branches = paper.project.getItems {name: "HeatBranchUI"}
  #           branches = _.map branches, (branch)-> branch.self
  #           b =  _.min branches, (branch)->
  #             return branch.ui.position.getDistance e.point
  #           if b
  #             scope.parent = b
  #           this.l.remove()

  #         e.stopPropagation()

  #     c = new paper.Path.Circle
  #       name: "button"
  #       parent: ps
  #       fillColor: color.base
  #       strokeColor: color.dark
  #       radius: 15
  #       strokeRadius: 3
  #       # shadowColor: "black"
  #       # shadowBlur: 3


  #     paper.project.importSVG "/icons/immaterial_power.svg", 
  #       insert: false
  #       expandShapes: true
  #       applyMatrix: false
  #       onLoad: (svg)->
  #         svg = svg.children[1]
  #         svg.name = "power"
  #         svg.parent = ps
  #         ps.set
  #           position: scope.get("boundary").bounds.center
  #         svg.fitBounds(c.bounds.expand(-10))
  #         # svg.set
  #         #   parent: ps
  #         #   position: ps.bounds.center
  #       onError: (svg)->
  #         alertify.error "Could not load power SVG"