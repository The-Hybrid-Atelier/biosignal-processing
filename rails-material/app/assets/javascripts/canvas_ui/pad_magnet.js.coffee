class window.PadMagnet extends UIElement
    name: "pad_magnet"
    styles:
      pad: ()->
        style =  
          fillColor: "#AAAAAA"
          strokeColor: "#666666"
          strokeWidth: 3
      selected_pad: ()->
        style =  
          fillColor: "#CCCCCC"
          strokeColor: "#888888"
          strokeWidth: 3
    create: (options)->
      region = new Magnet
        name: "region"
        magnets: ["C"]
        path: new paper.Path.Rectangle
          name: "region"
          size: [30, 60]
          radius: 3
          position: options.point
          style: this.styles.pad()
      @addComponents [region.ui]
    update: ()->
      scope = this
      region = @getComponent "region"
      # CONNECTED?
      region.set if region.self.hasConnections() then @styles.selected_pad() else @styles.pad()
    interaction: ()->
      scope = this
      ui = @ui
      region = @getComponent "region"
      
      region.set
        onMouseDown: (e)->
          this.m_down(e)
          scope.update()
        onMouseDrag: (e)->
          this.m_drag(e)
          scope.update()
        onMouseUp: (e)->   
          this.m_up(e)
          scope.update()

class window.PowerPadMagnet extends PadMagnet
  name: "power_pad_magnet"
  styles:
    pad: ()->
      style =  
        fillColor: "#ea6262"
        strokeColor: "#e46868"
        strokeWidth: 3
    selected_pad: ()->
      style =  
        fillColor: "#ff4d4d"
        strokeColor: "#880000"
        strokeWidth: 3
  update: ()->
    pin = @getComponent "pinID"  
    region = @getComponent "region"  
    pin.position = region.bounds.topCenter
    super()
  generatePinID: ()->
    ids = _.map paper.project.getItems({name: this.name, class: "Group"}), (e)->
      return e.data.pin
    ids = _.compact ids
    if ids.length > 0
      return _.max(ids) + 1
    else
      return 1
  create: (options)->
    region = new Magnet
      name: "region"
      magnets: ["C"]
      accepts: ["magnet_start_terminal"]
      path: new paper.Path.Rectangle
        size: [30, 60]
        radius: 3
        position: options.point
        style: this.styles.pad()
        magnetClass: "power_pad_magnet"
    pin = @generatePinID()
    this.ui.data.pin = pin
    num = new PointText
      name: "pinID"
      content: "#"+pin
      fillColor: '#333333'
      fontFamily: 'Avenir'
      fontWeight: 'bold'
      fontSize: 25

    num.pivot = num.bounds.bottomCenter.add(new paper.Point(0, 5))
    num.position = region.ui.bounds.topCenter


    @addComponents [region.ui, num]
    
class window.GroundPadMagnet extends PadMagnet
  name: "ground_pad_magnet"
  styles:
    pad: ()->
      style =  
        fillColor: "#2b93b6"
        strokeColor: "#1a9bc7"
        strokeWidth: 3
    selected_pad: ()->
      style =  
        fillColor: "#00A8E1"
        strokeColor: "#006f95"
        strokeWidth: 3
  create: (options)->
    region = new Magnet
      name: "region"
      magnets: ["C"]
      accepts: ["magnet_end_terminal"]
      path: new paper.Path.Rectangle
        magnetClass: "ground_pad_magnet"
        size: [30, 60]
        radius: 3
        position: options.point
        style: this.styles.pad()
    @addComponents [region.ui]
