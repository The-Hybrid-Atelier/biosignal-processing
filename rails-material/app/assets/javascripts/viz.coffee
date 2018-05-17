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
		this.set
			position: this.anchor
		if this.moveable
			this.set
				onMouseDrag: (e)->
					this.translate e.delta
					e.stopPropagation()
		if this.window
			if this.children.background
				this.children.background.remove()
			bg = new paper.Path.Rectangle
				parent: this
				name: "background"
				rectangle: this.bounds.expand(15)
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
	


