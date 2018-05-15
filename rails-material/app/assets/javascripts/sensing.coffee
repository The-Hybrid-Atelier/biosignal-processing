# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
#= require papaparse.min
#= require moment
$ ->
	# json = $.get "/data/data.csv", (file)->
	color_scheme = ["red","orange","yellow","olive","green","teal","blue","violet","purple","pink","brown","grey","black"]
	json = Papa.parse "/data/data.csv",
		download: true 
		header: true
		before: (file)->
			console.log "Reading", file
		error: (err, file)->
			alertify.error err.message, err.type, err.code, err.row
		complete: (results, file)->
			actors = _.unique(_.map results.data, (r)-> r.Code.split("\\")[1])
			actors = _.object _.map actors, (a, i)-> 
				[a, color_scheme[i]]
			console.log "ACTORS", actors

			results = _.groupBy results.data, (r)-> r["Document name"]

			results = _.mapObject results, (codes, k)->
				codes = _.map codes, (code)->
					start = moment(code.Begin, "HH:mm:ss.SSS", false)
					end = moment(code.End, "HH:mm:ss.SSS", false)
					code = code.Code.split("\\").slice(1)
					rtn = 
						actor: code[0] 
						sub_codes: code.slice(1)
						color: actors[code[0]] 
						start: start.valueOf()
						end: end.valueOf()
						duration: end.valueOf() - start.valueOf()
				min_time = _.min codes, (code)-> return code.start
				min_time = min_time.start
				# console.log "min_time", min_time
				codes = _.map codes, (code)->
					code.start = code.start - min_time
					code.end = code.end - min_time
					code

			console.log results