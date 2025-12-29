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

    # If Auto-Walk is ON
    if defined?($auto_walk) && $auto_walk
      
      # SAFETY CHECK: Only disable if we had a route and it is now finished.
      # We check if @current_autowalk_route is NOT nil (meaning we started)
      # BUT is empty (meaning we finished).
      if !@current_autowalk_route.nil? && @current_autowalk_route.empty?
        $auto_walk = false
        @current_autowalk_route = nil # Reset to nil
        tts("Destination reached.")
        return
      end

      # Otherwise, follow the path (if one exists)
      unless $game_temp.in_battle || $game_temp.message_window_showing
        follow_autowalk_path
      end
    end
  end

# Clear the route silently (used on game load)
  def clear_autowalk_route
    @current_autowalk_route = nil
  end

  # Store a new route for auto-walking
  def start_autowalk(route)
    @current_autowalk_route = route
    tts("Auto-walking...")
  end

  # Actually consume the route and move tile by tile
  def follow_autowalk_path
    return if @current_autowalk_route.nil? || @current_autowalk_route.empty?

    # 1. Check if we have arrived at the current target node
    target = @current_autowalk_route.first
    
    if @x == target.x && @y == target.y
      # We are at the target, remove it from the list
      @current_autowalk_route.shift
      
      # If the route is now empty, return. The Safety Check in 'update' will 
      # handle disabling the toggle on the next frame.
      return if @current_autowalk_route.empty?
      
      # Update target to the next node
      target = @current_autowalk_route.first
    end

    # 2. Check if we are Adjacent + Blocked for the Final Step
    if @current_autowalk_route.length == 1
      dx = target.x - @x
      dy = target.y - @y
      
      # Check if strictly adjacent (distance 1)
      if dx.abs + dy.abs == 1
        # Determine the direction we are trying to go
        dir = 0
        dir = 6 if dx == 1
        dir = 4 if dx == -1
        dir = 2 if dy == 1
        dir = 8 if dy == -1
        
        # Check if passage is blocked
        if !passableEx?(@x, @y, dir)
           # We are stuck next to the final target. Assume we reached the interaction point.
           @current_autowalk_route.shift
           return
        end
      end
    end

    # 3. Issue the move command
    return if moving?

    dx = target.x - @x
    dy = target.y - @y

    if dx > 0
      move_right
    elsif dx < 0
      move_left
    elsif dy > 0
      move_down
    elsif dy < 0
      move_up
    end
  end
end