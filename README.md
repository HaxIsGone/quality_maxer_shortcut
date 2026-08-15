# quality_maxer_shortcut
A Factorio mod that adds a shortcut and hotkey (`ALT+Q`) to push target quality to the highest available quality tier.
# Quality maxer - hotkeys

A Factorio mod that adds the `ALT+Q` and `ALT+G` hotkeys to push target quality to the highest available quality tier or clear it to Any quality.

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
2. Press `ALT+Q` for maximum quality or `ALT+G` for Any quality.
3. The mod updates all supported targets without taking a new item into hand.