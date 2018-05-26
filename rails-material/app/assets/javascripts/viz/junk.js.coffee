
		renderLine = (data, plot)->
			lines = _.map data.data, (channel, k)->
				pts = _.map channel, (mag, i)->
					t = data.time[i]
					return [data.time[i], mag]
				plot.plotLine(pts, viz_settings.colors[k])
			plot.fitAxes()
		makePlot = (title, video)->
			plot = new TimePlot
				width: viz_settings.plot.width
				height: viz_settings.plot.height
				title: 
					content: title
				video: video
				orientation: "horizontal"
			plot.init()	
			return plot
		
		makeLegend = (labels)->
			console.log labels
		makeLegend(data.actors)
		# makeTracks()



class window.TimePlot extends paper.Group
	get: (name)->
		return this.getItem({name: name})
	init: ()->
		scope = this
		this.set 
			name: "plot"
		wrapper = new paper.Group
			parent: this
			name: "wrapper"	
		plot_wrapper = new paper.Group
			name: "plot_wrapper"
			parent: wrapper
			onMouseDrag: (e)->
				this.translate new paper.Point(e.delta.x, 0)
				e.stopPropagation(e)
		timeplot = new paper.Path.Rectangle
			name: "timeplot"
			parent: plot_wrapper
			size: [this.width * 2, this.height]
			fillColor: "white"
			strokeColor: new paper.Color(0.9)
			strokeWidth: 1
			onMouseDown: (e)->
				p = _.min([_.max([0, (e.point.x - this.parent.bounds.topLeft.x)/this.parent.bounds.width]), 1])
				video = $('video')[0]
				if $('video').attr('src') != scope.video
					$('video').attr('src', scope.video)
					video.addEventListener 'loadeddata', ()->
					  this.currentTime = this.duration * p
					  this.play()
				else	
				
					video.currentTime = video.duration * p
					video.play()
				
		timeline = new paper.Path.Line
			name: "timeline"
			parent: plot_wrapper
			from: timeplot.bounds.leftCenter
			to: timeplot.bounds.rightCenter
			strokeColor: "#00A8E1"
			start: 0
			end: 6 * 60
		clip = new paper.Path.Rectangle
			name: "clip"
			parent: wrapper
			size: [this.width, this.height]
			clipMask: true

		if this.title 
			@addTitle()
	addTitle: ()->
		ops = 
			name: "title"
			parent: this
			content: ""
			fillColor: 'black'
			fontFamily: 'Avenir'
			fontSize: 10	
			justification: 'center'
		ops = _.extend ops, this.title
		t = new paper.PointText ops
			
		t.rotate(90+180)
		t.position = this.get('clip').bounds.leftCenter.clone().add(new paper.Point(-t.bounds.width/2, 0))
	plotLine: (data, color)->
		plot_wrapper = this.get("plot_wrapper")
		timeline = this.get("timeline")
		
		pts = _.filter data, (pt)-> return pt[0] >= timeline.start and pt[0] <= timeline.end
		line = new paper.Path.Line
			parent: plot_wrapper
			strokeColor: color
			strokeWidth: 1
			segments: pts
			data: 
				line: true
				pts: data

	fitAxes: ()->		
		plot_wrapper = this.get("plot_wrapper")
		timeplot = this.get("timeplot")
		plot_height = timeplot.bounds.height
		plot_width = timeplot.bounds.width
		lines = this.getItems {data: {line: true}}

		lw_max = (_.max lines, (line)-> return line.bounds.width).bounds.width			
		lh_max = (_.max lines, (line)-> return line.bounds.height).bounds.height

		_.each lines, (line)-> line.scaling.x = (plot_width)/lw_max
		_.each lines, (line)-> line.scaling.y = (plot_height - 10)/lh_max
		
		_.each lines, (line)-> 
			line.pivot = line.bounds.leftCenter
			line.position = timeplot.bounds.leftCenter

	plotEvent: (event, videoURL)->
		plot_wrapper = this.get("plot_wrapper")
		timeline = this.get("timeline")
		
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
			parent: plot_wrapper
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

# makeTracks = ()->
			# panel = new AlignmentGroup
			# 	name: "panel"
			# 	shading: true
			# 	moveable: true
			# 	anchor: 
			# 		pivot: "topCenter"
			# 		position: paper.project.getItem({name: "legend"}).bounds.bottomCenter.add(new paper.Point(0, 15))
			
			# # TRACK CREATION			
			# track_window = new AlignmentGroup
			# 	name: "data_pane"
			# 	shading: true
			# 	moveable: false
			# 	title: 
			# 		content: "DATAPANE"
			# 		buttons: true
			# 	pane: 
			# 		padding: 5
			# 		orientation: "vertical"
			# 		background:
			# 			fillColor: new paper.Color(0.7)
			# 			padding: [30, 15]
			# track_window.init()
			# track_window.pushItem new paper.Path.Circle
			# 	radius: 100
			# 	fillColor: "red"	
		
			# panel.pushItem track_window



			# _.each data.activity, (activity, user)->
			# 	track = new AlignmentGroup
			# 		name: "track"
			# 		padding: 10
			# 		orientation: "horizontal"

			# 	label = new LabelGroup
			# 		orientation: "horizontal"
			# 		text: user
			# 		onMouseDown: (e)->
			# 			$('video').attr('src', activity.video.mp4)
			# 	# label2 = new LabelGroup
			# 	# 	orientation: "horizontal"
			# 	# 	text: user + "2"
			# 	# 	onMouseDown: (e)->
			# 	# 		$('video').attr('src', activity.video.mp4)

			# 	plot_container = new AlignmentGroup
			# 		name: "plot_container"
			# 		padding: 5
			# 		orientation: "vertical"
			# 		backgroundColor: "#F0F0F0"

			# 	if viz_settings.render_codes
			# 		code_plot = makePlot('codes', activity.video.mp4)
			# 		_.each activity.video.codes, (event)-> code_plot.plotEvent(event, activity.video.mp4)
			# 		plot_container.pushItem(code_plot)
				
			# 	# if viz_settings.render_iron_imu
			# 	# 	_.each activity.iron.imu, (sensor_data, k)->
			# 	# 		p = makePlot(k, activity.video.mp4)
			# 	# 		renderLine(sensor_data, p)
			# 	# 		plot_container.pushItem p

			# 	track.pushItem label
			# 	# track.pushItem label2
			# 	track.pushItem plot_container
			# 	track_window.pushItem track


			.ui.container
  .ui.segment.session
    .node
      .label
        %span Molly
      .panel
        .node
          .label
            %span Iron
          .panel
            .node
              .label
                %span Acc
              .panel.paper
                Stuff
            .node
              .label
                %span Gyro
              .panel.paper
                Stuff
            .node
              .label
                %span Mag
              .panel.paper
                Stuff

    .node
      .label
        %span Cesar
      .panel
        .node
          .label
            %span Iron
          .panel
            .node
              .label
                %span Acc
              .panel.paper
                Stuff
            .node
              .label
                %span Gyro
              .panel.paper
                Stuff
            .node
              .label
                %span Mag
              .panel.paper
                Stuff
        .node
          .label
            %span Env
          .panel
            .node
              .label
                %span Audio
              .panel.paper
                Stuff
            .node
              .label
                %span Codes
              .panel.paper
                Stuff
			