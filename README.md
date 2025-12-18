# Pokémon Reborn Access

V3.2.1

## Description

The Pokémon Reborn Access project (PRA) consists of mods to further enhance accessibility for blind players in the Pokémon Reborn game, designed to be played alongside the "blindstep" password.

Confirmed working with game version 19.5 on Windows and the NVDA screen reader: [https://www.nvaccess.org/download/](https://www.nvaccess.org/download/).

I will always try to keep the mods updated to work with the latest game version, but feedback about other platforms or game versions is welcome and encouraged!

## Contents

The project is modular. You can choose to install the features you want.

- **Pathfinding Mod (`pra-pathfind.rb`)**: Provides a scanner to find and get pathfinding directions to events on the map.
- **Auto walk mod (`pra-walk.rb`)**: Provides the player with a functionality to automatically walk to desired coordinates on the map.
- **Accessible Summary Mod (`pra-accessible-summary.rb`)**: Adds an accessible, text-based summary screen to the Pokémon party and PC storage menus.
- **Gone Fishing Mod (`pra-gone-fishing.rb`)**: Automates the fishing mini-game by removing the need to press a button when a Pokémon bites.
- **Terra Readability Mod (`blindstep.dat` & `Settings.rb`) [Legacy]**: Replaces all instances of Terra's leet speak with English.
  - **Note:** As of game version **19.5.38**, this feature has been integrated into the base game and these files are no longer included in the latest mod releases.
  - **For older game versions:** If you are playing a version older than 19.5.38, you must download the `blindstep.dat` and `settings.rb` files from **[Release v2.12.4](https://github.com/fclorenzo/pkreborn-access/releases/tag/v2.12.4)**.

## Controls

### Map Controls

- **F5**: Manually refresh the scanner's list of events on the current map.
- **Shift + F5**: Toggle auto-refresh of the event list when entering a new map (On/Off).
- **O and I**: Cycle forward and backward through event filters. The available filters are:
  - `All`,
  - `Connections`,
  - `NPCs`,
  - `Items`,
  - `Merchants`,
  - `Signs`,
  - `Hidden Items`,
  - `Notes` (Events with custom notes attached).
- **J, K and L**: Announce previous, current, and next event in the events list.
- **N**: Announce the custom notes for the selected event (if any exist).
- **Shift + N**: Add a note to the selected event without changing its name.
- **Shift + P**: Announce the X and Y coordinates of the selected event, and indicate if the event has notes attached.
- **P**: Announce the path for the selected event, or auto walk to it if the auto walk toggle is on.
- **H**: Cycle through HM pathfinding modes. The available modes are:
  - `Off`,
  - `Surf Only`,
  - `Surf & Waterfall`.
- **Shift + H**: Toggle distance sorting of events on or off.
- **Shift + K**: Rename the selected event and add optional notes.
- **T**: Place the marker to a given x and y coordinates.
- **Q**: Get directions to the placed coordinates, or auto walk to them if the auto walk toggle is on.
- **R**: Toggle auto walk on or off.

### Pokémon Party Menu Controls

When you open the menu for a Pokémon in your party, a new option is available:

- **Accessible Summary**: Selecting this opens a sub-menu with three choices:
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
2. Locate the `assets` section.
3. Under that section, you will find the mod files. Download the files for the features you wish to use.
    - **Note:** If you need the **Terra Readability Mod** (for game versions older than 19.5.38), you must download the `blindstep.dat` and `settings.rb` files from **[Release v2.12.4](https://github.com/fclorenzo/pkreborn-access/releases/tag/v2.12.4)**, as they are no longer included in the latest version.
4. Finally, create a folder called "Mods" inside the "patch" folder of your game, usually something like "Reborn-xxx-windows>patch" (where "xxx" corresponds to your game version), and paste the file(s) you just downloaded there.
5. **[Legacy Instructions: Game Version < 19.5.38]**
   For the Terra Readability mod, you will need to place the `blindstep.dat` file in your "Data" folder. Specifically the root folder ("Reborn-xxx-windows>Data"), this will not work in a "patch>Data" folder. You also need to add the "blindstep" language in the languages array in the `settings.rb` file, in the "Scripts>Reborn" folder ("Reborn-xxx-windows>Scripts>Reborn"). Manually make the change needed by finding the languages array in the settings file, that should look like this:

    ```Settings.rb
    LANGUAGES = [
      ["Default", "default.dat"],
    ]
    ```

    Add this line inside the array:

    ```Settings.rb
      ["Blindstep", "blindstep.dat"],
    ```

    The array now should look like this:

    ```Settings.rb
    LANGUAGES = [
      ["Default", "default.dat"],
      ["Blindstep", "blindstep.dat"],
    ]
    ```

    Then, save the file. On start-up the game will prompt you to pick a language, choose `Blindstep`.

### Notes for Mods & Terra Readability Installation

- **Do not change the names of any files**, as it will likely break something due to the fact that the game loads the modfiles in alphabetical order. **If using the legacy Terra Readability mod**, the game specifically looks for those file names to work.
- **The auto walk mod requires the pathfind mod to be installed to work**.

## Custom Event Naming (Community Project)

**The Problem:** As many players know, the scanner often announces generic event names like "ev12" or "Interactable object." This makes it difficult to know what you are navigating to.

**The Solution:** This feature allows the mod to read from a simple text file, `pra-custom-names.txt`, to replace those generic names with meaningful, human-readable ones (e.g., "Rival Battle 1" or "Hidden Moon Stone"). This file is a collaborative community effort, and your contributions are what will make it great.

### How to Use the Community Names File

1. **Download the File:**
    - **a.** Open the link to the community file: **[Custom community file](https://docs.google.com/document/d/1OCNpQe4GQEQAycn-1AK4IINBfW09BkNd49YbTn7hiv0/edit?usp=sharing)**
    - **b.** In the menu bar at the top of the page, select **File**.
    - **c.** From the File menu, move your cursor down to **Download**.
    - **d.** A new sub-menu will appear. From this list, select **Plain Text (.txt)**.
    - **e.** Your browser will now download the file.

2. **Place and Rename the File:**
    - Find the file you just downloaded.
    - Make sure the file is named exactly **`pra-custom-names.txt`**.
    - Place this renamed file into your root Pokémon Reborn game folder (the same folder that contains `Game.exe`). The mod will automatically detect and load it the next time you start the game.

### How to Find Event Information

If you want to find an event in the file or manually add a new one, you first need to get its unique identifiers. The mod makes this easy:

1. Use the **J** and **L** keys to select the event with the scanner.
2. Press **Shift + P** to hear the event's coordinates (e.g., "Coordinates: X 36, Y 29").
3. Press the **D** key to hear the map information (e.g., "Map 586, Azurine Island").

You now have all the information (`map_id`, `coord_x`, and `coord_y`) you need to find or add that specific event in the `pra-custom-names.txt` file.

### File Format Explained

The `pra-custom-names.txt` file is a simple text file that uses a semicolon (`;`) to separate its columns. Each line represents a single event.

| Column | Name | Required? | Explanation |
| :--- | :--- | :--- | :--- |
| 1 | `map_id` | Yes | The unique ID number of the map the event is on. |
| 2 | `optional_map_name` | No | The name of the map (for human readability). The mod doesn't use this. |
| 3 | `coord_x` | Yes | The event's X coordinate on the map. |
| 4 | `coord_y` | Yes | The event's Y coordinate on the map. |
| 5 | `event_name` | Yes | The new, meaningful name you want the mod to announce. |
| 6 | `notes` | No | Optional notes (e.g., instructions). These are announced when you press **N**. |

**Example:**

``` plaintext
# map_id;optional_map_name;coord_x;coord_y;event_name;notes
586;Azurine Island;36;29;Pokemon Trainer;Battle, mandatory.
````

### How to Ignore Specific Events

If there is an event you never want to interact with (e.g., a "junk" event or a repetitive object), you can hide it from the scanner list.

1. Select the event with the scanner using the **J** and **L** keys.
2. Press **Shift + K** to rename the event.
3. When prompted for a name, type **Ignore**. (This is not case-sensitive, so `ignore` or `IGNORE` also work).
4. You can skip the notes field.
5. Press **F5** to refresh the event list.
    The event will no longer be loaded into the scanner list for that map.

### Naming Events & Contributing to the Community File

This feature allows you to replace generic event names like "ev12" with meaningful ones. You can create your own personal names for events, and we highly encourage you to contribute these names to the community so everyone can benefit.

#### How to Create Your Own Custom Names

This is the primary method for both personal use and for contributing.

1. While in-game, find an event you want to name and select it with the scanner using the **J** and **L** keys.
2. Press **Shift + K** to rename an event, or **Shift + N** to just add a note.
3. A text box will appear, prompting you for input.
4. If using Shift + K, a second text box will appear for optional notes.

After you're done, the mod automatically gathers the Map ID, Map Name, and coordinates, and saves a perfectly formatted entry to your local `pra-custom-names.txt` file, located in your root Pokémon Reborn folder.

#### How to Contribute to the Community File

The easiest and best way to contribute is to use the in-game renaming feature first. This prevents any typos in the map or coordinate data.

1. **Rename an Event In-Game:** Follow the steps above to give a meaningful name to a generic event.
2. **Find Your Local File:** Open the `pra-custom-names.txt` file located in your root Pokémon Reborn game folder.
3. **Copy the New Line:** Find the new line that was just added for the event you renamed. It will look something like this:
    `586;Azurine Island;36;29;Pokemon trainer;Battle, mandatory.`
4. **Paste into the Community Doc:** Copy that entire line and paste it into a new line in the community Google Doc.
      - **Link to the Community Google Doc:** **[Custom community file](https://docs.google.com/document/d/1OCNpQe4GQEQAycn-1AK4IINBfW09BkNd49YbTn7hiv0/edit?usp=sharing)**

**Important Rule:** Please do not use semicolons (`;`) in the names or notes you create, as this character is used to separate the data fields.

For those new to using Google Docs with a screen reader, this guide is a fantastic resource: [Google Docs and NVDA Guide](https://docs.google.com/document/d/1J1oXAtwC7h8FpEY52TQWBwthTeAvdSv93RacuxkM0Rs/pub)

Also, do note that, while the document can be publicly viewed, only allowed people have editing permissions. If you are a new contributor and would like to be able to edit the document, just request editing access via the Docs menu and [message me on Discord](https://www.discordapp.com/users/427201804061638681) so I can know you are not a random person who requested that.

## Report a Problem or Suggest a Feature

If you find a bug or documentation issue, or just want to suggest a feature, your contribution is appreciated! Please use the [issues page](https://github.com/fclorenzo/pkreborn-access/issues) after checking for duplicates,

Or post in [the mod's forum thread](https://www.rebornevo.com/forums/topic/79433-pokemon-reborn-access-pra-mods-to-enhance-accessibility-in-pokemon-reborn/).

You can also join the [Reborn server](https://www.rebornevo.com/discord/invite/rebornevo/) on Discord, and post in the `#zero-vision-reborn-blindstep` channel, or even dm me there.

## Known Bugs

- Pathfinder is not able to find routes inside Nightclub.
- Event cycling in wasteland makes the game music break.

## Contributing

Contributions from other developers are welcome and greatly appreciated! If you have an idea for a new feature or a bug fix, here's how you can help.

1. **Fork the Repository**: Start by creating your own copy (a "fork") of the project on GitHub.
2. **Create a New Branch**: Make all your changes on a dedicated branch in your fork, not on the `main` branch. This makes it easier to review and merge your changes.
3. **Make Your Changes**: Implement your new feature or bug fix in the code.
4. **Submit a Pull Request**: When your changes are ready, submit a "Pull Request" from your branch to the main project. Please provide a clear description of the changes you've made.

For simple bug reports and feature suggestions, please continue to use the [issues page](https://www.google.com/search?q=%23report-a-bug-or-suggest-a-feature).

## Credits

- [Aironfaar's Mod Box](https://www.rebornevo.com/forums/topic/40480-aironfaars-mod-box-e19updated-2022-05-22/) — for the original Gone Fishing mod.
- [Torre's Decat](https://www.rebornevo.com/forums/topic/59095-torres-madness-modpacks-debug-rogue-mod-stat-display-qol-bug-patching/) — for the accessible displaying of pokémon stats and team exporting.
- [Malta10's pathfinding mod](https://www.rebornevo.com/forums/topic/55210-accessibility-mod-pack-reborn/) — for the original pathfinding mod implementation.
- [The Pokémon Access Project](https://github.com/nuive/pokemon-access) — for inspiring the idea to build something similar for Reborn.
- [Enu](https://www.rebornevo.com/forums/profile/55272-enu/) — for helping me to understand Reborn's codebase.
- [Wire](https://github.com/yrsegal/crawli-support-pack) — for fixing jumping ledges issues.
- KilehKa — for modifying Terra's dialogues to improve readability for text-to-speech users.
- Maulpaul — for implementing the auto walk mod.
- The blindstep channel in the [reborn Discord server](https://www.rebornevo.com/discord/invite/rebornevo/) — for beta testing, suggesting features, and valuable feedback.

-----

Happy gaming!
