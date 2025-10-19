#===============================================================================
# Pokémon Reborn Access - Debugging Tools
#
# Contains tools for debugging game mechanics, intended for development use.
#
# == Terrain Tag Inspector ==
# - Press 'G' (0x47) on the map.
# - Enter an X coordinate.
# - Enter a Y coordinate.
# - The tool will announce the terrain tag ID and its name for those coordinates.
#===============================================================================

# Helper module to convert Terrain Tag IDs to readable names
module PRA_Debug_Tools
  # Create a reverse lookup map from the PBTerrain constants
  def self.get_terrain_tag_name(tag_id)
    # Check if PBTerrain is defined (it should be, from Field.rb)
    unless defined?(PBTerrain)
      return "PBTerrain module not found"
    end
    
    # Iterate over all constants in PBTerrain
    PBTerrain.constants.each do |const_name|
      # Find the constant whose value matches the tag_id
      if PBTerrain.const_get(const_name) == tag_id
        # Return a readable name, e.g., "Ledge", "Grass", "Water"
        return const_name.to_s.capitalize 
      end
    end
    
    # If no match is found
    return "Unknown Tag"
  end
end

# Add the keybind to the Game_Player class
class Game_Player < Game_Character
  # Make a copy of the original update method
  alias_method :pra_debug_tools_update, :update
  
  def update
    # Call the original update first
    pra_debug_tools_update
    
    # --- Terrain Tag Inspector Keybind ---
    # Check if 'G' key (0x47) is pressed and player is not busy
    if Input.triggerex?(0x47) && !moving? && !$game_temp.message_window_showing
      
      # Get X coordinate from user
      x_text = Kernel.pbMessageFreeText("Enter target X:", "", false, 4)
      
      if x_text && !x_text.strip.empty?
        # Get Y coordinate from user
        y_text = Kernel.pbMessageFreeText("Enter target Y:", "", false, 4)
        
        if y_text && !y_text.strip.empty?
          x = x_text.to_i
          y = y_text.to_i
          
          # Check if coordinates are valid on the current map
          if $game_map.valid?(x, y)
            # Get the terrain tag ID (the number)
            tag_id = $game_map.terrain_tag(x, y)
            # Get the readable name (the string)
            tag_name = PRA_Debug_Tools.get_terrain_tag_name(tag_id)
            
            # Announce the result
            tts("Terrain tag at X #{x}, Y #{y} is: #{tag_name} (#{tag_id})")
          else
            tts("Invalid coordinates for this map: X #{x}, Y #{y}")
          end
        else
          tts("Y coordinate cancelled.")
        end
      else
        tts("X coordinate cancelled.")
      end
    end
    # --- End of Terrain Tag Inspector ---
  end
end