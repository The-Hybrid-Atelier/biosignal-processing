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
			else if this.anchor.object
				this.position = this.anchor.object.bounds[this.anchor.magnet].add(this.anchor.offset)
