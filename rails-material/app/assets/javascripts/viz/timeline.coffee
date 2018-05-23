class window.Timeline
	constructor: ()->
		timeline = new AlignmentGroup
			name: "timeline"
			title: 
				content: "TIMELINE"
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
			anchor: 
				pivot: "center"
				position: paper.view.bounds.center.add(new paper.Point(0, 300))
			range: 
				start: 0
				end: 60 * 4
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
		
		timebox = new paper.Path.Rectangle
			size: [600, 60]
			fillColor: "#F5F5F5"
			strokeColor: "#CACACA"
			video: $('video')[0]
			cueThreshold: 5
			name: "timebox"
			get: (name)-> return this.children[name]
			getP: (name)-> return this.parent.children[name]
			clearCue: ()-> if cue = this.getP("cue") then cue.remove()
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
					cue.pivot = if dir > 0 then cue.bounds.leftCenter else cue.bounds.rightCenter
					cue.position = timebar.getNearestPoint(this.down)
					cue.pivot = cue.bounds.leftCenter
			updateScrubber: (e)->
				scrubber = @getP("scrubber")
				scrub.setPos(e.point.x)
			onMouseDown: (e)->
				@clearCue()
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
				@clearCue()
				@updateScrubber(e)
				if e.modifiers.shift
					@addCue(e)
				e.stopPropagation()
			onMouseUp: (e)->
				this.p.remove()
				if cue = @getP("cue")
					scrub = this.parent.children.scrubber
					scrub.setPos(cue.position.x+1)
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

		$('video').on 'loadeddata', (e)->
			timeline.addEnding()
		$('video').on 'timeupdate', (e)->
			scrub.gotoTime(this.currentTime)
			cue = timeline.children.cue
			if cue and not scrub.intersects(cue)
				this.pause()
				scrub.position.x = cue.position.x+1
				this.currentTime = scrub.getTime()
		@addTimeLabels(timeline)
		@addUI(timeline)
		this.timeline = timeline
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
	addUI: (timeline)->
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