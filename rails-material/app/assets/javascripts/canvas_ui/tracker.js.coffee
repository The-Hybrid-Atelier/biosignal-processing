# HISTORY TRACKING
class window.Tracker
  history_max_idx: 0
  history_curr_idx: 0
  constructor: ()->
    @load()
    @bindEvents()
    
  add_power: ()->
    b1 = new HeatTwigUI
      properties: 
        V: 0
        I: 0
      
  bindEvents: ()->
    # LOAD ARTWORK ONTO CANVAS
    $('#artwork-toggle').click ()->
      switch $(this).attr('state')
        when "none"
          thermopainting.add_artwork()
          thermopainting.update_opacity(0.5)
          $(this).attr('state', 'half').removeClass("blue").addClass("light-blue")
        when "half"
          thermopainting.update_opacity(1.0)
          $(this).attr('state', 'full').removeClass("light-blue").addClass("blue")
        when "full"
          thermopainting.update_opacity(0)
          $(this).attr('state', 'none').removeClass("blue").removeClass("light-blue")
    $('#saved-artwork').click ()->
      thermopainting.add_artwork()


    # LIBRARY BINDINGS 
    _.each $("#components").children(), (component)->
      $(component).click ()->
        component = eval($(this).attr('name'))
        
        layer = eval($(this).attr('layer'))
        layer.activate()
        p = new component
          layer: layer
          point: paper.view.center

    # ENABLE/BIND TOOL BUTTONS
    $('.tools button, .tool').click (e)->
      tool = $(this).attr('name')
      tool = eval(tool)
      if $(this).hasClass("red")
        tool.deactivate()
      else
        if paper.tool and paper.tool.deactivate then paper.tool.deactivate()
        tool.activate()
        if tool.activate2
          tool.activate2()
        $(this).addClass("red")
    $('.heat-options button').click (e)->
      variable = $(this).attr('name')
      value = $(this).attr('value')
      Environment[variable] = value
      $(this).addClass('blue').siblings().removeClass('blue')
      heat_tool.update()
    # SIDEBAR FUNCTIONALITY
    $('#sidebar-trigger').click ()->
      $('#options').sidebar
        transition: 'overlay'
        mobileTransition: 'overlay'

      $('#options').sidebar 'toggle'
      _.delay (()->$('.pusher').removeClass('dimmed')), 100
      

    # MAGNET FUNCTIONALITY 
    # $('#magnetize').click ()->
    $('#magnetize').on 'mousedown mouseup', ()->
    # $('#magnetize').on 'mousedown mouseup touchstart touchend', ()->
      if $(this).hasClass('red')
        $(this).removeClass('red').addClass('green')
          .children('i')
          .addClass('unlinkify')
          .removeClass('linkify')
      else
        $(this).addClass("red").removeClass('green')
          .children('i')
          .addClass('linkify')
          .removeClass('unlinkify')

    # CANVAS BUTTON FUNCTIONALITY
    _.each $('.tracker'), (button)->
      $(button).click ()->
        action = $(this).attr('id')
        tracker[action](button)
  export: ()->
    exp = paper.project.exportSVG
      asString: true
      precision: 5
    saveAs(new Blob([exp], {type:"application/svg+xml"}), participant_id+"_heater" + ".svg");
  zoomin: ()->
    paper.view.zoom = paper.view.zoom + 0.1
  zoomout: ()->
    paper.view.zoom = paper.view.zoom - 0.1
  help: ()->
    $('#tutorial').modal('show')
  recenter: ()->
    _.each paper.project.layers, (l)->
      if l.name == "ui" then return
      l.position = paper.view.center
    paper.view.zoom = 1
  annotate: ()->
    thermopainting.toggle_annotations()
  mode: (dom)->
    mode = $(dom).attr 'name'
    if mode == "print" and $(dom).hasClass('green')
      @print()
      return
    $(dom).addClass("blue").siblings().removeClass('blue')
    Environment.mode = mode
    Environment[mode]()
    ws.set("mode", mode)

    if mode == "print"
      $(dom).addClass('green').find('i').removeClass("print").addClass("check").removeClass("blue")
    else
      $("button[name='print']").removeClass('green').find('i').addClass("print").removeClass("check")

  materialize: ()->
    thermopainting.toggle_materialization()
  print_preview: ()->
    playSound("Its-In-The-Computer")
    thermopainting.print_preview()
  
  print: ()->
    # scope = this
    # $('#print').addClass("loading")
    # $('.canvas-area').dimmer("show")
    # playSound("Its-In-The-Computer")
    # this.save(false)
    # scope = this
    
    _.delay (()->
      thermopainting.print()
      # scope.undo()
    # ), 2000
    ), 0
  clear: ()->
    scope = this
    $('#clear').addClass("loading red")
      
    alertify.confirm "CLEAR CANVAS?", "Are you sure you want to clear your canvas?", (()->
      thermopainting.clear()
      $('#clear').removeClass("loading red")
    ), (()->
      $('#clear').removeClass("loading red")
    )
  load: ()->
    history = ws.includes("zip_history_max") and ws.includes("zip_history_curr")
    if not history
      console.log "NO HISTORY FOUND"
      this.save(false)   
      return

    if ws.includes "zip_history_max"
      this.history_max_idx = parseInt(ws.get "zip_history_max", this.history_curr_idx)
    if ws.includes "zip_history_curr"
      this.history_curr_idx = parseInt(ws.get "zip_history_curr", this.history_curr_idx)
      this.loadHistory this.history_curr_idx
  HISTORY_TRACK: 5  
  save: (alert=true)->
    hide = paper.project.getItems 
      saveable: false
    _.each hide, (h)->
      h.remove()
    json = paper.project.exportJSON()
    _.each hide, (h)->
      ui_layer.addChild(h)
    # ADD TO THE TAIL
    this.history_curr_idx = this.history_curr_idx + 1
    ws.set "zip_history" + this.history_curr_idx, json

    # TRIM THE TAIL
    if this.history_curr_idx != this.history_max_idx
      this.history_max_idx = this.history_curr_idx

    # SAVE STATE FOR REFRESH
    ws.set "zip_history_curr", this.history_curr_idx
    ws.set "zip_history_max", this.history_max_idx
    @clean(alert)
    if alert
      alertify.success('<b>Saved!</b></br>' + "We won't forget.")
  clean: ()->
    clean = _.range(0, this.history_curr_idx - @HISTORY_TRACK, 1)
    _.each clean, (i)->
      if ws.includes "zip_history"+ i
        # console.log "CLEANING", i
        ws.remove "zip_history"+ i
  loadHistory: (idx)->
    scope = this
    if idx < 0
      alertify.error('<b>We are at the beginning. </b></br>' + "Can't undo anymore.")
      return false
    if idx > this.history_max_idx
      alertify.error('<b>We are at the most recent.</b></br>' + "Can't redo anymore.")
      return false
    json = ws.get("zip_history" + idx)
    json = JSON.parse(json)
    paper.project.clear()
    paper.project.importJSON(json)
    paper.view.update()
    thermopainting.load()
    console.log "BRANCHES", paper.project.getItem({name: "HeatBranchUI"})
    # this.save()
  undo: ()->
    loaded = this.loadHistory(this.history_curr_idx - 1)
    if loaded
      this.history_curr_idx = this.history_curr_idx - 1
      ws.set "zip_history_curr", this.history_curr_idx
  redo: ()->
    loaded = this.loadHistory(this.history_curr_idx + 1)
    if loaded
      this.history_curr_idx = this.history_curr_idx + 1
      ws.set "zip_history_curr", this.history_curr_idx
      



