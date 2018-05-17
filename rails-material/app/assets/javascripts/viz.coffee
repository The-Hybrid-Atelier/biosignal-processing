class window.AlignmentGroup extends paper.Group
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
		if this.anchor
			this.set
				position: this.anchor
		if this.moveable
			this.set
				onMouseDrag: (e)->
					previous = this.position.clone()
					this.translate e.delta
					if not paper.view.bounds.contains(this.bounds)
						this.position = previous
					e.stopPropagation()
		if this.window
			if this.children.background
				this.children.background.remove()
			bg = new paper.Path.Rectangle
				parent: this
				name: "background"
				rectangle: this.bounds.expand(30, 15)
				fillColor: "white"
				shadowColor: new paper.Color(0.3)
				shadowBlur: 5
				radius: 5
			bg.sendToBack()
		if this.backgroundColor
			if this.children.background
				this.children.background.remove()
			bg = new paper.Path.Rectangle
				parent: this
				name: "background"
				rectangle: this.bounds.expand(25)
				fillColor: this.backgroundColor
				radius: 5
			bg.sendToBack()

class window.ScrollWindow extends AlignmentGroup
	makeScroll: ()->
		b = this.bounds.expand(0)
		b.height = this.max_height
		clip = new paper.Path.Rectangle
			parent: this
			name: "clip"
			rectangle: b
			fillColor: "yellow"
			shadowColor: new paper.Color(0.3)
			shadowBlur: 5
			radius: 5
			clipMask: true
			data: 
				scroll: true

		clip.pivot = clip.bounds.topCenter
		clip.position = this.bounds.topCenter
		clip.sendToBack()	

		scroll_bar = new paper.Path.Rectangle
			parent: this
			name: "scroll_bar"
			size: [15, clip.bounds.height]
			fillColor: new paper.Color(0.9)
			data: 
				scroll: true
		scroll_bar.pivot = scroll_bar.bounds.rightCenter	
		scroll_bar.position = clip.bounds.rightCenter	

		diff = this.children.background.bounds.height - this.max_height + 15					
		island_height = scroll_bar.bounds.height * (1 - (diff/400))
		island = new paper.Path.Rectangle
			parent: this
			name: "island"
			size: [scroll_bar.bounds.width * 0.8, island_height]
			fillColor: new paper.Color(0.5)
			shadowColor: new paper.Color(0.1)
			shadowBlur: 2
			data: 
				scroll: true
		island.pivot = island.bounds.topCenter	
		island.position = scroll_bar.bounds.topCenter
		island.pivot = island.bounds.center
		scope = this
		_.delay ()->
			island_path = new paper.Path.Line
				parent: scope
				from: scroll_bar.bounds.topCenter.add(new paper.Point(0, island.bounds.height/2))
				to: scroll_bar.bounds.bottomCenter.subtract(new paper.Point(0, island.bounds.height/2))
				data: 
					scroll: true
				strokeWidth: 1
				strokeColor: "black"
				visible: false
			island.set
				onMouseDown: (e)->
					this.fillColor.brightness = this.fillColor.brightness - 0.2
				onMouseDrag: (e)->
					this.position = island_path.getNearestPoint(e.point)
					param = island_path.getOffsetOf(this.position)/island_path.length
					scrollTop = param * diff - 15
					pane = scope.getItem {data: {pane: true}}
					if pane
						pane.pivot = pane.bounds.topCenter
						pane.position = clip.bounds.topCenter.add(new paper.Point(0, -scrollTop))
					e.stopPropagation()
				onMouseUp: (e)->
					this.fillColor.brightness = this.fillColor.brightness + 0.2
	
	pushItem: (obj)->
		_.each this.getItems({data: {scroll: true}}), (item)-> item.remove()
		obj.data.pane = true
		super obj
		scope = this
		_.delay (()-> 
			if scope.children.background
				this.children.background.remove()

			bg = new paper.Path.Rectangle
				parent: scope
				name: "background"
				rectangle: scope.bounds.expand(30, 15)
				fillColor: "white"
				shadowColor: new paper.Color(0.3)
				shadowBlur: 5
				radius: 5
			bg.sendToBack()
			

			if scope.max_height < scope.children.background.bounds.height
				scope.makeScroll()
				
			scope.position = scope.anchor
			), 0
				
class window.LabelGroup extends AlignmentGroup
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
		if not this.hoverable
			if not this.children.hover
				hover = new paper.Path.Rectangle
					parent: this
					name: "hover"
					rectangle: this.bounds.expand(15)
					radius: 5
				hover.sendToBack()
			this.on('mouseenter', (e)-> this.children.hover.fillColor = new paper.Color(0.9, 0.3))
			this.on('mousemove', (e)-> this.children.hover.fillColor = new paper.Color(0.9, 0.3))
			this.on('mousedown', (e)-> this.children.hover.fillColor = new paper.Color(0.8, 0.6))
			this.on('mouseup', (e)-> this.children.hover.fillColor = new paper.Color(0.9, 0.3))
			this.on('mouseleave', (e)-> this.children.hover.fillColor = new paper.Color(0.9, 0))
			this.hoverable = true

class window.TimePlot extends AlignmentGroup
	init: ()->
		this.set 
			name: "plot"
		timeplot = new paper.Path.Rectangle
			name: "timeplot"
			parent: this
			size: [this.width, this.height]
			fillColor: "white"
			strokeColor: new paper.Color(0.9)
			strokeWidth: 1
		timeline = new paper.Path.Line
			name: "timeline"
			parent: this
			from: timeplot.bounds.leftCenter
			to: timeplot.bounds.rightCenter
			strokeColor: "#00A8E1"
			start: 0
			end: 6 * 60
	pushItem: (obj)-> 
		super(obj)
	plotEvent: (event, videoURL)->
		timeline = this.children.timeline
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
			parent: this
			name: "event"
			size: [width, this.height]
			fillColor: event.color
			data: event_orig
			onMouseDown: (e)->
				if $('video').attr('src') != videoURL then $('video').attr('src', videoURL)
				video = $('video')[0]
				video.currentTime = event_orig.start
				video.play()
				codes = _.flatten [event.actor, event.codes]
				$("#video-container .label").removeClass()
					.addClass(event.color).addClass('ui label ribbon')
					.html(codes.join('<span><i class="ui angle right icon"></i></span>'))
		e.pivot = e.bounds.leftCenter
		e.position = position
window.installPaper = (dimensions)->
	# PAPER SETUP
	markup = $('canvas#markup')[0]
	paper.install window
	vizpaper = new paper.PaperScope()
	vizpaper.setup(markup)
	vizpaper.settings.handleSize = 10
	loadCustomLibraries()
	return vizpaper


