# materialmanifest.js
class window.MaterialManifest
  constructor: (ops)->
    @ws = new WebStorage()
    @importMaterialManifest(ops)
  importMaterialManifest: (ops)->
    scope = this
    if not ops.file
      console.error "You need to provide a file to open the MaterialManifest.", ops
      return
    name = MMH.filename(ops.file)

    onsvgload = (svg)->
      scope.svg = svg
      paper.view.update()

      #PROCESSING
      tree = MMH.process_tree svg, (svg)-> MMH.process_ui(svg)
      MMH.validate(svg)
      
      #REPOSITIONING
      svg.set
        position: paper.view.center
      svg.fitBounds(paper.view.bounds)
      svg.position = paper.view.center
      
      # UI SPECIFIC
      ops.onsvgload.apply(scope, svg)
      paper.view.update()

    if @ws.includes name
      console.log "Loading from WebStorage..."
      cache = @ws.get(name)
      svg = paper.project.importJSON JSON.parse cache
      onsvgload svg[0].children[0]
    else 
      console.log "Loading from LocalStorage..."
      paper.project.importSVG ops.file, onsvgload
  queryH: (svg, criteria)->
    return svg.getItems
      data: criteria
  query:(criteria)->
    return @svg.getItems
      data: criteria
      
MMH = 
  defaultFillColor: ()->
    c = new paper.Color(245, 244, 240)
    c.brightness = 0.7
    c.alpha = 0.5
    return c
  filename: (file)-> 
    x = file.split('.')
    x = x[0].split('/')
    return x[x.length-1]

  process_ui: (svg)->
    if svg and svg.className == "Path" and not svg.fillColor then svg.fillColor = MMH.defaultFillColor()
    if svg and svg.className == "Shape" then svg = svg.replaceWith(svg.toPath())
    if svg and svg.className == "Raster" 
      svg.remove()
      return
    svg.set
      data: JSON.parse(MMH.processName(svg))
      # active: false
    # _.extend svg, svg.name
  process_tree: (svg, process)->
    if svg
      process(svg)
      if svg.className == "Group" or svg.className == "Layer" 
        if svg.children and svg.children.length >= 0 
          _.map svg.children, (child)->
            MMH.process_tree(child, process)

  validate: (svg)->
    MMH.json_validate(svg)

  json_validate: (svg)->
    try
      JSON.parse(svg.name)
      if svg.dom then svg.dom.removeClass("error")
    catch error
      if error instanceof SyntaxError and svg
        if not svg.errors then svg.errors = []
        svg.errors.push error
        if svg.dom then svg.dom.addClass("error")
    if svg.children
      _.each svg.children, (child)-> MMH.validate(child)

  processName: (item)->
    name = item.name
    if _.isUndefined(name) or _.isNull(name) then return JSON.stringify({})
    name = name.trim()
    name = name.replaceAll("_x5F_", "_")
    name = name.replaceAll("_x23_", "#")
    name = name.replaceAll("_x27_", "")
    name = name.replaceAll("_x22_", '"')
    name = name.replaceAll("_x7B_", '{')
    name = name.replaceAll("_x7D_", '}')
    name = name.replaceAll("_x5B_", '[')
    name = name.replaceAll("_x5D_", ']')
    name = name.replaceAll("_x2C_", ',')
    name = name.replaceAll("_", ' ')
    lastBracketIdx = name.lastIndexOf("}")
    if lastBracketIdx > -1 then name = name.slice(0, lastBracketIdx + 1)