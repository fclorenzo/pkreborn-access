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
