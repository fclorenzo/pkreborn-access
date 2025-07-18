class Game_Player < Game_Character

  @mapevents = []
  @selected_event_index = -1
  @@lastSelectedSearchItem = -1
  @@lastSelectedSearchDestination = nil
  @@savedNode = nil
  @@savedMapId = -1
def announce_selected_event
  return if @selected_event_index == -1 || @mapevents[@selected_event_index].nil?
  
  event = @mapevents[@selected_event_index]
  tts(event.name) # Announce the event's name using TTS
end

def pathfind_to_selected_event
  return if @selected_event_index == -1 || @mapevents[@selected_event_index].nil?
  
  target_event = @mapevents[@selected_event_index]
  
  # Use the existing A* and instruction logic
  route = aStern(Node.new(@x, @y), Node.new(target_event.x, target_event.y))
  printInstruction(convertRouteToInstructions(route))
end

  def populate_event_list
  @mapevents = []
  for event in $game_map.events.values
    # We define an "interactable" event as one with a command list.
    # This filters out decorative events.
    if event.list && event.list.size > 1
      @mapevents.push(event)
    end
  end
  
  # Set the index to the first event, or -1 if the list is empty.
  @selected_event_index = @mapevents.empty? ? -1 : 0
end

  class MapEventForSearch
    attr_accessor :mapId, :event

    def initialize(paraMapId, paraEvent)
      @mapId = paraMapId
      @event = paraEvent
    end
  end

  class EventWithRelativeDirection
    attr_accessor :direction, :node

    def initialize(paraNode, paraDirection)
      @direction = paraDirection
      @node = paraNode
    end
  end

  class SearchTerm
    attr_accessor :searchTerm, :code

    def initialize(paraSearchTerm, paraCode = -1)
      @searchTerm = paraSearchTerm
      @code = paraCode
    end
  end

  class SearchEvent
    attr_accessor :searchTerms, :name, :range, :trigger, :array, :id

    def initialize(paraName, paraRange, paraTrigger, paraId, array = [])
      @name = paraName
      @range = paraRange
      @searchTerms = array
      @trigger = paraTrigger
      @array = array
      @id = paraId
    end
  end

  class MapWithPoint
    attr_accessor :map, :x, :y, :event, :eventArray
    @eventArray #All found events will be saved here
    def initialize(paraMap, paraX, paraY, paraEvent)
      @map = paraMap
      @x = paraX
      @y = paraY
      @event = paraEvent #TeleportEvent, which leads to map
    end
  end

  def pbEventAhead(x, y)
    if $game_system.map_interpreter.running?
      return nil
    end
    new_x = x + (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
    new_y = y + (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
    for event in $game_map.events.values
      if event.x == new_x and event.y == new_y
        if not event.jumping? and not event.over_trigger?
          return event
        end
      end
    end
    if $game_map.counter?(new_x, new_y)
      new_x += (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
      new_y += (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
      for event in $game_map.events.values
        if event.x == new_x and event.y == new_y
          if not event.jumping? and not event.over_trigger?
            return event
          end
        end
      end
    end
    return nil
  end

  def eventContains(event, searchEvent)
    #    Kernel.pbMessage(event.trigger.to_s + "==" + searchEvent.trigger.to_s)
    if event.list == nil || (event.list.length == 1 && event.list[0].code == 0) || searchEvent.searchTerms == nil
      return false
    end
    case searchEvent.id
    when 1 #Healing Spot
      for eventCommand in event.list
        if eventCommand.code == 314 #Code for healing all Pokemon
          return true
        end
      end
    when 2 #Merchant
      for eventCommand in event.list
        if eventCommand.code == 355 && (eventCommand.parameters[0].downcase.include? "pbPokemonMart".downcase) #Code for script and content of PokemonMarkt script
          return true
        end
      end
    when 3 #Teleport tile
      for eventCommand in event.list
        if eventCommand.code == 201 #Code for teleport
          return true
        end
      end
      return false
    when 4 #Clickable event
      return event.trigger == 0
    else
      Kernel.pbMessage("Error: Event is not handeled in the Method eventContains")
    end
    return false
  end

  def check_event_in_range(x, y, searchEvent, map = $game_map)
    #Kernel.pbMessage(x.to_s + ", " + y.to_s + ", " + searchEvent.range.to_s)
    eventsArray = []
    r = searchEvent.range.to_s == "completeMap" ? ($game_map.height < $game_map.width ? $game_map.width : $game_map.height) : searchEvent.range.to_i
    #Kernel.pbMessage(r.to_s)
    for event in map.events.values
      if event.x >= x - r && event.x <= x + r && event.y >= y - r && event.y <= y + r && eventContains(event, searchEvent)
        eventsArray.push(event)
      end
    end
    if searchEvent.name.downcase == "teleport tile"
      reduceEventsInLanes(eventsArray)
    end
    return eventsArray
  end

  def reduceEventsInLanes(eventsArray)
    eventsInLane = []
    for event in eventsArray
      neighbourNode = getNeighbour(event, eventsArray)
      if neighbourNode != nil
        deleteNodesInOneLane(event, neighbourNode, eventsArray)
      end
    end
  end

  def getEvent(x, y, eventsArray)
    for ea in eventsArray
      if ea.x == x && ea.y == y
        return ea
      end
    end
    return nil
  end

  def deleteNodesInOneLane(event, neighbourNode, eventsArray)
    nodesInLane = []
    eventDestination = nil
    for eventCommand in event.list
      if eventCommand.code == 201
        eventDestination = eventCommand.parameters[1]
      end
    end
    if event.x == neighbourNode.x #y-axis
      i = 1
      while true
        foundEvent = getEvent(event.x, event.y + i, eventsArray)
        if foundEvent == nil
          break
        end
        for eventCommand in foundEvent.list
          if eventCommand.parameters[1] == eventDestination
            eventsArray.delete(foundEvent)
            break
          end
        end
        i = i + 1
      end
      i = 1
      while true
        foundEvent = getEvent(event.x, event.y - i, eventsArray)
        if foundEvent == nil
          break
        end
        for eventCommand in foundEvent.list
          if eventCommand.parameters[1] == eventDestination
            eventsArray.delete(foundEvent)
            break
          end
        end
        i = i + 1
      end
    else
      #x-axis
      i = 1
      while true
        foundEvent = getEvent(event.x + i, event.y, eventsArray)
        if foundEvent == nil
          break
        end
        for eventCommand in foundEvent.list
          if eventCommand.parameters[1] == eventDestination
            eventsArray.delete(foundEvent)
            break
          end
        end
        i = i + 1
      end
      i = 1
      while true
        foundEvent = getEvent(event.x - i, event.y, eventsArray)
        if foundEvent == nil
          break
        end
        for eventCommand in foundEvent.list
          if eventCommand.parameters[1] == eventDestination
            eventsArray.delete(foundEvent)
            break
          end
        end
        i = i + 1
      end
    end
  end

  def getNeighbour(event, eventsArray)
    for currentEvent in eventsArray
      if (event.x - currentEvent.x).abs == 1 && event.y == currentEvent.y || (event.y - currentEvent.y).abs == 1 && event.x == currentEvent.x
        return currentEvent
      end
    end
    return nil
  end

  def isNeighbourWithMapWithEntryPointDataType(mapWithPoint, mapsWithPoints)
    for mwp in mapsWithPoints
      if (mapWithPoint.event.x - mwp.event.x).abs == 1 && mapWithPoint.event.y == mwp.event.y || (mapWithPoint.event.y - mwp.event.y).abs == 1 && mapWithPoint.event.x == mwp.event.x
        return true
      end
    end
  end

  def convertRouteToInstructions(route)
    if route.length == 0
      return []
    end
    instructions = []
    lastNode = Node.new(@x, @y)
    currentDirection = "none"
    # Kernel.pbMessage(route.length.to_s)
    for node in route
      if node == nil
        # Kernel.pbMessage("Node ist nil" + route.to_s)
      else
        #    Kernel.pbMessage("Node ist nicht nil " + node.x.to_s + ", " + node.y.to_s)
      end
      if lastNode == nil
        #Kernel.pbMessage("lastNode ist nil" + route.to_s)
      end
      direction = findRelativeDirection(lastNode, node)
      if (currentDirection == direction)
        instructions[-1].steps = instructions[-1].steps + 1
      else
        instructions.push(Instruction.new(direction))
        currentDirection = direction
      end
      lastNode = node
    end
    return instructions
  end

  def findRelativeDirection(lastNode, node)
    if lastNode.x == node.x
      if lastNode.y < node.y
        return "down"
      else
        return "up"
      end
    else
      if lastNode.x < node.x
        return "right"
      else
        return "left"
      end
    end
    Kernel.pbMessage("Error")
    return "Error"
  end

  def addAdjacentNode(route, direction)
    case direction
    when 2
      route = route.push(Node.new(route[-1].x, route[-1].y - 1))
    when 4
      route = route.push(Node.new(route[-1].x + 1, route[-1].y))
    when 6
      route = route.push(Node.new(route[-1].x - 1, route[-1].y))
    when 8
      route = route.push(Node.new(route[-1].x, route[-1].y + 1))
    else
      Kernel.pbMessage("Error: Something went horrible wrong")
    end
  end

  def getMatchingConnectedMapsWithEntryPoint(map, searchEvent)
    mapsWithEntryPoint = []
    result = []
    tempEventArray = []
    for event in map.events.values
      if event.list == nil
        next
      end
      for eventCommand in event.list
        if eventCommand.code == 201 #Code for teleport
          tempEventArray.push(event)
        end
      end
    end
    reduceEventsInLanes(tempEventArray)
    for event in tempEventArray
      for eventCommand in event.list
        if eventCommand.code == 201 #Code for teleport
          mapsWithEntryPoint.push(MapWithPoint.new($MapFactory.getMap(eventCommand.parameters[1]), eventCommand.parameters[2], eventCommand.parameters[3], event))
        end
      end
    end
    for mwep in mapsWithEntryPoint
      eventArray = check_event_in_range(mwep.x, mwep.y, searchEvent, mwep.map)
      if eventArray.length > 0
        mwep.eventArray = eventArray
        result.push(mwep)
      end
    end
    return result
  end

  def getSaleTilesOfNPC(event, map = $game_map)
    possibleTiles = []
    if !$MapFactory.isPassable?(map.map_id, event.x, event.y + 1) && $MapFactory.isPassable?(map.map_id, event.x, event.y + 2)
      possibleTiles.push(EventWithRelativeDirection.new(Node.new(event.x, event.y + 2), 2))
    end
    if !$MapFactory.isPassable?(map.map_id, event.x - 1, event.y) && $MapFactory.isPassable?(map.map_id, event.x - 2, event.y)
      possibleTiles.push(EventWithRelativeDirection.new(Node.new(event.x - 2, event.y), 4))
    end
    if !$MapFactory.isPassable?(map.map_id, event.x + 1, event.y) && $MapFactory.isPassable?(map.map_id, event.x + 2, event.y)
      possibleTiles.push(EventWithRelativeDirection.new(Node.new(event.x + 2, event.y), 6))
    end
    if !$MapFactory.isPassable?(map.map_id, event.x, event.y - 1) && $MapFactory.isPassable?(map.map_id, event.x, event.y - 2)
      possibleTiles.push(EventWithRelativeDirection.new(Node.new(event.x, event.y - 2), 8))
    end
    return possibleTiles
  end

  def searchEvent()

    # List of available searchable event categories
    searchableEvents = [
        SearchEvent.new("Last selected category", nil, nil, 0),
        SearchEvent.new("Healing spot", "completeMap", "0", 1),
        SearchEvent.new("Merchant", "completeMap", "0", 2),
        SearchEvent.new("Teleport tile", "completeMap", "1", 3),
        #SearchEvent.new("Clickable event", 5, "0", 4),
        SearchEvent.new("Clickable event", "completeMap", "0", 4), # Search clickable events on the entire map
        SearchEvent.new("Save current coordinates", nil, nil, 5),
        SearchEvent.new("Load saved coordinates", nil, nil, 6)
    ]

    # Build choice list string for the message window
    s = "5,-1"
    for searchableEvent in searchableEvents
        s = s + "," + searchableEvent.name.to_s
    end
    Kernel.pbMessage("Please select a destination.\\ch[" + s + "]")

    input = $game_variables[5] # Get selected index from the choice

    # Cancelled
    if input == -1
        return

    # Repeat last selected category
    elsif input == 0
        if @@lastSelectedSearchItem == -1
            Kernel.pbMessage("No prior selected destination exists.")
            return
        else
            input = @@lastSelectedSearchItem
        end

    # Save current coordinates
    elsif input == 5
        @@savedNode = Node.new(@x, @y)
        @@savedMapId = $game_map.map_id
        Kernel.pbMessage("Saved.")
        return
    end

    # Searchable event categories that require processing
    if input == 1 || input == 2 || input == 3 || input == 4
        eventsArray = check_event_in_range(@x, @y, searchableEvents[input])

        case input
        when 1, 2 # Healing Spot & Merchant
            mapsWithEntryPoint = getMatchingConnectedMapsWithEntryPoint($game_map, searchableEvents[input])

            # Count all search results including teleport-connected maps
            amountSearchResults = 0
            for mwep in mapsWithEntryPoint
                amountSearchResults += mwep.eventArray.length
            end
            Kernel.pbMessage((eventsArray.length + amountSearchResults).to_s + ' ' + searchableEvents[input].name.to_s + " detected.")

            # No results found
            if (eventsArray.length + amountSearchResults) == 0
                return

            # One result found
            elsif (eventsArray.length + amountSearchResults) == 1
                if eventsArray.length == 1
                    # Event is on current map
                    route = searchToNearestEvent(eventsArray)
                    direction = 0
                    if route.length == 0
                        possibleTargets = getSaleTilesOfNPC(eventsArray[0])
                        for pt in possibleTargets
                            route = aStern(Node.new(@x, @y), Node.new(pt.node.x, pt.node.y))
                            if route.length != 0
                                direction = pt.direction
                                break
                            end
                        end
                    end
                    if route.length == 0
                        Kernel.pbMessage("No route to destination could be found.")
                    else
                        addAdjacentNode(route, direction) if direction != 0
                        printInstruction(convertRouteToInstructions(route))
                    end
                else
                    # Event is on a different map, follow teleport chain
                    firstRoute = aStern(Node.new(@x, @y), Node.new(mapsWithEntryPoint[0].event.x, mapsWithEntryPoint[0].event.y))
                    secondRoute = aStern(Node.new(mapsWithEntryPoint[0].x, mapsWithEntryPoint[0].y),
                                         Node.new(mapsWithEntryPoint[0].eventArray[0].x, mapsWithEntryPoint[0].eventArray[0].y),
                                         mapsWithEntryPoint[0].map)
                    direction = 0
                    if secondRoute.length == 0
                        possibleTargets = getSaleTilesOfNPC(mapsWithEntryPoint[0].eventArray[0], mapsWithEntryPoint[0].map)
                        for pt in possibleTargets
                            secondRoute = aStern(Node.new(mapsWithEntryPoint[0].x, mapsWithEntryPoint[0].y),
                                                 Node.new(pt.node.x, pt.node.y), mapsWithEntryPoint[0].map)
                            if secondRoute.length != 0
                                direction = pt.direction
                                break
                            end
                        end
                    end
                    if firstRoute.length == 0 || secondRoute.length == 0
                        Kernel.pbMessage("No route to destination could be found.")
                    else
                        route = firstRoute + secondRoute
                        addAdjacentNode(route, direction) if direction != 0
                        printInstruction(convertRouteToInstructions(route))
                    end
                end

            # Multiple matching events, let player choose
            elsif (eventsArray.length + amountSearchResults) > 1
                s = "5,-1"
                for event in eventsArray
                    s += "," + $game_map.name + " (" + event.x.to_s + "; " + event.y.to_s + ")"
                end
                for mwep in mapsWithEntryPoint
                    for event in mwep.eventArray
                        s += "," + mwep.map.name + " (" + event.x.to_s + "; " + event.y.to_s + ")"
                    end
                end
                Kernel.pbMessage("Please select a destination. Your current location is " + $game_map.name + ".\\ch[" + s + "]")
                input2 = $game_variables[5]

                # Handle second choice
                if input2 == -1
                    return
                elsif input2 < eventsArray.length
                    # Selected event from current map
                    route = searchToNearestEvent(eventsArray[input2, 1])
                    direction = 0
                    if route.length == 0
                        possibleTargets = getSaleTilesOfNPC(eventsArray[input2])
                        for pt in possibleTargets
                            route = aStern(Node.new(@x, @y), Node.new(pt.node.x, pt.node.y))
                            if route.length != 0
                                direction = pt.direction
                                break
                            end
                        end
                    end
                    if route.length == 0
                        Kernel.pbMessage("No route to destination could be found.")
                    else
                        addAdjacentNode(route, direction) if direction != 0
                        printInstruction(convertRouteToInstructions(route))
                    end
                else
                    # Selected event from other map
                    input2 -= eventsArray.length
                    inputMwep = nil
                    for mwep in mapsWithEntryPoint
                        if input2 < mwep.eventArray.length
                            inputMwep = mwep
                            break
                        end
                        input2 -= mwep.eventArray.length
                    end
                    return if inputMwep.nil?

                    firstRoute = aStern(Node.new(@x, @y), Node.new(inputMwep.event.x, inputMwep.event.y))
                    secondRoute = aStern(Node.new(inputMwep.x, inputMwep.y),
                                         Node.new(inputMwep.eventArray[input2].x, inputMwep.eventArray[input2].y),
                                         inputMwep.map)
                    direction = 0
                    if secondRoute.length == 0
                        possibleTargets = getSaleTilesOfNPC(inputMwep.eventArray[input2], inputMwep.map)
                        for pt in possibleTargets
                            secondRoute = aStern(Node.new(inputMwep.x, inputMwep.y),
                                                 Node.new(pt.node.x, pt.node.y), inputMwep.map)
                            if secondRoute.length != 0
                                direction = pt.direction
                                break
                            end
                        end
                    end
                    if firstRoute.length == 0 || secondRoute.length == 0
                        Kernel.pbMessage("No route to destination could be found.")
                    else
                        route = firstRoute + secondRoute
                        addAdjacentNode(route, direction) if direction != 0
                        printInstruction(convertRouteToInstructions(route))
                    end
                end
            end

        when 3 # Teleport Tiles
            # Remove unreachable events
            eventsArray.reject! { |event| aStern(Node.new(@x, @y), Node.new(event.x, event.y)).length == 0 }
            Kernel.pbMessage(eventsArray.length.to_s + ' ' + searchableEvents[input].name.to_s + " detected.")

            if eventsArray.length == 0
                return
            elsif eventsArray.length == 1
                printInstruction(convertRouteToInstructions(aStern(Node.new(@x, @y), Node.new(eventsArray[0].x, eventsArray[0].y))))
            else
                s = "5,-1,Nearest destination"
                for event in eventsArray
                    teleportDestination = ""
                    for eventCommand in event.list
                        if eventCommand.code == 201
                            teleportDestination = $MapFactory.getMap(eventCommand.parameters[1]).name
                            break
                        end
                    end
                    s += "," + teleportDestination + " (" + event.x.to_s + "; " + event.y.to_s + ")"
                end
                Kernel.pbMessage("Please select a destination. Your current location is " + $game_map.name + ".\\ch[" + s + "]")
                input2 = $game_variables[5]
                if input2 == -1
                    return
                elsif input2 == 0
                    printInstruction(convertRouteToInstructions(searchToNearestEvent(eventsArray)))
                else
                    printInstruction(convertRouteToInstructions(searchToNearestEvent(eventsArray[input2 - 1, 1])))
                end
            end

        when 4 # Clickable Events
            Kernel.pbMessage(eventsArray.length.to_s + ' ' + searchableEvents[input].name.to_s + " detected.")
            if eventsArray.length == 0
                return
            elsif eventsArray.length == 1
                printInstruction(convertRouteToInstructions(aStern(Node.new(@x, @y), Node.new(eventsArray[0].x, eventsArray[0].y))))
            else
                s = "5,-1,Nearest destination"
                for event in eventsArray
                    s += ",(" + event.x.to_s + "; " + event.y.to_s + ")"
                end
                Kernel.pbMessage("Please select a destination.\\ch[" + s + "]")
                input2 = $game_variables[5]
                if input2 == -1
                    return
                elsif input2 == 0
                    printInstruction(convertRouteToInstructions(searchToNearestEvent(eventsArray)))
                else
                    printInstruction(convertRouteToInstructions(searchToNearestEvent(eventsArray[input2 - 1, 1])))
                end
            end

        else
            Kernel.pbMessage("Error: Missing case in method searchEvent")
        end

        @@lastSelectedSearchItem = input
        return
    elsif input == 6
        # Load coordinates
        @@lastSelectedSearchItem = input
        if @@savedNode == nil
            Kernel.pbMessage("No coordinates have been saved")
            return
        end
        if @@savedMapId != $game_map.map_id
            Kernel.pbMessage("Previous saved coordinates are not in current map section")
            return
        else
            printInstruction(convertRouteToInstructions(aStern(Node.new(@x, @y), @@savedNode)))
        end

    else
        Kernel.pbMessage("Error: Missing number in method searchEvent cases")
    end
    @@lastSelectedSearchItem = input
    return
end

  def nearestEvent(eventArray, x = @x, y = @y)
    minDistance = -1
    minEvent = nil
    for event in eventArray
      distance = distance(x, y, event.x, event.y)
      if (minDistance < 0 || distance < minDistance)
        minDistance = distance
        minEvent = event
      end
    end
    return minEvent
  end

  def printInstruction(instructions)
    if instructions.length == 0
      tts("No route to destination could be found.")
      return
    end
    s = ""
    for instruction in instructions
      #     file.write(instruction.steps.to_s + ", " + instruction.direction.to_s + "\n")
      #s = s + instruction.steps.to_s + (instruction.steps == 1 ? " step " : " steps ") + instruction.direction.to_s + ", "
      s = s + instruction.steps.to_s + " " + instruction.direction.to_s + ", "
    end
    if s.length > 2
      s = s[0..-3]
    end
    s = s + "."
    tts(s)
  end

  def distance(sx, sy, tx, ty)
    return Math.sqrt((sx - tx) * (sx - tx) + (sy - ty) * (sy - ty))
  end

  def searchToNearestEvent(eventArray)
    minEvent = nearestEvent(eventArray)
    #file = File.open("testLog.txt", "a")
    #Kernel.pbMessage("Event wird gesucht: " + minEvent.id.to_s)
    route = aStern(Node.new(@x, @y), Node.new(minEvent.x, minEvent.y))
    return route
  end

  class Node
    attr_accessor :x, :y, :gCost, :hCost, :parent
    @parent
    @gCost
    @hCost

    def initialize(paraX, paraY)
      @x = paraX
      @y = paraY
      @parent = "none"
    end

    def equals (node)
      return @x == node.x && @y == node.y
    end

    def fCost
      return @gCost + @hCost
    end
  end

  class Instruction
    attr_accessor :steps, :direction
    @steps
    @direction

    def initialize(paraDirection)
      @steps = 1
      @direction = paraDirection
    end
  end

  def distanceNode(node1, node2)
    return distance(node1.x, node1.y, node2.x, node2.y)
  end

  def aStern(start, target, map = $game_map)
    iterations = 0;
    start.gCost = 0

    d = 0
    isTargetPassable = isTargetPassable(target, map)
    targetDirection = getTargetDirection(target, map)
    originalTarget = nil
    if !isTargetPassable && targetDirection != -1
      originalTarget = target
      case targetDirection
      when 2
        target = Node.new(target.x, target.y - 1)
      when 4
        target = Node.new(target.x + 1, target.y)
      when 6
        target = Node.new(target.x - 1, target.y)
      when 8
        target = Node.new(target.x, target.y + 1)
      else
        Kernel.pbMessage("Error: Something went wrong in aStern begin.")
      end
    end

    start.hCost = distanceNode(start, target)
    openSet = []
    closedSet = []
    openSet.push(start)
    while openSet.length > 0 do
      iterations = iterations + 1
      if iterations > 400
        return []
      end
      s = ""
      for node in openSet
        s = s + node.x.to_s + ", " + node.y.to_s + ";"
      end
      currentNode = openSet[0]
      i = 1
      while i < openSet.length do
        if (openSet[i].fCost < currentNode.fCost || openSet[i].fCost == currentNode.fCost && openSet[i].hCost < currentNode.hCost)
          currentNode = openSet[i]
        end
        i = i + 1
      end

      openSet.delete(currentNode)
      closedSet.push(currentNode)
      #   Kernel.pbMessage("current Node is " + currentNode.x.to_s + ", " + currentNode.y.to_s)
      s = ""
      for node in openSet
        s = s + node.x.to_s + ", " + node.y.to_s + ";"
      end

      if currentNode.equals(target)
        return retracePath(start, currentNode, isTargetPassable, targetDirection, originalTarget)
      end

      neighbours = getNeighbours(currentNode, target, isTargetPassable, targetDirection, map)
      for neighbour in neighbours
        if nodeInSet(neighbour, closedSet)
          next
        end
        neighbourIndex = getNodeIndexInSet(neighbour, openSet)
        newMovementCostToNeighbour = 2
        if currentNode.parent != "none"
          xDifNeighbour = neighbour.x - currentNode.x
          yDifNeighbour = neighbour.y - currentNode.y
          xDifParent = currentNode.x - currentNode.parent.x
          yDifParent = currentNode.y - currentNode.parent.y
          if xDifNeighbour == xDifParent && yDifNeighbour == yDifParent
            newMovementCostToNeighbour = currentNode.gCost + 1
          else
            newMovementCostToNeighbour = currentNode.gCost + 1.5
          end
        else
          newMovementCostToNeighbour = 1.5
        end

        if neighbourIndex > -1 && newMovementCostToNeighbour < openSet[neighbourIndex].gCost
          openSet[neighbourIndex].gCost = newMovementCostToNeighbour
          openSet[neighbourIndex].hCost = distanceNode(openSet[neighbourIndex], target)
          openSet[neighbourIndex].parent = currentNode
        end
        if (neighbourIndex == -1)
          neighbour.gCost = newMovementCostToNeighbour
          neighbour.hCost = distanceNode(neighbour, target)
          neighbour.parent = currentNode
          openSet.push(neighbour)
        end
      end
    end
    return []
  end

  def retracePath(start, target, isTargetPassable, targetDirection, originalTarget)
    path = []
    currentNode = target
    while !currentNode.equals(start) do
      path.push(currentNode)
      currentNode = currentNode.parent
    end
    path = path.reverse

    if isTargetPassable && targetDirection != -1 #Signs without filling an event
      case targetDirection
      when 2
        path.push(Node.new(target.x, target.y + 1))
      when 4
        path.push(Node.new(target.x - 1, target.y))
      when 6
        path.push(Node.new(target.x + 1, target.y))
      when 8
        path.push(Node.new(target.x, target.y - 1))
      else
        Kernel.pbMessage("Error: Something went wrong in aStern()")
      end
    end
    if !isTargetPassable && targetDirection != -1 #immovable objects, which require the operation from a specific direction
      path.push(originalTarget)
    end
    return path
  end

  def getNodeIndexInSet(neighbour, set)
    i = 0
    while i < set.length do
      if set[i].equals(neighbour)
        return i
      end
      i = i + 1
    end
    return -1
  end

  def nodeInSet(neighbour, set)
    for node in set
      if node.equals(neighbour)
        return true
      end
    end
    return false
  end

  def getNeighbours(node, target, isTargetPassable, targetDirection, map)
    neighbours = []
    if isTargetPassable || targetDirection != -1
      if passableEx?(node.x, node.y, 2, false, map)
        neighbours.push(Node.new(node.x, node.y + 1))
      end
      if passableEx?(node.x, node.y, 4, false, map)
        neighbours.push(Node.new(node.x - 1, node.y))
      end
      if passableEx?(node.x, node.y, 6, false, map)
        neighbours.push(Node.new(node.x + 1, node.y))
      end
      if passableEx?(node.x, node.y, 8, false, map)
        neighbours.push(Node.new(node.x, node.y - 1))
      end
    else
      if passableEx?(node.x, node.y, 2, false, map) || target.equals(Node.new(node.x, node.y + 1))
        neighbours.push(Node.new(node.x, node.y + 1))
      end
      if passableEx?(node.x, node.y, 4, false, map) || target.equals(Node.new(node.x - 1, node.y))
        neighbours.push(Node.new(node.x - 1, node.y))
      end
      if passableEx?(node.x, node.y, 6, false, map) || target.equals(Node.new(node.x + 1, node.y))
        neighbours.push(Node.new(node.x + 1, node.y))
      end
      if passableEx?(node.x, node.y, 8, false, map) || target.equals(Node.new(node.x, node.y - 1))
        neighbours.push(Node.new(node.x, node.y - 1))
      end
    end
    return neighbours
  end

  def getTargetDirection(target, map)
    for event in map.events.values
      if event.x != target.x || event.y != target.y
        next
      end
      for eventCommand in event.list
        if eventCommand.code.to_s == 111.to_s
          if eventCommand.parameters[0] != nil && eventCommand.parameters[1] != nil && eventCommand.parameters[0].to_s == 6.to_s && eventCommand.parameters[1].to_s == -1.to_s
            return eventCommand.parameters[2]
          end
        end
      end
    end
    return -1
  end

  def isTargetPassable(target, map = $game_map)
    return passableEx?(target.x, target.y - 1, 2, false, map) || passableEx?(target.x + 1, target.y, 4, false, map) || passableEx?(target.x - 1, target.y, 6, false, map) || passableEx?(target.x, target.y + 1, 8, false, map)
  end

  def update
    # Remember whether or not moving in local variables
    last_moving = moving?
    # If moving, event running, move route forcing, and message window
    # display are all not occurring
    dir=Input.dir4
    unless moving? or $game_system.map_interpreter.running? or
           @move_route_forcing or $game_temp.message_window_showing or
           $PokemonTemp.miniupdate
      # Move player in the direction the directional button is being pressed
      if dir==@lastdir && Graphics.frame_count-@lastdirframe>2
        case dir
          when 2
            move_down
          when 4
            move_left
          when 6
            move_right
          when 8
            move_up
        end
      elsif dir!=@lastdir
        case dir
          when 2
            turn_down
          when 4
            turn_left
          when 6
            turn_right
          when 8
            turn_up
        end
      end
    end
    $PokemonTemp.dependentEvents.updateDependentEvents
    if dir!=@lastdir
      @lastdirframe=Graphics.frame_count
    end
    @lastdir=dir
    # Remember coordinates in local variables
    last_real_x = @real_x
    last_real_y = @real_y
    super
    center_x = (Graphics.width/2 - Game_Map::TILEWIDTH/2) * Game_Map::XSUBPIXEL   # Center screen x-coordinate * 4
    center_y = (Graphics.height/2 - Game_Map::TILEHEIGHT/2) * Game_Map::YSUBPIXEL   # Center screen y-coordinate * 4
    # If character moves down and is positioned lower than the center
    # of the screen
    if @real_y > last_real_y and @real_y - $game_map.display_y > center_y
      # Scroll map down
      $game_map.scroll_down(@real_y - last_real_y)
    end
    # If character moves left and is positioned more left on-screen than
    # center
    if @real_x < last_real_x and @real_x - $game_map.display_x < center_x
      # Scroll map left
      $game_map.scroll_left(last_real_x - @real_x)
    end
    # If character moves right and is positioned more right on-screen than
    # center
    if @real_x > last_real_x and @real_x - $game_map.display_x > center_x
      # Scroll map right
      $game_map.scroll_right(@real_x - last_real_x)
    end
    # If character moves up and is positioned higher than the center
    # of the screen
    if @real_y < last_real_y and @real_y - $game_map.display_y < center_y
      # Scroll map up
      $game_map.scroll_up(last_real_y - @real_y)
    end
    # Count down the time between allowed bump sounds
    @bump_se-=1 if @bump_se && @bump_se>0
    # If not moving
    unless moving?
      if Input.trigger?(Input::F6)
      populate_event_list
      tts('Map list refreshed')
    end

        # Make sure we have events to cycle through
    if !@mapevents.nil? && !@mapevents.empty?
      
      # Cycle to the PREVIOUS event (J)
      if Input.triggerex?(0x4A)
        @selected_event_index -= 1
        if @selected_event_index < 0
          @selected_event_index = @mapevents.size - 1 # Wrap around
        end
        announce_selected_event
      end

      # Cycle to the NEXT event (L)
      if Input.triggerex?(0x4C)
        @selected_event_index += 1
        if @selected_event_index >= @mapevents.size
          @selected_event_index = 0 # Wrap around
        end
        announce_selected_event
      end
      
      # ANNOUNCE the current event (K)
      if Input.triggerex?(0x4B)
        announce_selected_event
      end
      
      # PATHFIND to the current event
      if Input.triggerex?(0x50)
        pathfind_to_selected_event
      end
    end
      # If player was moving last time
      if last_moving
        $PokemonTemp.dependentEvents.pbTurnDependentEvents
        result = pbCheckEventTriggerFromDistance([2])
        # Event determinant is via touch of same position event
        result |= check_event_trigger_here([1,2])
        # If event which started does not exist
        Kernel.pbOnStepTaken(result) # *Added function call
      end
      # If C button was pressed
      if Input.trigger?(Input::C) && !$PokemonTemp.miniupdate
        # Same position and front event determinant
        check_event_trigger_here([0])
        check_event_trigger_there([0,2]) # *Modified to prevent unnecessary triggers
      end
    end
  end
end

class Game_Character
  def passableEx?(x, y, d, strict = false, map = self.map)
    new_x = x + (d == 6 ? 1 : d == 4 ? -1 : 0)
    new_y = y + (d == 2 ? 1 : d == 8 ? -1 : 0)
    return false unless map.valid?(new_x, new_y)
    return true if @through
    if strict
      return false unless map.passableStrict?(x, y, d, self)
      return false unless map.passableStrict?(new_x, new_y, 10 - d, self)
    else
      return false unless map.passable?(x, y, d, self)
      return false unless map.passable?(new_x, new_y, 10 - d, self)
    end
    for event in map.events.values
      if event.x == new_x and event.y == new_y
        unless event.through
          return false if self != $game_player || event.character_name != ""
        end
      end
    end
    if $game_player.x == new_x and $game_player.y == new_y
      unless $game_player.through
        return false if @character_name != ""
      end
    end
    return true
  end
end

# Accessible Summary Screen Functions
def pbDisplayBSTData(pkmn,defaultMoveID=0)
  cmdwin=pbListWindow([],200)
  commands=[]
  moveDefault=0
  dexentity=$cache.pkmn[pkmn.species]
  name = dexentity.forms[pkmn.form]
  singleformoverride=false
  if !name
    name="Base Form"
    singleformoverride=true
  end

  commands.push("Species : #{dexentity.pokemonData[dexentity.forms[0]].name}")
  commands.push("Dex n° : #{dexentity.pokemonData[dexentity.forms[0]].dexnum}")
  commands.push("Form : #{name}")

  if pkmn.form==0 || singleformoverride
    typing=""
    typing+="#{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type1)}"
    
    if dexentity.pokemonData[dexentity.forms[0]].Type2!=dexentity.pokemonData[dexentity.forms[0]].Type1 && !(dexentity.pokemonData[dexentity.forms[0]].Type2.nil?)
      typing+=" / #{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type2)}"
    end
  else
    type1changed=true
    type2changed=true
    typing=""
    if !dexentity.pokemonData[dexentity.forms[pkmn.form]].Type1.nil?
      typing+="#{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type1)}"
    end
    if typing==""
      type1changed=false
    end
    
    if dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2!=dexentity.pokemonData[dexentity.forms[pkmn.form]].Type1 && !(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2.nil?)
      typing+=" / #{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2)}"
    end
    if typing==""
      type2changed=false
    end
    if !type1changed && !type2changed
      typing=""
      typing+="#{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type1)}"
      if dexentity.pokemonData[dexentity.forms[0]].Type2!=dexentity.pokemonData[dexentity.forms[0]].Type1 && !(dexentity.pokemonData[dexentity.forms[0]].Type2.nil?)
        typing+=" / #{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type2)}"
      end
    end
    if !type1changed && type2changed
      typing=""
      typing+="#{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type1)}"
      if dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2!=dexentity.pokemonData[dexentity.forms[pkmn.form]].Type1 && !(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2.nil?)
        typing+=" / #{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2)}"
      end
    end
    if dexentity.pokemonData[dexentity.forms[0]].name=="Arceus" || dexentity.pokemonData[dexentity.forms[0]].name=="Silvally"
      typing=""
      typing+="#{dexentity.forms[pkmn.form]}"
      if dexentity.pokemonData[dexentity.forms[0]].name=="Arceus"
        typing+=" Plate"
      end
      if dexentity.pokemonData[dexentity.forms[0]].name=="Silvally"
        typing+=" Memory"
      end
    end
  end
  
  commands.push("#{typing}")
  commands.push(" ")
  bst=0
  bsstat=[]
  if pkmn.form==0 || singleformoverride
    bsstat=dexentity.pokemonData[dexentity.forms[0]].BaseStats
  else
    bsstat=dexentity.pokemonData[dexentity.forms[pkmn.form]].BaseStats
    if bsstat.nil?
      bsstat=dexentity.pokemonData[dexentity.forms[0]].BaseStats
    end
  end

  for i in 0..5
    bst=bst+bsstat[i]
  end
  commands.push("HP : #{bsstat[0]}")
  commands.push("Atk : #{bsstat[1]}")
  commands.push("Def : #{bsstat[2]}")
  commands.push("SpA : #{bsstat[3]}")
  commands.push("SpD : #{bsstat[4]}")
  commands.push("Spe : #{bsstat[5]}")	
  commands.push("BST : #{bst}")	
  
  ablist=pkmn.getAbilityList
  abilities="#{getAbilityName(ablist[0])}"
  abcount=0
  for ab in ablist
    if abcount>0
      abilities+=" / #{getAbilityName(ablist[abcount])}"
    end
    abcount=abcount+1
  end
  commands.push(" ")
  commands.push("Abilities : #{abilities}")	

  realcommands=[]
  for command in commands
    realcommands.push(_ISPRINTF("{1:s}",command))
  end
  pbCommands2(cmdwin,realcommands,-1,0,false) 
  cmdwin.dispose
  return 0
end

def torDisplayPokemonDetails(pkmn,defaultMoveID=0)
  cmdwin=pbListWindow([],500)
  commands=[]
  dexentity=$cache.pkmn[pkmn.species]
  name = dexentity.forms[pkmn.form]
  singleformoverride=false
  if !name
    name="Base Form"
    singleformoverride=true
  end

  if pkmn.form==0 || singleformoverride
    typing=""
    typing+="#{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type1)}"
    
    if dexentity.pokemonData[dexentity.forms[0]].Type2!=dexentity.pokemonData[dexentity.forms[0]].Type1 && !(dexentity.pokemonData[dexentity.forms[0]].Type2.nil?)
      typing+=" / #{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type2)}"
    end
  else
    type1changed=true
    type2changed=true
    typing=""
    if !dexentity.pokemonData[dexentity.forms[pkmn.form]].Type1.nil?
      typing+="#{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type1)}"
    end
    if typing==""
      type1changed=false
    end
    
    if dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2!=dexentity.pokemonData[dexentity.forms[pkmn.form]].Type1 && !(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2.nil?)
      typing+=" / #{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2)}"
    end
    if typing==""
      type2changed=false
    end
    if !type1changed && !type2changed
      typing=""
      typing+="#{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type1)}"
      if dexentity.pokemonData[dexentity.forms[0]].Type2!=dexentity.pokemonData[dexentity.forms[0]].Type1 && !(dexentity.pokemonData[dexentity.forms[0]].Type2.nil?)
        typing+=" / #{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type2)}"
      end
    end
    if !type1changed && type2changed
      typing=""
      typing+="#{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[0]].Type1)}"
      if dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2!=dexentity.pokemonData[dexentity.forms[pkmn.form]].Type1 && !(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2.nil?)
        typing+=" / #{torDeCapsTypings(dexentity.pokemonData[dexentity.forms[pkmn.form]].Type2)}"
      end
    end
    if dexentity.pokemonData[dexentity.forms[0]].name=="Arceus" || dexentity.pokemonData[dexentity.forms[0]].name=="Silvally"
      typing=""
      typing+="#{dexentity.forms[pkmn.form]}"
      if dexentity.pokemonData[dexentity.forms[0]].name=="Arceus"
        typing+=" Plate"
      end
      if dexentity.pokemonData[dexentity.forms[0]].name=="Silvally"
        typing+=" Memory"
      end
    end
  end
  
  commands.push("#{dexentity.pokemonData[dexentity.forms[0]].name} - #{typing}")
  remexp=PBExp.startExperience(pkmn.level+1,pkmn.growthrate)-pkmn.exp
  commands.push("Level #{pkmn.level} - #{remexp} experience to next level")
  itemname="No Held Item"
  if pkmn.item
    itemname="Held item : #{$cache.items[pkmn.item].name}"
  end  
  commands.push("#{itemname}")  
  commands.push("Ability : #{getAbilityName(pkmn.ability)} - Nature : #{torDeCapsNature(pkmn.nature)}")	
  commands.push("HP : #{pkmn.iv[0]} IV - #{pkmn.ev[0]} EV - #{pkmn.totalhp} total")
  commands.push("Attack : #{pkmn.iv[1]} IV - #{pkmn.ev[1]} EV - #{pkmn.attack} total")
  commands.push("Defense : #{pkmn.iv[2]} IV - #{pkmn.ev[2]} EV - #{pkmn.defense} total")
  commands.push("Special Attack : #{pkmn.iv[3]} IV - #{pkmn.ev[3]} EV - #{pkmn.spatk} total")
  commands.push("Special Defense : #{pkmn.iv[4]} IV - #{pkmn.ev[4]} EV - #{pkmn.spdef} total")
  commands.push("Speed : #{pkmn.iv[5]} IV - #{pkmn.ev[5]} EV - #{pkmn.speed} total")	
  
  movecounter=1
  for move in pkmn.moves
    if move
      commands.push("Move #{movecounter} - #{$cache.moves[move.move].name}")	
      movecounter=movecounter+1
    end
  end

  realcommands=[]
  for command in commands
    realcommands.push(_ISPRINTF("{1:s}",command))
  end
  pbCommands2(cmdwin,realcommands,-1,0,true) 
  cmdwin.dispose
  return 0
end

def torDeCapsTypings(entrytype)
  decapshash = {:NORMAL => "Normal", :FIRE => "Fire", :WATER => "Water", :GRASS  => "Grass", :ELECTRIC  => "Electric", :ICE  => "Ice", :FIGHTING  => "Fighting", :POISON  => "Poison",
  :GROUND  => "Ground", :FLYING  => "Flying", :PSYCHIC  => "Psychic", :BUG  => "Bug", :ROCK => "Rock", :GHOST  => "Ghost", :DRAGON  => "Dragon", :DARK  => "Dark", :STEEL  => "Steel",
  :FAIRY  => "Fairy"}
	if entrytype.nil?
	  return nil
	else
	  return decapshash[entrytype]
	end
end

def torDeCapsNature(entrynat)
  decapshash = {:HARDY => "Hardy", :LONELY => "Lonely", :ADAMANT => "Adamant", :NAUGHTY  => "Naughty", :BRAVE  => "Brave",
  :BOLD  => "Bold", :DOCILE  => "Docile", :IMPISH  => "Impish", :LAX  => "Lax", :RELAXED  => "Relaxed",
  :MODEST  => "Modest", :MILD  => "Mild", :BASHFUL => "Bashful", :RASH  => "Rash", :QUIET  => "Quiet",
  :CALM  => "Calm", :GENTLE  => "Gentle", :CAREFUL => "Careful", :QUIRKY  => "Quirky", :SASSY  => "Sassy",
  :TIMID  => "Timid", :HASTY  => "Hasty", :JOLLY => "Jolly", :NAIVE  => "Naive", :SERIOUS  => "Serious",
  }
	if entrynat.nil?
	  return nil
	else
	  return decapshash[entrynat]
	end
end

# Add "Accessible Summary" to the Pokémon Screen Menu
class PokemonScreen
  # Create a copy of the original pbPokemonScreen method to modify
  alias_method :accessibility_mod_original_pbPokemonScreen, :pbPokemonScreen

def pbPokemonScreen
    @scene.pbStartScene(@party, @party.length > 1 ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."), nil)
    loop do
      @scene.pbSetHelpText(@party.length > 1 ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
      pkmnid = @scene.pbChoosePokemon(false, true, shortcut_keys: true)
      if pkmnid.is_a?(Array) && pkmnid[0] == 1 # Switch
        @scene.pbSetHelpText(_INTL("Move to where?"))
        oldpkmnid = pkmnid[1]
        pkmnid = @scene.pbChoosePokemon(true, true, 1)
        if pkmnid >= 0 && pkmnid != oldpkmnid
          pbSwitch(oldpkmnid, pkmnid)
        end
        next
      end
      if pkmnid.is_a?(Array) && pkmnid[0] == 2 # Item
        pkmn = @party[pkmnid[1]]
        itemMenu(pkmnid[1], pkmn)
        next
      end
      if pkmnid.is_a?(Array) && pkmnid[0] == 3 # Summary
        @scene.pbSummary(pkmnid[1])
        next
      end
      if pkmnid < 0
        break
      end

      pkmn = @party[pkmnid]
      commands = []
      cmdSummary = -1
      cmdRelearn = -1
      cmdSwitch = -1
      cmdItem = -1
      cmdDebug = -1
      cmdMail = -1
      cmdRename = -1
      # --- INJECT OUR NEW COMMAND VARIABLE ---
      cmdAccessibleSummary = -1
      # --- END OF INJECTION ---

      # Build the commands
      commands[cmdSummary = commands.length] = _INTL("Summary")
      
      # --- INJECT OUR NEW COMMAND ---
      commands[cmdAccessibleSummary = commands.length] = _INTL("Accessible Summary")
      # --- END OF INJECTION ---

      pkmn.relearner = [pkmn.relearner, 0] if !pkmn.relearner.is_a?(Array)
      commands[cmdRelearn = commands.length] = _INTL("Relearn") if pkmn.relearner[0] == true
      if $DEBUG || (Reborn && $game_switches[:MiniDebug_Pass])
        # Commands for debug mode only
        commands[cmdDebug = commands.length] = _INTL("Debug")
      end
      if $game_switches[:EasyHMs_Password]
        acmdTMX = -1
        commands[acmdTMX = commands.length] = _INTL("Use TMX")
      end
      cmdMoves = [-1, -1, -1, -1]
      for i in 0...pkmn.moves.length
        move = pkmn.moves[i]
        # Check for hidden moves and add any that were found
        if !pkmn.isEgg? && (
           move.move == :MILKDRINK ||
           move.move == :SOFTBOILED ||
           HiddenMoveHandlers.hasHandler(move.move)
         )
          commands[cmdMoves[i] = commands.length] = getMoveName(move.move)
        end
      end
      commands[cmdSwitch = commands.length] = _INTL("Switch") if @party.length > 1
      if !pkmn.isEgg?
        if pkmn.mail
          commands[cmdMail = commands.length] = _INTL("Mail")
        else
          commands[cmdItem = commands.length] = _INTL("Item")
        end
        commands[cmdRename = commands.length] = _INTL("Rename")
      end
      commands[commands.length] = _INTL("Cancel")
      command = @scene.pbShowCommands(_INTL("Do what with {1}?", pkmn.name), commands)
      havecommand = false
      for i in 0...4
        if cmdMoves[i] >= 0 && command == cmdMoves[i]
          havecommand = true
          if pkmn.moves[i].move == :SOFTBOILED || pkmn.moves[i].move == :MILKDRINK
            if pkmn.hp <= (pkmn.totalhp / 5.0).floor
              pbDisplay(_INTL("Not enough HP..."))
              break
            end
            @scene.pbSetHelpText(_INTL("Use on which Pokémon?"))
            oldpkmnid = pkmnid
            loop do
              @scene.pbPreSelect(oldpkmnid)
              pkmnid = @scene.pbChoosePokemon(true)
              break if pkmnid < 0

              newpkmn = @party[pkmnid]
              if newpkmn.isEgg? || newpkmn.hp == 0 || newpkmn.hp == newpkmn.totalhp || pkmnid == oldpkmnid
                pbDisplay(_INTL("This item can't be used on that Pokémon."))
              else
                pkmn.hp -= (pkmn.totalhp / 5.0).floor
                hpgain = pbItemRestoreHP(newpkmn, (pkmn.totalhp / 5.0).floor)
                @scene.pbDisplay(_INTL("{1}'s HP was restored by {2} points.", newpkmn.name, hpgain))
                pbRefresh
              end
            end
            break
          elsif Kernel.pbCanUseHiddenMove?(pkmn, pkmn.moves[i].move)
            @scene.pbEndScene
            if pkmn.moves[i].move == :FLY
              if $cache.mapdata[$game_map.map_id].MapPosition.is_a?(Hash)
                region = pbUnpackMapHash[0]
              else
                region = $cache.mapdata[$game_map.map_id].MapPosition[0]
              end

              if $game_switches[:Blindstep]
                ret = Blindstep.flyMenu
              else
                scene = PokemonRegionMapScene.new(region, false)
                screen = PokemonRegionMap.new(scene)
                ret = screen.pbStartFlyScreen
              end

              if ret
                $PokemonTemp.flydata = ret
                $game_system.bgs_stop
                $game_screen.weather(0, 0, 0)
                return [pkmn, pkmn.moves[i].move]
              end
              @scene.pbStartScene(@party, @party.length > 1 ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
              break
            end
            return [pkmn, pkmn.moves[i].move]
          else
            break
          end
        end
      end
      if $game_switches[:EasyHMs_Password] && !pkmn.isEgg?
        if acmdTMX >= 0 && command == acmdTMX
          aRetArr = passwordUseTMX(pkmn)
          if aRetArr.length > 0
            havecommand = true
            return aRetArr
          end
        end
      end
      next if havecommand

      if cmdSummary >= 0 && command == cmdSummary
        @scene.pbSummary(pkmnid)
      # --- INJECT OUR NEW COMMAND LOGIC ---
      elsif cmdAccessibleSummary >= 0 && command == cmdAccessibleSummary
        # This opens our new sub-menu
        loop do
          # Use the scene's showCommands method to display our sub-menu
          sub_command = @scene.pbShowCommands(_INTL("Accessible Summary"), [
            _INTL("Display BST"),
            _INTL("Pokemon Details"),
            _INTL("Cancel")
          ])

          case sub_command
          when 0 # Display BST
            # Call the helper function we added earlier
            pbDisplayBSTData(pkmn)
          when 1 # Pokemon Details
            # Call the helper function we added earlier
            torDisplayPokemonDetails(pkmn)
          when -1, 2 # Cancel
            break
          end
        end
      # --- END OF INJECTION ---
      elsif cmdRelearn >= 0 && command == cmdRelearn
        pbRelearnMoveScreen(pkmn)
      elsif cmdSwitch >= 0 && command == cmdSwitch
        @scene.pbSetHelpText(_INTL("Move to where?"))
        oldpkmnid = pkmnid
        pkmnid = @scene.pbChoosePokemon(true)
        if pkmnid >= 0 && pkmnid != oldpkmnid
          pbSwitch(oldpkmnid, pkmnid)
        end
      elsif cmdDebug >= 0 && command == cmdDebug
        pbPokemonDebug(self, pkmn, pkmnid)
      elsif cmdMail >= 0 && command == cmdMail
        command = @scene.pbShowCommands(_INTL("Do what with the mail?"), [_INTL("Read"), _INTL("Take"), _INTL("Cancel")])
        case command
          when 0 # Read
            pbFadeOutIn(99999) {
              pbDisplayMail(pkmn.mail, pkmn)
            }
          when 1 # Take
            pbTakeItem(pkmn)
            pbRefreshSingle(pkmnid)
        end
      elsif cmdItem >= 0 && command == cmdItem
        itemMenu(pkmnid, pkmn)
      elsif cmdRename >= 0 && command == cmdRename
        species = getMonName(pkmn.species, pkmn.form)
        $game_variables[5] = Kernel.pbMessageFreeText("#{species}'s nickname?", _INTL(""), false, 12)
        if pbGet(5) == ""
          pkmn.name = getMonName(pkmn.species, pkmn.form)
          pbSet(5, pkmn.name)
        end
        if pbGet(5) != pkmn.name
          pkmn.name = pbGet(5)
          pbDisplay(_INTL("{1} was renamed to {2}.", species, pkmn.name))
        end
      end
    end
    @scene.pbEndScene
    return nil
  end
end