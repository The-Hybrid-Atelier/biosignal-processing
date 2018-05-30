class window.Gutter extends UIElement
  name: "gutter"
  styles:
    region: ()->
      style =  
        fillColor: "#DFDFDF"
        strokeColor: "#DDDDDD"
        strokeWidth: 0
    hatch: ()->
      style =  
        strokeColor: "#CCCCCC"
        strokeWidth: 2
  @styles: 
    print: ()->
      style = 
        strokeColor: "black",
        strokeWidth: 1
        fillColor: null
        dashArray: [2, 1]
    region: ()->
      style =  
        fillColor: "#DFDFDF"
        strokeColor: "#DDDDDD"
        strokeWidth: 0
  highlight: ()->
    #override
  print: ()->
    # debugger;
    region = @getComponent("region")
    _.each paper.project.getItems({name: "hatch"}), (hatch)->
      hatch.remove()
    region.set this.styles.print()
  create: (options)->
    scope = this
    
    height = Ruler.in2pts(1)

    artboard = paper.project.getItem 
      name: "paper"
    if not artboard
      alertify.error("Artboard object not found")
      return

    # OBJECT CREATION  
    guide_layer.activate()
    region = new paper.Path.Rectangle
      name: "region"
      size: [artboard.bounds.width, height]
    region.pivot = region.bounds[options.direction + "Left"]
    region.position = artboard.bounds[options.direction + "Left"]
    region.parent = options.parent
    # STYLING
    region.set @styles.region()

    op = options.direction
    switch op
      when "top"
        op = "bottom"
      when "bottom"
        op = "top"

    t = new paper.Path.Line
      from: region.bounds[options.direction + "Right"].add(new paper.Point(height, 0))
      to: region.bounds[options.direction + "Left"].add(new paper.Point(-1 * height, 0))
    b = new paper.Path.Line
      from: region.bounds[op + "Right"].add(new paper.Point(height, 0))
      to: region.bounds[op + "Left"].add(new paper.Point(-1 * height, 0))

    hatches = _.range(0, 1, 0.03)
    _.each hatches, (p)->
      step = p+ 0.10
      if step > 1
        return 
      hatch = new paper.Path.Line
        parent: options.parent
        name: "hatch"
        from: t.getPointAt(t.length * p)
        to: b.getPointAt(b.length * step)
      hatch.set scope.styles.hatch()
      ixts = hatch.getIntersections(region)
      if not (region.contains(hatch.firstSegment.point) or region.contains(hatch.lastSegment.point))
        hatch.remove()
      h = hatch.intersect(region)
      h.name = 'hatch'
      h.parent = options.parent
      hatch.remove()

    t.remove()
    b.remove()
    this.addComponents [region]

   
  interaction: (ui)->
    scope = this
    region = @getComponent("region")
    region.set
      onMouseDown: (e)->
        scope.highlight(region, true)
      onMouseDrag: (e)->
        ;
      onMouseUp: (e)->
        scope.highlight(region, false)