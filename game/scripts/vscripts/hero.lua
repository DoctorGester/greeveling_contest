---@type table<number, table>
hero_state_by_entity_id = {}

---@class Hero : Entity
---@field public native_unit_proxy CDOTA_BaseNPC_Hero
---@field public primal_seals Primal_Seal_Type[]
---@field public greater_seals Greater_Seal_Type[]
---@field public lesser_seals Lesser_Seal_Type[]
---@field public greevil_eggs number
---@field public bonuses Bonus[]
---@field public is_hatching_an_egg boolean
---@field public started_hatching_at number

MAX_BONUS_SLOTS = 18

MAX_HERO_PRIMAL_SEALS = 1
MAX_HERO_GREATER_SEALS = 2
MAX_HERO_LESSER_SEALS = 4

---@return Hero
function make_hero(native_unit_proxy)
    local hero = make_entity(Entity_Type.HERO, {
        native_unit_proxy = native_unit_proxy,
        greevil_eggs = 1,
        bonuses = {},
        primal_seals = {},
        greater_seals = {},
        lesser_seals = {},
        is_hatching_an_egg = false,
        started_hatchingg_at = -1
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
function add_egg_to_hero_inventory(hero, greevil_egg)
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
---@param seal_type Seal_Type
function find_empty_egg_seal_slot(hero, seal_type)
    local max_seals_of_this_type = get_max_hero_seal_amount_by_seal_type(seal_type)
    local seal_table = hero_get_seal_table_by_seal_type(hero, seal_type)

    for slot_index = 1, max_seals_of_this_type do
        if not seal_table[slot_index] then
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

    local seal_table = hero_get_seal_table_by_seal_type(hero, seal.seal_type)
    local empty_slot_index, found = find_empty_egg_seal_slot(hero, seal.seal_type)

    if not found then
        return error_cant_insert_all_slots_are_full
    end

    seal_table[empty_slot_index] = seal.seal
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
    hero_state.egg.primal_seals = hero.primal_seals
    hero_state.egg.greater_seals = hero.greater_seals
    hero_state.egg.lesser_seals = hero.lesser_seals

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
---@return table
function hero_get_seal_table_by_seal_type(hero, seal_type)
    if seal_type == Seal_Type.PRIMAL then
        return hero.primal_seals
    elseif seal_type == Seal_Type.GREATER then
        return hero.greater_seals
    elseif seal_type == Seal_Type.LESSER then
        return hero.lesser_seals
    else
        assert(false, "Unrecognized seal type " .. tostring(seal_type))
    end
end

---@param seal_type Seal_Type
---@return number
function get_max_hero_seal_amount_by_seal_type(seal_type)
    if seal_type == Seal_Type.PRIMAL then
        return MAX_HERO_PRIMAL_SEALS
    elseif seal_type == Seal_Type.GREATER then
        return MAX_HERO_GREATER_SEALS
    elseif seal_type == Seal_Type.LESSER then
        return MAX_HERO_LESSER_SEALS
    else
        assert(false, "Unrecognized seal type " .. tostring(seal_type))
    end
end

---@param hero Hero
---@param seal_type Seal_Type
---@param seal number
function hero_remove_seal(hero, seal_type, slot_index)
    assert_hero_can_act_on_an_egg(hero)

    assert(seal_type ~= nil, "Seal type can't be nil")
    assert(slot_index ~= nil, "Slot index can't be nil")
    assert(hero_has_a_slot_for_another_bonus(hero), "No empty slot to drop another bonus in")

    local seal_table = hero_get_seal_table_by_seal_type(hero, seal_type)

    assert(seal_table[slot_index] ~= nil, string.format("Invalid/empty seal slot %i", slot_index))

    local removed_bonus = seal_table[slot_index]
    seal_table[slot_index] = nil

    add_bonus_to_hero_inventory(hero, make_seal_in_inventory(seal_type, removed_bonus))
end

---@param hero Hero
function hero_hatch_egg(hero)
    assert_hero_can_act_on_an_egg(hero)

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
function hero_finish_hatching_an_egg(hero)
    hero.is_hatching_an_egg = false
    hero.greevil_eggs = hero.greevil_eggs - 1

    local greevil_primal_seals = filter_empty_slots_from_seal_table(hero.primal_seals)
    local greevil_greater_seals = filter_empty_slots_from_seal_table(hero.greater_seals)
    local greevl_lesser_seals = filter_empty_slots_from_seal_table(hero.lesser_seals)

    hero.primal_seals = {}
    hero.greater_seals = {}
    hero.lesser_seals = {}

    add_entity(make_greevil(hero, greevil_primal_seals[1], greevil_greater_seals, greevl_lesser_seals))
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
    local playerID = event.PlayerID

    ---@type Hero
    local hero = PlayerResource:GetPlayer(playerID):GetAssignedHero().attached_entity

    ---@type Big_Egg
    local big_egg = big_egg_by_team_id[PlayerResource:GetTeam(playerID)]

    local result = hero_insert_seal_into_big_egg(hero, event.seal + 1, big_egg)

    if result == error_cant_insert_all_slots_are_full then
        emit_custom_hud_error_for_player(PlayerResource:GetPlayer(playerID), "error_all_slots_are_occupied", 80)
    end

    if result == error_big_eggs_have_already_hatched then
        emit_custom_hud_error_for_player(PlayerResource:GetPlayer(playerID), "error_all_big_eggs_already_hatched", 80)
    end
end

---@param event table
function on_hatchery_hero_drop_seal(event)
    local playerID = event.PlayerID

    ---@type Hero
    local hero = PlayerResource:GetPlayer(playerID):GetAssignedHero().attached_entity

    hero_drop_seal(hero, event.seal + 1)
end