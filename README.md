# Pokémon Reborn Access

V2.7.0

## Description

The Pokémon Reborn Access project (PRA) consists of mods to further enhance accessibility for blind players in the Pokémon Reborn game, designed to be played alongside the "blindstep" password.

Confirmed working with game version 19.6 on Windows and the NVDA screen reader: [https://www.nvaccess.org/download/](https://www.nvaccess.org/download/).

I will always try to keep the mods updated to work with the latest game version, but feedback about other platforms or game versions is welcome and encouraged!

## Contents

The project is modular. You can choose to install the features you want.

- **Pathfinding Mod (`pra-pathfind.rb`)**: Provides a scanner to find and get pathfinding directions to events on the map. Includes a category filtering system and the ability to find paths across water (Surf and Waterfall).
- **Accessible Summary Mod (`pra-accessible-summary.rb`)**: Adds an accessible, text-based summary screen to the Pokémon party and PC storage menus.

## Controls

### Map Controls

- **F5**: Refresh the scanner's list of events on the current map.
- **O and I**: Cycle forward and backward through event filters. The available filters are: All, Connections, NPCs, Items, Merchants, Signs, and Hidden Items.
- **J, K and L**: Announce previous, current, and next event in the events list.
- **Shift + P**: Announce the X and Y coordinates of the selected event.
- **P**: Announce the path for the selected event.
- **H**: Cycle through HM pathfinding modes. The available modes are: `Off`, `Surf Only`, and `Surf & Waterfall`.

### Pokémon Party Menu Controls

When you open the menu for a Pokémon in your party, a new option is available:

- **Accessible Summary**: Selecting this opens a sub-menu with two choices:
  - **Display BST**: Reads the Pokémon's species, form, typing, base stats, and abilities.
  - **Pokemon Details**: Reads more in-depth information, including level, held item, nature, IVs, EVs, and moves.
  - **Export Team**: Exports your party to a file in pokepaste format.

### Pokémon PC Menu Controls

The "Accessible Summary" option is also available when you select a Pokémon in a PC box. It provides the "Display BST" and "Pokemon Details" sub-options.

## Installation

### Download the Game

1. [Download the game here](https://www.rebornevo.com/pr/index.html/).
2. Extract the ZIP folder and run the game.
3. If prompted, apply updates. If updates break the mod, please [submit an issue](https://github.com/fclorenzo/pkreborn-access/issues).
4. When asked for special instructions, choose “Yes” and enter the password "blindstep" to enable in-game accessibility features.

### Install the Mods

1. Download the mod files by going to [the latest release page](https://github.com/fclorenzo/pkreborn-access/releases/latest).
2. Locate the "assets" section.
3. Under that section, you will find the mod files: "pra-pathfind.rb" and "pra-accessible-summary.rb". Download the files for the features you wish to use. You can install one or both.
4. Finally, create a folder called "Mods" inside the "patch" folder of your game, usually something like "Reborn-xxx-windows>patch" (where "xxx" corresponds to your game version), and paste the file(s) you just downloaded there.

## Custom Event Naming (Community Project)

**The Problem:** As many players know, the scanner often announces generic event names like "ev12" or "Interactable object." This makes it difficult to know what you are navigating to.

**The Solution:** This feature allows the mod to read from a simple text file, `pra-custom-names.txt`, to replace those generic names with meaningful, human-readable ones (e.g., "Rival Battle 1" or "Hidden Moon Stone"). This file is a collaborative community effort, and your contributions are what will make it great.

### How to Use the Community Names File

1. **Download the File:** Get the latest version of the community-curated names file here: **[LINK TO THE COMMUNITY FILE HERE]**
2. **Place the File:** Place the downloaded `pra-custom-names.txt` file into your main Pokémon Reborn game folder (the same folder that contains `Game.exe`). The mod will automatically detect and load it the next time you start the game.

### How to Find Event Information

If you want to find an event in the file or add a new one, you first need to get its unique identifiers. The mod makes this easy:

1. Use the **J** and **L** keys to select the event with the scanner.
2. Press **Shift + P** to hear the event's coordinates (e.g., "Coordinates: X 36, Y 29").
3. Press the **D** key to hear the map information (e.g., "Map 586, Azurine Island").

You now have all the information (`map_id`, `coord_x`, and `coord_y`) you need to find or add that specific event in the `pra-custom-names.txt` file.

### File Format Explained

The `pra-custom-names.txt` file is a simple text file that uses a semicolon (`;`) to separate its columns. Each line represents a single event.

| Column | Name | Required? | Description |
| :--- | :--- | :--- | :--- |
| 1 | `map_id` | **Yes** | The unique ID number of the map the event is on. |
| 2 | `optional_map_name` | No | The name of the map (for human readability). The mod doesn't use this. |
| 3 | `coord_x` | **Yes** | The event's X coordinate on the map. |
| 4 | `coord_y` | **Yes** | The event's Y coordinate on the map. |
| 5 | `event_name` | **Yes** | The new, meaningful name you want the mod to announce. |
| 6 | `optional_description`| No | An optional description. This is announced when you press `Shift+P`. |

**Example:**

``` plaintext
# map_id;optional_map_name;coord_x;coord_y;event_name;optional_description
586;Azurine Lake;36;29;Pokemon Trainer;Battle, mandatory.
```

### Contributing to the Community File

The master version of this file is hosted on a collaborative Google Docs document, allowing the community to update and improve it over time.

- **Link to the Google Doc:** **[LINK TO THE GOOGLE DOCS SPREADSHEET HERE]**
- **Guide for Screen Reader Users:** For those new to using Google Docs with a screen reader, this community-made guide is a fantastic resource: [Google Docs and NVDA Guide](https://docs.google.com/document/d/1J1oXAtwC7h8FpEY52TQWBwthTeAvdSv93RacuxkM0Rs/pub)

### Guidelines for Contributing

Your contributions are essential to making this feature useful for everyone. Here is a step-by-step guide to adding a new event to the community file:

1. **Find an Unnamed Event:** While playing the game, use the scanner (J and L keys). If you find an event that is announced with a generic name like "ev42" or "Interactable object," you've found a great candidate to add to the file.
2. **Gather the Information:** Use the mod's built-in tools to get the precise data for the event:
      - With the event selected in the scanner, press **Shift + P** to get its X and Y coordinates.
      - Press and hold the **D** key to get the Map ID and Map Name.
3. **Add a New Row:** Open the community Google Doc and add a new row for the event.
4. **Fill in the Columns:**
      - **`map_id`**: Enter the Map ID number you just found.
      - **`optional_map_name`**: Enter the Map Name. This is not used by the mod but is very helpful for other people editing the file.
      - **`coord_x` / `coord_y`**: Enter the X and Y coordinates.
      - **`event_name`**: This is the most important part. Enter a clear, descriptive name (e.g., "Nurse Joy," "Hidden Potion," "Rival Battle 2").
      - **`optional_description`**: If you wish, add a more detailed description. This will be announced when a user presses `Shift+P`.
5. **Important Rule:** Please **do not use semicolons (`;`)** in any of the fields, as this is the character used to separate the columns.

### Creating Your Own Personal Renames

You can also rename events for your own personal use directly in-game.

1. Select an event with the scanner using the **J** and **L** keys.
2. Press **Shift + K**.
3. A text box will appear, prompting you for a new name.
4. A second text box will then appear, prompting for an optional description.

This will automatically add or update the entry for that event in your local `pra-custom-names.txt` file.

## Report a Bug or Suggest a Feature

If you find a bug or want to suggest a feature, your contribution is appreciated! Please use the [issues page](https://github.com/fclorenzo/pkreborn-access/issues) after checking for duplicates.

You can also join the [Reborn Discord server](https://www.rebornevo.com/discord/invite/rebornevo/) and post in the `#zero-vision-reborn-blindstep` channel.

## Known Bugs

- Pathfinding may fail on complex routes that require multiple land/water transitions or other complex situations (e.g., island hopping, or platform jumping).

## Credits

- [Torre's Decat](https://www.rebornevo.com/forums/topic/59095-torres-madness-modpacks-debug-rogue-mod-stat-display-qol-bug-patching/) — for the accessible displaying of pokémon stats.
- [Malta10's pathfinding mod](https://www.rebornevo.com/forums/topic/55210-accessibility-mod-pack-reborn/) — for the original pathfinding mod implementation.
- [The Pokémon Access Project](https://github.com/nuive/pokemon-access) — for inspiring the idea to build something similar for Reborn.

---

Happy gaming!
