class window.AlignmentGroup extends paper.Group
	pushItem: (obj)->
		_.each this.getItems({data: {ui: true}}), (el)-> el.remove()
		
		lc = this.lastChild		
		obj.parent = this
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
		if this.background
			if this.children.background then this.children.background.remove()
			if this.background.padding
				if not this.background.padding.x
					this.background.padding = 
						x: this.background.padding
						y: this.background.padding

			bg = new paper.Path.Rectangle
				parent: this
				name: "background"
				rectangle: this.bounds.expand(this.background.padding.x + 10, this.background.padding.y)
				radius: 0 or this.background.radius 
			bg.set this.background
			bg.sendToBack()

		
		@ui_elements()
		@reposition()
	ui_elements: ()->
		if this.moveable and this.children.length != 0
			handle = new paper.Path.Rectangle
				parent: this
				name: "handle"
				size: [15, this.bounds.height]
				fillColor: new paper.Color("#F5F5F5")
				strokeColor: new paper.Color("#CACACA")
				strokeWidth: 1
				data: 
					ui: true

			handle.pivot = handle.bounds.rightCenter.subtract(new paper.Point(5, 0))
			handle.position = this.children.background.bounds.leftCenter
		if this.title
			ops = 
				name: "title"
				parent: this
				content: ""
				fillColor: 'black'
				fontFamily: 'Adobe Gothic Std'
				fontSize: 12
				fontWeight: "bold"
				justification: 'left'
				data:
					ui: true
				
			ops = _.extend ops, this.title
			
			t = new paper.PointText ops
			t.pivot = t.bounds.bottomLeft
			t.position = this.children.background.bounds.topLeft.add(new paper.Point(10,-3))
	init: ()->
		@configureWindow()

	configureWindow: ()->
		if this.moveable
			this.on 'mousedown', (e)-> this.bringToFront()
			this.on 'mousedrag', (e)->
				previous = this.position.clone()
				this.translate e.delta
				if not paper.view.bounds.contains(this.bounds)
					this.position = previous
				e.stopPropagation()	
	reposition: ()->
		if this.anchor
			if this.anchor.pivot 
				this.pivot = this.bounds[this.anchor.pivot]
			if not this.anchor.offset
				this.anchor.offset = new paper.Point(0, 0)
			if this.anchor.position
				this.position = this.anchor.position.add(this.anchor.offset)

class window.WindowGroup extends AlignmentGroup
	init: ()->
		@ui = {}
		@ui.clipped = new paper.Group
			parent: this
			name: "clipped"

		@makePane()
		@makeTitle()
		@configureWindow()
	get: (name)-> return @ui[name]
	pushItem: (obj)->
		this.get("pane").pushItem(obj)
		
		@reposition()
		@clipWindow()
		@makeTitle()
	configureWindow: ()->
		if this.moveable
			this.set
				onMouseDown: (e)->
					this.bringToFront()
				onMouseDrag: (e)->
					previous = this.position.clone()
					this.translate e.delta
					if not paper.view.bounds.contains(this.bounds)
						this.position = previous
					e.stopPropagation()		
	clipWindow: ()->
		if this.get("clip") then this.get("clip").remove()
		if this.get("shade") then this.get("shade").remove()
		
		r = this.bounds.expand(0)
		
		if this.pane.max_height and r.height > this.pane.max_height
			r.height = this.pane.max_height
		if this.pane.max_width and r.width > this.pane.max_width
			r.width = this.pane.max_width

		@ui.clip = new paper.Path.Rectangle
			parent: this.get("clipped")
			name: "clip"
			rectangle: r
			radius: 3
			strokeWidth: 1
			strokeColor: "#00A8E1"
			clipMask: true
			onMouseDown: (e)->
				console.log this.parent.parent.name
				this.selected = true
			onMouseUp: (e)->
				this.selected = false
		@makeScroll()

		@ui.shade = new paper.Path.Rectangle
			parent: this
			name: "shade"
			rectangle: @ui.clip.bounds.expand(0)
			fillColor: 'purple'
			shadowColor: new paper.Color(0.3, 0.4)
			shadowBlur: 5
			radius: 3
			strokeColor: "#CACACA"
			strokeWidth: 1
			shadowOffset: new paper.Point(2, 2)
		@ui.shade.sendToBack()		
	makePane: ()->
		@ui.pane = new AlignmentGroup _.extend this.pane, 
			parent: this.get("clipped")
			name: "pane"
			background: 
				padding: [15, 30]
				fillColor: "yellow"
	makeTitle: ()->
		scope = this
		if not this.title then return 
		
		bg = @get('clipped')
		if this.get("title_bar") then this.get("title_bar").remove()

		title = new paper.Group
			parent: this.get("clipped")
			name: "title_bar"
			data: 
				ui: true
		

		# BACKGROUND 
		t_bg = new paper.Path.Rectangle
			parent: title
			name: "title_bg"
			size: [bg.bounds.width, 15]
			fillColor: new paper.Color(0.8)
			strokeWidth: 1
			strokeColor: "#CACACA"
			
		title.pivot = title.bounds.topCenter
		title.position = bg.bounds.topCenter
		
		
		# # TEXT
		ops = 
			name: "title"
			parent: title
			content: ""
			fillColor: 'black'
			fontFamily: 'Avenir'
			fontSize: 8
			fontWeight: "bold"
			justification: 'left'
			
		ops = _.extend ops, this.title
		
		t = new paper.PointText ops
		t.pivot = t.bounds.center
		t.position = t_bg.bounds.center
		
		if this.title.buttons
			minimizeButton = new paper.Path.Circle
				name: "minimize"
				fillColor: "#D8D8D8"
				strokeColor: "#CACACA"
				baseColor: new paper.Color "#24C339"
				strokeWidth: 2
				radius: title.bounds.height * 0.8 / 2
				data: 
					button: true
				onMouseDown: ()->
					scope.get('pane').visible = not scope.get('pane').visible
					scope.clipWindow()	
			# hideButton = new paper.Path.Circle
			# 	name: "hide"
			# 	fillColor: "#D8D8D8"
			# 	strokeColor: "#CACACA"
			# 	baseColor: new paper.Color "#FFBA2A"
			# 	strokeWidth: 2
			# 	radius: title.bounds.height * 0.8 / 2
			# 	data: 
			# 		button: true
			# 	
			button_group = new AlignmentGroup
				parent: title
				padding: 2
				orientation: "horizontal"
				anchor: 
					pivot: "leftCenter"
					position: t_bg.bounds.leftCenter
					offset: new paper.Point(3, 0)
				onMouseEnter: ()->
					buttons = this.getItems({data: {button: true}})
					_.each buttons, (b)->
						c = b.baseColor.clone()
						c.brightness += 0.1
						b.fillColor = c

			button_group.pushItem minimizeButton
			# button_group.pushItem hideButton
			@ui.title_bar = title
	makeScroll: ()->
		b = this.bounds.expand(0)
		b.height = this.max_height
		
		if @ui.scroll_bar then @ui.scroll_bar.remove()

		clip = @get("clipped")
		title_bar = @get("title_bar")

		scroll_bar = new Group
			parent: this
			name: "scroll_bar"
			
		scroll_bar_bg = new paper.Path.Rectangle
			parent: scroll_bar
			size: [10, clip.bounds.height - title_bar.bounds.height]
			fillColor: new paper.Color(0.95)
			strokeColor: "#CACACA"
			strokeWidth: 1
			
		scroll_bar.pivot = scroll_bar.bounds.bottomRight	
		scroll_bar.position = clip.bounds.bottomRight	
		

		pane = @get("pane")
		diff = pane.bounds.height - this.pane.max_height + 15
		island_height = scroll_bar.bounds.height * (1 - (diff/400))
		island_height = _.max([30, island_height])
		

		island = new paper.Path.Rectangle
			parent: scroll_bar
			name: "island"
			size: [scroll_bar.bounds.width * 0.8, island_height]
			fillColor: new paper.Color(0.5)
			shadowColor: new paper.Color(0.1)
			shadowBlur: 2

		island.pivot = island.bounds.topCenter	
		island.position = scroll_bar_bg.bounds.topCenter
		island.pivot = island.bounds.center

		@ui.scroll_bar = scroll_bar
		scope = this
		_.delay ()->
			island_path = new paper.Path.Line
				parent: scope
				from: scroll_bar_bg.bounds.topCenter.add(new paper.Point(0, island.bounds.height/2))
				to: scroll_bar_bg.bounds.bottomCenter.subtract(new paper.Point(0, island.bounds.height/2))
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
					scrollTop = param * diff - 55
					pane.pivot = pane.bounds.leftCenter
					pane.position = clip.bounds.leftCenter.add(new paper.Point(0, -scrollTop))
					e.stopPropagation()
				onMouseUp: (e)->
					this.fillColor.brightness = this.fillColor.brightness + 0.2

				
class window.LabelGroup extends AlignmentGroup
	constructor: (op)->
		super op
		if op.key then this.pushItem op.key
		if op.text
			t = new paper.PointText
				name: "label"
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
					rectangle: this.bounds.expand(10, 5)
					radius: 5
				hover.sendToBack()
			this.on('mouseenter', (e)-> this.children.hover.fillColor = new paper.Color(0.9, 0.3))
			this.on('mousemove', (e)-> this.children.hover.fillColor = new paper.Color(0.9, 0.3))
			this.on('mousedown', (e)-> this.children.hover.fillColor = new paper.Color(0.8, 0.6))
			this.on('mouseup', (e)-> this.children.hover.fillColor = new paper.Color(0.9, 0.3))
			this.on('mouseleave', (e)-> this.children.hover.fillColor = new paper.Color(0.9, 0))
			this.hoverable = true
			if this.button
				background = new paper.Path.Rectangle
					parent: this
					name: "background"
					rectangle: hover.bounds
					radius: 5
					fillColor: "white"
					strokeColor: "#CACACA"
					strokeWidth: 1
				hover.sendToBack()
				background.sendToBack()
				background.set this.button
			
	updateLabel: (lab)->
		this.children.label.content = lab
		
window.installPaper = (dimensions)->
	# PAPER SETUP
	markup = $('canvas#markup')[0]
	paper.install window
	vizpaper = new paper.PaperScope()
	vizpaper.setup(markup)
	vizpaper.settings.handleSize = 10
	loadCustomLibraries()
	return vizpaper

window.makePaper = (parent)->
	c = $('<canvas></canvas>')
	parent.html(c)
	c.attr
		height: parent.height()
	console.log parent.height()
	p = new paper.PaperScope()
	p.setup(c[0])
	p.settings.handleSize = 10
	new paper.Path.Circle
		radius: 20
		fillColor: "#00A8E1"
		position: paper.view.center
	return p


