# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
#= require papaparse.min
#= require moment
#= require paper
#= require viz


window.manifest = null
window.color_scheme = ["red","orange","blue","green","yellow","violet","purple","teal", "pink","brown","grey","black"]
window.data_source = "/data/compiled.json"

$ ->
	window.env = new VizEnvironment()
	window.installPaper()
	papers = _.map $('.panel.paper'), (papel)->
		p = $(papel)
		makePaper(p)

	
window.exportSVG = ()->
	exp = paper.project.exportSVG
    asString: true
    precision: 5
  saveAs(new Blob([exp], {type:"application/svg+xml"}), participant_id+"_heater" + ".svg");
class VizEnvironment
	constructor: ()-> 
		@acquireManifest(@renderData)
	populateDataTable: (manifest)->
		table = $('#sessions')

	renderData: (data)->
		@populateDataTable(data)


	
	mapEach: (root, mapFn)->
		scope = this
		root = mapFn(root)
		_.map root, (data, root)-> 
			if _.isObject(data) then scope.mapEach(data, mapFn)

	acquireManifest: (callbackFn)->
		scope = this
		rtn = $.getJSON data_source, (manifest)-> 
			window.manifest = manifest

			# RESOLVE JSON FILES
			scope.mapEach manifest, (obj)->
				if not obj.url then return obj
				filetype = obj.url.split('.').slice(-1)[0] 
				switch filetype
					when "json"
						return _.extend obj, 
							data: $.ajax({dataType: "json", url: obj.url, async: false}).responseJSON
					else
						return obj
			
			# ZIP adjustment
			_.each manifest, (data, user)->
				if data.iron.imu
					manifest[user].iron.imu = data.iron.imu.various.data


			# EXTRACT AUTHORS
			actors = _.values manifest
			actors = _.pluck actors, "env"
			actors = _.flatten _.pluck actors, "video"
			actors = _.flatten _.pluck actors, "codes"
			actors = _.flatten _.pluck actors, "data"
			actors = _.unique _.pluck actors, "actor"
			actors = _.object _.map actors, (a, i)-> 
				[a, color_scheme[i]]

			# console.log "actors", actors
			
			# ATTACH COLOR
			_.each manifest, (data, user)->
				manifest[user].env.video.codes.data = _.map data.env.video.codes.data, (code)->
					_.extend code, 
						color: actors[code.actor]
	
			callbackFn.apply scope, [
				activity: manifest
				actors: actors
			]

