---@class Greevil : Entity
---@field public native_unit_proxy CDOTA_BaseNPC_Creature
---@field public respawn_at number
---@field public is_dead boolean
---@field public tick_counter number
---@field public ai Greevil_AI
---@field public lost_owner_at number
---@field public started_attacking_at number

local RESPAWN_DURATION = 15.0

---@param primal_seal Seal_With_Level
---@param greater_seals Seal_With_Level[]
---@param lesser_seals Seal_With_Level[]
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

    greevil:SetUnitCanRespawn(true)
    greevil:EmitSound("greevil_hatch")

    fx("particles/ui/ui_game_start_hero_spawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, greevil, { release = true })

    print("Creating a greevil for player", owner.native_unit_proxy:GetPlayerID())

    local skin_id
    local primal_seal_to_ability = {}

    if primal_seal then
        skin_id = map_primal_seal_type_to_skin_id(primal_seal.seal)

        greevil:SetSkin(skin_id)
        greevil:AddNewModifier(greevil, nil, convert_primal_seal_type_to_animation_modifier_name(primal_seal.seal), {})

        local ability = greevil:AddAbility(convert_primal_seal_type_to_ability_name(primal_seal.seal))
        ability:SetLevel(primal_seal.level)

        primal_seal_to_ability[primal_seal.seal] = ability
    end

    randomize_greevil_wearables(greevil, skin_id)

    greevil:AddNewModifier(greevil, nil, "modifier_greevil", {}):SetStackCount(RandomInt(0, 6))

    for _, greater_seal_and_level in pairs(greater_seals) do
        local ability = greevil:AddAbility(convert_greater_seal_type_to_ability_name(greater_seal_and_level.seal))
        ability:SetLevel(greater_seal_and_level.level)
    end

    for _, lesser_seal_and_level in pairs(lesser_seals) do
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
        native_unit_proxy = greevil,
        tick_counter = 0,
        ai = make_greevil_ai(greevil, primal_seal_to_ability),
        lost_owner_at = 0,
        started_attacking_at = 0
    })

    greevil.attached_entity = entity

    return entity
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
        local is_casting = greevil_ai_is_casting(greevil.ai) or greevil.native_unit_proxy:IsChanneling()

        if not is_casting then
            if owner:IsAlive() then
                if (owner:GetAbsOrigin() - greevil.native_unit_proxy:GetAbsOrigin()):Length2D() >= 1100 then
                    if greevil.lost_owner_at == 0 then
                        greevil.lost_owner_at = GameRules:GetGameTime()
                    end

                    if greevil.lost_owner_at ~= 0 and GameRules:GetGameTime() - greevil.lost_owner_at >= 0.8 then
                        fx("particles/econ/events/winter_major_2016/blink_dagger_start_wm.vpcf", PATTACH_WORLDORIGIN, nil, {
                            cp0 = greevil.native_unit_proxy:GetAbsOrigin(),
                            release = true
                        })

                        greevil.native_unit_proxy:EmitSound("greevil_blink")

                        FindClearSpaceForUnit(greevil.native_unit_proxy, owner:GetAbsOrigin(), true)

                        fx("particles/econ/events/winter_major_2016/blink_dagger_wm_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, greevil.native_unit_proxy, {
                            release = true
                        })

                        greevil.lost_owner_at = 0
                    else
                        greevil.native_unit_proxy:Stop()
                    end
                end

                local owner_has_no_attack_target = owner:GetAttackTarget() == nil

                if owner_has_no_attack_target then
                    if GameRules:GetGameTime() - greevil.started_attacking_at >= 1.5 then
                        if greevil.tick_counter % 10 == 0 then
                            greevil.native_unit_proxy:MoveToNPC(owner)
                        end
                    end
                else
                    greevil.started_attacking_at = GameRules:GetGameTime()
                    greevil.native_unit_proxy:MoveToTargetToAttack(owner:GetAttackTarget())
                end
            else
                if greevil.tick_counter % 10 == 0 then
                    greevil.native_unit_proxy:MoveToPosition(get_random_greevil_respawn_location(greevil))
                end
            end

            if GameRules:GetGameTime() - greevil.ai.started_casting_at > 1.5 then
                update_greevil_ai_ability_ai(greevil.ai)
            end
        end
    else
        if GameRules:GetGameTime() >= greevil.respawn_at then
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
    greevil.respawn_at = GameRules:GetGameTime() + RESPAWN_DURATION

    local owner_hero = greevil.native_unit_proxy:GetOwner()
    owner_hero:AddNewModifier(owner_hero, nil, "modifier_greevil_respawn", { duration = RESPAWN_DURATION })
end

function get_random_greevil_respawn_location(greevil)
    local respawn_locations_by_team = {
        [DOTA_TEAM_GOODGUYS] = Entities:FindAllByClassname("info_player_start_goodguys"),
        [DOTA_TEAM_BADGUYS] = Entities:FindAllByClassname("info_player_start_badguys")
    }

    local respawn_locations = respawn_locations_by_team[greevil.native_unit_proxy:GetTeam()]

    return respawn_locations[RandomInt(1, #respawn_locations)]:GetAbsOrigin()
end

---@param greevil Greevil
function respawn_greevil(greevil)
    local respawn_location = greevil.native_unit_proxy:GetOwner():GetAbsOrigin()

    if not greevil.native_unit_proxy:GetOwner():IsAlive() then
        respawn_location = get_random_greevil_respawn_location(greevil)
    end

    greevil.is_dead = false
    greevil.native_unit_proxy:RespawnUnit()
    greevil.native_unit_proxy:SetUnitCanRespawn(true)

    fx("particles/ui/ui_game_start_hero_spawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, greevil.native_unit_proxy, { release = true })

    FindClearSpaceForUnit(greevil.native_unit_proxy, respawn_location, true)
end