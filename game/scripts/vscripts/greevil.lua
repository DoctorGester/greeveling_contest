---@class Greevil : Entity
---@field public native_unit_proxy CDOTA_BaseNPC_Creature
---@field public respawn_at number
---@field public is_dead boolean
---@field public using_custom_death_timer boolean
---@field public tick_counter number

local MAX_ABILITY_LEVEL = 4
local RESPAWN_DURATION = 15.0

---@param primal_seal Primal_Seal_Type
---@param greater_seals Greater_Seal_Type[]
---@param lesser_seals Lesser_Seal_Type[]
---@param owner Hero
---@return Greevil
function make_greevil(owner, primal_seal, greater_seals, lesser_seals)
    local native_unit_proxy = owner.native_unit_proxy

    local greevil = CreateUnitByName(
        "npc_unit_bare_greevil",
        native_unit_proxy:GetAbsOrigin(),
        true,
        native_unit_proxy,
        native_unit_proxy,
        native_unit_proxy:GetTeamNumber()
    )

    greevil:EmitSound("greevil_hatch")

    fx("particles/ui/ui_game_start_hero_spawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, greevil, { release = true })

    print("Creating a greevil for player", owner.native_unit_proxy:GetPlayerID())

    if primal_seal then
        greevil:SetSkin(map_primal_seal_type_to_skin_id(primal_seal))
        greevil:AddNewModifier(greevil, nil, convert_primal_seal_type_to_animation_modifier_name(primal_seal), {})
    end

    randomize_greevil_wearables(greevil, map_primal_seal_type_to_skin_id(primal_seal))
    randomize_greevil_animation_set(greevil)

    local primal_seals_and_levels, greater_seals_and_levels, lesser_seals_and_levels =
        collapse_abilities_and_levels_into_abilities_with_levels({ primal_seal }, greater_seals, lesser_seals)

    for _, primal_seal_and_level in pairs(primal_seals_and_levels) do
        local ability = greevil:AddAbility(convert_primal_seal_type_to_ability_name(primal_seal_and_level.seal))

        ability:SetLevel(primal_seal_and_level.level)
    end

    for _, greater_seal_and_level in pairs(greater_seals_and_levels) do
        local ability = greevil:AddAbility(convert_greater_seal_type_to_ability_name(greater_seal_and_level.seal))

        ability:SetLevel(greater_seal_and_level.level)
    end

    for _, lesser_seal_and_level in pairs(lesser_seals_and_levels) do
        local modifier_name = convert_lesser_seal_type_to_modifier_name(lesser_seal_and_level.seal)
        local new_modifier = greevil:AddNewModifier(greevil, nil, modifier_name, {})
        new_modifier:SetStackCount(lesser_seal_and_level.level)

        if lesser_seal_and_level.seal == Lesser_Seal_Type.HEALTH then
            new_modifier:RefreshCustomHealth()
        end
    end

    local entity = make_entity(Entity_Type.GREEVIL, {
        respawn_at = 0,
        is_dead = false,
        using_custom_death_timer = false,
        native_unit_proxy = greevil,
        tick_counter = 0
    })

    greevil.attached_entity = entity

    return entity
end

---@param greevil CDOTA_BaseNPC_Creature
function randomize_greevil_animation_set(greevil)
    greevil:AddNewModifier(greevil, nil, "modifier_greevil_animation", {}):SetStackCount(RandomInt(0, 6))
end

---@param greevil CDOTA_BaseNPC_Creature
function randomize_greevil_wearables(greevil, skin_id)
    local all_ears = {
        "models/courier/greevil/greevil_ears1.vmdl",
        "models/courier/greevil/greevil_ears2.vmdl"
    }

    local all_hair = {
        nil,
        "models/courier/greevil/greevil_hair1.vmdl",
        "models/courier/greevil/greevil_hair2.vmdl"
    }

    local all_horns = {
        nil,
        "models/courier/greevil/greevil_horns1.vmdl",
        "models/courier/greevil/greevil_horns2.vmdl",
        "models/courier/greevil/greevil_horns3.vmdl"
    }

    local all_noses = {
        nil,
        "models/courier/greevil/greevil_nose1.vmdl",
        "models/courier/greevil/greevil_nose2.vmdl",
        "models/courier/greevil/greevil_nose3.vmdl"
    }

    local all_tails = {
        "models/courier/greevil/greevil_tail1.vmdl",
        "models/courier/greevil/greevil_tail2.vmdl",
        "models/courier/greevil/greevil_tail3.vmdl"
    }

    local all_teeth = {
        "models/courier/greevil/greevil_teeth1.vmdl",
        "models/courier/greevil/greevil_teeth2.vmdl",
        "models/courier/greevil/greevil_teeth3.vmdl"
    }

    local all_wings = {
        nil,
        "models/courier/greevil/greevil_wings1.vmdl",
        "models/courier/greevil/greevil_wings2.vmdl",
        "models/courier/greevil/greevil_wings3.vmdl"
    }

    local function add_random_wearable_from(from)
        local selected = from[RandomInt(1, #from)]

        if selected == nil then return end

        add_wearable_to_greevil(greevil, skin_id, selected)
    end

    add_random_wearable_from(all_ears)
    add_random_wearable_from(all_hair)
    add_random_wearable_from(all_horns)
    add_random_wearable_from(all_noses)
    add_random_wearable_from(all_tails)
    add_random_wearable_from(all_teeth)
    add_random_wearable_from(all_wings)

    add_wearable_to_greevil(greevil, skin_id, "models/courier/greevil/greevil_eyes.vmdl")
end

---@class Seal_And_Level
---@field public seal number
---@field public level number

---@param primal_seals Primal_Seal_Type[]
---@param greater_seals Greater_Seal_Type[]
---@param lesser_seals Lesser_Seal_Type[]
---@return Seal_And_Level[], Seal_And_Level[], Seal_And_Level[]
function collapse_abilities_and_levels_into_abilities_with_levels(primal_seals, greater_seals, lesser_seals)
    local collapsed_primal_seals = {}
    local collapsed_greater_seals = {}
    local collapsed_lesser_seals = {}
    local primal_seal_index = 1
    local greater_seal_index = 1
    local lesser_seal_index = 1

    local function collapse(seal, seal_table, current_index)
        local collapsed_seal = seal_table[seal]

        if collapsed_seal then
            collapsed_seal.level = collapsed_seal.level + 1
        else
            collapsed_seal = {
                level = 1,
                index = current_index
            }

            seal_table[seal] = collapsed_seal

            return current_index + 1
        end

        return current_index
    end

    for _, primal_seal in pairs(primal_seals) do
        primal_seal_index = collapse(primal_seal, collapsed_primal_seals, primal_seal_index)
    end

    for _, greater_seal in pairs(greater_seals) do
        greater_seal_index = collapse(greater_seal, collapsed_greater_seals, greater_seal_index)
    end

    for _, lesser_seal in pairs(lesser_seals) do
        lesser_seal_index = collapse(lesser_seal, collapsed_lesser_seals, lesser_seal_index)
    end

    local function flatten(seal_table)
        local flattened = {}

        for seal, data in pairs(seal_table) do
            flattened[data.index] = {
                seal = seal,
                level = data.level
            }
        end

        return flattened
    end

    local flattened_primal_seals = flatten(collapsed_primal_seals)
    local flattened_greater_seals = flatten(collapsed_greater_seals)
    local flattened_lesser_seals = flatten(collapsed_lesser_seals)

    local undistributed_ability_levels = (collapsed_lesser_seals[Lesser_Seal_Type.ABILITY_LEVEL] or {}).level

    print("Found", undistributed_ability_levels, "undistributed ability levels")

    if undistributed_ability_levels then
        local function get_and_decrement_remaining_ability_level(current_level)
            local level = math.min(undistributed_ability_levels, MAX_ABILITY_LEVEL - current_level)

            undistributed_ability_levels = undistributed_ability_levels - level

            print("Adding", level, "levels to", current_level)

            return level + current_level
        end

        for _, seal_and_level in pairs(flattened_primal_seals) do
            seal_and_level.level = get_and_decrement_remaining_ability_level(seal_and_level.level)
        end

        for _, seal_and_level in pairs(flattened_greater_seals) do
            seal_and_level.level = get_and_decrement_remaining_ability_level(seal_and_level.level)
        end

        for _, seal_and_level in pairs(flattened_lesser_seals) do
            if seal_and_level.seal ~= Lesser_Seal_Type.ABILITY_LEVEL then
                seal_and_level.level = get_and_decrement_remaining_ability_level(seal_and_level.level)
            end
        end
    end

    return flattened_primal_seals, flattened_greater_seals, flattened_lesser_seals
end

---@param primal_seal_type Primal_Seal_Type
---@return number
function map_primal_seal_type_to_skin_id(primal_seal_type)
    if primal_seal_type == nil then
        return 0 -- Gray
    end

    local primal_seal_type_to_skin_id = {
        [Primal_Seal_Type.RED] = 1,
        [Primal_Seal_Type.ORANGE] = 2,
        [Primal_Seal_Type.YELLOW] = 3,
        [Primal_Seal_Type.GREEN] = 4,
        [Primal_Seal_Type.BLUE] = 5,
        [Primal_Seal_Type.PURPLE] = 6,
        [Primal_Seal_Type.WHITE] = 7,
        [Primal_Seal_Type.BLACK] = 8
    }

    local skin_id = primal_seal_type_to_skin_id[primal_seal_type]

    assert(skin_id ~= nil, "Unrecognized primal seal type " .. tostring(primal_seal_type))

    return skin_id
end

function add_wearable_to_greevil(greevil, skin_id, model_path)
    ---@type CBaseModelEntity
    local wearable = SpawnEntityFromTableSynchronous("prop_dynamic", { model = model_path })
    wearable:FollowEntity(greevil, true)
    wearable:SetSkin(skin_id)
end

---@param greevil Greevil
function update_greevil(greevil)
    ---@type CDOTA_BaseNPC_Hero
    local owner = greevil.native_unit_proxy:GetOwner()

    greevil.tick_counter = greevil.tick_counter + 1

    if not greevil.is_dead then
        if owner:GetAttackTarget() ~= nil then
            greevil.native_unit_proxy:MoveToTargetToAttack(owner:GetAttackTarget())
        else
            if greevil.tick_counter % 10 == 0 then
            greevil.native_unit_proxy:MoveToNPC(owner) end
        end
    else
        if greevil.using_custom_death_timer and GameRules:GetGameTime() >= greevil.respawn_at then
            respawn_greevil(greevil)
        end
    end
end

---@param greevil Greevil
function network_greevil_respawn_time(greevil)
    local entity_index = greevil.native_unit_proxy:GetEntityIndex()

    CustomGameEventManager:Send_ServerToAllClients("greevil_respawn_time", {
        entity_index = entity_index,
        respawn_time_remaining = greevil.respawn_time_remaining
    })
end

---@param greevil Greevil
function handle_greevil_death(greevil)
    greevil.is_dead = true

    local owner_hero = greevil.native_unit_proxy:GetOwner()
    local modifier = owner_hero:AddNewModifier(owner_hero, nil, "modifier_greevil_respawn", { duration = RESPAWN_DURATION })

    if modifier then
        greevil.respawn_at = GameRules:GetGameTime() + RESPAWN_DURATION
        greevil.using_custom_death_timer = true
    else
        modifier.attached_entity = greevil
    end
end

---@param greevil Greevil
function respawn_greevil(greevil)
    local respawn_location = greevil.native_unit_proxy:GetOwner():GetAbsOrigin()

    if not greevil.native_unit_proxy:GetOwner():IsAlive() then
        local respawn_locations_by_team = {
            [DOTA_TEAM_GOODGUYS] = Entities:FindAllByClassname("info_player_start_goodguys"),
            [DOTA_TEAM_BADGUYS] = Entities:FindAllByClassname("info_player_start_badguys")
        }

        respawn_locations = respawn_locations_by_team[greevil.native_unit_proxy:GetTeam()]
    end

    greevil.is_dead = false
    greevil.native_unit_proxy:RespawnUnit()

    fx("particles/ui/ui_game_start_hero_spawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, greevil.native_unit_proxy, { release = true })

    FindClearSpaceForUnit(greevil.native_unit_proxy, respawn_location, true)
end