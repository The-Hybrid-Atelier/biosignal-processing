class window.MaterialLib
  @AgIC:   
    resistivity: 0.3
    specific_heat: 0.233 #J/gmK
    k: 0.016 #s-1
    thickness: 0.69746 #mm
    density: 1.2 #g/m^3
    kappa: 0.278#0.4418#1921235988
    interval_min: 0.3  #mm
    max_current: 1.5
  @TLC:
    activationEnergy: 8
  @TWatercolor:
    activationEnergy: 55
  @TPLA:
    activationEnergy: 757
  @units: 
    tr: 
      term: "rise time"
      unit: " s"
      decimals: 1
      prep: (v)->
        v.toFixed(this.decimals) + this.unit
    P: 
      term: "power"
      unit: " W"
      decimals: 2
      prep: (v)->
        v.toFixed(this.decimals) + this.unit
    V: 
      term: "voltage"
      unit: " V"
      decimals: 1
      prep: (v)->
        v.toFixed(this.decimals) + this.unit
    I:
      term: "current" 
      unit: " A"
      decimals: 2
      prep: (v)->
        v.toFixed(this.decimals) + this.unit
    max_I: 
      term: "max_current" 
      unit: " A"
      decimals: 2
      prep: (v)->
        "[" + v.toFixed(this.decimals) + this.unit + "]"
        
    R:
      term: "resistance"
      unit: " Ω"
      decimals: 0
      prep: (v)->
        v.toFixed(this.decimals) + this.unit
    annotations:
      term: "annotations"
      prep: (v)->
        if v then "ANNOTATED" else ""
    print:
      term: "print"
      prep: (v)->
        if v then "PRINT" else "NONPRINT"
    alpha: 
      term: "current_proportion"
      unit: "%"
      multiplier: 100
      decimals: 1
      prep: (v)->
        v = v * this.multiplier
        v.toFixed(this.decimals) + this.unit
    min_tr: 
      term: "rise time"
      unit: " s"
      decimals: 1
      prep: (v)->
        v.toFixed(this.decimals) + this.unit
    w:
      term: "trace_width"
      unit: " mm"
      decimals: 1
      prep: (v)->
        v.toFixed(this.decimals) + this.unit
    A:
      term: "area" 
      unit: " mm^2"
      decimals: 1
      prep: (v)->
        v.toFixed(this.decimals) + this.unit
    guid: 
      prep: (v)->
        "#" + v.slice(0, 2) + " |"
    max_P: 
      term: "power"
      unit: " W"
      decimals: 2
      prep: (v)->
        "[" + v.toFixed(this.decimals) + this.unit+ "]"
    parent: 
      prep: (v)->
        if v 
          "["+ "#"+v.guid.slice(0, 2)+"]"
    children: 
      prep: (children)->
        _.map children, (child)->
          "["+ "#"+child.guid.slice(0, 2)+"]"
        # console.log "-----"+"N:"+ children.length+"-------"
        # _.each children, (child)->
          # console.log child.toString()
  @toString: (dictionary)->
    header = _.map dictionary, (value, unit)->
      config = MaterialLib.units[unit]
      if config
        return config.term
      else
        return unit
    str = _.map dictionary, (value, unit)->
      config = MaterialLib.units[unit]
      if config
        config.prep(value)
      else
        value
    rtn = 
      header: header.join(', ') 
      values: str.join(', ')