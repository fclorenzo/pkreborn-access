class Game_Player < Game_Character
  alias_method :access_mod_original_update, :update # Make a copy of the original update
  def update
    # First, call the original update method (which includes the running logic)
    access_mod_original_update

    # Then, execute our mod's logic
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

        # PATHFIND to the current event (P)
        if Input.triggerex?(0x50)
          pathfind_to_selected_event
        end
      end
    end
  end

  @mapevents = []
  @selected_event_index = -1

def is_teleport_event?(event)
  return false if !event || !event.list
  for command in event.list
    # 201 is the event code for "Transfer Player"
    return true if command.code == 201
  end
  return false
end

def get_teleport_destination_name(event)
  return nil if !event || !event.list
  for command in event.list
    if command.code == 201 # Event command for "Transfer Player"
      map_id = command.parameters[1]
      # Use the Map Factory to get the destination map object
      destination_map = $MapFactory.getMap(map_id)
      return destination_map.name if destination_map
    end
  end
  return nil # Return nil if it's not a teleport event
end

def announce_selected_event
  return if @selected_event_index == -1 || @mapevents[@selected_event_index].nil?
  
  event = @mapevents[@selected_event_index]
  dist = distance(@x, @y, event.x, event.y).round
  
  facing_direction = ""
  case @direction
  when 2; facing_direction = "facing down"
  when 4; facing_direction = "facing left"
  when 6; facing_direction = "facing right"
  when 8; facing_direction = "facing up"
  end

  announcement_text = ""
  if event.name.nil? || event.name.strip.empty?
    if is_teleport_event?(event)
      destination = get_teleport_destination_name(event)
      announcement_text = "Connection to #{destination}"
    else
      announcement_text = "Interactable object"
    end
  else
    announcement_text = event.name
  end
  
  # Combine all parts for the final announcement
  tts("#{announcement_text}, #{dist} steps away, #{facing_direction}.")
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
  
  # --- NEW: Sort events by distance from the player (closest first) ---
  @mapevents.sort! { |a, b| distance(@x, @y, a.x, a.y) <=> distance(@x, @y, b.x, b.y) }
  
  # Set the index to the first event (now the closest), or -1 if the list is empty.
  @selected_event_index = @mapevents.empty? ? -1 : 0
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

  def access_mod_update
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

#  Automatic Event List Refresh on Map Transfer
class Scene_Map
  # Create a copy of the original transfer_player method to modify
  alias_method :access_mod_original_transfer_player, :transfer_player

  def transfer_player(cancelVehicles = true)
    # First, call the original method to perform the map transfer
    access_mod_original_transfer_player(cancelVehicles)
    
    # After the transfer is complete, call our refresh method
    $game_player.populate_event_list
  end
end