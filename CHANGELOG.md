# Changelog

All notable changes for Quality maxer - hotkeys are documented here.

## [1.0.3] - 2026-08-15

### Fixed
- Restored the earlier `ALT+Q` max-quality behavior so it again works in the way that was previously more reliable.
- Kept the current `ALT+G` Any-quality planner fix in place.

### Changed
- Version bumped from `1.0.2` to `1.0.3`.

## [1.0.2] - 2026-08-15

### Added
- Required dependency on the Factorio `quality` mod in `info.json`.
- Clearer user-facing naming: the mod is now described as using hotkeys rather than shortcut buttons.

### Fixed
- Fixed planner behavior when using `ALT+G` (Any quality): the mod no longer tries to pick up a new item into hand while editing upgrade planner mappings.
- Fixed planner editing so only the matching mapper is changed instead of clearing unrelated planner entries.
- Fixed the case where both `from` and `to` entries shared the same item; changing one side no longer silently removes the other side's quality setting.
- Fixed ghost-only behavior so the max-quality hotkey updates the active ghost target without turning it into a hand item.
- Prevented accidental item pipetting during ghost/planner operations while preserving normal world behavior.

### Changed
- Updated mod title and descriptions from `shortcut` to `hotkey` terminology.
- Updated README wording to reflect the actual hotkey usage (`ALT+Q` for max quality, `ALT+G` for Any quality).
- Version bumped from `1.0.0` to `1.0.2`.

## [1.0.0] - Initial release

### Included
- Max quality hotkey support for:
  - cursor ghost quality
  - blueprint entity quality
  - blueprint setup quality
  - upgrade planner mapper quality
- Dynamic detection of the highest available quality prototype.
- Compatibility with quality mods that add tiers beyond Legendary.
- Support for `ALT+Q` to set target quality to the highest available quality tier.
