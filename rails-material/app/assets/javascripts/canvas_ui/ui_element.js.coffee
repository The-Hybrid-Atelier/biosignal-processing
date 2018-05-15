
class window.UIElement extends Collectable
  name: "ui_element"
  hitoptions: 
    stroke: true
    fill: true
    segments: false
    tolerance: 20  
  _print:
    fill: ()-> 
      style =  
        fillColor: "black"
        strokeColor: "black"
        shadowBlur: 0
    stroke: ()->
      style =  
        strokeColor: "black"
        shadowBlur: 0

  to_s: ()->
    return @ui.name+" ("+@ui.data.guid.slice(0, 4)+")"

  constructor: (options)->
    # LOADING OBJECT
    if options.obj
      @ui = options.obj
      @resolveCollections ["magnets", "connections", "components"]
      
    else
      # CREATE OBJECT
      if options.layer
        options.layer.activate()


      this.ui = new paper.Group
        name:  options.name or this.name
        data: 
          ui: true
          guid: guid()
          class: this.constructor.name
      
      if options.parent
        this.ui.parent = options.parent

      @createCollections ["magnets", "connections", "components"]
      @create(options)
      # tracker.save(false)

    # INTERNAL LINKS

    @ui.set
      handler: eval(this.constructor.name)
      self: this
      
    # BIND INTERACTION
    @interaction()

  print: ()->
    scope = this
    components = @getCollection "components"
    unprintable = @ui.getItems
      data:
        printable: false
    _.each unprintable, (obj)->
      obj.visible = false
    _.each components, (obj)->
      if _.includes ["boundary","heater_magnet"], obj.name
        obj.visible = false
        return
      if _.includes ["start_terminal", "end_terminal", "source", "sink"], obj.name
        obj.set
          strokeWidth: 0
          scaling: new Size(0.3, 0.3)
        scope.printify(obj) 
      if obj.className == "Group"
        _.each obj.children, (c)->
          scope.printify(c)
      else  
        scope.printify(obj)    
    paper.view.update()
  printify: (obj)->
    if obj.closed
      obj.set @_print.fill()
    else 
      obj.set @_print.stroke()
    
  
  highlight: (ui, bool)->
    @_highlight(ui, bool)
  
  _highlight: (ui, bool)->
    scope = this
    if ui.className == "Group"
      _.each ui.children, (child)->
        scope._highlight(child, bool)
    else if _.includes(["Path", "CompoundPath"], ui.className)
      ui.set
        shadowColor:"black"
        shadowBlur: if bool then 10 else 0
        shadowOffset: if bool then new paper.Point(5, 5) else new paper.Point(0, 0) 
  interaction: ()->
    @ui.set
      onMouseDown: (e)->
        console.log "TODO: Implement mdo interaction"
      onMouseDrag: (e)->
        console.log "TODO: Implement mdr interaction"
      onMouseUp: (e)->
        console.log "TODO: Implement mup interaction"

  @load: (ui)->
    obj = new this
      obj: ui
    return obj
  destroy: ()->
    console.log "DESTROYING OBJECT", this.ui.name
    magnets = @getComponentMagnets()
    _.each magnets, (mag)->
      mag.clearConnections()
    this.ui.remove()




