<<<<<<< HEAD
# quality_maxer_shortcut
A Factorio mod that adds a shortcut and hotkey (`ALT+Q`) to push target quality to the highest available quality tier.
=======
# Quality maxer - shortcut

A Factorio mod that adds a shortcut and hotkey (`ALT+Q`) to push target quality to the highest available quality tier.

## What it updates

- Cursor ghost quality (when possible)
- Blueprint entity quality for the blueprint in hand
- Blueprint quality while setting up blueprints (`player.blueprint_to_setup`)
- Upgrade planner mapper quality (`from` and `to`) so it also works while creating/editing upgrade planners

## Compatibility

- Detects the highest quality dynamically from runtime prototypes.
- Works with quality mods that add tiers beyond Legendary.

## Usage

1. Hold a blueprint or upgrade planner (or have a building ghost in cursor).
2. Click the `Max quality` shortcut or press `ALT+Q`.
3. The mod updates all supported targets to the highest available quality.
>>>>>>> fbce9b0 (Initial commit)
