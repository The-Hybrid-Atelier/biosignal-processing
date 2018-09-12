# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
#= require moment
#= require paper
#= require jquery-ui/core
#= require jquery-ui/widget
#= require jquery-ui/position
#= require jquery-ui/widgets/mouse
#= require jquery-ui/widgets/draggable
#= require viz


$ ->
	window.env = new VizEnvironment
		ready: ()->
			scope = this
			@event_binding()
			@keybinding()
		event_binding: ()->
			scope = this
			$('.panel').draggable()
			@reposition_video()
			$(window).resize ()-> scope.reposition_video()
			$("canvas").on 'wheel', (e)->
				delta = e.originalEvent.deltaY
				pt = paper.view.viewToProject(new paper.Point(e.originalEvent.offsetX, e.originalEvent.offsetY))
				e = _.extend e, 
					point: pt
					delta: new paper.Point(e.originalEvent.deltaX, e.originalEvent.deltaY)
				hits = _.filter paper.project.getItems({data: {class: "Timeline"}}), (el)->
					return el.contains(pt)
				_.each hits, (el)-> el.emit "mousedrag", e

			$('video').on 'loadeddata', (e)->
				_.each Timeline.lines, (line)->
					line.ui.video = this
					line.ui.range.timestamp = Timeline.ts
					line.refresh()
		keybinding: ()->				
			paper.tool = new paper.Tool
				video: $('video')[0]
				onKeyDown: (e)->
					switch e.key
						when "space"
							if this.video.paused then this.video.play() else this.video.pause()
	
	grabber = new DataGrabber
		success: (data)-> 
			console.log data
			env.renderData(data)

		



	
	
	

