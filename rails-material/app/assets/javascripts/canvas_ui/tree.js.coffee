
class window.Tree
  @traversed: []
  @extractTree: ()->
    power_pads = paper.project.getItems
      class: "Group"
      name: "power_pad_magnet"
    power_pads = _.pluck power_pads, "self" 
    console.log "FOUND", power_pads.length, "POWER_PADS"
    power_pads = _.flatten(_.map power_pads, (pp)-> pp.getComponentMagnets())
    return power_pads
    # branches = _.map power_pads, (root)->
    #   return scope.extractBranch(root)
    # console.log "BRANCHES", branches

  @extractBranch: (root)->
    Tree.traversed = []
    return Tree.BFS(root, 0)

  @BFS: (root, level=0)->
    level_tab = _.map _.range(0, level, 1), (t)-> "-"
    level_tab = level_tab.join('')
    
    Tree.traversed.push root.ui.data.guid

    children = root.children()
    children = _.reject children, (c)-> _.includes Tree.traversed, c.ui.data.guid 
    console.log level_tab, root.to_s(), "["+children.length+"]"

    return _.map children, (c)->
      if _.includes Tree.traversed, c.ui.data.guid then return []
      node = 
        parent: root    
        data: c
        children: Tree.BFS(c, level + 1)
    