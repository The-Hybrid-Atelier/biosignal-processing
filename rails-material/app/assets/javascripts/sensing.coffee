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
		@makeTimeline(data)
		@ready()

	makeTimeline: (data)->
		timeline = new AlignmentGroup
			name: "timeline"
			title: 
				content: "TIMELINE"
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
				pivot: "center"
				position: paper.view.bounds.center.add(new paper.Point(0, 300))
			range: 
				start: 0
				end: 60 * 4

		timeline.init()
		
		
		timebox = new paper.Path.Rectangle
			size: [600, 60]
			fillColor: "#F5F5F5"
			strokeColor: "#CACACA"
			video: $('video')[0]
			cueThreshold: 10
			getScrubber: ()-> return this.parent.children.scrubber
			updateScrubber: (e)->
				scrubber = @getScrubber()
				scrubber.position.x = e.point.x
				t = scrubber.getTime()
				return t
			onMouseDown: (e)->
				if this.parent.children.cue then this.parent.children.cue.remove()
				
				this.p = new paper.Path
					strokeColor: "#00A8E1"
					strokeWidth: 1
					segments: [e.point]
				t = this.updateScrubber(e)
				this.video.currentTime = t
				this.down = e.point
				e.stopPropagation()
			
			onMouseDrag: (e)->
				this.p.addSegment(e)
				dis = e.point.x-this.down.x
				dir = dis > 0
				if this.parent.children.cue then this.parent.children.cue.remove()
				
				if dis > this.cueThreshold
					this.cue = new paper.Path.Rectangle
						parent: this.parent
						name: "cue"
						size: [dis, this.bounds.height * 0.9]
						opacity: 0.5
						fillColor: "#00A8E1"
						radius: 2
					this.cue.pivot = if dir > 0 then this.cue.bounds.leftCenter else this.cue.bounds.rightCenter
					this.cue.position = this.parent.children.timebar.getNearestPoint(this.down)
				e.stopPropagation()
			onMouseUp: (e)->
				this.p.remove()
				e.stopPropagation()
		timeline.pushItem timebox
		timebar = new paper.Path.Line
			name: "timebar"
			parent: timeline
			to: timebox.bounds.rightCenter
			from: timebox.bounds.leftCenter
			strokeColor: "#CACACA"
			strokeWidth: 1
			visible: true
		scrub = new paper.Path.Line
			parent: timeline
			name: "scrubber"
			from: timebox.bounds.topLeft
			to: timebox.bounds.bottomLeft
			strokeColor: "#00A8E1"
			strokeWidth: 2
			getTime: ()->
				timebar = this.parent.children.timebar
				np = timebar.getNearestPoint(this.bounds.center)
				offset = timebar.getOffsetOf(np)
				p = offset / timebar.length
				range = (this.parent.range.end - this.parent.range.start)
				return this.parent.range.start + range * p
			gotoTime: (t)->
				timebar = this.parent.children.timebar
				range = (this.parent.range.end - this.parent.range.start)
				if t > this.parent.range.end or t < this.parent.range.start
					# Timeline needs update;
					# Need to update the range of the timeline and redraw labels
					return
				else
					p = (t - this.parent.range.start) / range
					np = timebar.getPointAt(p * timebar.length)
					this.position.x = np.x
		$('video').on 'timeupdate', (e)->
			scrub.gotoTime(this.currentTime)
			
		textbox = new paper.Path.Rectangle
			parent: timeline
			size: [timebox.bounds.width, 25]
			strokeColor: "#CACACA"
			strokeWidth: 1
			visible: false
		textbox.pivot = textbox.bounds.topCenter
		textbox.position = timebox.bounds.bottomCenter

		

		textline = new paper.Path.Line
			parent: timeline
			from: textbox.bounds.leftCenter
			to: textbox.bounds.rightCenter
			strokeColor: "#CACACA"
			strokeWidth: 1
			visible: false
		
		start = timeline.range.start
		range = timeline.range.end - timeline.range.start
		text = _.range(0, timeline.range.end, Math.ceil(range/10))
		_.each text, (t)->
			p = t / timeline.range.end
			time = start + text
			tt = new paper.PointText
				parent: timeline
				content: window.time(t * 1000)
				fillColor: new paper.Color("#CACACA")
				fontFamily: 'Avenir'
				fontSize: 12
				fontWeight: "normal"
				justification: 'center'
			tt.pivot = tt.bounds.center
			tt.position = textline.getPointAt(p * textline.length)
			


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

