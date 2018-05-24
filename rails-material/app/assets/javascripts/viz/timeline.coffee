class window.Timeline
	constructor: (op)->
		op = op or {}
		_.extend this, op
		timeline = new AlignmentGroup
			name: "timeline"
			title: 
				content: op.title or "TIMELINE"
			moveable: true
			padding: 5
			orientation: "vertical"
			video: $('video')[0]
			background: 
				fillColor: "white"
				padding: 5
				radius: 5
				shadowBlur: 5
				shadowColor: new paper.Color(0.9)
			anchor: op.anchor
			range: 
				start: 0
				end: 60 * 4
			get: (name)-> return this.children[name]			
			addEnding: ()->
				d = $('video')[0].duration
				if buffer = this.children.buffer then buffer.remove()
				if d < timeline.range.end
					dim = this.children.scrubber.probeTime(d)
					buffer = new paper.Path.Rectangle
						parent: this
						name: "buffer"
						size: [dim.total - dim.offset, this.children.timebox.bounds.height]
						fillColor: new paper.Color(0)
						opacity: 0.5
					buffer.pivot = buffer.bounds.rightCenter
					buffer.position = this.children.timebox.bounds.rightCenter
		timeline.init()
		@addPlot(timeline)
		@addTimeLabels(timeline)
		@addControlUI(timeline)
		@bindVideoEvents(timeline)
		this.ui = timeline
	makeTimeLabel: ()->
		scrubber = this.ui.get("scrubber")
		t = scrubber.getTime()
		t_label = new Group
			name: "t_label"
			parent: this.ui
			ui: true
			onMouseDown: (e)-> this.bringToFront()
		
		label = new paper.PointText
			parent: t_label
			content: window.time(t * 1000)
			fillColor: new paper.Color(0.6)
			fontFamily: 'Avenir'
			fontSize: 12
			fontWeight: "normal"
			justification: 'center'
			
		bg = new paper.Path.Rectangle
			parent: t_label
			rectangle: t_label.bounds.expand(5, 3)
			fillColor: "white"
			radius: 2
			shadowColor: new paper.Color(0.4)
			shadowBlur: 2
		bg.sendToBack()
		t_label.pivot = t_label.bounds.bottomCenter.add(new paper.Point(0, 5))
		t_label.position = scrubber.bounds.topCenter
	addPlot: (timeline)->
		scope = this
		timebox = new paper.Path.Rectangle
			size: [600, 60]
			fillColor: "#F5F5F5"
			strokeColor: "#CACACA"
			video: $('video')[0]
			cueThreshold: 5
			name: "timebox"
			get: (name)-> return this.children[name]
			getP: (name)-> return this.parent.children[name]
			clearUI: ()-> 
				ui = this.parent.getItems {ui: true}
				_.each ui, (el)-> el.remove()
			addCue: (e)->
				timebar = @getP("timebar")
				dis = e.point.x - this.down.x
				dir = dis > 0
				dis = Math.abs(dis)
				if dis > this.cueThreshold
					cue = new paper.Path.Rectangle
						parent: this.parent
						name: "cue"
						size: [dis, this.bounds.height * 0.9]
						opacity: 0.5
						fillColor: "#00A8E1"
						radius: 2
						ui: true
					cue.pivot = if dir > 0 then cue.bounds.leftCenter else cue.bounds.rightCenter
					cue.position = timebar.getNearestPoint(this.down)
					cue.pivot = cue.bounds.leftCenter
			updateScrubber: (pt)->
				scrubber = @getP("scrubber")
				scrubber.setPos(pt.x)
				scope.makeTimeLabel()
			
			onMouseDown: (e)->
				@clearUI()
				this.p = new paper.Path
					strokeColor: "#00A8E1"
					strokeWidth: 1
					segments: [e.point]
				t = this.updateScrubber(e.point)
				this.down = e.point
				e.stopPropagation()
			onMouseDrag: (e)->
				this.p.addSegment(e)
				@clearUI()
				@updateScrubber(e.point)
				if e.modifiers.shift
					@addCue(e)
				e.stopPropagation()
			onMouseUp: (e)->
				this.p.remove()
				if cue = @getP("cue")
					scrub = this.parent.children.scrubber
					scrub.setPos(cue.position.x+1)
					@updateScrubber(cue.position)
				e.stopPropagation()

		timeline.pushItem timebox
		timeline.addEnding()
		
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
			setPos: (x)->
				this.position.x = x
				timeline.video.currentTime = this.getTime()
			getPos: ()-> return this.bounds.center
			getOffset: ()->
				timebar = this.parent.children.timebar
				np = timebar.getNearestPoint(@getPos())
				offset = timebar.getOffsetOf(np)
				return offset
			getP: ()->
				timebar = this.parent.children.timebar
				return @getOffset() / timebar.length
			getTime: ()->
				range = (this.parent.range.end - this.parent.range.start)
				return this.parent.range.start + range * @getP()

			probeTime: (t)->
				timebar = this.parent.children.timebar
				range = (this.parent.range.end - this.parent.range.start)
				p = (t - this.parent.range.start) / range
				return {
					point: timebar.getPointAt(p * timebar.length) 
					p: p
					offset: p * timebar.length
					total: timebar.length
				}
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
	addTimeLabels: (timeline)->
		# time label container
		timebox = timeline.children.timebox
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
		text = _.range(0, timeline.range.end, Math.ceil(range/10)) #10 labels max

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
	addControlUI: (timeline)->
		if this.controls.rate
			buttons = new AlignmentGroup
				parent: timeline
				name: "buttons"
				padding: 3
				orientation: "horizontal"
				settings:
					step: 0.5
					max: 9
					min: 0.5
				anchor: 
					pivot: "bottomRight"
					position: timeline.bounds.topRight.add(new paper.Point(0, 15))

			buttons.pushItem new LabelGroup
				orientation: "horizontal"
				padding: 1
				text: "SPEED +"
				button: 
					fillColor: new paper.Color(0.9)
				onMouseDown: (e)->
					$('video')[0].playbackRate += this.parent.settings.step
					if $('video')[0].playbackRate > this.parent.settings.max then $('video')[0].playbackRate = this.parent.settings.max
					if $('video')[0].playbackRate < this.parent.settings.min then $('video')[0].playbackRate = this.parent.settings.min
					e.stopPropagation()	
			rate = new LabelGroup
				orientation: "horizontal"
				padding: 1
				text: "1.0"
			buttons.pushItem rate
			buttons.pushItem new LabelGroup
				orientation: "horizontal"
				padding: 1
				text: "SPEED -"
				button: 
					fillColor: new paper.Color(0.9)
				onMouseDown: (e)->
					$('video')[0].playbackRate -= this.parent.settings.step
					if $('video')[0].playbackRate > this.parent.settings.max then $('video')[0].playbackRate = this.parent.settings.max
					if $('video')[0].playbackRate < this.parent.settings.min then $('video')[0].playbackRate = this.parent.settings.min
					e.stopPropagation()	
			$('video').on "ratechange", ()->
				rate.updateLabel this.playbackRate.toFixed(1)
	bindVideoEvents: (timeline)->
		$('video').on 'loadeddata', (e)->
			timeline.addEnding()
		$('video').on 'timeupdate', (e)->
			scrub = timeline.children.scrubber
			scrub.gotoTime(this.currentTime)
			cue = timeline.children.cue
			if cue and not scrub.intersects(cue)
				this.pause()
				scrub.position.x = cue.position.x+1
				this.currentTime = scrub.getTime()
class window.CodeTimeline extends Timeline
	load: (codes)->
		scope = this
		_.each this.ui.getItems({name: "tag"}), (el)-> el.remove()
		scrubber = this.ui.get("scrubber")
		tracks = 3
		H = scrubber.bounds.height
		h =  H/tracks
		track_offset = h/tracks
		timebox = this.ui.get("timebox")

		tags = []
		_.each codes.data, (code, i)->

			s = scrubber.probeTime(code.start)
			e = scrubber.probeTime(code.end)
			if not e.point then return
			if not s.point then return
			dis = e.point.x - s.point.x

			track_iter = 0
			track_id = i % tracks
			s.point.y -= H/2

			while track_iter < tracks
				
				s.point.y += (track_id * h) + (h/2)
				all_clear = _.every tags, (t)->
					return not t.contains(s.point)
				if all_clear
					break
				track_iter++
				
				if track_iter >= tracks	
					break
				
				s.point.y -= (track_id * h) + (h/2)
				
				track_id += 1
				if track_id == tracks then track_id = 0 
				
			dark = new paper.Color(code.color)
			dark.brightness -= 0.3
			c = new paper.Path.Rectangle
				parent: scope.ui
				name: "tag"
				data: 
					actor: code.actor
					tags: code.codes
				size: [dis, h * 0.9]
				opacity: 1
				fillColor: code.color
				radius: 2
				strokeColor: dark
				opacity: 0.5
				onMouseDown: (e)-> 
					# console.log i
					timebox.onMouseDown(e)
				onMouseDrag: (e)-> timebox.onMouseDrag(e)
				onMouseUp: (e)-> timebox.onMouseUp(e)
			c.pivot = c.bounds.leftCenter 
			c.position = s.point
			tags.push c
	makeTimeLabel: ()->
		scrubber = this.ui.get("scrubber")
		tags = this.ui.getItems({name: "tag"})
		tags = _.filter tags, (t)-> scrubber.intersects(t)
		tags = _.map tags, (t)-> 
			t.data.actor + ": " + t.data.tags.join("→ ")
		t = scrubber.getTime()
		t_label = new Group
			name: "t_label"
			parent: this.ui
			ui: true
			onMouseDown: (e)-> this.bringToFront()
		
		t = window.time(t * 1000)
		tags.push t
		label = new paper.PointText
			parent: t_label
			content: tags.join('\n')
			fillColor: new paper.Color(0.6)
			fontFamily: 'Avenir'
			fontSize: 12
			fontWeight: "normal"
			justification: 'center'
			
		bg = new paper.Path.Rectangle
			parent: t_label
			rectangle: t_label.bounds.expand(5, 3)
			fillColor: "white"
			radius: 2
			shadowColor: new paper.Color(0.4)
			shadowBlur: 2
		bg.sendToBack()
		t_label.pivot = t_label.bounds.bottomCenter.add(new paper.Point(0, 5))
		t_label.position = scrubber.bounds.topCenter