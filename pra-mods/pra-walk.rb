#===============================================================================
# Auto-Walk Toggle for Accessibility Pathfinding
#===============================================================================
# Adds a keybind to automatically walk along the last calculated route
# instead of only announcing it.
# Default toggle key = R (use Input::R, keycode 0x52)
#===============================================================================

$auto_walk = false

class Game_Player < Game_Character
  alias_method :update_autowalk_base, :update

  def update
    # Toggle auto-walk with R
    if Input.triggerex?(0x52)   # R key
      $auto_walk = !$auto_walk
      tts("Auto-Walk " + ($auto_walk ? "Enabled" : "Disabled"))
    end

    # Call original update
    update_autowalk_base

    # If auto-walk enabled and a route exists, move automatically
    if $auto_walk && @current_autowalk_route && !@current_autowalk_route.empty?
      unless $game_temp.in_battle || $game_temp.message_window_showing
        follow_autowalk_path
      end
    end
  end

  # Store a new route for auto-walking
  def start_autowalk(route)
    @current_autowalk_route = route
  end

  # Actually consume the route and move tile by tile
  def follow_autowalk_path
    return if @current_autowalk_route.nil? || @current_autowalk_route.empty?

    next_node = @current_autowalk_route.first
    dx = next_node.x - @x
    dy = next_node.y - @y

    if dx == 1 && dy == 0
      move_right
    elsif dx == -1 && dy == 0
      move_left
    elsif dx == 0 && dy == 1
      move_down
    elsif dx == 0 && dy == -1
      move_up
    end

    # If we reached that tile, pop it off
    if @x == next_node.x && @y == next_node.y
      @current_autowalk_route.shift
      # If route finished, disable auto-walk automatically
      if @current_autowalk_route.empty?
        $auto_walk = false
        tts("Destination reached.")
      end
    end
  end
end

# Hook into the pathfinder: whenever we compute a path, also queue it for auto-walk
class Game_Player
  alias_method :pathfind_to_selected_event_autowalk, :pathfind_to_selected_event
  def pathfind_to_selected_event
    pathfind_to_selected_event_autowalk
    # After computing a route, capture it if one exists
    route = aStern(Node.new(@x, @y), Node.new(@mapevents[@selected_event_index].x, @mapevents[@selected_event_index].y))
    start_autowalk(route) unless route.empty?
  end
end
