# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
#= require papaparse.min
#= require moment
#= require paper

class AlignmentGroup extends paper.Group
	pushItem: (obj)->
		lc = this.lastChild		
		if lc
			switch this.orientation
				when "vertical"
					obj.pivot = obj.bounds.topCenter
					obj.position = lc.bounds.bottomCenter.add(new paper.Point(0, this.padding))
					obj.pivot = obj.bounds.center
				when "horizontal"
					obj.pivot = obj.bounds.leftCenter
					obj.position = lc.bounds.rightCenter.add(new paper.Point(this.padding, 0))
					obj.pivot = obj.bounds.center
		obj.parent = this
		this.position = this.anchor

class LabelGroup extends AlignmentGroup
	constructor: (op)->
		super op
		if op.key then this.pushItem op.key
		if op.text
			t = new paper.PointText
				content: op.text
				fillColor: 'black'
				fontFamily: 'Avenir'
				fontWeight: 'bold'
				fontSize: 12		
			this.pushItem t

window.debug = null
$ ->
	installPaper()
	vizPipeline.acquireAndProcessData(vizPipeline.renderData)
window.color_scheme = ["red","orange","yellow","olive","green","teal","blue","violet","purple","pink","brown","grey","black"]
window.data_source = "/data/data.csv"


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
		console.log data
		viz_settings = 
			padding: 30
			plot:
				height: 60
				width: 600
		# LEGEND CREATION
		g = new AlignmentGroup
			name: "legend"
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
						this.opacity = 0.5
						_.each codes, (c)-> c.visible = false
				onMouseDown: ()->
					this.data.activate = not this.data.activate
					this.update()
			g.pushItem label

		# TRACK CREATION
		tracks = new AlignmentGroup
			name: "tracks"
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

			plot = new paper.Group
				name: "plot"

			timeplot = new paper.Path.Rectangle
				name: "timeplot"
				parent: plot
				size: [viz_settings.plot.width, viz_settings.plot.height]
				fillColor: "white"
				shadowColor: new paper.Color(0.1)
				shadowBlur: 5
			
			timeline = new paper.Path.Line
				name: "timeline"
				parent: plot
				from: timeplot.bounds.leftCenter
				to: timeplot.bounds.rightCenter
				strokeColor: "#00A8E1"
				start: 0
				end: 6 * 60 * 1000
			

			_.each activity, (event)->
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
				e.pivot = e.bounds.leftCenter
				e.position = position
			track.pushItem label
			track.pushItem plot
			tracks.pushItem track
		
	acquireAndProcessData: (callbackFn)->
		json = Papa.parse data_source,
			download: true 
			header: true
			before: (file)->
				console.log "Reading", file
			error: (err, file)->
				alertify.error err.message, err.type, err.code, err.row
			complete: (results, file)->
				# EXTRACT AUTHORS
				actors = _.unique(_.map results.data, (r)-> r.Code.split("\\")[1])
				actors = _.object _.map actors, (a, i)-> 
					[a, color_scheme[i]]
				# GROUP ACTIVITIES, CALCULATE DURATION, NORMALIZE TIMES
				results = _.groupBy results.data, (r)-> r["Document name"]
				results = _.mapObject results, (codes, k)->
					codes = _.map codes, (code)->
						start = moment(code.Begin, "HH:mm:ss.SSS", false)
						end = moment(code.End, "HH:mm:ss.SSS", false)
						code = code.Code.split("\\").slice(1)
						rtn = 
							actor: code[0] 
							sub_codes: code.slice(1)
							color: actors[code[0]] 
							start: start.valueOf()
							end: end.valueOf()
							duration: end.valueOf() - start.valueOf()
					min_time = _.min codes, (code)-> return code.start
					min_time = min_time.start
					codes = _.map codes, (code)->
						code.start = code.start - min_time
						code.end = code.end - min_time
						code
				# RETURN DATA THROUGH CALLBACK
				callbackFn
					activity: results
					actors: actors	

