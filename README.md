# Pokémon Reborn Access

V4.0.2

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
  - **For older game versions:** If you are playing a version older than 19.5.38, you must download the `blindstep.dat` and `settings.rb` files from **[Release V2.12.4](https://github.com/fclorenzo/pkreborn-access/releases/tag/V2.12.4)**.

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
  - `Notes` (Events with custom notes attached),
  - `Points of Interest` (Custom user-created markers).
- **J, K and L**: Announce previous, current, and next event in the events list.
- **Shift + J**: Toggle **Auto-Walk** On/Off.
- **Shift + K**: Rename the selected event and add optional notes.
- **Shift + L**: Create a **Point of Interest (PoI)** at custom coordinates.
- **N**: Announce the custom notes for the selected event (if any exist).
- **Shift + N**: Add a note to the selected event without changing its name.
- **Shift + P**: Announce the X and Y coordinates of the selected event, and indicate if the event has notes attached.
- **P**: Announce the path to the selected event. **If Auto-Walk is ON**, this will automatically walk the player to the target.
- **H**: Cycle through HM pathfinding modes. The available modes are:
  - `Off`,
  - `Surf Only`,
  - `Surf & Waterfall`.
- **Shift + H**: Toggle distance sorting of events on or off.

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
3. If prompted, apply updates. If updates break the mod, please [submit an issue](https://github.com/fclorenzo/pkreborn-access/issues/new/choose).
4. When asked for special instructions, choose “Yes” and enter the password "blindstep" to enable in-game accessibility features.

### Install the Mods

1. Download the mod files by going to [the latest release page](https://github.com/fclorenzo/pkreborn-access/releases/latest).
2. Locate the `assets` section.
3. Under that section, you will find the mod files. Download the files for the features you wish to use.
    - **Note:** If you need the **Terra Readability Mod** (for game versions older than 19.5.38), you must download the `blindstep.dat` and `settings.rb` files from **[Release V2.12.4](https://github.com/fclorenzo/pkreborn-access/releases/tag/V2.12.4)**, as they are no longer included in the latest version.
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

## Custom Event Naming & Points of Interest

This mod allows you to customize the names of events and create your own virtual markers (Points of Interest) to make navigation easier.

### Naming Existing Events

1. Select an event with the scanner (**J** / **L** keys).
2. Press **Shift + K**.
3. Enter a new name (e.g., "Healing Machine") and an optional note.
4. The event will now appear with this name in your list.
5. You can filter for these by pressing **O** until you hear "Filter set to Notes".

### Creating Points of Interest (PoIs)

Points of Interest are virtual events you create yourself at specific coordinates. They behave just like real events in the scanner.

1. Press **Shift + L**.
2. Enter the X and Y coordinates (defaults to your current position).
3. Give the PoI a name and an optional note.
4. The PoI will be created and added to your list immediately.
5. You can filter for these by pressing **O** until you hear "Filter set to Points of Interest".

### How to Ignore Specific Events

If there is an event you never want to interact with (e.g., a "junk" event), you can hide it from the scanner list.

1. Select the event with the scanner.
2. Press **Shift + K** to rename the event.
3. Type **ignore** as the name (This is not case-sensitive, so **Ignore** or **IGNORE** also work).
4. Press **F5** to refresh the list. The event will vanish.

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
# Real Event
586;Azurine Island;36;29;Pokemon Trainer;Battle, mandatory.
# Virtual PoI
586;Azurine Island;40;30;Good Fishing Spot;Use Good Rod here.
```

**Important Rule:** Please do not use semicolons (`;`) in the names or notes you create, as this character is used to separate the data fields.

## Community Label Sets

The **Community Label Sets** library allows players to share and download custom naming files (`pra-custom-names.txt`). This allows you to benefit from other players' map notes and Points of Interest.

### Downloading a Label Set

You can browse all available label sets in the **[Community Sets Library](community_sets/README.md)**.
The library table lists the Creator, Set Name, Language, Game Progress, and includes a direct download link.

**To use a downloaded set:**

1. Download the file from the library.
2. Make sure the file is named `pra-custom-names.txt`.
3. Place it in your game's Root folder.

### Submitting Your Own Set

If you have created a `pra-custom-names.txt` file and want to share it with the community:

1. **[Create a new issue](https://github.com/fclorenzo/pkreborn-access/issues/new/choose)**.
2. Select **Submit Custom Label Set**.
3. Fill out the required information:
   - **Label Set Name:** A unique name for your theme (e.g., "Lore Accurate Names").
   - **Version:** An integer number (e.g., 1, 2, 3, 10, 50000...). **Do not use decimals like 1.0.**
   - **Language:** The language of your labels.
   - **Game Progress:** How far into the game your labels cover (e.g., "Up to 7th gym").
   - **Upload File:** Drag and drop your `pra-custom-names.txt` file into the upload box or click the `Paste, drop, or click to add files` button.
4. Click **Create**.

**What happens next?**

- Our **Automated Triage Bot** will immediately check your file to ensure it has the correct structure (valid columns) and scan it for profanity.
- If the validation passes, the issue will be marked for review.
- Once approved by a moderator, your set will be automatically published to the **Community Sets Library**.

### Disclaimer

All Community Label Sets are user-submitted content. While we have automated filters and manual review processes in place to prevent offensive content, the repository owner is not responsible for the specific contents of these files. Use them at your own discretion.

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

For simple bug reports and feature suggestions, please continue to use the [issues page](https://github.com/fclorenzo/pkreborn-access/issues).

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

---

Happy gaming!
