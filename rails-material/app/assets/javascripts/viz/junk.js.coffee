
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
			