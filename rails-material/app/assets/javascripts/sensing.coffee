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
	window.installPaper()
	vizPipeline.acquireAndProcessData(vizPipeline.renderData)
	window.addEventListener "wheel", (e)->
		island = paper.project.getItem {name: "island"} 
		island.emit 'mousedrag', 
			point: island.position.clone().add(new paper.Point(0, e.deltaY * 0.5))
			stopPropagation: ()-> return

window.exportSVG = ()->
	exp = paper.project.exportSVG
    asString: true
    precision: 5
  saveAs(new Blob([exp], {type:"application/svg+xml"}), participant_id+"_heater" + ".svg");
vizPipeline = 
	renderData: (data)->
		viz_settings = 
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

		renderLine = (data, plot)->
			lines = _.map data.data, (channel, k)->
				pts = _.map channel, (mag, i)->
					t = data.time[i]
					return [data.time[i], mag]
				plot.plotLine(pts, viz_settings.colors[k])
			plot.fitAxes()
		makeLegend = ()->		
			# LEGEND CREATION
			g = new AlignmentGroup
				name: "legend"
				orientation: "horizontal"
				padding: 20
				window: 
					background: true
					moveable: true
					shading: true
				anchor: 
					position: paper.view.bounds.topCenter.add(new paper.Point(0, viz_settings.padding))

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
		makePlot = (title, video)->
			plot = new TimePlot
				width: viz_settings.plot.width
				height: viz_settings.plot.height
				title: 
					content: title
				video: video
				orientation: "horizontal"
			plot.init()	
			return plot
		makeTracks = ()->
			panel = new WindowGroup
				name: "panel"
				shading: true
				moveable: true
				anchor: 
					pivot: "topCenter"
					position: paper.project.getItem({name: "legend"}).bounds.bottomCenter.add(new paper.Point(0, 15))
				pane: 
					padding: 15
					orientation: "vertical"
					max_height: 100
					background:
						fillColor: new paper.Color(0.9)
						padding: [30, 15]
				title: 
					content: "TIMELINE"
					buttons: true
		
			panel.init()	
			
			
			# # TRACK CREATION			
			# track_window = new WindowGroup
			# 	name: "data_pane"
			# 	shading: true
			# 	moveable: false
			# 	title: 
			# 		content: "DATAPANE"
			# 		buttons: true
			# 	pane: 
			# 		padding: 5
			# 		orientation: "vertical"
			# 		background:
			# 			fillColor: new paper.Color(0.7)
			# 			padding: [30, 15]
			# track_window.init()
			# track_window.pushItem new paper.Path.Circle
			# 	radius: 100
			# 	fillColor: "red"	
			panel.pushItem new paper.Path.Circle
				radius: 100
				fillColor: "orange"	
			# panel.pushItem track_window



			# _.each data.activity, (activity, user)->
			# 	track = new AlignmentGroup
			# 		name: "track"
			# 		padding: 10
			# 		orientation: "horizontal"

			# 	label = new LabelGroup
			# 		orientation: "horizontal"
			# 		text: user
			# 		onMouseDown: (e)->
			# 			$('video').attr('src', activity.video.mp4)
			# 	# label2 = new LabelGroup
			# 	# 	orientation: "horizontal"
			# 	# 	text: user + "2"
			# 	# 	onMouseDown: (e)->
			# 	# 		$('video').attr('src', activity.video.mp4)

			# 	plot_container = new AlignmentGroup
			# 		name: "plot_container"
			# 		padding: 5
			# 		orientation: "vertical"
			# 		backgroundColor: "#F0F0F0"

			# 	if viz_settings.render_codes
			# 		code_plot = makePlot('codes', activity.video.mp4)
			# 		_.each activity.video.codes, (event)-> code_plot.plotEvent(event, activity.video.mp4)
			# 		plot_container.pushItem(code_plot)
				
			# 	# if viz_settings.render_iron_imu
			# 	# 	_.each activity.iron.imu, (sensor_data, k)->
			# 	# 		p = makePlot(k, activity.video.mp4)
			# 	# 		renderLine(sensor_data, p)
			# 	# 		plot_container.pushItem p

			# 	track.pushItem label
			# 	# track.pushItem label2
			# 	track.pushItem plot_container
			# 	track_window.pushItem track
			
		
		makeLegend()
		makeTracks()
	acquireAndProcessData: (callbackFn)->
		rtn = $.getJSON data_source, (manifest)-> 
			window.manifest = manifest
			
			# RESOLVE JSON FILES
			activity = _.mapObject manifest, (data, user)->
				_.mapObject data, (sensors, object)->
					_.mapObject sensors, (file, sensor)->
						filetype = file.url.split('.').slice(-1)[0] 
						switch filetype
							when "json"
								return $.ajax({dataType: "json", url: file.url, async: false}).responseJSON
							else
								return file.url
			# PROCESS DATA
			_.each activity, (data, user)->
				activity[user].video.codes = _.map data.video.codes, (code)->
					_.extend code, 
						actor: code.codes[1]
						codes: code.codes.slice(2)

			# EXTRACT AUTHORS
			actors = _.values activity
			actors = _.pluck actors, "video"
			actors = _.flatten _.pluck actors, "codes"
			actors = _.unique _.pluck actors, "actor"
			actors = _.object _.map actors, (a, i)-> 
				[a, color_scheme[i]]
			# ATTACH COLOR
			_.each activity, (data, user)->
				activity[user].video.codes = _.map data.video.codes, (code)->
					_.extend code, 
						color: actors[code.actor]

			callbackFn
				activity: activity
				actors: actors

