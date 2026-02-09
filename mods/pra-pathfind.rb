#===============================================================================
# PRE-REQUISITE CLASSES & STORAGE
#===============================================================================

# A temporary storage module to keep our custom events OUT of the save file.
module PraSession
  class << self
    attr_accessor :mapevents
    attr_accessor :selected_event_index
    attr_accessor :event_filter_modes
    attr_accessor :event_filter_index
  end

  # Initialize defaults
  def self.reset!
    @mapevents = []
    @selected_event_index = -1
    @event_filter_modes = [:all, :connections, :npcs, :items, :merchants, :signs, :hidden_items, :notes, :pois]
    @event_filter_index = 0
  end
end

# Helper class for finding interactable tiles next to an event
class EventWithRelativeDirection
  attr_accessor :direction, :node
  def initialize(paraNode, paraDirection)
    @direction = paraDirection
    @node = paraNode
  end
end

# Add attributes to GLOBAL Game_Event (Open Class)
class Game_Event
  attr_accessor :candidates
  attr_accessor :custom_name # Allow real events to carry a cluster-based custom name
end

# VirtualEvent class
class VirtualEvent
  # FIX: Added :id to the list of accessible attributes
  attr_accessor :id, :x, :y, :map_id, :type, :custom_name, :candidates, :destination_id
  
  def initialize(map_id, x, y, type=:poi, name="Point of Interest", candidates=[], destination_id=nil)
    # FIX: Generate a pseudo-ID based on location.
    # We use negative numbers to distinguish them from real map events (which are positive).
    # Logic: -(X * 1000 + Y) ensures a unique ID for every tile.
    @id = -((x * 1000) + y)
    
    @map_id = map_id
    @x = x
    @y = y
    @type = type
    @custom_name = name
    @candidates = candidates
    @destination_id = destination_id
  end
  
  # Duck-typing: pretend to be a Game_Event so existing methods accept it
  def name; @custom_name; end
  def list; nil; end
  def trigger; 0; end
  def character_name; ""; end
  def through; true; end 
end

class Game_Player < Game_Character
  alias_method :access_mod_original_update, :update 
  def update
    # First, call the original update method
    access_mod_original_update

    # --- Auto-refresh on map change ---
    if @auto_refresh_map_list && @last_map_id != $game_map.map_id
      @last_map_id = $game_map.map_id
      populate_event_list
    end

    # Then, execute the mod's logic
    unless moving?
      # Cycle event filter (O / I)
      if Input.triggerex?(0x4F)
        cycle_event_filter(1)
      elsif Input.triggerex?(0x49)
        cycle_event_filter(-1)
      end

      # Toggle sort by distance (Shift+H)
      if Input.pressex?(0x10) && Input.triggerex?(0x48)
        @sort_by_distance = !@sort_by_distance
        tts("Sort by distance: #{@sort_by_distance ? 'On' : 'Off'}")
    
      # Cycle HM pathfinding toggle (H)
      elsif Input.triggerex?(0x48)
        cycle_hm_toggle
      end

      # Toggle Auto-Refresh Map List (Shift+F5)
      if Input.pressex?(0x10) && Input.triggerex?(0x74)
        @auto_refresh_map_list = !@auto_refresh_map_list
        tts("Auto-refresh map list: #{@auto_refresh_map_list ? 'On' : 'Off'}")

      # Refresh the event list (F5)
      elsif Input.triggerex?(0x74)
        populate_event_list
        tts('Map list refreshed')
      end

      # Make sure we have events to cycle through
      # UPDATED: Use PraSession
      if !PraSession.mapevents.nil? && !PraSession.mapevents.empty?
        
        # --- J Key Logic (Previous Event OR Toggle Auto-Walk) ---
        if Input.triggerex?(0x4A)
          # If Shift is held: Toggle Auto-Walk (Shift+J)
          if Input.pressex?(0x10)
            if defined?($auto_walk)
              $auto_walk = !$auto_walk
              tts("Auto-Walk #{$auto_walk ? 'Enabled' : 'Disabled'}")
            else
              tts("Auto-Walk mod not installed.")
            end
          # If Shift is NOT held: Cycle Previous Event (J)
          else
            PraSession.selected_event_index -= 1
            if PraSession.selected_event_index < 0
              PraSession.selected_event_index = PraSession.mapevents.size - 1 
            end
            announce_selected_event
          end
        end

        # --- L Key Logic (Next Event OR Place Marker) ---
        if Input.triggerex?(0x4C)
          # If Shift is held: Place Coordinate Marker (Shift+L)
          if Input.pressex?(0x10)
            create_poi
          # If Shift is NOT held: Cycle Next Event (L)
          else
            PraSession.selected_event_index += 1
            if PraSession.selected_event_index >= PraSession.mapevents.size
              PraSession.selected_event_index = 0 
            end
            announce_selected_event
          end
        end

        # Rename selected event (Shift+K)
        if Input.pressex?(0x10) && Input.triggerex?(0x4B)
          rename_selected_event

        # ANNOUNCE the current event (K)
        elsif Input.triggerex?(0x4B)
          announce_selected_event
        end

        # Announce coordinates (Shift+P)
        if Input.pressex?(0x10) && Input.triggerex?(0x50)
          announce_selected_coordinates

        # PATHFIND to the current event (P)
        elsif Input.triggerex?(0x50)
            pathfind_to_selected_event
        end

        # Add Note to Event (Shift+N)
        if Input.pressex?(0x10) && Input.triggerex?(0x4E)
          add_note_to_selected_event

        # Announce Notes (N)
        elsif Input.triggerex?(0x4E)
          announce_selected_notes
        end
      end
    end
  end

  alias_method :access_mod_original_initialize, :initialize
  def initialize(*args)
    access_mod_original_initialize(*args)

    # Initialize the temporary session (replacing instance variables)
    PraSession.reset!

    # Settings that are safe to save
    @hm_toggle_modes = [:off, :surf_only, :surf_and_waterfall]
    @hm_toggle_index = 0 
    @sort_by_distance = true 
    @auto_refresh_map_list = true
    @last_map_id = -1             
  end
  
# Checks if an event is a "Jump Event" (invisible event that forces a move route)
  def is_jump_event?(event, direction)
    return false if !event || !event.list
    return false if event.trigger != 1 # Must be Player Touch
    
    # Calculate offsets based on direction
    offsetx, offsety =  0,  1 if direction == 2
    offsetx, offsety = -1,  0 if direction == 4
    offsetx, offsety =  1,  0 if direction == 6
    offsetx, offsety =  0, -1 if direction == 8

    in_leap = false
    for command in event.list
      if in_leap
        # Code 209 is "Set Move Route"
        if command.code == 209 && command.parameters[0] == -1 # -1 is Player
          for mvcmd in command.parameters[1].list
            # Code 14 is "Jump". Parameters are x and y offsets.
            # We check if the jump distance matches the direction we are facing (x2 for 2 tiles)
            if mvcmd.code == 14 && mvcmd.parameters[0] == offsetx * 2 && mvcmd.parameters[1] == offsety * 2
              return true
            end
          end
        elsif command.code == 0
          in_leap = false
        end
      else
        # Code 111 is Conditional Branch. 
        # Param 0=6 (Character), Param 1=-1 (Player), Param 2=Direction
        if command.code == 111 && command.parameters[0] == 6 && command.parameters[1] == -1 && command.parameters[2] == direction
          in_leap = true
        end
      end
    end
    return false
  end

# Checks if we can perform a 2-tile jump over a ledge or event
  def is_path_ledge_passable?(x, y, d)
    # Get the coordinates of the tile immediately in front (the gap/ledge)
    new_x = x + (d == 6 ? 1 : d == 4 ? -1 : 0)
    new_y = y + (d == 2 ? 1 : d == 8 ? -1 : 0)
    
    # Use global $game_map to be safe
    return false unless $game_map.valid?(new_x, new_y)

    # 1. Check for Jump Events
    for event in $game_map.events.values
      if event.x == new_x && event.y == new_y && is_jump_event?(event, d)
        return true
      end
    end
    
    # 2. Check for Standard Ledges
    terrain_tag = $game_map.terrain_tag(new_x, new_y)
    
    # Robust Check: Constant OR 1
    ledge_id = defined?(PBTerrain::Ledge) ? PBTerrain::Ledge : 1
    
    if terrain_tag == ledge_id
      # FORCE RETURN TRUE. We trust the tag. 
      # Logic filtering happens in push_neighbthe.
      return true 
    end
    
    return false
  end

def getEventTiles(event, map = $game_map)
    possibleTiles = []
    #tts("Scanning targets for Event #{event.id} at #{event.x}, #{event.y}")
    
    # Define the 4 directions
    directions = [
      { dir: 2, dx: 0, dy: 1, face: 8 }, 
      { dir: 4, dx: -1, dy: 0, face: 6 }, 
      { dir: 6, dx: 1, dy: 0, face: 4 }, 
      { dir: 8, dx: 0, dy: -1, face: 2 }
    ]

    found_any = false
    
    for d in directions
      x1 = event.x + d[:dx]
      y1 = event.y + d[:dy]
      x2 = event.x + (d[:dx] * 2)
      y2 = event.y + (d[:dy] * 2)

      # Check 1: Standard (1 tile away)
      if map.valid?(x1, y1) && map.passable?(x1, y1, 0, $game_player)
        possibleTiles.push(EventWithRelativeDirection.new(Node.new(x1, y1), d[:face]))
        found_any = true
      # Check 2: Reach-Over (2 tiles away)
      elsif map.valid?(x2, y2) && map.passable?(x2, y2, 0, $game_player)
        possibleTiles.push(EventWithRelativeDirection.new(Node.new(x2, y2), d[:face]))
        found_any = true
      end
    end

    if found_any
      #tts("Target found.")
    else
      #tts("Error. No valid standing spots found around NPC.")
    end

    return possibleTiles
  end
def create_poi
  # 1. Get Coordinates
  default_x = $game_player.x
  default_y = $game_player.y
  x_text = Kernel.pbMessageFreeText(_INTL("Enter X coordinate (default: #{default_x}):"), "", false, 4)
  y_text = Kernel.pbMessageFreeText(_INTL("Enter Y coordinate (default: #{default_y}):"), "", false, 4)
  final_x = (x_text && !x_text.strip.empty?) ? x_text.to_i : default_x
  final_y = (y_text && !y_text.strip.empty?) ? y_text.to_i : default_y
  
  unless $game_map.valid?(final_x, final_y)
    tts("Invalid coordinates.")
    return
  end

  # 2. Get Name
  name = Kernel.pbMessageFreeText(_INTL("Enter name for this point of interest (max 100 chars):"), "", false, 100)
  if name.nil? || name.strip.empty?
    tts("Creation cancelled.")
    return 
  end
  
  # 3. Get Note
  note = Kernel.pbMessageFreeText(_INTL("Enter optional note (max 500 chars):"), "", false, 500)
  
  # 4. Save
  map_id = $game_map.map_id
  map_name = $game_map.name
  key = "#{map_id};#{final_x};#{final_y}"
  
  value = {
    map_name: map_name,
    event_name: name,
    notes: note || "",
    type: :poi # <--- EXPLICIT FLAG
  }
  
  $custom_event_names[key] = value
  save_custom_names
  tts("PoI '#{name}' created at X #{final_x}, Y #{final_y}.")
  populate_event_list
end

def cycle_hm_toggle
  # --- Safeguard for old save files ---
  if @hm_toggle_modes.nil? || !@hm_toggle_modes.include?(:surf_and_waterfall)
    @hm_toggle_modes = [:off, :surf_only, :surf_and_waterfall]
    @hm_toggle_index = 0
  end

  @hm_toggle_index = (@hm_toggle_index + 1) % @hm_toggle_modes.length
  
 
  current_mode = @hm_toggle_modes[@hm_toggle_index]
  announcement = ""
  case current_mode
  when :off
    announcement = "HM pathfinding off"
  when :surf_only
    announcement = "HM pathfinding set to Surf only"
  when :surf_and_waterfall
    announcement = "HM pathfinding set to Surf and Waterfall"
  end
  tts(announcement)
end

def cycle_event_filter(direction = 1)
  if PraSession.event_filter_modes.nil?
    PraSession.reset!
  end
  
  PraSession.event_filter_index += direction
  
  if PraSession.event_filter_index >= PraSession.event_filter_modes.length
    PraSession.event_filter_index = 0
  elsif PraSession.event_filter_index < 0
    PraSession.event_filter_index = PraSession.event_filter_modes.length - 1
  end
  
  current_filter = PraSession.event_filter_modes[PraSession.event_filter_index]
  
  filter_name = current_filter.to_s.gsub('_', ' ').capitalize
  filter_name = "Points of Interest" if current_filter == :pois
  
  tts("Filter set to #{filter_name}")
  populate_event_list
end

def rename_selected_event
  # Ensure an event is selected
  return if PraSession.selected_event_index < 0 || PraSession.mapevents[PraSession.selected_event_index].nil?
  
  # --- FIX: Define 'event' before using it ---
  event = PraSession.mapevents[PraSession.selected_event_index]
  # -------------------------------------------

  # Prompt user for the new name
  new_name = Kernel.pbMessageFreeText(_INTL("Enter new name for the selected event (max 100 characters)."), "", false, 100)
  
  # Check if the user entered a valid, non-blank name
  if new_name && !new_name.strip.empty?
    # Prompt user for an optional description/note
    new_note = Kernel.pbMessageFreeText(_INTL("Enter optional notes (max 500 characters)."), "", false, 500)

    # Gather all necessary data
    map_id = $game_map.map_id
    map_name = $game_map.name
    x = event.x
    y = event.y

    # Create the unique key and the value hash
    key = "#{map_id};#{x};#{y}"

    # --- FIX: Preserve POI type ---
    current_type = :event
    if $custom_event_names[key] && $custom_event_names[key][:type]
       current_type = $custom_event_names[key][:type]
    elsif event.is_a?(VirtualEvent) && event.type == :poi
       current_type = :poi
    end

    value = {
      map_name: map_name,
      event_name: new_name,
      notes: new_note || "",
      type: :event # <--- EXPLICIT FLAG
    }
    # Update the in-memory hash
    $custom_event_names[key] = value
    
    # Save the entire hash back to the file
    save_custom_names
    
    # Provide feedback to the player
    tts("Event renamed to #{new_name}")
  else
    # If the name is blank or the user cancelled, provide feedback
    tts("Event renaming cancelled.")
  end
end

def add_note_to_selected_event
  return if PraSession.selected_event_index < 0 || PraSession.mapevents[PraSession.selected_event_index].nil?

  # --- FIX: Define 'event' before using it ---
  event = PraSession.mapevents[PraSession.selected_event_index]
  # -------------------------------------------

  # Prompt user for the note only
  new_note = Kernel.pbMessageFreeText(_INTL("Enter notes for this event (max 500 characters)."), "", false, 500)
  
  if new_note
    # Gather necessary data
    map_id = $game_map.map_id
    map_name = $game_map.name
    x = event.x
    y = event.y

    # Create the unique key
    key = "#{map_id};#{x};#{y}"
    
    # Check if this event already has a custom name and type we need to preserve
    current_custom_name = ""
    current_type = :event # Default to event if we are adding a note to something new
    # Preserve existing data
    if $custom_event_names[key]
      current_custom_name = $custom_event_names[key][:event_name] if $custom_event_names[key][:event_name]
      current_type = $custom_event_names[key][:type] if $custom_event_names[key][:type]
    elsif event.is_a?(VirtualEvent) && event.type == :poi
      current_type = :poi
    end
    # Create value hash, preserving the name if it exists, updating the note
    value = {
      map_name: map_name,
      event_name: current_custom_name,
      notes: new_note,
      type: current_type
    }

    # Update and save
    $custom_event_names[key] = value
    save_custom_names
    
    tts("Note saved.")
  else
    tts("Note entry cancelled.")
  end
end

def is_path_passable?(x, y, d)
    # --- Safeguard for old save files ---
    if @hm_toggle_modes.nil?
      @hm_toggle_modes = [:off, :surf_only, :surf_and_waterfall]
      @hm_toggle_index = 0
    end

    # Handle holes (prevent walking into teleport events that aren't connections)
    for event in $game_map.events.values
      if event.x == x && event.y == y && is_teleport_event?(event)
        return false
      end
    end

  tag = $game_map.terrain_tag(x, y)
  return false if tag == 1 # Force the pathfinder to treat this as an obstacle, not a floor

    # First, check if the tile is normally passable
    return true if passable?(x, y, d)
    
    # If not, check if it's an HM obstacle the player can pass with the toggle
    current_mode = @hm_toggle_modes[@hm_toggle_index]
    return false if current_mode == :off

    # Get the coordinates of the tile we are trying to move to
    new_x = x + (d == 6 ? 1 : d == 4 ? -1 : 0)
    new_y = y + (d == 2 ? 1 : d == 8 ? -1 : 0)
    return false unless self.map.valid?(new_x, new_y)
    
    # Get the terrain tag of the destination tile
    terrain_tag = self.map.terrain_tag(new_x, new_y)

    # Check for Surf (Water or Lava)
    # Note: Added pbIsPassableLavaTag for Reborn compatibility
    if pbIsPassableWaterTag?(terrain_tag) || (defined?(pbIsPassableLavaTag?) && pbIsPassableLavaTag?(terrain_tag))
      return true if current_mode == :surf_only || current_mode == :surf_and_waterfall
    end
    
    # Check for Waterfall
    if terrain_tag == PBTerrain::Waterfall || terrain_tag == PBTerrain::WaterfallCrest
      return true if current_mode == :surf_and_waterfall
    end 
    return false
  end

def is_sign_event?(event)
  return false if !event || !event.list || !event.character_name.empty?
  for command in event.list
    return true if command.code == 101 # Show Text
  end
  return false
end

def is_merchant_event?(event)
  return false if !event || !event.list
  for command in event.list
    if command.code == 355 && command.parameters[0].is_a?(String)
      return true if command.parameters[0].include?("pbPokemonMart")
    end
  end
  return false
end

def is_item_event?(event)
  return false if !event
  return event.character_name.start_with?("itemball")
end

def is_hidden_item_event?(event)
  return event.name == "HiddenItem"
end

def is_npc_event?(event)
  return false if !event
  # An NPC is any event with a character sprite that isn't a connection or an item.
  return !event.character_name.empty? && 
         !is_teleport_event?(event) && 
         !is_item_event?(event)
end

def is_teleport_event?(event)
  return false if !event || !event.list
  for command in event.list
    # 201 is the event code for "Transfer Player"
    return true if command.code == 201
  end
  return false
end

def get_map_name(map_id)
    return "" if map_id.nil?
    # Retrieve the map object from the factory using the ID
    map = $MapFactory.getMap(map_id)
    return map ? map.name : "Unknown Map"
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

def getNeighbthe(event, eventsArray)
  for currentEvent in eventsArray
    if (event.x - currentEvent.x).abs == 1 && event.y == currentEvent.y || 
       (event.y - currentEvent.y).abs == 1 && event.x == currentEvent.x
      return currentEvent
    end
  end
  return nil
end

def getEvent(x, y, eventsArray)
  for ea in eventsArray
    if ea.x == x && ea.y == y
      return ea
    end
  end
  return nil
end

  def deleteNodesInOneLane(event, neighbtheNode, eventsArray)
    nodesInLane = []
    eventDestination = nil
    for eventCommand in event.list
      if eventCommand.code == 201
        eventDestination = eventCommand.parameters[1]
      end
    end
    if event.x == neighbtheNode.x #y-axis
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

def announce_selected_coordinates
  return if PraSession.selected_event_index < 0 || PraSession.mapevents[PraSession.selected_event_index].nil?
  
  # --- FIX: Define 'event' before using it ---
  event = PraSession.mapevents[PraSession.selected_event_index]
  # -------------------------------------------

  # Start with the base coordinate announcement
  announcement = "Coordinates: X #{event.x}, Y #{event.y}"
  
  # Create a unique key for the current event
  key = "#{$game_map.map_id};#{event.x};#{event.y}"
  custom_name_data = $custom_event_names[key]
  
  # Check if custom data exists and has a non-empty notes field
  if custom_name_data && custom_name_data[:notes] && !custom_name_data[:notes].strip.empty?
    announcement += ". Has notes."
  end
  
  tts(announcement)
end

def announce_selected_notes
  return if PraSession.selected_event_index < 0 || PraSession.mapevents[PraSession.selected_event_index].nil?
  event = PraSession.mapevents[PraSession.selected_event_index]
  
  key = "#{$game_map.map_id};#{event.x};#{event.y}"
  custom_name_data = $custom_event_names[key]
  
  if custom_name_data && custom_name_data[:notes] && !custom_name_data[:notes].strip.empty?
    tts("Notes: #{custom_name_data[:notes]}")
  else
    tts("No notes available for this event.")
  end
end

def announce_selected_event
  return if PraSession.selected_event_index == -1 || PraSession.mapevents[PraSession.selected_event_index].nil?
  event = PraSession.mapevents[PraSession.selected_event_index]
  dist = distance(@x, @y, event.x, event.y).round

  key = "#{$game_map.map_id};#{event.x};#{event.y}"
  custom_name_data = $custom_event_names[key]
  announcement_text = ""
  
  # PRIORITY 1: Cluster-based Custom Name (The fix for lanes)
  if event.respond_to?(:custom_name) && event.custom_name && !event.custom_name.strip.empty?
    announcement_text = event.custom_name

  # PRIORITY 2: Direct Coordinate Custom Name (Fallback for single tiles)
  elsif custom_name_data && custom_name_data[:event_name] && !custom_name_data[:event_name].strip.empty?
    announcement_text = custom_name_data[:event_name]

  else
    # Standard Logic
    if is_teleport_event?(event)
      destination = get_teleport_destination_name(event)
      if destination && !destination.strip.empty?
        announcement_text = destination
      elsif event.name && !event.name.strip.empty?
        announcement_text = event.name
      else
        announcement_text = "Unknown Connection"
      end

    elsif event.is_a?(VirtualEvent) && event.type == :connection
       announcement_text = event.name

    elsif event.name && !event.name.strip.empty?
      announcement_text = event.name

    else
      announcement_text = "Interactable object"
    end  
  end
  facing_direction = ""
  case @direction
  when 2; facing_direction = "facing down"
  when 4; facing_direction = "facing left"
  when 6; facing_direction = "facing right"
  when 8; facing_direction = "facing up"
  end
  
  tts("#{announcement_text}, #{dist} steps away, #{facing_direction}.")
end

def populate_event_list
    # Ensure session is initialized
    if PraSession.event_filter_modes.nil?
      PraSession.reset!
    end

    PraSession.mapevents = []
    current_filter = PraSession.event_filter_modes[PraSession.event_filter_index]

    all_connections = []
    all_others = []

    # 1. PROCESS REAL GAME EVENTS
    for event in $game_map.events.values
      next if !event.list || event.list.size <= 1
      next if event.trigger == 3 || event.trigger == 4 

      key = "#{$game_map.map_id};#{event.x};#{event.y}"
      custom_name_data = $custom_event_names[key]

      # We apply the custom name (even "ignore") so the grouper can see it.
      if custom_name_data && custom_name_data[:event_name]
         event.custom_name = custom_name_data[:event_name]
      else
         event.custom_name = nil
      end

      if is_teleport_event?(event)
        all_connections.push(event)
      else
        all_others.push(event)
      end
    end

    # 2. PROCESS MAP CONNECTIONS (VIRTUAL EDGES)
    if $game_map && $MapFactory
      w = $game_map.width
      h = $game_map.height
      edges = [
        { range: (0...w), axis: :y, val: 0,   cx: 0,  cy: -1, dir: 8 }, # North
        { range: (0...w), axis: :y, val: h-1, cx: 0,  cy: 1,  dir: 2 }, # South
        { range: (0...h), axis: :x, val: 0,   cx: -1, cy: 0,  dir: 4 }, # West
        { range: (0...h), axis: :x, val: w-1, cx: 1,  cy: 0,  dir: 6 }  # East
      ]

      for edge in edges
        for i in edge[:range]
          x = (edge[:axis] == :x) ? edge[:val] : i
          y = (edge[:axis] == :y) ? edge[:val] : i
          
          map_info = $MapFactory.getNewMap(x + edge[:cx], y + edge[:cy])
          
          # Fix: Handle both Map Object and Map ID return types
          connected_id = nil
          if map_info
            if map_info[0].is_a?(Game_Map)
              connected_id = map_info[0].map_id
            else
              connected_id = map_info[0]
            end
          end

          if connected_id
            # Check if this tile is passable
            tag = $game_map.terrain_tag(x, y)
            is_passable = $game_map.passableStrict?(x, y, 0, $game_player)
            is_ledge = defined?(PBTerrain::Ledge) && tag == PBTerrain::Ledge
            is_water = defined?(PBTerrain::Water) && (tag == PBTerrain::Water || tag == PBTerrain::DeepWater || tag == PBTerrain::Waterfall || tag == PBTerrain::WaterfallCrest)
            
            if is_passable || is_ledge || is_water
              
              # Check Ignore
              # We apply the name if it exists, otherwise default.
              key = "#{$game_map.map_id};#{x};#{y}"
              custom_name_data = $custom_event_names[key]
              
              final_name = ""
              if custom_name_data && custom_name_data[:event_name]
                 final_name = custom_name_data[:event_name]
              else
                 final_name = get_map_name(connected_id)
              end

              ve = VirtualEvent.new($game_map.map_id, x, y, :connection, final_name, [], connected_id)
              all_connections.push(ve)
            end
          end
        end
      end
    end

    # 3. PROCESS USER POINTS OF INTEREST (POIS)
    current_map_id = $game_map.map_id
    $custom_event_names.each do |key, value|
      mid, ex, ey = key.split(';').map(&:to_i)
      next if mid != current_map_id
      next if value[:event_name] && value[:event_name].strip.downcase == "ignore"

      # Determine if we should create a Virtual Event
      should_create_virtual = false
      
      case value[:type]
      when :poi
        # Explicit POI: Always create (unless it's a connection/duplicate POI)
        should_create_virtual = true
        
      when :event
        # Explicit Event: NEVER create a virtual copy. It's just a label for a real event.
        should_create_virtual = false

      end

#          when :legacy, nil
#         # Legacy/Unknown: Use the Heuristic (Check if real event exists)
#         # If a real event exists (even invisible), DO NOT create virtual.
#         real_event_exists = false
#         for ev in $game_map.events.values
#            if ev.x == ex && ev.y == ey
#              real_event_exists = true
#              break
#            end
#         end
#         should_create_virtual = !real_event_exists
#       end
#  end

 if should_create_virtual
        # Deduplicate against connections
        next if all_connections.any? { |c| c.x == ex && c.y == ey }
        
        ve = VirtualEvent.new(mid, ex, ey, :poi, value[:event_name])
        all_others.push(ve)
      end
    end

    # 4. FINALIZE AND FILTER
    reduceEventsInLanes(all_connections)
    reduceEventsInLanes(all_others)

    # --- FINAL FILTER: REMOVE IGNORED GROUPS ---
    reject_ignore = proc do |e|
       (e.respond_to?(:custom_name) && e.custom_name && e.custom_name.strip.downcase == "ignore") ||
       (e.respond_to?(:name) && e.name && e.name.strip.downcase == "ignore")
    end

    all_connections.reject!(&reject_ignore)
    all_others.reject!(&reject_ignore)
    final_list = []
    case current_filter
    when :all
      final_list = all_connections + all_others
    when :connections
      final_list = all_connections
    when :npcs
      final_list = all_others.select { |e| is_npc_event?(e) }
    when :items
      final_list = all_others.select { |e| is_item_event?(e) }
    when :merchants
      final_list = all_others.select { |e| is_merchant_event?(e) }
    when :signs
      final_list = all_others.select { |e| is_sign_event?(e) }
    when :hidden_items
      final_list = all_others.select { |e| is_hidden_item_event?(e) }
    when :pois
      final_list = all_others.select { |e| e.is_a?(VirtualEvent) && e.type == :poi }
    when :notes
      candidates = all_connections + all_others
      final_list = candidates.select do |e|
        key = "#{$game_map.map_id};#{e.x};#{e.y}"
        dat = $custom_event_names[key]
        dat && dat[:notes] && !dat[:notes].strip.empty?
      end
    end
    
    if @sort_by_distance
      final_list.sort! { |a, b| distance(@x, @y, a.x, a.y) <=> distance(@x, @y, b.x, b.y) }
    end
    
    # Save to Session
    PraSession.mapevents = final_list
    PraSession.selected_event_index = final_list.empty? ? -1 : 0
  end  

def reduceEventsInLanes(events_list)
    buckets = {}
    
    # --- UPDATED BUCKETING LOGIC ---
    # We now create buckets for ANY event that should be grouped.
    # 1. Connections group by Destination ID.
    # 2. Named NPCs/POIs group by their Name.
    get_group_key = proc do |e|
      if e.is_a?(VirtualEvent) && e.type == :connection
        "conn_#{e.destination_id}"
      elsif is_teleport_event?(e)
        dest = get_teleport_destination_name(e) # Or logic to get ID
        # Since getting the exact ID from real events is tricky without parsing commands again,
        # we can stick to grouping real connections by their coordinates if needed, 
        # but usually, they fall into the 'connection' bucket if we extracted the ID.
        # For now, let's group adjacent teleport events if they go to the same map ID.
        dest_id = nil
        if e.list
          e.list.each do |cmd|
            if cmd.code == 201 
              dest_id = cmd.parameters[1]
              break
            end
          end
        end
        dest_id ? "conn_#{dest_id}" : nil
      else
        # --- NEW: Group by Name ---
        # If the event has a specific name (Custom or Real), use that as the key.
        # We ignore generic names to prevent merging random items.
        name_to_check = nil
        if e.respond_to?(:custom_name) && e.custom_name && !e.custom_name.strip.empty?
          name_to_check = e.custom_name
        elsif e.is_a?(VirtualEvent) && e.name
          name_to_check = e.name
        elsif e.respond_to?(:name)
          name_to_check = e.name
        end

        # IMPORTANT: Allow grouping by "ignore" so ignored tiles cluster together
        if name_to_check && !name_to_check.strip.empty? && name_to_check != "Interactable object" && name_to_check != "Point of Interest"
          "name_#{name_to_check}"
        else
          nil
        end
      end
    end
    # Fill Buckets
    events_list.each do |e|
      key = get_group_key.call(e)
      if key
        buckets[key] ||= []
        buckets[key] << e
      else
        # If it doesn't fit a bucket, it shouldn't be removed, but our logic below clears the list.
        # So we treat "nil" key as "Unique events", but we can't bucket them together.
        # We will handle them by keeping them separate.
        # TRICK: Use the object ID as a unique key for non-groupables.
        buckets[e.object_id] = [e]
      end
    end

    events_list.clear
    
    # Process Buckets
    buckets.each do |key, bucket|
      # If bucket has 1 item, just add it back
      if bucket.size == 1
        events_list << bucket[0]
        next
      end

      # For multiple items, perform the spatial clustering (Flood Fill)
      while !bucket.empty?
        current = bucket.shift
        cluster = [current]
        
        loop do
          found_new = false
          bucket.dup.each do |candidate|
            # Check if candidate is adjacent (4-way) to ANY tile in the cluster
            is_connected = cluster.any? do |c| 
              (c.x - candidate.x).abs + (c.y - candidate.y).abs == 1
            end
            
            # --- FIX: Use 'is_connected' instead of 'dist' ---
            if is_connected
              cluster << candidate
              bucket.delete(candidate)
              found_new = true
            end
          end
          break unless found_new
        end
        
        # Sort by coordinates to find "Middle" or "Top-Left"
        cluster.sort_by! { |e| [e.x, e.y] }
        mid_event = cluster[cluster.size / 2]
        
        # Consolidate candidates
        all_coords = []
        cluster.each do |e|
          all_coords << [e.x, e.y]
          if e.respond_to?(:candidates) && e.candidates
            all_coords.concat(e.candidates)
          end
        end
        
        # --- CLUSTER NAMING FIX (WITH IGNORE PRIORITY) ---
        found_custom_name = nil
        should_ignore_cluster = false
        
        cluster.each do |e|
          # Determine the name for this specific tile
          name = nil
          if e.respond_to?(:custom_name) && e.custom_name
             name = e.custom_name
          else
             # Fallback to checking hash directly (safety)
             key_coords = "#{$game_map.map_id};#{e.x};#{e.y}"
             if $custom_event_names[key_coords] && $custom_event_names[key_coords][:event_name]
                name = $custom_event_names[key_coords][:event_name]
             end
          end
          
          # Check priority
          if name
             if name.strip.downcase == "ignore"
                should_ignore_cluster = true
                break # Found ignore! The whole cluster is doomed.
             elsif !name.strip.empty?
                found_custom_name = name
             end
          end
        end
        
        if should_ignore_cluster
           mid_event.custom_name = "ignore"
        elsif found_custom_name
           mid_event.custom_name = found_custom_name
        end
        # -------------------------------------------------
        
        mid_event.candidates = all_coords.uniq
        events_list << mid_event
      end
    end
  end  

  def pathfind_to_selected_event
    idx = PraSession.selected_event_index
    list = PraSession.mapevents
    return if idx < 0 || list.nil? || list[idx].nil?
    
    target_event = list[idx]
    route = []

    # STRATEGY 1: Check Candidates (Virtual Connections)
    if target_event.respond_to?(:candidates) && target_event.candidates && !target_event.candidates.empty?
      for tile in target_event.candidates
        cand_route = aStern(Node.new(@x, @y), Node.new(tile[0], tile[1]))
        if !cand_route.empty?
          route = cand_route
          break
        end
      end
      
      if route.empty?
        tts("Could not find a path to any tile in this connection.")
        return
      end

    # STRATEGY 2: Standard Event Pathfinding
    else
      route = aStern(Node.new(@x, @y), Node.new(target_event.x, target_event.y))
      if route.empty?
        possible_targets = getEventTiles(target_event)
        for target in possible_targets
          alternative_route = aStern(Node.new(@x, @y), target.node)
          if !alternative_route.empty?
            route = alternative_route
            break
          end
        end
      end
    end
    
    if route.empty?
      tts("No path found.")
    else
      if defined?($auto_walk) && $auto_walk && defined?(start_autowalk)
        start_autowalk(route)
      else
        printInstruction(convertRouteToInstructions(route))
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
      if iterations > 5000
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

      neighbthes = getNeighbthes(currentNode, target, isTargetPassable, targetDirection, map)
      for neighbthe in neighbthes
        if nodeInSet(neighbthe, closedSet)
          next
        end
        neighbtheIndex = getNodeIndexInSet(neighbthe, openSet)
        newMovementCostToNeighbthe = 2
        if currentNode.parent != "none"
          xDifNeighbthe = neighbthe.x - currentNode.x
          yDifNeighbthe = neighbthe.y - currentNode.y
          xDifParent = currentNode.x - currentNode.parent.x
          yDifParent = currentNode.y - currentNode.parent.y
          if xDifNeighbthe == xDifParent && yDifNeighbthe == yDifParent
            newMovementCostToNeighbthe = currentNode.gCost + 1
          else
            newMovementCostToNeighbthe = currentNode.gCost + 1.5
          end
        else
          newMovementCostToNeighbthe = 1.5
        end

        if neighbtheIndex > -1 && newMovementCostToNeighbthe < openSet[neighbtheIndex].gCost
          openSet[neighbtheIndex].gCost = newMovementCostToNeighbthe
          openSet[neighbtheIndex].hCost = distanceNode(openSet[neighbtheIndex], target)
          openSet[neighbtheIndex].parent = currentNode
        end
        if (neighbtheIndex == -1)
          neighbthe.gCost = newMovementCostToNeighbthe
          neighbthe.hCost = distanceNode(neighbthe, target)
          neighbthe.parent = currentNode
          openSet.push(neighbthe)
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

  def getNodeIndexInSet(neighbthe, set)
    i = 0
    while i < set.length do
      if set[i].equals(neighbthe)
        return i
      end
      i = i + 1
    end
    return -1
  end

  def nodeInSet(neighbthe, set)
    for node in set
      if node.equals(neighbthe)
        return true
      end
    end
    return false
  end

# Helper to add valid neighbors to the A* list
  # NUCLEAR DEBUG VERSION: Logs EVERYTHING
  def push_neighbthe(neighbthes, node, dir, target = nil)
    # Calculate offsets
    offsetx, offsety =  0,  1 if dir == 2
    offsetx, offsety = -1,  0 if dir == 4
    offsetx, offsety =  1,  0 if dir == 6
    offsetx, offsety =  0, -1 if dir == 8

    next_x = node.x + offsetx
    next_y = node.y + offsety

    # --- HELPER: Debug Event Scan ---
    scan_events = ->(tx, ty, context) {
      found_something = false
      if $game_map.events
        # tts("#{context} scanning at #{tx}, #{ty}...") # Uncomment if needed
        for event in $game_map.events.values
          if event.x == tx && event.y == ty
            found_something = true
            name = event.character_name
            thr = event.through
            id = event.id
            # Log everything found
            #tts("Found Event #{id} at #{tx},#{ty}. Name: '#{name}'. Thr: #{thr}")
            
            if name != "" && !thr
               return true # Blocked
            end
          end
        end
      end
      return false
    }
    # --------------------------------

    # 1. MOVEMENT (Walking)
    can_walk = is_path_passable?(node.x, node.y, dir)
    next_tag = $game_map.valid?(next_x, next_y) ? $game_map.terrain_tag(next_x, next_y) : 0
    
    # Override for Stairs
    if !can_walk && (next_tag == 27 || next_tag == 28)
      can_walk = true 
    end

    if can_walk && scan_events.call(next_x, next_y, "Walk")
       can_walk = false
    end
    
    if next_tag == 4 || next_tag == 5 || next_tag == 26
       can_walk = false
    end

    if can_walk || (target && target.equals(Node.new(next_x, next_y)))
      neighbthes.push(Node.new(next_x, next_y))
    end
    
    # 2. JUMP LOGIC
    if is_path_ledge_passable?(node.x, node.y, dir)
      
      ledge_x = next_x
      ledge_y = next_y
      return unless $game_map.valid?(ledge_x, ledge_y)

      # tts("Checking Jump #{dir} at #{ledge_x},#{ledge_y}") # Announce Jump Attempt

      # Tile Data
      tag = 0
      tile_id = 0
      [2, 1, 0].each do |layer|
        tid = $game_map.data[ledge_x, ledge_y, layer]
        next if tid == 0
        t_tag = $game_map.terrain_tag(ledge_x, ledge_y)
        if t_tag == 1 || t_tag == 27 || t_tag == 28
          tag = t_tag
          tile_id = tid
          break
        end
      end
      tag = $game_map.terrain_tag(ledge_x, ledge_y) if tag == 0
      is_ledge = (tag == 1)
      is_stair = (tag == 27 || tag == 28)
      
      has_jump_event = false
      for event in $game_map.events.values
        if event.x == ledge_x && event.y == ledge_y && is_jump_event?(event, dir)
          has_jump_event = true
          break
        end
      end

      # Physics Check
      if is_ledge && !has_jump_event
         passages = $game_map.passages[tile_id] rescue 0
         blocked = false
         blocked = true if dir == 2 && (passages & 0x01 == 0x01)
         blocked = true if dir == 4 && (passages & 0x02 == 0x02)
         blocked = true if dir == 6 && (passages & 0x04 == 0x04)
         blocked = true if dir == 8 && (passages & 0x08 == 0x08)
         
         if !blocked
            # tts("Jump rejected: Not blocked.")
            return 
         end
      end

      return if !is_ledge && !is_stair && !has_jump_event

      # Chain Jump
      # tts("Chain Jump Start")
      landing_x = node.x + offsetx * 2
      landing_y = node.y + offsety * 2
      
      5.times do
        break unless $game_map.valid?(landing_x, landing_y)
        
        # --- NEW: Check for Obstacles INSIDE the slide ---
        # If we slide through a rock, we should probably stop or block.
        if scan_events.call(landing_x, landing_y, "Slide")
           # tts("Slide blocked by event at #{landing_x},#{landing_y}")
           # If we hit an event, we stop sliding. 
           # If this is the rock, landing_x/y is now the rock's pos.
           break 
        end

        l_tag = $game_map.terrain_tag(landing_x, landing_y)
        if (l_tag == 1 || l_tag == 27 || l_tag == 28)
          landing_x += offsetx
          landing_y += offsety
        else
          break
        end
      end
      
      # Landing Validation
      # tts("Landing Check at #{landing_x}, #{landing_y}")
      landing_node = Node.new(landing_x, landing_y)

      # --- FINAL OBSTACLE CHECK ---
      if scan_events.call(landing_x, landing_y, "Landing")
         tts("Jump BLOCKED by event at #{landing_x}, #{landing_y}")
         return 
      end
      
      l_tag = $game_map.terrain_tag(landing_x, landing_y)
      if l_tag == 4 || l_tag == 5 || l_tag == 26
         tts("Jump BLOCKED by tag #{l_tag}")
         return
      end

      if target && target.equals(landing_node)
         neighbthes.push(landing_node)
         return
      end

      if $game_map.valid?(landing_x, landing_y) && $game_map.passable?(landing_x, landing_y, 0, $game_player)
         # tts("Jump Validated to #{landing_x}, #{landing_y}")
         neighbthes.push(landing_node)
      else
         # tts("Jump Rejected: Impassable.")
      end
    end
  end  
  # Updated getNeighbthes using the new push logic
  def getNeighbthes(node, target, isTargetPassable, targetDirection, map)
    neighbthes = []
    # If the target is strictly passable, we don't need to pass the target node to push_neighbthe
    chooseTarget = (isTargetPassable || targetDirection != -1) ? nil : target
    
    push_neighbthe(neighbthes, node, 2, chooseTarget)
    push_neighbthe(neighbthes, node, 4, chooseTarget)
    push_neighbthe(neighbthes, node, 6, chooseTarget)
    push_neighbthe(neighbthes, node, 8, chooseTarget)
    
    return neighbthes
  end

  def getTargetDirection(target, map)
    for event in map.events.values
      if event.x != target.x || event.y != target.y
        next
      end
      next if event.list.nil?
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
    if !PraSession.mapevents.nil? && !PraSession.mapevents.empty?
      
      # Cycle to the PREVIOUS event (J)
      if Input.triggerex?(0x4A)
        @PraSession.selected_event_index -= 1
        if PraSession.selected_event_index < 0
          PraSession.selected_event_index = PraSession.mapevents.size - 1 # Wrap around
        end
        announce_selected_event
      end

      # Cycle to the NEXT event (L)
      if Input.triggerex?(0x4C)
        PraSession.selected_event_index += 1
        if PraSession.selected_event_index >= PraSession.mapevents.size
          PraSession.selected_event_index = 0 # Wrap around
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

class Scene_Map
  # A flag to ensure we only load the names once per game session
  @@pra_names_loaded = false

  alias_method :access_mod_original_main, :main
  def main
    # Load custom event names if they haven't been loaded yet
    if !@@pra_names_loaded
      load_custom_names
      @@pra_names_loaded = true

      # This prevents the character from walking immediately upon enabling the toggle
      if $game_player && $game_player.respond_to?(:clear_autowalk_route)
        $game_player.clear_autowalk_route
      end
    end
    
    # Force an initial population of the event list to prevent TTS freeze
    $game_player.populate_event_list if $game_player
    
    # Call the original main method to start the game loop as normal
    access_mod_original_main
  end
end

#===============================================================================
# Data System for Custom Event Names
#===============================================================================
# Define the global hash to store names while the game is running
$custom_event_names = {}
# Define the path for the save file
CUSTOM_NAMES_FILE = "pra-custom-names.txt"

# Method to load the custom names from the file
def load_custom_names
  $custom_event_names = {}
  return unless File.exist?(CUSTOM_NAMES_FILE)

  File.open(CUSTOM_NAMES_FILE, "r") do |file|
    file.each_line do |line|
      next if line.start_with?("#") || line.strip.empty?
      
      parts = line.strip.split(";").map(&:strip)
      next if parts.length < 5
      
      # Attempt to read the new 7th column (type)
      map_id, map_name, x, y, event_name, notes, type_str = parts
      
      key = "#{map_id};#{x};#{y}"
      
      # Determine Type
      # :poi   = Explicitly created via Shift+L
      # :event = Explicitly renamed via Shift+K
      # :legacy = Old file entry (unknown intent)
      type = :event
      if type_str
        cleaned_type = type_str.strip.downcase
        type = :poi if cleaned_type == "poi"
        type = :event if cleaned_type == "event"
      end

      $custom_event_names[key] = {
        map_name: map_name,
        event_name: event_name,
        notes: notes || "",
        type: type
      }
    end
  end
  tts ("Custom event names loaded from #{CUSTOM_NAMES_FILE}.")
end

# Method to save the custom names to the file
def save_custom_names
  header = <<~TEXT
    # Pokémon Reborn Access - Custom Event Names
    # This file allows you to provide custom, meaningful names for in-game events, as well as ignoring events and creating your own Points of Interest.
    # The mod will automatically read this file when the game starts.
    # --- FORMAT ---
    # Each line must have 7 fields, separated by a semicolon (;).
    # map_id;map_name;coord_x;coord_y;event_name;notes;type
    # Type can be 'event' (renamed real event) or 'poi' (virtual point of interest).
    # --- IMPORTANT ---
    # - Do NOT use semicolons (;) in any of the names or notes.
    # - You can also create entries in-game by pressing Shift+K on a selected event, or create a POI with Shift+L.
    # For the full, detailed guide, please visit the project's README on GitHub:
    # [https://github.com/fclorenzo/pkreborn-access]
    #
  TEXT

  File.open(CUSTOM_NAMES_FILE, "w") do |file|
    file.puts(header)
    $custom_event_names.each do |key, value|
      map_id, x, y = key.split(";")
      
      # Determine what to write for the type column
      type_str = (value[:type] == :poi) ? "poi" : "event"      
      parts = [map_id, value[:map_name], x, y, value[:event_name], value[:notes]]
      parts.push(type_str) if type_str # Only add 7th column if we know the type
      
      file.puts(parts.join(";"))
    end
  end
  tts ("Custom event names saved to #{CUSTOM_NAMES_FILE}.")
end

#===============================================================================
# ** Bug Fix for addMovedEvent Crash **
# This patches a base game method to prevent a crash with certain events.
#===============================================================================
class PokemonMapMetadata
  # Re-open the class to overwrite the method
  def addMovedEvent(eventID)
    key = [$game_map.map_id, eventID]
    event = $game_map.events[eventID]
    # --- SAFETY CHECK START ---
    # If the event doesn't exist on the current map, do nothing instead of crashing.
    return if event.nil?
    # --- SAFETY CHECK END ---
    @movedEvents[key] = [event.x, event.y, event.direction, event.through, event.opacity]
  end
end