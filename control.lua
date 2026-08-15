local SHORTCUT_NAME = "quality-maxer-shortcut-apply"
local UPGRADE_ANY_QUALITY_SHORTCUT_NAME = "quality-maxer-shortcut-upgrade-any-quality"

-- Scan all quality prototypes and return the highest tier name currently available.
local function compute_highest_quality_name()
  local best_name = nil
  local best_level = -1

  for name, quality in pairs(prototypes.quality) do
    if quality.level > best_level then
      best_name = name
      best_level = quality.level
    elseif quality.level == best_level and best_name ~= nil and name < best_name then
      best_name = name
    end
  end

  return best_name
end

-- Cache the highest quality name so runtime code can reuse it cheaply.
local function refresh_cached_quality_name()
  storage.max_quality_name = compute_highest_quality_name()
end

-- Resolve the currently selected prototype from the custom input event payload.
local function get_selected_prototype(event)
  local selected = event and event.selected_prototype
  if not selected or not selected.base_type or not selected.name then
    return nil
  end

  local prototype_set = prototypes[selected.base_type]
  if prototype_set and prototype_set[selected.name] then
    return prototype_set[selected.name]
  end

  local normalized_base_type = selected.base_type:gsub("-", "_")
  prototype_set = prototypes[normalized_base_type]
  if prototype_set then
    return prototype_set[selected.name]
  end

  return nil
end

-- Try to smart-pipette the selected prototype at the highest available quality.
local function pipette_selected_prototype(player, event, quality_name)
  local prototype = get_selected_prototype(event)
  if not prototype then
    return 0
  end

  local ok = pcall(function()
    return player.pipette(prototype, quality_name, true)
  end)

  if ok then
    return 1
  end

  return 0
end

-- Return the upgrade planner stack when the player is holding it or has it open.
local function get_upgrade_planner_stack(player)
  local cursor_stack = player.cursor_stack
  if cursor_stack and cursor_stack.valid_for_read and cursor_stack.is_upgrade_item then
    return cursor_stack
  end

  local opened = player.opened
  if opened and opened.object_name == "LuaItemStack" and opened.valid_for_read and opened.is_upgrade_item then
    return opened
  end

  return nil
end

-- Check whether a mapper matches the prototype currently under the cursor.
local function mapper_matches_selected_prototype(mapper, selected_prototype)
  if not mapper or not selected_prototype then
    return false
  end

  if mapper.name ~= selected_prototype.name then
    return false
  end

  if selected_prototype.base_type then
    return mapper.type == selected_prototype.base_type or selected_prototype.base_type == "entity-ghost"
  end

  return mapper.type == "entity"
end

-- Use the only mapper as the target when the planner UI provides no selection payload.
local function mapper_matches_planner_target(mapper, selected_prototype, mapper_count)
  if selected_prototype then
    return mapper_matches_selected_prototype(mapper, selected_prototype)
  end

  return mapper_count == 1 and mapper ~= nil
end

-- When both mapper sides are the same prototype, changing one side should not silently clear the other.
local function should_mutate_planner_mapper(mapper, mapper_type, source, destination, selected_prototype, mapper_count)
  if not mapper or not mapper_matches_planner_target(mapper, selected_prototype, mapper_count) then
    return false
  end

  if source and destination and source.name == destination.name and source.type == destination.type then
    if mapper_type == "to" then
      return false
    end
  end

  return true
end

-- Clear the quality on one upgrade mapper so the planner shows Any quality.
local function apply_any_quality_to_upgrade_mapper(stack, mapper_index, mapper_type, mapper)
  if not mapper or mapper.quality == nil then
    return false
  end

  mapper.quality = nil

  if mapper_type == "from" then
    mapper.comparator = nil
  end

  local ok = pcall(function()
    stack.set_mapper(mapper_index, mapper_type, mapper)
  end)

  return ok
end

-- Remove the quality from matching upgrade planner entries for the hovered prototype.
local function apply_any_quality_to_upgrade_planner(stack, selected_prototype)
  if not (stack and stack.valid_for_read and stack.is_upgrade_item and selected_prototype) then
    return 0
  end

  local changes = 0
  local mapper_count = stack.mapper_count

  for i = 1, mapper_count do
    local source = stack.get_mapper(i, "from")
    local destination = stack.get_mapper(i, "to")

    if should_mutate_planner_mapper(source, "from", source, destination, selected_prototype, mapper_count) and apply_any_quality_to_upgrade_mapper(stack, i, "from", source) then
      changes = changes + 1
    end

    if should_mutate_planner_mapper(destination, "to", source, destination, selected_prototype, mapper_count) and apply_any_quality_to_upgrade_mapper(stack, i, "to", destination) then
      changes = changes + 1
    end
  end

  return changes
end

-- Rewrite the current cursor ghost to use the highest available quality.
local function set_cursor_ghost_quality(player, quality_name)
  local ghost = player.cursor_ghost
  if not ghost then
    return 0
  end

  local ghost_name = ghost.name
  if not ghost_name then
    return 0
  end

  local ok = pcall(function()
    player.cursor_ghost = { name = ghost_name, quality = quality_name }
  end)

  if ok then
    return 1
  end

  return 0
end

-- Apply max quality to a blueprint stack by updating all blueprint entities.
local function apply_quality_to_blueprint(stack, quality_name)
  if not (stack and stack.valid_for_read and stack.is_blueprint and stack.is_blueprint_setup()) then
    return 0
  end

  local entities = stack.get_blueprint_entities()
  if not entities then
    return 0
  end

  local changes = 0
  for i = 1, #entities do
    local entity = entities[i]
    if entity and entity.name and entity.quality ~= quality_name then
      entity.quality = quality_name
      changes = changes + 1
    end
  end

  if changes > 0 then
    stack.set_blueprint_entities(entities)
  end

  return changes
end

-- Apply max quality to matching upgrade planner mappers for the hovered prototype.
local function apply_quality_to_upgrade_planner(stack, quality_name, selected_prototype)
  if not (stack and stack.valid_for_read and stack.is_upgrade_item and selected_prototype) then
    return 0
  end

  local changes = 0
  local mapper_count = stack.mapper_count

  for i = 1, mapper_count do
    local source = stack.get_mapper(i, "from")
    local destination = stack.get_mapper(i, "to")

    if should_mutate_planner_mapper(source, "from", source, destination, selected_prototype, mapper_count) and source.quality ~= quality_name then
      source.quality = quality_name
      source.comparator = nil

      local ok = pcall(function()
        stack.set_mapper(i, "from", source)
      end)

      if ok then
        changes = changes + 1
      end
    end

    if should_mutate_planner_mapper(destination, "to", source, destination, selected_prototype, mapper_count) and destination.quality ~= quality_name then
      destination.quality = quality_name

      local ok = pcall(function()
        stack.set_mapper(i, "to", destination)
      end)

      if ok then
        changes = changes + 1
      end
    end
  end

  return changes
end

-- Apply max quality to a regular cursor item selected with Q (non-blueprint/non-planner).
local function apply_quality_to_cursor_item(player, quality_name)
  local stack = player.cursor_stack
  if not (stack and stack.valid_for_read) then
    return 0
  end

  if stack.is_blueprint or stack.is_blueprint_book or stack.is_upgrade_item or stack.is_deconstruction_item then
    return 0
  end

  local current_quality = stack.quality
  if current_quality and current_quality.name == quality_name then
    return 0
  end

  local item_name = stack.name
  if not item_name then
    return 0
  end

  local item_count = stack.count
  local ok = pcall(function()
    stack.set_stack({ name = item_name, count = item_count, quality = quality_name })
  end)

  if ok then
    return 1
  end

  return 0
end

-- Dispatch a stack to the blueprint and targeted upgrade planner quality handlers.
local function apply_to_stack_if_supported(stack, quality_name, selected_prototype)
  if not (stack and stack.valid_for_read) then
    return 0
  end

  local changed = 0
  changed = changed + apply_quality_to_blueprint(stack, quality_name)
  changed = changed + apply_quality_to_upgrade_planner(stack, quality_name, selected_prototype)
  return changed
end

-- Main handler for the max-quality shortcut.
local function apply_quality_maxer(player, event)
  if not (player and player.valid) then
    return
  end

  local quality_name = storage.max_quality_name
  if not quality_name then
    refresh_cached_quality_name()
    quality_name = storage.max_quality_name
  end

  if not quality_name then
    player.print({ "quality-maxer-shortcut.no-quality" })
    return
  end

  local changes = 0
  local selected_prototype = event and event.selected_prototype
  local cursor_stack = player.cursor_stack
  local has_cursor_stack = cursor_stack and cursor_stack.valid_for_read
  local has_blueprint_to_setup = player.blueprint_to_setup and player.blueprint_to_setup.valid_for_read
  local has_cursor_ghost = player.cursor_ghost ~= nil

  -- The shortcut is explicitly for mutating the active ghost/planner target, not for pipetting a new item into hand.
  changes = changes + set_cursor_ghost_quality(player, quality_name)

  if has_cursor_stack then
    changes = changes + apply_quality_to_cursor_item(player, quality_name)
    changes = changes + apply_to_stack_if_supported(cursor_stack, quality_name, selected_prototype)
  end

  if has_blueprint_to_setup then
    changes = changes + apply_to_stack_if_supported(player.blueprint_to_setup, quality_name, selected_prototype)
  end

  local opened = player.opened
  if opened and opened.object_name == "LuaItemStack" and opened.valid_for_read then
    changes = changes + apply_to_stack_if_supported(opened, quality_name, selected_prototype)
  end

  if changes > 0 then
    player.create_local_flying_text({
      text = { "quality-maxer-shortcut.applied", quality_name, changes },
      create_at_cursor = true,
      color = { r = 0.2, g = 1.0, b = 0.2 }
    })
  else
    player.create_local_flying_text({
      text = { "quality-maxer-shortcut.no-target" },
      create_at_cursor = true,
      color = { r = 1.0, g = 0.8, b = 0.2 }
    })
  end
end

-- Main handler for the planner-only Any quality shortcut.
local function apply_upgrade_any_quality(player, event)
  if not (player and player.valid) then
    return
  end

  local selected_prototype = event and event.selected_prototype
  local stack = get_upgrade_planner_stack(player)
  if not stack then
    player.create_local_flying_text({
      text = { "quality-maxer-shortcut.no-target" },
      create_at_cursor = true,
      color = { r = 1.0, g = 0.8, b = 0.2 }
    })
    return
  end

  local changes = apply_any_quality_to_upgrade_planner(stack, selected_prototype)
  if changes > 0 then
    player.create_local_flying_text({
      text = { "quality-maxer-shortcut.applied", { "shortcut-name.quality-maxer-shortcut-upgrade-any-quality" }, changes },
      create_at_cursor = true,
      color = { r = 0.2, g = 1.0, b = 0.2 }
    })
  else
    player.create_local_flying_text({
      text = { "quality-maxer-shortcut.no-target" },
      create_at_cursor = true,
      color = { r = 1.0, g = 0.8, b = 0.2 }
    })
  end
end

local function handle_trigger(event)
  local player = game.get_player(event.player_index)
  if not player then
    return
  end

  apply_quality_maxer(player, event)
end

script.on_init(function()
  storage.max_quality_name = storage.max_quality_name or nil
  refresh_cached_quality_name()
end)

-- Refresh the cached quality name when mods or quality prototypes change.
script.on_configuration_changed(function()
  refresh_cached_quality_name()
end)

-- Register both configurable shortcuts.
script.on_event(SHORTCUT_NAME, handle_trigger)
script.on_event(UPGRADE_ANY_QUALITY_SHORTCUT_NAME, function(event)
  local player = game.get_player(event.player_index)
  if not player then
    return
  end

  apply_upgrade_any_quality(player, event)
end)
