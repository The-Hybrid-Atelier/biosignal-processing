class window.Magnet extends UIElement
  @CLOSE: 60
  @SNAP: 30
  @hide: ()->
    magnets = paper.project.getItems
      data: 
        magnet: true
    _.each magnets, (m)->
      m.visible = false
  default_magnets: ["N", "S", "E", "W"]
  m_styles: 
    snap: ()->
      style = 
        strokeColor: "yellow"
        strokeWidth: 3
        visible: true
    close: ()-> 
      style = 
        strokeColor: "white"
        strokeWidth: 3
        visible: true
    far: ()->
      style = 
        strokeWidth: 3
        strokeColor: "#DDD"
        visible: true
    hidden: ()->
      visible: false

  _magnet: (pt, location)->
    return paper.Path.Circle
      radius: 5
      name: @magnetClass
      fillColor: "#666666"
      position: pt
      data: 
        location: location
        magnet: true
        guid: guid()
  
  constructor: (options)->
    super options
    
  getUIElement: ()->
    return this.ui.parent.self

  create: (options)->
    @clearConnections()
    
    # OBJECT CREATION 
    if options.path 
      m = options.path
      m.name = "magnet_component"
      m.set options.style or {}
      m.data.connectable = true
      @magnetClass = options.path.magnetClass

    
    @ui.data.accepts = options.accepts or []
    this.addComponents [m]
    @setMagnets if options.magnets then options.magnets else @default_magnets

    


  setMagnets: (locations)->
    scope = this
    b = @ui.bounds
    _.each locations, (l)->
      pt = switch l
        when "N"
          b.topCenter
        when "NE"
          b.topRight
        when "E"
          b.rightCenter
        when "SE"
          b.bottomRight
        when "S"
          b.bottomCenter
        when "SW"
          b.bottomLeft
        when "W"
          b.leftCenter
        when "NW"
          b.topLeft
        when "C"
          b.center
      
      m = scope._magnet pt, l
      scope.addMagnet(m)

  magnetResolve: (pt)->
    scope = this
    magnet_guids = @getMagnetsIDs()

    magnets = @getAcceptableMagnets()
   
    _.each magnets, (m)->
      m.set scope.m_styles.far()

    magnets = _.reject magnets, (m)-> _.includes magnet_guids, m.data.guid
   
    close_magnets = _.filter magnets, (m)-> 
      d = m.position.getDistance pt 
      return (d < Magnet.CLOSE) and (d > Magnet.SNAP)

    snap_magnets = _.filter magnets, (m)-> 
      d = m.position.getDistance pt
      return d <= Magnet.SNAP
    
    _.each close_magnets, (m)->
      m.set scope.m_styles.close()
    _.each snap_magnets, (m)->
      m.set scope.m_styles.snap()
    

    candidates = _.union(snap_magnets, close_magnets)
    if _.isEmpty candidates
      return null
    else
      return _.min candidates, (m)-> m.position.getDistance pt
  getAcceptableMagnets: ()->
    accepts = @ui.data.accepts
    scope = this
    all_magnets = paper.project.getItems
        data: 
          magnet: true

    
    if _.isEmpty accepts
      return paper.project.getItems
        data: 
          magnet: true
    else
      mags = paper.project.getItems
        name: (i)->
          return _.includes accepts, i
        data: 
          magnet: true

      mags = _.map mags, (m)->
        return m.self.getMagnets()

      mags = _.flatten(_.compact(mags))
      return mags

  # TODO - REVERSE POLARITY ON SNAP
  getUnacceptableMagnets: ()->
    accepts = @ui.data.accepts
    scope = this
    if _.isEmpty accepts
      return []
    else
      mags = paper.project.getItems
        name: (i)->
          return not _.includes accepts, i
      mags = _.map mags, (m)->
        return m.self.getMagnets()
      mags = _.flatten(_.compact(mags))
      return mags
      

  interaction: ()->
    scope = this
    @ui.set
      is_magnetized: ()-> return $('#magnetize').hasClass('red') 
      m_down: (e)->
        this.closest = null
        magnets = scope.getAcceptableMagnets()
        
        _.each magnets, (m)->
          m.set scope.m_styles.far()
        print = _.map scope.getConnections(), (c)-> return c.data.guid.slice(0, 4)
        
        # console.log "MY C", scope.ui.name, scope.ui.data.guid.slice(0, 4),":", print.join(',')
        
        if not this.is_magnetized()
          _.each scope.getConnections(), (c)->
            c.self.removeConnection(scope.ui)
            scope.clearConnections(c)

      m_drag: (e)->
        pos =  this.position.add e.delta
        this.position = pos
        this.closest = scope.magnetResolve(pos)
        _.each scope.getConnections(), (c)->
          c.position = pos
          if c.parent and c.parent.self
            c.parent.self.update()
      m_up: (e)->
        closest = this.closest
        if closest
          # A CONNECTION HAS BEEN MADE
          magnets = scope.getMagnets()
          c_mag = _.min magnets, (m)-> m.position.getDistance(closest.position)
          delta = closest.position.subtract(c_mag.position)
          this.position = this.position.add delta

          if this.is_magnetized()
            # console.log "CONNECTION CALL", scope.ui.name, scope.ui.data.guid.slice(0, 4), "to", closest.parent.name,  closest.parent.data.guid.slice(0, 4)
            scope.addConnection(closest.parent)
            # HACK
            # closest.parent.self.addConnection(this)
            if closest.parent.self.update
              closest.parent.self.update()
            else
              closest.parent.self.getUIElement().update()

        magnets = scope.getAcceptableMagnets()
        _.each magnets, (m)->
          m.set scope.m_styles.hidden()
        tracker.save(false)
  
  # CONNECTIONS
  getParent: ()-> return this.ui.parent.self
  getSiblings: ()-> 
    scope = this
    sibs = @getParent().getComponentMagnets()
    return _.reject sibs, (s)-> s.ui.data.guid == scope.ui.data.guid
   
  hasConnections: ()-> return not @isEmpty "connections"
  getConnections: ()-> return @getCollection "connections"
  getConnectedMagnets: ()-> _.pluck @getConnections(), "self"
  clearConnections: (connection)-> 
    scope = this
    connections = @getConnections
    _.each connections, (connection)->
      connection.self.removeConnection(this.ui)
    @clearCollection "connections"
    tracker.save(false)
  childrenDebug: ()->
    children = @children()
    console.log this.ui.name, "("+this.ui.data.guid.slice(0, 4)+")"
    _.each children, (child)->
      console.log "---", child.ui.name, "("+child.ui.data.guid.slice(0, 4)+")"
  children: ()->
    my_connections = this.getConnectedMagnets()
    my_siblings = this.getSiblings()
    return _.compact _.flatten [my_siblings, my_connections]
  addConnection: (connection)-> 
    scope = this
    connectionsA = @getConnections()
    connectionsB = connection.self.getConnections()
    connections = [connectionsA, connectionsB, [this.ui, connection]]
    connections = _.uniq _.flatten(connections), (c)-> c.data.guid

    print = _.map connections, (c)-> c.data.guid.slice(0, 4)
    # console.log "ADDING SHARED CONNECTIONS", print.join(',')

    _.each connections, (parent)->
      current_connections = _.map parent.self.getConnections(), (l)-> l.data.guid.slice(0, 4)
      # console.log parent.data.guid.slice(0, 4),":", current_connections.join(current_connections)
      _.each connections, (c)->
        if parent.data.guid != c.data.guid

          success = parent.self.addToCollection("connections", c)
          console.log "\t", parent.data.guid.slice(0, 4), c.data.guid.slice(0, 4), success
    tracker.save(false)
  removeConnection: (connection)-> 
    if connection.data.guid == this.ui.data.guid then return
    scope = this
    @removeFromCollection "connections", connection.data.guid

    # console.log "REMOVING CONNECTION", connection.data.guid.slice(0, 4)
    # console.log "\t", scope.ui.data.guid.slice(0, 4), connection.data.guid.slice(0, 4)
          
    connections = @getConnections()
    _.each connections, (c)->
      c.self.removeFromCollection "connections", connection.data.guid
      # console.log "\t", c.data.guid.slice(0, 4), connection.data.guid.slice(0, 4)
    tracker.save(false)
  
    # children = tree.root.getConnections()
    # children = _.reject children, (child)-> _.includes child.data.guid, traversed
    
    # _.each children, (child)->
    #   scope.extractTree child, root, traversed, tree

    #     