 @test_spiral: ()->
    junk = paper.project.getItems
      name: "spiral"
    _.each junk, (j)-> j.remove()
    @test_a()
    @test_b()
  @test_a: ()->
    prop = 
      traceWidth: 10
      traceInterval: 2

    boundary = new paper.Path.Circle
      name: "spiral"
      dashArray: [10, 4]
      strokeColor: "green"
      radius: 100
      position: paper.view.center
    boundary.segments[2].clearHandles()

    entry = new paper.Path.Circle
      name: "spiral"
      position: boundary.getPointAt(100)
      fillColor: "red"
      radius: prop.traceWidth/2
    exit = new paper.Path.Circle
      name: "spiral"
      position: boundary.getPointAt(100 + prop.traceWidth + prop.traceInterval)
      fillColor: "blue"
      radius: prop.traceWidth/2

    testA = _.extend prop, 
      name: "testA"
      boundary: boundary
      start: boundary.getPointAt(100)
      end: boundary.getPointAt(prop.traceWidth + prop.traceInterval)

    HeatSketch.spiral(testA)

   @test_b: ()->
    prop = 
      traceWidth: 10
      traceInterval: 2
    boundary2 = new paper.Path.Rectangle
      name: "spiral"
      dashArray: [10, 4]
      strokeColor: "green"
      size: [100, 200]
      position: paper.view.center.add(new paper.Point(200, 0))
    boundary2.segments[2].clearHandles()


    entry2 = new paper.Path.Circle
      name: "spiral"
      position: boundary2.getPointAt(0)
      fillColor: "red"
      radius: prop.traceWidth/2
    exit2 = new paper.Path.Circle
      name: "spiral"
      position: boundary2.getPointAt(prop.traceWidth + prop.traceInterval)
      fillColor: "blue"
      radius: prop.traceWidth/2
    
    testB = _.extend prop,
      name: "testB" 
      boundary: boundary2
      start: boundary2.getPointAt(100)
      end: boundary2.getPointAt(prop.traceWidth + prop.traceInterval)

    HeatSketch.spiral(testB)
  # END BEHAVIORS
        if i == 0
          nextStroke = shift_path(nextStroke, start)
          nextStroke.closed = false
          nextStroke.insert(0, start)



# spiralizePaths = (paths)->
    #   # SPIRAL ALGORITHM
    #   result = new paper.Path
    #     name: "spiral"
    #     strokeColor: "magenta"
    #     strokeWidth: 1
    #     strokeJoin: "round"
    #     strokeCap: "round"
        
    #   back_track = prop.traceWidth * 2 + prop.traceInterval * 2
    #   p = paths[0]
    #   p.closed = false
      
    #   nl = p.getNearestLocation(p.getPointAt(p.length - back_track))
    #   p.removeSegments(nl.segment.index)
    #   result.addSegments p.segments
    #   p.remove()

    #   _.each paths, (p, i)->
    #     if i == 0 then return

    #     p = paths[i]
    #     p.closed = false 

    #     attach = p.getNearestPoint(result.lastSegment.point)
    #     nl = p.getNearestLocation(attach)
    #     result.addSegments p.removeSegments(nl.segment.index)

    #     nl = p.getNearestLocation(p.getPointAt(p.length - back_track))

    #     if nl.segment.index == 0
    #       p.reverse()
    #       nl = p.getNearestLocation(p.getPointAt(p.length - back_track))
    #     console.log nl.segment.index
    #     p.removeSegments(nl.segment.index)
    #     result.addSegments p.segments
    #     p.remove()
    #   return result


# spiral.set
    #   strokeColor: "blue"
    #   strokeWidth: 2
    
    # # result.selected = true
    # result.remove()

    # # POWER/GROUND DECOMPOSITION
    # pl = result.clone()
    # result_path = null

    # circles = _.map _.range(0, result.length, (prop.traceWidth + prop.traceInterval)/3), (offset)->
    #   return new paper.Path.Circle
    #     name: "spiral"
    #     position: result.getPointAt(offset)
    #     fillColor: "orange"
    #     radius: (prop.traceWidth + prop.traceInterval)/2

    # firstPoint = null
    # result_path = new paper.Path
    #   fillColor: "red"
    #   lastLeft: null
    #   lastRight: null
    #   firstPoint: null
    #   init: (circle1, circle2)->
    #     ixts = circle1.getIntersections(circle2)
    #     @lastLeft = ixts[0].point
    #     firstPoint = ixts[0].point
    #     @lastLeft = ixts[0].point
    #     @lastRight = ixts[1].point
    #   addStrokePoint: (pt, i)->
    #     # if pt.getDistance(@lastLeft) > pt.getDistance(@lastRight) then @addRight(pt) else @addLeft(pt)
    #     distance_diff = Math.abs(pt.getDistance(@lastLeft) - pt.getDistance(@lastRight))

    #     if i == 0 then @addRight(pt) else @addLeft(pt)
    #     console.log pt.getDistance(@lastLeft) - pt.getDistance(@lastRight) 
    #   addRight: (pt)-> 
    #     @add(pt)
    #     @lastRight = pt
    #     new paper.Path.Circle
    #       radius: 1
    #       fillColor: "black"
    #       position: pt.clone()
    #   addLeft: (pt)-> 
    #     @insert(0, pt)
    #     @lastLeft = pt
    #     new paper.Path.Circle
    #       radius: 1
    #       fillColor: "yellow"
    #       position: pt.clone()
        
      

    # result_path.init(circles[0], circles[1])

    # _.each circles, (c, i)->
    #   if i == 0 then return

    #   prev = circles[i-1]
    #   ixts = prev.getIntersections(c)
    #   ixts = _.each ixts, (ixt, i)-> 
    #     result_path.addStrokePoint(ixt.point, i)
    # result_path.closed = true
    # r = result_path.unite(circles[circles.length - 1])
    # _.each circles, (c)-> 
    #   c.remove()

    # # console.log r
    # result_path.remove()
    # result_path = r
    # # r = result_path.unite(circles[circles.length-1])
    # # result_path.remove()
    # # result_path = r
    # result_path.set
    #   fillColor: null
    #   strokeColor: "gray"
    #   strokeWidth: 1
    #   strokeJoin: "round"
    #   strokeWidth: prop.traceWidth
    # result.dashArray = [10, 4]
    # result.strokeWidth = 1
    # result.remove()

    # result_path = shift_path(result_path, firstPoint)
   
    # result_path.closed = false

   
