# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
#= require papaparse.min
#= require moment
#= require paper
#= require jquery-ui/core
#= require jquery-ui/widget
#= require jquery-ui/position
#= require jquery-ui/widgets/mouse
#= require jquery-ui/widgets/draggable
#= require jquery-ui/widgets/droppable
#= require jquery-ui/widgets/resizable
#= require jquery-ui/widgets/selectable
#= require jquery-ui/widgets/sortable
#= require viz
#= require viz/timeline


window.manifest = null
window.color_scheme = ["red","orange","blue","green","yellow","violet","purple","teal", "pink","brown","grey","black"]
window.data_source = "/data/compiled.json"

$ ->
	window.env = new VizEnvironment
		reposition_video: ()->
			pt = paper.project.getItem({name: "legend"}).bounds.bottomLeft
			$('#video-container').css
				top: pt.y
				left: pt.x
			# console.log pt
			# console.log paper.view.viewToProject pt
			# console.log paper.view.projectToView pt

		ready: ()->
			scope = this
			$('.panel').draggable()
			@reposition_video()
			$(window).resize ()->
				scope.reposition_video()
			
			paper.tool = new paper.Tool
				video: $('video')[0]
				onKeyDown: (e)->
					switch e.key
						when "space"
							if this.video.paused then this.video.play() else this.video.pause()


			# 	onMouseDown: (e)->
			# 		console.log e.point.x, e.point.y
	
window.exportSVG = ()->
	exp = paper.project.exportSVG
    asString: true
    precision: 5
  saveAs(new Blob([exp], {type:"application/svg+xml"}), participant_id+"_heater" + ".svg");


window.time = (ms)->
  t = new Date(ms).toISOString().slice(11, -5);
  hour = t.slice(0, 3)
  if hour == "00:"
  	t =  t.slice(3)
  if t.slice(0, 2) == "00"
  	return t
  if t.slice(0, 1) == "0" 
  	t = t.slice(1)
  return t

  	
class VizEnvironment
	constructor: (op)->
		_.extend this, op
		this.viz_settings = 
			padding: 30
			plot:
				height: 30
				width: 500
			colors: 
				0: "red"
				1: "green"
				2: "blue"
			render_iron_imu: false
			render_codes: true
		@acquireManifest(@renderData)
		
	renderData: (data)->
		window.installPaper()
		@makeLegend(data)
		@makeTracks(data)
		this.timeline = new Timeline()
		@ready()

	


	makeTracks: (data)->
		# LEGEND CREATION
		g = new AlignmentGroup
			name: "legend"
			title: 
				content: "SESSIONS"
			moveable: true
			padding: 5
			orientation: "vertical"
			background: 
				fillColor: "white"
				padding: 5
				radius: 5
				shadowBlur: 5
				shadowColor: new paper.Color(0.9)
			anchor: 
				pivot: "topLeft"
				position: paper.view.bounds.topLeft.add(new paper.Point(30, 430))
		g.init()

		_.each data.activity, (data, user)->
			
			label = new LabelGroup
				orientation: "horizontal"
				padding: 5
				text: user
				onMouseDown: (e)->
					$('video').attr('src', data.env.video.mp4.url)
				
			g.pushItem label
	makeLegend: (data)->		
		# LEGEND CREATION
		g = new AlignmentGroup
			name: "legend"
			title: 
				content: "ACTORS"
			moveable: true
			padding: 5
			orientation: "horizontal"
			background: 
				fillColor: "white"
				padding: 5
				radius: 5
				shadowBlur: 5
				shadowColor: new paper.Color(0.9)
			anchor: 
				position: paper.view.bounds.topCenter.add(new paper.Point(0, this.viz_settings.padding))
		g.init()

		_.each data.actors, (color, actor)->
			color_code = new paper.Color color
			color_code.saturation = 0.8
		
			label = new LabelGroup
				orientation: "horizontal"
				padding: 5
				key: new paper.Path.Circle
					name: actor
					radius: 10
					fillColor: color_code
					data: 
						actor: true
						color: color
				text: actor
				data:
					activate: true
				update: ()->
					codes = paper.project.getItems
						name: "event"
						data: 
							actor: actor
					if this.data.activate 
						this.opacity = 1 
						_.each codes, (c)-> c.visible = true
					else 
						this.opacity = 0.2
						_.each codes, (c)-> c.visible = false
				onMouseDown: ()->
					this.data.activate = not this.data.activate
					this.update()
			g.pushItem label


	
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

