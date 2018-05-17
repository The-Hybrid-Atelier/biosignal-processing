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
	installPaper()
	vizPipeline.acquireAndProcessData(vizPipeline.renderData)



window.installPaper = (dimensions)->
	# PAPER SETUP
	markup = $('canvas#markup')[0]
	paper.install window
	vizpaper = new paper.PaperScope()
	vizpaper.setup(markup)
	vizpaper.settings.handleSize = 10
	loadCustomLibraries()
	return vizpaper

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
		renderCodes = (activity, plot)->
			timeline = plot.children.timeline		
			_.each activity.video.codes, (event)->
				event_orig = _.clone event
				if event.start > timeline.end then return
				if event.end < timeline.start then return
				if event.start < timeline.start then event.start = timeline.start
				if event.end > timeline.end then event.end = timeline.end
				
				pos = event.start - timeline.start
				pos_p = pos / (timeline.end - timeline.start)
				duration = event.end - event.start
				duration_p = duration / (timeline.end - timeline.start)
				max = (timeline.end - event.start) / (timeline.end - timeline.start)
				
				width = duration_p * timeline.length
				position = timeline.getPointAt(pos_p * timeline.length)
				
				e = new paper.Path.Rectangle
					parent: plot
					name: "event"
					size: [width, viz_settings.plot.height]
					fillColor: event.color
					data: event_orig
					onMouseDown: (e)->
						if $('video').attr('src') != activity.video.mp4 then $('video').attr('src', activity.video.mp4)
						video = $('video')[0]
						video.currentTime = event_orig.start
						video.play()
						codes = _.flatten [event.actor, event.codes]
						$("#video-container .label").removeClass()
							.addClass(event.color).addClass('ui label ribbon')
							.html(codes.join('<span><i class="ui angle right icon"></i></span>'))
				e.pivot = e.bounds.leftCenter
				e.position = position
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
			plot = new paper.Group
				name: "plot"

			timeplot = new paper.Path.Rectangle
				name: "timeplot"
				parent: plot
				size: [viz_settings.plot.width, viz_settings.plot.height]
				fillColor: "white"
				strokeColor: new paper.Color(0.9)
				strokeWidth: 1
				# shadowColor: new paper.Color(0.1)
				# shadowBlur: 5
			
			timeline = new paper.Path.Line
				name: "timeline"
				parent: plot
				from: timeplot.bounds.leftCenter
				to: timeplot.bounds.rightCenter
				strokeColor: "#00A8E1"
				start: 0
				end: 6 * 60
				
			return plot
		makeTracks = ()->
			# TRACK CREATION
			tracks = new AlignmentGroup
				name: "tracks"
				window: true
				moveable: true
				padding: 10
				orientation: "vertical"
				anchor: paper.view.center

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

				code_plot = makePlot()
				renderCodes(activity, code_plot)

				acc_plot = makePlot()
				renderLine(activity.iron.imu.A, acc_plot)

				mag_plot = makePlot()
				renderLine(activity.iron.imu.M, mag_plot)

				gyro_plot = makePlot()
				renderLine(activity.iron.imu.G, gyro_plot)

				plot_container.pushItem(code_plot)
				plot_container.pushItem(acc_plot)
				plot_container.pushItem(mag_plot)
				plot_container.pushItem(gyro_plot)

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

