#===============================================================================
# Auto-Walk Logic for Accessibility Pathfinding
#===============================================================================
# This mod handles the mechanics of automatically moving the player along a path.
# Key inputs are handled by the main pathfinding mod to ensure cohesion.
#===============================================================================

# Initialize the global toggle if it doesn't exist
$auto_walk = false if !$auto_walk

class Game_Player < Game_Character
  alias_method :access_mod_walk_original_update, :update

  def update
    # Call original update first
    access_mod_walk_original_update

    # If auto-walk is enabled and we have a route, follow it
    if defined?($auto_walk) && $auto_walk && @current_autowalk_route && !@current_autowalk_route.empty?
      unless $game_temp.in_battle || $game_temp.message_window_showing
        follow_autowalk_path
      end
    end
  end

  # Store a new route for auto-walking
  def start_autowalk(route)
    @current_autowalk_route = route
    # Optional: Announce that walking has started
    tts("Auto-walking...")
  end

  # Actually consume the route and move tile by tile
  def follow_autowalk_path
    return if @current_autowalk_route.nil? || @current_autowalk_route.empty?

    # Get the next target node
    next_node = @current_autowalk_route.first
    
    # Calculate direction
    dx = next_node.x - @x
    dy = next_node.y - @y

    # Move in the correct direction
    if dx == 1 && dy == 0
      move_right
    elsif dx == -1 && dy == 0
      move_left
    elsif dx == 0 && dy == 1
      move_down
    elsif dx == 0 && dy == -1
      move_up
    end

    # If we successfully reached that tile (coordinates match), remove it from the list
    if @x == next_node.x && @y == next_node.y
      @current_autowalk_route.shift
      
      # If route finished, disable auto-walk automatically and announce
      if @current_autowalk_route.empty?
        $auto_walk = false
        tts("Destination reached.")
      end
    end
  end
end