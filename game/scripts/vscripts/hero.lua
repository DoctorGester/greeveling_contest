---@type table<number, table>
hero_state_by_entity_id = {}

---@class Hero : Entity
---@field public native_unit_proxy CDOTA_BaseNPC_Hero
---@field public egg_greevil Stored_Greevil
---@field public active_greevils Stored_Greevil[]
---@field public stored_greevils Stored_Greevil[]
---@field public greevil_eggs number
---@field public bonuses Bonus[]
---@field public is_hatching_an_egg boolean
---@field public started_hatching_at number

MAX_BONUS_SLOTS = 18

MAX_HERO_PRIMAL_SEALS = 1
MAX_HERO_GREATER_SEALS = 2
MAX_HERO_LESSER_SEALS = 4

MAX_ACTIVE_GREEVILS = 2
MAX_STORED_GREEVILS = 12

---@return Hero
function make_hero(native_unit_proxy)
    local hero = make_entity(Entity_Type.HERO, {
        native_unit_proxy = native_unit_proxy,
        greevil_eggs = 1,
        bonuses = {},
        egg_greevil = make_stored_greevil(MAX_HERO_PRIMAL_SEALS, MAX_HERO_GREATER_SEALS, MAX_HERO_LESSER_SEALS),
        active_greevils = {},
        stored_greevils = {},
        is_hatching_an_egg = false
    })

    native_unit_proxy.attached_entity = hero

    update_hero_network_state(hero)

    return hero
end

---@param hero Hero
function assert_hero_can_act_on_an_egg(hero)
    assert(hero ~= nil, "Hero can't be nil")
    assert(hero.greevil_eggs > 0, "Hero needs to have an active egg")
    assert(not hero.is_hatching_an_egg, "Currently hatching an egg, can't act")
end

---@param hero Hero
---@param greevil_egg Greevil_Egg
function add_egg_to_hero_inventory(hero)
    hero.greevil_eggs = hero.greevil_eggs + 1

    update_hero_network_state(hero)
end

---@param hero Hero
function find_empty_inventory_slot(hero)
    for slot_index = 1, MAX_BONUS_SLOTS do
        if not hero.bonuses[slot_index] then
            return slot_index, true
        end
    end

    return nil, false
end

---@param hero Hero
---@param bonus Bonus
function add_bonus_to_hero_inventory(hero, bonus)
    assert(hero ~= nil)
    assert(bonus ~= nil)

    local empty_slot_index, found = find_empty_inventory_slot(hero)

    assert(found, "No empty slot found")

    hero.bonuses[empty_slot_index] = bonus
    update_hero_network_state(hero)
end

---@param hero Hero
function hero_has_a_slot_for_another_bonus(hero)
    local _, found = find_empty_inventory_slot(hero)

    return found
end

---@param hero Hero
---@param seal Bonus
function hero_egg_apply_seal(hero, seal)
    assert_hero_can_act_on_an_egg(hero)
    local result = stored_greevil_apply_seal(hero.egg_greevil, seal)

    if result ~= success then
        return result
    end

    update_hero_network_state(hero)

    return success
end

---@param hero Hero
function update_hero_network_state(hero)
    local hero_state = {}
    local big_egg = big_egg_by_team_id[hero.native_unit_proxy:GetTeam()]

    hero_state.bonuses = {}

    for slot_index, bonus in pairs(hero.bonuses) do
        hero_state.bonuses[slot_index] = {
            seal_type = bonus.seal_type,
            seal = bonus.seal
        }
    end

    hero_state.egg = {}
    hero_state.egg.primal_seals = hero.egg_greevil.primal_seals
    hero_state.egg.greater_seals = hero.egg_greevil.greater_seals
    hero_state.egg.lesser_seals = hero.egg_greevil.lesser_seals

    hero_state.active_greevils = {}
    hero_state.stored_greevils = {}

    for slot_index = 1, MAX_ACTIVE_GREEVILS do
        local stored_greevil = hero.active_greevils[slot_index]

        if stored_greevil then
            hero_state.active_greevils[slot_index] = {
                storage = {
                    primal_seals = stored_greevil.primal_seals,
                    greater_seals = stored_greevil.greater_seals,
                    lesser_seals = stored_greevil.lesser_seals,
                },
                respawn_at = stored_greevil.greevil.respawn_at
            }
        end
    end

    for slot_index = 1, MAX_STORED_GREEVILS do
        local stored_greevil = hero.stored_greevils[slot_index]

        if stored_greevil then
            hero_state.stored_greevils[slot_index] = {
                storage = {
                    primal_seals = stored_greevil.primal_seals,
                    greater_seals = stored_greevil.greater_seals,
                    lesser_seals = stored_greevil.lesser_seals,
                },
                respawn_at = stored_greevil.greevil.respawn_at
            }
        end
    end

    hero_state.is_hatching_an_egg = hero.is_hatching_an_egg
    hero_state.total_eggs = hero.greevil_eggs
    hero_state.big_egg_is_past_the_hatching_state = big_egg ~= nil and (big_egg.is_hatching or big_egg.has_hatched)

    hero_state_by_entity_id[hero.native_unit_proxy:GetPlayerOwnerID()] = hero_state

    CustomNetTables:SetTableValue("heroes", "state", hero_state_by_entity_id)
end

---@param hero Hero
---@param slot_index number
function hero_insert_seal(hero, slot_index)
    assert_hero_can_act_on_an_egg(hero)
    assert(slot_index ~= nil, "Slot index can't be nil")

    local seal = hero.bonuses[slot_index]

    assert(seal ~= nil, string.format("Seal not found in slot %i", slot_index))

    local result = hero_egg_apply_seal(hero, seal)

    if result ~= success then
        return result
    end

    hero.bonuses[slot_index] = nil

    update_hero_network_state(hero)

    return success
end

---@param hero Hero
---@param slot_index number
function hero_drop_seal(hero, slot_index)
    assert(slot_index ~= nil, "Slot index can't be nil")

    local seal = hero.bonuses[slot_index]

    assert(seal ~= nil, string.format("Seal not found in slot %i", slot_index))

    make_bonus(hero.native_unit_proxy:GetAbsOrigin(), seal.seal_type, seal.seal)
    hero.bonuses[slot_index] = nil

    update_hero_network_state(hero)
end

---@param hero Hero
---@param slot_index number
---@param big_egg Big_Egg
function hero_insert_seal_into_big_egg(hero, slot_index, big_egg)
    assert(hero ~= nil, "Hero can't be nil")
    assert(slot_index ~= nil, "Slot index can't be nil")
    assert(big_egg ~= nil, "Big egg can't be nil")

    if big_eggs_hatched then
        return error_big_eggs_have_already_hatched
    end

    local seal = hero.bonuses[slot_index]

    assert(seal ~= nil, string.format("Seal not found in slot %i", slot_index))

    local result = big_egg_apply_seal(big_egg, seal)

    if result ~= success then
        return result
    end

    hero.bonuses[slot_index] = nil
    update_hero_network_state(hero)

    return success
end

---@param hero Hero
---@param seal_type Seal_Type
---@param seal number
function hero_remove_seal(hero, seal_type, slot_index)
    assert_hero_can_act_on_an_egg(hero)

    assert(seal_type ~= nil, "Seal type can't be nil")
    assert(slot_index ~= nil, "Slot index can't be nil")
    assert(hero_has_a_slot_for_another_bonus(hero), "No empty slot to drop another bonus in")

    local removed_seal = stored_greevil_remove_seal(hero.egg_greevil, seal_type, slot_index)
    add_bonus_to_hero_inventory(hero, make_seal_in_inventory(seal_type, removed_seal))
end

---@param hero Hero
function hero_hatch_egg(hero)
    assert_hero_can_act_on_an_egg(hero)

    local slot_found = find_an_empty_greevil_table_and_slot(hero)
    assert(slot_found, "No slot found for a new greevil!")

    hero.started_hatching_at = GameRules:GetGameTime()
    hero.is_hatching_an_egg = true

    update_hero_network_state(hero)
end

function filter_empty_slots_from_seal_table(seal_table)
    local result_table = {}

    for _, seal in pairs(seal_table) do
        if seal ~= nil then
            table.insert(result_table, seal)
        end
    end

    return result_table
end

---@param hero Hero
---@return boolean, table, number
function find_an_empty_greevil_table_and_slot(hero)
    for slot_index = 1, MAX_ACTIVE_GREEVILS do
        if not hero.active_greevils[slot_index] then
            return true, hero.active_greevils, slot_index
        end
    end

    for slot_index = 1, MAX_STORED_GREEVILS do
        if not hero.stored_greevils[slot_index] then
            return true, hero.stored_greevils, slot_index
        end
    end

    return false, nil, nil
end

---@param hero Hero
function hero_finish_hatching_an_egg(hero)
    hero.is_hatching_an_egg = false
    hero.greevil_eggs = hero.greevil_eggs - 1

    ---@type Stored_Greevil
    local greevil_copy = {}

    copy_struct_into(hero.egg_greevil, greevil_copy)

    local greevil_primal_seals = filter_empty_slots_from_seal_table(hero.egg_greevil.primal_seals)
    local greevil_greater_seals = filter_empty_slots_from_seal_table(hero.egg_greevil.greater_seals)
    local greevl_lesser_seals = filter_empty_slots_from_seal_table(hero.egg_greevil.lesser_seals)

    hero.egg_greevil.primal_seals = {}
    hero.egg_greevil.greater_seals = {}
    hero.egg_greevil.lesser_seals = {}

    local slot_found, greevil_table, slot = find_an_empty_greevil_table_and_slot(hero)
    assert(slot_found, "Empty greevil slot not found!")

    greevil_table[slot] = greevil_copy

    local new_greevil = make_greevil(hero, greevil_primal_seals[1], greevil_greater_seals, greevl_lesser_seals)
    add_entity(new_greevil)
    greevil_copy.greevil = new_greevil

    update_hero_network_state(hero)

    if greevil_table == hero.stored_greevils then
        deactivate_greevil(new_greevil)
    end
end

---@param hero Hero
---@param greevil_slot number
---@param target_slot number
function hero_put_greevil_into_slot(hero, greevil_slot, target_slot)
    assert(hero ~= nil, "Hero can't be nil")
    assert(hero.stored_greevils[greevil_slot] ~= nil, "Invalid greevil slot!")
    assert(not hero.stored_greevils[greevil_slot].greevil.is_dead, "Trying to swap out a dead greevil")

    local current_active_greevil = hero.active_greevils[target_slot]
    local stored_greevil = hero.stored_greevils[greevil_slot]

    if current_active_greevil then
        deactivate_greevil(current_active_greevil.greevil)
    end

    activate_greevil_for_hero(hero, stored_greevil.greevil)

    hero.stored_greevils[greevil_slot] = current_active_greevil
    hero.active_greevils[target_slot] = stored_greevil

    update_hero_network_state(hero)
end

---@param hero Hero
function update_hero(hero)
    if hero.is_hatching_an_egg then
        local current_time = GameRules:GetGameTime()

        if current_time - hero.started_hatching_at > 3.0 then
            hero_finish_hatching_an_egg(hero)
        end
    end
end

---@param event table
function on_hatchery_insert_seal(event)
    local playerID = event.PlayerID

    ---@type Hero
    local hero = PlayerResource:GetPlayer(playerID):GetAssignedHero().attached_entity
    local result = hero_insert_seal(hero, event.seal + 1)

    if result == error_cant_insert_all_slots_are_full then
        emit_custom_hud_error_for_player(PlayerResource:GetPlayer(playerID), "error_all_slots_are_occupied", 80)
    end

    if result == error_max_seal_level then
        emit_custom_hud_error_for_player(PlayerResource:GetPlayer(playerID), "error_max_seal_level", 80)
    end
end

---@param event table
function on_hatchery_remove_seal(event)
    local playerID = event.PlayerID

    ---@type Hero
    local hero = PlayerResource:GetPlayer(playerID):GetAssignedHero().attached_entity
    hero_remove_seal(hero, event.seal_type, event.seal + 1)
end

---@param event table
function on_hatchery_hero_hatch_egg(event)
    local playerID = event.PlayerID

    ---@type Hero
    local hero = PlayerResource:GetPlayer(playerID):GetAssignedHero().attached_entity
    hero_hatch_egg(hero)
end

---@param event table
function on_hatchery_hero_feed_big_egg(event)
    local player_id = event.PlayerID
    local player = PlayerResource:GetPlayer(player_id)

    assert(player ~= nil)

    ---@type Hero
    local hero = player:GetAssignedHero().attached_entity

    ---@type Big_Egg
    local big_egg = big_egg_by_team_id[PlayerResource:GetTeam(player_id)]

    local result = hero_insert_seal_into_big_egg(hero, event.seal + 1, big_egg)

    if result == error_cant_insert_all_slots_are_full then
        emit_custom_hud_error_for_player(player, "error_all_slots_are_occupied", 80)
    end

    if result == error_max_seal_level then
        emit_custom_hud_error_for_player(player, "error_max_seal_level", 80)
    end

    if result == error_big_eggs_have_already_hatched then
        emit_custom_hud_error_for_player(player, "error_all_big_eggs_already_hatched", 80)
    end
end

---@param event table
function on_hatchery_hero_drop_seal(event)
    local player_id = event.PlayerID

    ---@type Hero
    local hero = PlayerResource:GetPlayer(player_id):GetAssignedHero().attached_entity

    hero_drop_seal(hero, event.seal + 1)
end

function on_hatchery_hero_put_greevil_into_slot(event)
    local greevil_slot = event.greevil_slot + 1
    local target_slot = event.target_slot + 1
    local player_id = event.PlayerID

    ---@type Hero
    local hero = PlayerResource:GetPlayer(player_id):GetAssignedHero().attached_entity

    hero_put_greevil_into_slot(hero, greevil_slot, target_slot)
end