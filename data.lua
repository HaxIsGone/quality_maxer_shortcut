data:extend({
  {
    type = "custom-input",
    name = "quality-maxer-shortcut-apply",
    action = "lua",
    order = "a[quality-maxer-shortcut]-a[max-quality]",
    localised_name = { "shortcut-name.quality-maxer-shortcut-apply" },
    localised_description = { "shortcut-description.quality-maxer-shortcut-apply" },
    key_sequence = "ALT + Q",
    consuming = "game-only",
    include_selected_prototype = true
  },
  {
    type = "custom-input",
    name = "quality-maxer-shortcut-upgrade-any-quality",
    action = "lua",
    order = "a[quality-maxer-shortcut]-b[upgrade-any-quality]",
    localised_name = { "shortcut-name.quality-maxer-shortcut-upgrade-any-quality" },
    localised_description = { "shortcut-description.quality-maxer-shortcut-upgrade-any-quality" },
    key_sequence = "",
    consuming = "game-only",
    include_selected_prototype = true
  }
})
