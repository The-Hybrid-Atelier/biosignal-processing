class window.Collectable
  # Stores a {guid: ID, obj: OBJ}, guids go into data field, 
  # component gets stored as hash at root level
  constructor: ()->
  createCollections: (collections)-> @_collectiveCall collections, "createCollection"
  resolveCollections: (collections)-> @_collectiveCall collections, "resolveCollection"
  isEmpty: (collection)-> return @getCollection(collection).length == 0
  clearCollection: (collection)-> @createCollection(collection)
  getCollectionGUIDS: (collection)-> _.keys @ui[collection]
  getCollection: (collection)-> _.values @ui[collection]
  createCollection: (collection)->
    @ui[collection] = {}
    @ui.data[collection] = []
  resolveCollection: (collection)->
    scope = this
    collectionData = _.map @ui.data[collection], (guid)->
      try 
        obj = paper.project.getItem
          data: 
            guid: guid
        if not obj.self
          obj.set
            handler: eval(scope.constructor.name)
            self: scope
        return [guid, obj]
      catch err
        console.log "COULD NOT RESOLVE", err, guid
        return null
    # console.log "COLLECTION DATA", collectionData, collection
    collectionData = _.compact(collectionData)
    @ui[collection] = _.object collectionData
  searchCollection: (collection, name)->
    collection = @getCollection(collection)
    return _.find collection, (c)-> c.name == name

  addToCollection: (collection, component)->
    # console.log "ADDING TO ", collection, component.guid, component
    guid = component.data.guid
    obj = component
    if not @ui[collection][guid]
      @ui[collection][guid] = obj
    else
      return false
    if not _.includes @ui.data[collection], guid
      @ui.data[collection].push guid
      return true
    else
      return false
  # Removes component from record
  removeFromCollection: (collection, guid)-> 
    @ui.data[collection] = _.without @ui.data[collection], guid
    delete @ui[collection][guid]
  _collectiveCall: (collections, method)->
    scope = this
    _.each collections, (c)->
      scope[method](c)

  # COMPONENTS
  addComponents: (components)->
    scope = this
    _.each components, (c)-> scope.addComponent(c)
  addComponent: (component)->
    if not component.data.guid then component.data.guid = guid()
    @addToCollection("components", component)
    @ui.addChild(component)
    if not component.self
      component.set
        handler: eval(this.constructor.name)
        self: this
    # @ui.set
    #   handler: eval(this.constructor.name)
    #   self: this
  getComponent: (name)-> 
    rtn = @searchCollection("components", name)
    if _.isUndefined rtn
      return null
    else 
      return rtn
  deleteComponent: (name)->
    component = @getComponent(name)
    if component
      @removeComponent(component)
      component.remove()
  removeComponent: (component)-> 
    if component
      @removeFromCollection("components", component.data.guid)
  
  # MAGNETS
  addMagnet: (component)->
    @addToCollection("magnets", component)
    @ui.addChild(component)
    component.set
      handler: eval(this.constructor.name)
      self: this
  getMagnets: ()-> return @getCollection "magnets"
  getMagnetsIDs: ()-> return @getCollectionGUIDS "magnets"
  getComponentMagnets: ()->
    components = @getCollection "components"
    comp_mags = _.filter components, (c)-> 
      c.self.constructor.name == "Magnet"
    return _.pluck comp_mags, "self"
  # getChildren: ()->
  #   components = @getCollection "components"
  #   connections = _.map components, (c)-> 
  #     console.log "CONNECTIONS", c.name, c.data.guid.slice(0, 4), (_.map c.self.getConnections(), ((d)-> return d.self.ui.name+"("+d.self.ui.data.guid.slice(0, 4)+")")).join(',')
  #     return _.map c.self.getConnections(), (d)-> return d.self

  #   connections = _.compact(_.flatten(connections))
  #   print = _.map connections, (c)-> return c.ui.name+"("+c.ui.data.guid.slice(0, 4)+")"
  #   console.log "CHILDREN", print.join(',')
  #   return connections