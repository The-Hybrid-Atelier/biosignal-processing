class window.HeatBranch extends Material
  @override: ["children", "annotations"]
  name: "heat_branch"
  destroyAll: ()->
    if this.children
      _.each this.children, (child)->
        child.parent = null
    this.ui.remove()
    b1 = new HeatBranchUI
      properties: 
        V: 12
        I: 3
        

  removeChild: (child)->
    console.log 'REMOVING CHILD', child.guid
    @prop.children = _.reject @prop.children, (c)-> c.guid == child.guid
    this.update()
  register: ()-> Environment.last_heat_branch = this
  toString: ()->
    console.log MaterialLib.toString(_.omit @prop, "children").values
    MaterialLib.toString(_.pick @prop, "children")
  @defaults: ()->
    guid: guid()
    min_tr: 0
    V: 12
    P: 0
    max_P: 0
    I: 3
    max_I: 3
    R: 0
    children: []
    annotations: Environment.annotations
    mode: null
  
  material_update: ()->
    @prop.P = _.sum(_.pluck @prop.children, "P")
    if @prop.V
      @prop.max_P = @prop.V**2/(@prop.V/@prop.max_I)
      @prop.min_tr = Environment.thermoreactive_composite.activationEnergy / @prop.max_P
      if @prop.P == 0
        @prop.R = 0
        @prop.I = 0
      else
        @prop.R = @prop.V**2 / @prop.P
        @prop.I = @prop.V/@prop.R

    return
  Object.defineProperties @prototype, @make_object()
  Object.defineProperties @prototype,
    children:
      get: ()->
        @prop.children
      set: (obj)->
        if _.isNull obj then return
        if _.isArray obj
          # @prop.children = obj
          return
        current = _.pluck @prop.children, "guid"
        if not _.includes(current, obj.guid)
          if obj.parent and obj.parent.guid != @prop.guid
            obj.parent.children = _.filter obj.parent.children, (c)-> c.guid == obj.guid
          
          @prop.children.push obj
          # @update()
          # _.each @prop.children, (child)->
          #   child.update()
          Environment.update()
        
    annotations: 
      get: ()->
        @prop.annotations
      set: (obj)->
        if @prop.annotations == obj then return
        @prop.annotations = obj
        _.each @prop.children, (child)-> child.annotations = obj
        @update()
   



  class window.HeatTwig extends Material
    @override: ["children", "parent", "annotations"]
    destroyAll: ()->
      if this.parent
        this.parent.removeChild(this)
      if this.children
        _.each this.children, (child)->
          child.parent = null
      this.ui.remove()
    removeChild: (child)->
      @prop.children = _.reject @prop.children, (c)-> c.guid == child.guid
      this.update()
    name: "heat_space"
    register: ()-> Environment.last_twig_space = this
    @defaults: ()->
      guid: guid()
      parent: null
      min_tr: 0
      V: 12
      P: 0
      max_P: 0
      max_I: 3
      I: 3
      R: 0
      alpha: 0
      children: []
      annotations: Environment.annotations
      mode: null
      
    

    material_update: ()->
      if @prop.parent
        @prop.max_P = @prop.parent.P
        @prop.V = @prop.parent.V

        @prop.P = _.sum(_.pluck @prop.children, "P")

        if @prop.P == 0
          @prop.R = 0
          @prop.I = 0
        else
          @prop.R = @prop.V**2 / @prop.P
          @prop.I = @prop.V/@prop.R
          @prop.alpha = @prop.I / @prop.parent.I
      else
        @prop.P = 0
        @prop.R = 0
        @prop.I = 0
        @prop.V = 0

    Object.defineProperties @prototype, @make_object()
    Object.defineProperties @prototype,
      parent:
        get: ()->
          @prop.parent

        set: (obj)->
          if not _.isNull obj
            if obj.guid == @prop.guid then return
            @prop.parent = obj
            @prop.V = @prop.parent.V
            @prop.parent.children = this
          else
            @prop.parent = obj
          Environment.update()
          @save()
          
      children:
        get: ()->
          @prop.children
        set: (obj)->
          if _.isNull obj then return
          if _.isArray obj then return
          if obj.guid == @guid then return

          current = _.pluck @prop.children, "guid"
          if not _.includes(current, obj.guid)
            if obj.parent and obj.parent.guid != @prop.guid
              obj.parent.children = _.filter obj.parent.children, (c)-> c.guid == obj.guid
            
            @prop.children.push obj
            Environment.update()
      annotations: 
        get: ()->
          @prop.annotations
        set: (obj)->
          if @prop.annotations == obj then return
          @prop.annotations = obj
          _.each @prop.children, (child)-> child.annotations = obj
          @update()
    








class window.HeatSpace extends Material
  destroyAll: ()->
    if this.parent
      this.parent.removeChild(this)
    this.ui.remove()
  @override: ["parent"]
  name: "heat_space"
  register: ()-> Environment.last_heat_space = this
  @defaults: ()->
    guid: guid()
    parent: null
    tr: 30
    P: 0
    I: 0
    alpha: 0 
    R: 0
    w: 0
    A: 0
    rendered: false
    annotations: Environment.annotations
    mode: null
    
  material_update: ()->
    trc = Environment.thermoreactive_composite
    pjh = Environment.joule_heater_material
    @prop.P = trc.activationEnergy / @prop.tr

    # update branch
    if @prop.parent
      @prop.parent.update()
      if @prop.parent.V == 0
        @prop.R = 0
        @prop.w = 0
        @prop.I = 0
        @prop.alpha = 0
      else
        @prop.R = (@prop.parent.V**2)/@prop.P
        @prop.w = (pjh.kappa * @prop.A * 1/@prop.R)**0.5
        @prop.I = (@prop.P/@prop.R)**0.5  
        @prop.alpha = @prop.I / @prop.parent.I
    else
      @prop.V = 0
      @prop.R = 0
      @prop.w = 0
      @prop.I = 0
      @prop.alpha = 0

  Object.defineProperties @prototype, @make_object()
  Object.defineProperties @prototype,
    parent:
      get: ()->
        @prop.parent
      set: (obj)->
        if not _.isNull obj
          @prop.parent = obj
          @prop.parent.children = this
        else
          @prop.parent = obj
        Environment.update()
        @save()
