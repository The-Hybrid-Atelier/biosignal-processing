class window.CodeTimeline extends Timeline
	refresh: ()->
		super()
		this.draw()
	load: (data)->
		this.data = data
	draw: ()->
		scope = this
		_.each this.ui.getItems({name: "tag"}), (el)-> el.remove()
		if not this.data then return

		scrubber = this.ui.get("scrubber")
		tracks = 3
		H = scrubber.bounds.height
		h =  H/tracks
		track_offset = h/tracks
		timebox = this.ui.get("timebox")

		tags = []
		
		t_start = this.ui.range.start + this.ui.range.timestamp
		t_end = this.ui.range.end + this.ui.range.timestamp
		
		ts = this.data.timestamp
		
		codes = _.map this.data.data, (code)->
			s = ts + code.start
			e = ts + code.end
			if s > t_start and e < t_end
				_.extend _.clone(code), 
					draw: true
					start: s
					end: e
			else if s < t_start
				if t_start >= e then return {draw: false}
				_.extend _.clone(code), 
					draw: true
					start: t_start
					end: e
			else if e > t_end
				if s >= t_end then return {draw: false}
				_.extend _.clone(code), 
					draw: true
					start: s
					end: t_end
			else
				_.extend _.clone(code), 
					draw: false

		
		_.each codes, (code, i)->
			if not code.draw then return
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

		ms = this.ui.range.timestamp
		t = moment((ms + t) * 1000).format("hh:mm:ss A")
		tags.push t
		@make_label(tags.join('\n'))
		

window.channel_colors = ["red", "green", "blue"]
class window.SensorTimeline extends Timeline
	refresh: ()->
		super()
		this.draw()
	load: (data)->
		this.data = data
	get_minmax: (data, axis)->
		h_max = _.map data, (line)->
			pt = _.max line, (pt)-> return pt[axis]
			return pt[axis]			
		
		h_min = _.map data, (line)->
			pt = _.min line, (pt)-> return pt[axis]	
			return pt[axis]	
		return {
			max: _.max(h_max)
			min: _.min(h_min)
		}
	draw: ()->
		if not this.data then return
		_.each this.ui.getItems({name: "sensor_line"}), (el)-> el.remove()

		scope = this
		timebox = this.ui.children.timebox
		scrubber = this.ui.children.scrubber
		data = this.data
		channels = data.data


		ts = this.ui.range.timestamp
		t_start = this.ui.range.start + ts
		t_end = this.ui.range.end + ts

		lines = _.map channels, (channel, k)->
			filtered_pts = []
			original_pts = []
			_.each channel, (mag, i)->
				t = data.time[i]+ data.timestamp
				if t >= t_start and t <= t_end
					if filtered_pts.length == 0
						filtered_pts.push [t - 0.5, 0]
					filtered_pts.push [t, mag]	
					original_pts.push [t, mag]
				else
					original_pts.push [t, mag]
					return
			return {filtered: filtered_pts, raw: original_pts}
		h = @get_minmax _.pluck(lines, "raw"), 1
		h.range = h.max - h.min
		t = @get_minmax _.pluck(lines, "raw"), 0
	

		plot_start = scrubber.probeTime(t.min).p
		plot_end = scrubber.probeTime(t.max).p

		if plot_start < 0 then plot_start = 0
		if plot_end > 1 then plot_end = 1
		end = (1 - plot_end)
		start = plot_start
		w = 1 - end - start
		
		plot_width = timebox.bounds.width *  w
		if plot_width <= 0 then return

		lines = _.pluck(lines, "filtered")
		lines = _.map lines, (pts, i)->
			line = new paper.Path.Line
				name: "sensor_line"
				parent: scope.ui
				strokeColor: window.channel_colors[i]
				strokeWidth: 1
				segments: pts
			return line

		plot_height = timebox.bounds.height
		console.log h.range
		lw_max = (_.max lines, (line)-> return line.bounds.width).bounds.width			
		_.each lines, (line)-> line.scaling.x = (plot_width)/lw_max
		_.each lines, (line)-> line.scaling.y = (plot_height - 10)/h.range

		
		pos = scrubber.probeTime(t.min).point
		_.each lines, (line)-> 
			if line.length <= 0 then return
			line.pivot = line.firstSegment.point

			if plot_start <= 0
				line.position = timebox.bounds.leftCenter
			else
				line.position = pos