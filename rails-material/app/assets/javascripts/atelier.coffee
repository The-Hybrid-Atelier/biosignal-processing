class window.Atelier
    host: window.server_ip
    port: "8888"

    constructor: (@name, @route) ->
        scope = this
        console.log "Initializing", @name
        address = "ws://"+@host+":"+@port+"/"+@route
        @services = {}

        @socket = new WebSocket(address)
        @socket.binaryType = "blob"
        
        console.log "WEBSOCKET:", address

        @socket.onopen = (event)->
            console.log scope.name, "connected to", scope.route

        @socket.onmessage = (event)->
            task = JSON.parse(event.data)
            task.timestamp = parseInt(event.timeStamp)
            console.log "TRAFFIC", event#task, scope.name, _.keys(scope.services)
            # console.log "SERVICES", scope.services
            if scope.services.log
                scope.services.log(task)
            if task.to == scope.name
                # console.log "NAME MATCH"
                if scope.services[task.service]
                    # console.log "SERVICE MATCH"
                    scope.services[task.service](task, event)

        @socket.onerror = (event)->
            console.log "ERROR", event
            # alertify.error('An error occurred. Try refreshing the page and try again.')
            playSound(window.error_sound)
        @socket.onclose = (event)->
            console.log "CLOSED", event
            # alertify.error('We lost connection :(. Try refreshing the page and try again.')
            playSound(window.error_sound)
    addService: (name, callback)->
        @services[name] = callback
    send: (data)->
        if not data.from
            data = _.extend data, 
                from: @name
        try
            @socket.send(JSON.stringify(data))
        catch err
            msg = "We are having trouble connecting. Make sure you are on the right network."
            # alertify.error('<b>Whoops!</b></br>' + msg)
            playSound(window.error_sound)



    onerror: (e)->
        console.log "ERROR", event