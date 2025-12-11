class PokemonOptions
  #####MODDED
  attr_accessor :amb_walkThroughWalls
  
  def amb_walkThroughWalls
	  @amb_walkThroughWalls = 0 if !@amb_walkThroughWalls
	  return @amb_walkThroughWalls
  end
  #####/MODDED
end

class Game_Player
  def passable?(x, y, d)
    # Get new coordinates
    new_x = x + (d == 6 ? 1 : d == 4 ? -1 : 0)
    new_y = y + (d == 2 ? 1 : d == 8 ? -1 : 0)
    # If coordinates are outside of map
    unless $game_map.validLax?(new_x, new_y)
      # Impassable
      return false
    end
    if !$game_map.valid?(new_x, new_y)
      return false if !$MapFactory
      return $MapFactory.isPassableFromEdge?(new_x, new_y)
    end
    # If debug mode is ON and ctrl key was pressed
    #####MODDED
    if (Input.press?(Input::CTRL)) || (defined?($idk[:settings].amb_walkThroughWalls) && (($idk[:settings].amb_walkThroughWalls == 1 && Input.press?(Input::CTRL)) || $idk[:settings].amb_walkThroughWalls == 2))
    #####/MODDED
      # Passable
      return true
    end
    super
  end
end

