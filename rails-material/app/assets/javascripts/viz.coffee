#= require viz/data_grabber
#= require viz/alignment_group
#= require viz/label_group
#= require viz/timeline


window.manifest = null
window.color_scheme = ["red","orange","blue","green","yellow","violet","purple","teal", "pink","brown","grey","black"]
window.data_source = "/data/compiled.json"

window.exportSVG = ()->
	exp = paper.project.exportSVG
    asString: true
    precision: 5
  saveAs(new Blob([exp], {type:"application/svg+xml"}), participant_id+"_heater" + ".svg");

window.wipe = (caller, match)->
  _.each caller.getItems(match), (el)-> el.remove()