class window.Thermopainting
  constructor: ()->
    this.artwork_opacity = 1
    window.speaker = new Atelier("designer", "scanner")
    speaker.send
      to: "ipevo"
      service: "play_sound"
      name: "Complete"

  toggle_annotations: ()->
    Environment.annotations = not Environment.annotations
    if Environment.annotations
      $('#annotate').addClass("blue")
    else
      $('#annotate').removeClass("blue")
    Environment.update_annotations()
  print_preview: ()->
    @toggle_print()
  toggle_print: ()->
    Environment.print = not Environment.print
    Environment.update_print()
  
  toggle_materialization: ()->
    # console.log "MAT", Environment.materialization, "-->"
    switch Environment.materialization
      when "icon"
        Environment.materialization = "symbol"
        # console.log "MAT", Environment.materialization
        $('#materialize').removeClass("black yellow blue")
        $('#materialize').addClass("black")
      when "index"
        Environment.materialization = "icon"
        # console.log "MAT", Environment.materialization
        $('#materialize').removeClass("black yellow blue")
        $('#materialize').addClass("yellow")
      when "symbol"
        Environment.materialization = "index"
        # console.log "MAT", Environment.materialization
        $('#materialize').removeClass("black yellow blue")
        $('#materialize').addClass("blue")
    Environment.update_materialization()
    

  load: ()->
    @load_layers()
    @load_components()
    @bind_interactions()
    window.scale = new EnergyScale()
    paper.view.update()

    # _.delay (()->
    #   branch = paper.project.getItem {name: "HeatBranchUI"}
        
    #   if _.includes ["circuit", "power", "print"], Environment.mode
    #     console.log "BRANCHES", branch.bounds.height, branch.visible

    #     if branch and branch.bounds.height == 0
    #       branch.remove()
        
    #   if not branch
    #     alertify.error "Branch not found. Adding a new one."
    #     b1 = new HeatBranchUI
    #       properties: 
    #         V: 12
    #         I: 3


    #   ), 1000
   
    
  load_components: ()->
    components = paper.project.getItems {data: {component: true}}
    
    components = _.map components, (component)->
      console.log "Loading components", component.name
      klass = eval(component.name)
      k = new klass
        ui: component
        properties: 
          guid: component.data.properties.guid
      {obj: k, props: component.data.properties}
    paper.view.update()
    

    components = _.map components, (c)->
      # console.log "RESOLVING", c.obj, c.props
      c.obj.resolve c.props, true
      c.obj
 
    branches = _.filter components, (c)->
      return c.constructor.name == "HeatBranchUI"

  print: ()->
    # guide_layer.visible = false
    artwork_layer.visible = false
    ui_layer.visible = false
    paper.view.zoom = 1 

    p = paper.project.getItem
      name: "paper"
    
    p.set
      strokeColor: "black"
      strokeWidth: 1
      fillColor: null
      dashArray: [1, 1]

    gs = paper.project.getItems
      name: "gutter"
    _.each gs, (g)->
      g.set
        strokeColor: "black"
        strokeWidth: 1
        fillColor: null
        dashArray: [1, 2]
    

    ab = paper.project.getItem
      name: "move-artboard" 
    if ab then ab.remove()  

    # PRINT METADATA
    if ws.includes(participant_id+"_dimensions")
      dimensions = JSON.parse ws.get(participant_id+"_dimensions")
      guide_layer.activate()
      text = new PointText
        parent: p.parent
        fillColor: 'black'
        fontFamily: 'Avenir'
        fontSize: 8
        content: dimensions.name
      text.pivot = text.bounds.topRight.add( new paper.Point(8, -8))
      text.position = p.bounds.topRight

    delta = p.strokeBounds.topLeft.clone()
    back_delta = delta.clone().multiply(-1)
    paper.view.translate(back_delta)

    unprintable = [ "hatch"]
    # PRINT SPECIFICS

    ui_elements = paper.project.getItems
      name: (n)->
        _.includes unprintable, n
    rasters = paper.project.getItems
      className: "Raster"
    ui_elements = _.flatten [rasters, ui_elements]

    _.each ui_elements, (ui)->
      ui.visible = false

    # debugger;

    # ui_elements = paper.project.getItems
    #   name: "joule"

    # paper.project.getItems({name: "divider"}).fillColor = "black"
      
    # paper.project.getItem({name: "splitter"}).fillColor = "black"

    # _.each ui_elements, (ui)->
    #   ui.set
    #     strokeColor: "black"
    #     shadowBlur: 0

    paper.view.update()
    bufferCanvas = copyCanvasRegionToBuffer($('#markup')[0], p.strokeBounds.width, p.strokeBounds.height)
    
    $.ajax
      type: "POST"
      url:"/notebook/save_file"
      data: 
        png: bufferCanvas.toDataURL()
      success: (data)->
        $('#print').removeClass('loading')
        paper.view.update()
        window.location = "/notebook/print"
  setup_artboard: ()->    
    @setup_layers()
    window.scale = new EnergyScale()
    
    # ARTBOARD SETUP
    convert = if dimensions.units == "in" then Ruler.in2pts else Ruler.mm2pts
    
    # DELETE PREVIOUS
    artboard = paper.project.getItem {name: "artboard"}
    if artboard then artboard.remove()

    # CREATE NEW ARTBOARD
    console.log "SETTING ARTBOARD TO", dimensions.width, dimensions.units,"x", dimensions.height, dimensions.units, "("+convert(dimensions.width), "pts","x", convert(dimensions.height), "pts"
    
    guide_layer.activate()

    artboard = new paper.Group
      name: "artboard"
      
    p = new paper.Path.Rectangle
      parent: artboard
      name: "paper"
      size: [convert(dimensions.width), convert(dimensions.height) + Ruler.in2pts(2)]
      fillColor: "white"
      position: paper.view.center
      shadowColor: "black"
      shadowBlur: 0
      strokeColor: "#DFDFDF"

    # move = new paper.Path.Circle
    #   parent: artboard
    #   name: "move-artboard" 
    #   fillColor: "#2185D0"
    #   radius: 30
    #   position: p.bounds.topRight

    pp = new Gutter
      layer: guide_layer
      parent: artboard
      direction: "top"
    gp = new Gutter
      layer: guide_layer
      parent: artboard
      direction: "bottom"

    b1 = new HeatBranchUI
      properties: 
        V: 12
        I: 3
        

    @bind_interactions()
   
  
  bind_interactions: ()->
    console.log "Binding artboard interactions"
    # ARTBOARD INTERACTIONS
    artboard = paper.project.getItem
      name: "artboard"
    # move = paper.project.getItem
    #   name: "move-artboard"
    # if move
    #   move.set
    #     onMouseDown: (e)->
    #       this.initial = e.point
    #     onMouseDrag: (e)->
    #       artboard.position= artboard.position.add(e.delta)
    #     onMouseUp: (e)->
    #       nodrag = this.initial and this.initial.getDistance(e.point) < 10
    #       if nodrag
    #         artboard.position = paper.view.center

          # this.initial = null

  add_artwork: ()->
    artboard = paper.project.getItem 
      name: "artboard"
    p = paper.project.getItem 
      name: "paper"
    rasters = paper.project.getItems
      class: "Raster"
    _.each rasters, (r)-> r.remove()
    paper.project.layers.artwork.activate()
    r = new paper.Raster
      name: "artwork"
      parent: artboard
      source: $('#captured-scene img').attr('src')
      position: p.bounds.center
    r.fitBounds(p.bounds)
  page_setup: ()->
    scope = this
    $('#artboard-settings').modal('show')
    $('#artboard-settings .approve').click ()->
      dimensions.height = parseFloat($(this).parents('.modal').find('input[name="height"]').val())
      dimensions.width = parseFloat($(this).parents('.modal').find('input[name="width"]').val())
      scope.SetupArtboard()
  update_opacity: (val)->
    scope = this
    rasters = paper.project.getItems {class: "Raster"}
    scope.artwork_opacity = val
    _.each rasters, (r)-> r.opacity = val
    
  clear: ()->
    paper.project.clear()
    @setup_artboard()
  load_layers:()->
    window.circuit_layer = paper.project.getItem
      name: "circuit"
      class: "Layer"
    window.artwork_layer = paper.project.getItem
      name: "artwork"
      class: "Layer"
    window.guide_layer = paper.project.getItem
      name: "guides"
      class: "Layer"
    window.ui_layer = paper.project.getItem
      name: "ui"
      class: "Layer"
    window.heat_layer = paper.project.getItem
      name: "heat"
      class: "Layer"
    window.sim_layer = paper.project.getItem
      name: "sim"
      class: "Layer"
    layers = _.compact [circuit_layer, artwork_layer, guide_layer, ui_layer, heat_layer, sim_layer]
    if layers.length != 6
      alertify.error "Corrupt file detected. #" +  layers.length
      @clear()
  setup_layers: ()->
    window.guide_layer = new paper.Layer
        name: "guides"
    window.artwork_layer = new paper.Layer
      name: "artwork"
    window.heat_layer = new paper.Layer
      name: "heat"
    window.circuit_layer = new paper.Layer
      name: "circuit"
    window.sim_layer = new paper.Layer
      name: "sim"
    window.ui_layer = new paper.Layer
      name: "ui"