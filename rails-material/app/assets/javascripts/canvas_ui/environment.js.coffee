class window.Environment extends Material
  name: "environment"
  @thermoreactive_composite: MaterialLib.TWatercolor
  @power_supply: 
    voltage: 12
    max_current: 3
  @joule_heater_material: MaterialLib.AgIC
  @last_heat_space: null
  @last_heat_branch: null
  @last_heat_twig: null
  @fill_type: "polygon-build"
  @lineBuildWidth: 10
  @previousArtState: null
  @cutting: false
  @mode: "simulate"
  @pretty_color: (color)->
    color = new paper.Color(color)
    dark = color.clone()
    light = color.clone()
    dark.brightness = dark.brightness - 0.2
    light.brightness = light.brightness + 0.2
    clear = color.clone()
    clear.alpha = 0.5
    rtn = 
      base: color
      dark: dark
      light: light
      clear: clear
  @branches: ()-> _.pluck(paper.project.getItems({name: "HeatBranchUI"}), "self")
  @annotations: false
  @all: (property, value)-> _.each paper.project.getItems({data: {component: true}}), (c)-> if c.self then c.self[property] = value
  @update: ()-> _.each paper.project.getItems({data: {component: true}}), (c)-> if c.self then c.self.update()
  @update_annotations: ()-> @all "annotations", Environment.annotations
  @area_compare: ()->
    spaces = _.pluck(paper.project.getItems({name: "HeatSpaceUI"}), "self")
    _.each spaces, (s)-> s.compare_area()
  @paper_update: (color)->
    papel = paper.project.getItem
      name: "paper"
    papel.set
      fillColor: color
  @raster_visible: (visible)->
    rasters = paper.project.getItems {class: "Raster"}
    _.each rasters, (r)-> r.visible = visible
    
  @print: ()-> 
    $('.tools, #trc-select, #magnetize, #artwork-toggle, #playbar').hide()
    $('#zoom-tools').show()
    ui_layer.visible = false
    _.each paper.project.getItems({name: "hatch"}), (h)-> h.visible = false
    _.each paper.project.getItems({name: "region"}), (g)-> g.set(Gutter.styles.print())
    @paper_update("white")
    @raster_visible(false)
    @update()
    
  @simulate: ()->
    $('.tools, #trc-select, #artwork-toggle, #magnetize, #zoom-tools').hide()
    _.each paper.project.getItems({name: "region"}), (g)-> g.set(Gutter.styles.region())
    $('#playbar').show()
    ui_layer.visible = false
    @paper_update("black")
    @raster_visible(false)
    @update()
  @circuit: ()->
    $('.tools, #playbar').hide()
    $('#trc-select, #artwork-toggle, #magnetize, #zoom-tools').show()
    _.each paper.project.getItems({name: "hatch"}), (h)-> h.visible = true
    _.each paper.project.getItems({name: "region"}), (g)-> g.set(Gutter.styles.region())
    ui_layer.visible = true
    @paper_update("#333")
    @raster_visible(false)
    @update()
  @power: ()->
    $('.tools, #trc-select,  #artwork-toggle, #magnetize, #zoom-tools').show()
    _.each paper.project.getItems({name: "region"}), (g)-> g.set(Gutter.styles.region())
    _.each paper.project.getItems({name: "hatch"}), (h)-> h.visible = true
    $('#playbar').hide()
    ui_layer.visible = true
    @paper_update("white")
    @raster_visible(true)
    @update()

