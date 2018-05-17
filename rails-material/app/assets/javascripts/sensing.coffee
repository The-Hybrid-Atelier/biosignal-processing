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
			timeline = plot.children.timeline
			timeplot = plot.children.timeplot
			plot_height = timeplot.bounds.height
			plot_width = timeplot.bounds.width
			lines = _.map data.data.slice(0), (channel, k)->
				pts = _.map channel, (mag, i)->
					t = data.time[i]
					if t > timeline.end then return null
					if t < timeline.start then return null
					return [data.time[i], mag]
				pts = _.compact pts
				line = new paper.Path.Line
					parent: plot
					strokeColor: viz_settings.colors[k]
					strokeWidth: 1
					segments: pts
				return line

			lw_max = (_.max lines, (line)-> return line.bounds.width).bounds.width			
			lh_max = (_.max lines, (line)-> return line.bounds.height).bounds.height

			_.each lines, (line)-> line.scaling.x = (plot_width)/lw_max
			_.each lines, (line)-> line.scaling.y = (plot_height - 10)/lh_max
			
			_.each lines, (line)-> 
				line.pivot = line.bounds.leftCenter
				line.position = timeplot.bounds.leftCenter
		makeLegend = ()->		
			# LEGEND CREATION
			g = new AlignmentGroup
				name: "legend"
				title: true
				window: true
				moveable: true
				orientation: "horizontal"
				padding: 20
				anchor: paper.view.bounds.topCenter.add(new paper.Point(0, viz_settings.padding))

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
		makePlot = ()->
			plot = new TimePlot
				width: viz_settings.plot.width
				height: viz_settings.plot.height
			plot.init()	
			return plot
		makeTracks = ()->
			# TRACK CREATION
			tracks = new AlignmentGroup
				name: "tracks"
				padding: 10
				orientation: "vertical"
				window: false
			

			track_window = new ScrollWindow
				name: "data_pane"
				max_height: 300
				orientation: 'horizontal'
				padding: 5
				moveable: true
				anchor: paper.project.getItem({name: "legend"}).bounds.bottomCenter.add(new paper.Point(0, 150+15))

			track_window.pushItem(tracks)

			_.each data.activity, (activity, user)->
				track = new AlignmentGroup
					name: "track"
					padding: 10
					orientation: "horizontal"

				label = new LabelGroup
					orientation: "horizontal"
					text: user
					onMouseDown: (e)->
						$('video').attr('src', activity.video.mp4)

				plot_container = new AlignmentGroup
					name: "plot_container"
					padding: 5
					orientation: "vertical"
					backgroundColor: "#F0F0F0"

				if viz_settings.render_codes
					code_plot = makePlot()
					_.each activity.video.codes, (event)-> code_plot.plotEvent(event, activity.video.mp4)
					plot_container.pushItem(code_plot)
				
				if viz_settings.render_iron_imu
					_.each activity.iron.imu, (sensor_data)->
						p = makePlot()
						renderLine(sensor_data, p)
						plot_container.pushItem p

				track.pushItem label
				track.pushItem plot_container
				tracks.pushItem track
		
		makeLegend()
		makeTracks()
	acquireAndProcessData: (callbackFn)->
		rtn = $.getJSON data_source, (manifest)-> 
			window.manifest = manifest
			
			# RESOLVE JSON FILES
			activity = _.mapObject manifest, (data, user)->
				_.mapObject data, (sensors, object)->
					_.mapObject sensors, (url, sensor)->
						filetype = url.split('.').slice(-1)[0] 
						switch filetype
							when "json"
								return $.ajax({dataType: "json", url: url, async: false}).responseJSON
							else
								return url
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

