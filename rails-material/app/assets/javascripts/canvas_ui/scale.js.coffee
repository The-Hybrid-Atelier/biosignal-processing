class window.EnergyScale
  @ACTIVATION_ENERGY: ()-> return Environment.thermoreactive_composite.activationEnergy
  @MAX: 60
  @density_block: (alpha)->
    
  @hue_gram: (desat = true)->
    # hue_gram = ["#9400D3","#4B0082","#0000FF","#00FF00","#FFFF00","#FF7F00","#FF0000"].reverse()
    hue_gram = ["#0000FF","#FFFF00","#FF0000"].reverse()
    return  _.map hue_gram, (hue)-> 
      h = new paper.Color(hue)
      if desat
        h.saturation = 0.8
      return h
  refresh: ()->
    @scale.children.title.content = "Thread Color Legend\n" + Environment.thermoreactive_composite.activationEnergy + " J"

    axes_values = @scale.getItems
      name: (n)-> return _.includes ["powerscale", "risescale", "axeslines"], n

    _.each axes_values, (v)->
      v.remove()
    @addScale()
  constructor: ()->
    @hue_gram = EnergyScale.hue_gram()

    scale = paper.project.getItem {name: "scale"}
    if scale then scale.remove()

    ui_layer.activate()
    @scale = new paper.Group
      name: "scale"
      saveable: false

    reference = new paper.Path.Rectangle
      parent: @scale
      name: "reference"
      size: [30, paper.view.bounds.height * 0.5]
      fillColor: "orange"
      onMouseDown: (e)->
        y_max = this.bounds.bottomCenter.y
        y_min = this.bounds.topCenter.y
        range = y_max-y_min
        p = (e.point.y - y_min)/range

        if Environment.last_heat_space
          Environment.last_heat_space.tr = EnergyScale.MAX * p
    
    reference.set
      fillColor: 
        gradient:
          stops: EnergyScale.hue_gram(desat=true)
        origin: reference.bounds.topCenter
        destination: reference.bounds.bottomCenter

    @scale.pivot =  @scale.bounds.center
    @scale.position =  paper.view.bounds.leftCenter.add(new paper.Point(100, 0))
    @addScale()
    @addTitle()
  addTitle: ()->
    reference = @scale.children.reference
    reference
    title = new paper.PointText 
      name: "title"
      parent: @scale 
      content: "Thread Color Legend\n 60J"
      fillColor: 'black'
      justification: "center"
      fontWeight: 'bold'
      fontFamily: 'Avenir'
      fontSize: 8
    title.pivot = title.bounds.bottomCenter.add(new paper.Point(0, 5))
    title.position = reference.bounds.topCenter
  
  addScale: ()->
    scope = this
    reference = @scale.children.reference
    h = reference.bounds.height
    offset = 1
    l = reference.bounds.topLeft.clone().add(new paper.Point(-offset, 0))
    r = reference.bounds.topRight.clone().add(new paper.Point(offset, 0))
    pts = _.range 0.1, 1.1, 1/10

    _.each pts, (p)->
      s_y = h * p
      t_R = 60 * p#seconds
      P_X = EnergyScale.ACTIVATION_ENERGY()/t_R
      I = P_X / Environment.power_supply.voltage
      err = if (I > Environment.power_supply.max_current) or (I > Environment.joule_heater_material.max_current) then "(!)" else ""

      t_R = t_R.toFixed(0) + " s"
      P_X = P_X.toFixed(1) + "W " + err
      
      left = l.clone().add(new paper.Point(0, s_y))
      right = r.clone().add(new paper.Point(0, s_y))
      line = new paper.Path.Line
        name: "axeslines"
        parent: scope.scale 
        strokeWidth: 1
        strokeColor: "black"
        from: l
        to: r
      padding = 2
      power = new paper.PointText
        name: "powerscale"
        parent: scope.scale 
        content: P_X
        fillColor: 'black'
        fontFamily: 'Avenir'
        fontSize: 8
      power.pivot = power.bounds.bottomRight.add(new paper.Point(padding, 0))
      power.position = left.clone()

      rise_time = new paper.PointText
        name: "risescale"
        parent: scope.scale 
        content: t_R
        fillColor: 'black'
        fontFamily: 'Avenir'
        fontSize: 8
      rise_time.pivot = rise_time.bounds.bottomLeft.add(new paper.Point(-padding, 0))
      rise_time.position = right.clone()

  @rainbow: (p)->
    # if p < 0 or p > 1 then console.warn "OUT OF RANGE - TEMP TIME", p
    if _.isNaN(p) then p = 0
    if p > 1 then p = 1
    if p < 0 then p = 0



    hues = @hue_gram(true)
    if p == 0 then return hues[0]

    i = p * (hues.length - 1)
    a = Math.ceil(i)
    b = a - 1

    terp = a - i
    
    c1 = hues[a]
    c2 = hues[b]   

    h = c1.hue * (1-terp) + c2.hue * terp
    s = c1.saturation * (1-terp) + c2.saturation * terp
    l = c1.lightness * (1-terp) + c2.lightness * terp

    # console.log c1.toString(), c2.toString()
    # console.log c1.multiply(1-terp).toString(), c2.multiply(terp).toString(), terp

    # c = c1.multiply(1-terp).add(c2.multiply(terp))
    c = new paper.Color
      hue: h
      saturation: s
      lightness: l
    return c

    