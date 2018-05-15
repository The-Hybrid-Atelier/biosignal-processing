
class window.Simulator
  constructor: ()->
    scope = this
    $('.simulate').click (e)->
      action = $(this).attr('id')
      $(this).addClass('blue').siblings().removeClass('blue')
      scope[action]()
    $('#playbar .speed').html(Simulator.speed + "X")
  @speed: 15
  @SHADOW_BASE: 100
  @activeIntervals: []
  @activeElements: []
  @pauseTime: null
  play: ()->
    scope = this
    spaces = paper.project.getItems {name: "HeatSpaceUI"}
    spaces = _.pluck spaces, "self"
    fire = new paper.Color("red")
    clear = new paper.Color("red")
    clear.alpha = 0.3
    _.each spaces, (space)->
      boundary = space.get "boundary"
      joule = space.get "joule"
      
      boundary.set
        strokeWidth: 0
        fillColor: 
          gradient: 
            stops: [[fire, 0.5], [clear, 1]]
            radial: true
          origin: boundary.position
          destination: boundary.bounds.rightCenter
        shadowColor: fire
        shadowBlur: 0
        opacity: 0
      joule.set
        strokeColor: fire
        shadowColor: fire
        shadowBlur: 0
        opacity: 0

      t = space.tr / Simulator.speed
      interval = 5 / Simulator.speed
      
      low = (t - interval) * 1000
      high = (t + interval) * 1000
      t = t * 1000
      frames = _.range low, high, 1000/30
      # console.log "t", t
      # boundary.opacity = 1
      
      _.each frames, (f, i)->
        p = (f - low) / (high - low)
        console.log f
        id = _.delay (()->  
          boundary.set
            opacity: p
            shadowBlur: p * Simulator.SHADOW_BASE
          joule.set
            opacity: p
            shadowBlur: p * Simulator.SHADOW_BASE
        ),f
        Simulator.activeElements.push(id)
        
    startTime = ()->
      start = performance.now()
      tid = setInterval (()->
        now = (performance.now() - start) * Simulator.speed
        now = now / 1000
        sec = now % 60
        min = now / 60
        ts = Math.floor(min) + ":" + pad(sec.toFixed(0), 2)
        # console.log "min", min
        if min > 1
          # console.log "CLEARING", tid
          clearInterval(tid)
          scope.stop()
        sec = ((now % 1000)/1000) *
        $('.timestamp').html(ts)
      ), 1000 / Simulator.speed
      Simulator.activeIntervals.push tid
    startTime()
    # console.log space.tr
  stop: ()->
    $('#stop').addClass('blue').siblings().removeClass('blue')
    console.log "simulator stop"
    _.each Simulator.activeElements, (id)->
      clearTimeout(id)
    Simulator.activeElements = []
    _.each Simulator.activeIntervals, (id)->
      clearInterval(id)
    Simulator.activeIntervals = []
    
 

class window.HeatSim
  @RESOLUTION_X:30
  @RESOLUTION_Y:30
  @HEAT_LOSS_FACTOR: 0.2
  @temperatureColor: (p, with_white = true, reverse = false)->
    if p < 0 or p > 1 then console.warn "OUT OF RANGE - TEMP TIME", p
    if p > 1 then p = 1
    if p < 0 then p = 0
    if with_white
      thermogram = [new paper.Color(1, 1, 1, 0), "#380584", "#A23D5C", "#FAA503", new paper.Color(1, 1, 1, 1)]
    else
      thermogram = ["#380584", "#A23D5C", "#FAA503"]
    
    if reverse
      thermogram.reverse()
    
    thermogram = _.map thermogram, (t) -> return new paper.Color(t)
    if p == 0 then return thermogram[0]

    i = p * (thermogram.length - 1)
    
    a = Math.ceil(i)
    b = a - 1
    terp = a - i
    red = thermogram[a]
    blue = thermogram[b]    

    c = red.multiply(1-terp).add(blue.multiply(terp))
    c.saturation = 0.8
    # if p < 0.05
      # c.alpha = 0
    return c
  constructor: ()->
    sim_layer.activate()
    ii = _.range 0, HeatSim.RESOLUTION_X, 1
    jj = _.range 0, HeatSim.RESOLUTION_Y, 1
    matrix = paper.project.getItem 
      name: "matrix"
    console.log "MATRIX", matrix
    # if m then m.remove()
    if not matrix
      
      sim_layer.activate()
      matrix = new paper.Group
        name: "matrix"
      console.log "MAKING NEW MATRIX", matrix
      _.each ii, (i)->
        _.each jj, (j)->
          new paper.Path.Rectangle
            name: "cells"
            parent: matrix
            size: [10, 10]
            position: new paper.Point(i * 10, j * 10)
            strokeWidth: 1
            strokeColor: "red"
            i: i, 
            j: j
      matrix.pivot = matrix.bounds.center
      matrix.position = paper.view.center
      matrix.scaling.y = paper.view.bounds.height / matrix.bounds.height
      matrix.scaling.x = paper.view.bounds.width / matrix.bounds.width
    
    _.each matrix.children, (cell)->
      neighbor_c = new paper.Path.Circle
        position: cell.position
        radius: 10
      cell.neighbors = _.filter matrix.children, (child)-> child.intersects(neighbor_c)
      neighbor_c.remove()
    this.update()


  update: ()->
    sim_layer.visible = thermopainting.simulate
    if thermopainting.simulate
      cells = paper.project.getItems
        name: 'cells'
      conductive_elements = paper.project.getItems
        name: (i)-> _.includes ["joule", "trace"], i
        class: "Path"

      canvas = $('canvas')[0]
      context = canvas.getContext('2d')

      #INITIALIZE
      _.each cells, (c)-> 
        c.hits = 0
        # HEAT GENERATION
        c.heat_gen = _.reduce conductive_elements, ((memo, j)-> 
          ixts = j.getIntersections(c)
          offsets = _.pluck(ixts, "offset")
          sum = 0
          _.each offsets, (offset, i, arr)->
            if  i + 1 < arr.length
              sum = sum + (arr[i+1] - offset) * j.strokeWidth
          sum = sum / c.bounds.area
          return memo + sum
        ), 0
        
      
      steps = _.range 0, thermopainting.steps, 1

      #DQ STEP
      _.each steps, (s)-> 
        _.each cells, (c)->
          # # HEAT TRANSFER
          heat_loss = c.hits * HeatSim.HEAT_LOSS_FACTOR

          # DISTRIBUTE LOSS EVENLY TO NEIGHBORS
          n = c.neighbors.length
          heat_residue = heat_loss / n
          _.each c.neighbors, (x)->
            x.hits = x.hits + heat_residue

          # HEAT GENERATION TERM
          c.hits = c.hits + c.heat_gen
          
      # VISUALIZATION
      max_hits = _.max _.pluck cells, "hits"
      _.each cells, (c)->
        if c.hits == 0
          c.fillColor = null
        else
          c.fillColor = HeatSim.temperatureColor(c.hits / max_hits)
 