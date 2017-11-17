---@class AI_Crystal_Maiden : Entity
---@field public state AI_Crystal_Maiden_State
---@field public loot_drop_damage_buffer number
---@field public native_unit_proxy CDOTA_BaseNPC_Creature
---@field public ability_spiral CDOTABaseAbility
---@field public ability_frost_nova CDOTABaseAbility
---@field public ability_frostbite CDOTABaseAbility
---@field public initial_position vector
---@field public loot_dropped number
---@field public time_during_movement number
---@field public started_casting_frostbite_at number
---@field public started_casting_frost_nova_at number
---@field public started_casting_spiral_at number
---@field public queue_spiral_cast boolean
---@field public event_ended boolean
---@field public event_ended_at number

local FROST_NOVA_RADIUS = 275
local LOOT_BUFFER_SIZE = 400
local FROSTBITE_DURATION = 1.0

local DELAY_BETWEEN_EVENT_END_AND_DESTROY = 0.9

function make_crystal_maiden_ai(location)
    local native_unit_proxy = CreateUnitByName(
        "npc_dota_creature_crystal_maiden_boss",
        location,
        true,
        nil,
        nil,
        DOTA_TEAM_NEUTRALS
    )

    local entity = make_entity(Entity_Type.AI_CRYSTAL_MAIDEN, {
        state = AI_Crystal_Maiden_State.ON_THE_MOVE,
        loot_drop_damage_buffer = LOOT_BUFFER_SIZE,
        tick_counter = 0,
        time_during_movement = 0,
        native_unit_proxy = native_unit_proxy,
        ability_spiral = native_unit_proxy:FindAbilityByName("crystal_maiden_boss_spiral"),
        ability_frostbite = native_unit_proxy:FindAbilityByName("crystal_maiden_boss_frostbite"),
        ability_frost_nova = native_unit_proxy:FindAbilityByName("crystal_maiden_boss_frost_nova"),
        initial_position = location,
        queue_spiral_cast = false,
        loot_dropped = 0,
        event_ended = false,
        event_ended_at = 0
    })

    native_unit_proxy:AddNewModifier(nil, entity.native_unit_proxy, "modifier_crystal_maiden_boss", {})
    native_unit_proxy.attached_entity = entity

    return entity
end

---@param ai AI_Crystal_Maiden
function crystal_maiden_find_frost_nova_targets_at(ai, location, radius)
    return FindUnitsInRadius(
        DOTA_TEAM_NEUTRALS,
        location,
        nil,
        radius,
        ai.ability_frost_nova:GetAbilityTargetTeam(),
        ai.ability_frost_nova:GetAbilityTargetType(),
        ai.ability_frost_nova:GetAbilityTargetFlags(),
        FIND_CLOSEST,
        false
    )
end

---@param ai AI_Crystal_Maiden
function crystal_maiden_wants_to_cast_freezing_field(ai)

end

---@param ai AI_Crystal_Maiden
function crystal_maiden_start_casting_freezing_field(ai)

end

---@param ai AI_Crystal_Maiden
function crystal_maiden_start_casting_spiral(ai)
    ai.state = AI_Crystal_Maiden_State.CASTING_SPIRAL
    ai.started_casting_spiral_at = GameRules:GetGameTime()
end

---@param ai AI_Crystal_Maiden
function crystal_maiden_process_spiral_projectile_hit(ai, target)
    target:EmitSound("cm_spiral_hit")
    target:AddNewModifier(ai.native_unit_proxy, ai.ability_frostbite, "modifier_crystal_maiden_boss_frostbite", { duration = FROSTBITE_DURATION / 2.0 })
end

---@param ai AI_Crystal_Maiden
---@param at_location vector
function crystal_maiden_cast_frost_nova_at(ai, at_location)
    ai.state = AI_Crystal_Maiden_State.CASTING_FROST_NOVA
    ai.native_unit_proxy:RemoveGesture(ACT_DOTA_RUN)
    ai.native_unit_proxy:CastAbilityOnPosition(at_location, ai.ability_frost_nova, -1)
    ai.started_casting_frost_nova_at = GameRules:GetGameTime()
    ai.native_unit_proxy:EmitSound("cm_voice_before_frost_nova")

    aoe_marker(at_location, FROST_NOVA_RADIUS, false, Vector(175, 238, 238), ai.ability_frost_nova:GetCastPoint())
end

---@param ai AI_Crystal_Maiden
function crystal_maiden_cast_frostbite_on(ai, attacker)
    ai.native_unit_proxy:RemoveGesture(ACT_DOTA_RUN)
    ai.state = AI_Crystal_Maiden_State.CASTING_FROSTBITE
    ai.native_unit_proxy:CastAbilityOnTarget(attacker, ai.ability_frostbite, -1)
    ai.started_casting_frostbite_at = GameRules:GetGameTime()
    ai.native_unit_proxy:EmitSound("cm_voice_before_frostbite")
end

---@param ai AI_Crystal_Maiden
function crystal_maiden_can_cast_frostbite_on(ai, attacker)
    return
        ai.state == AI_Crystal_Maiden_State.ON_THE_MOVE and
        ai.native_unit_proxy:CanEntityBeSeenByMyTeam(attacker) and
        ai.ability_frostbite:IsCooldownReady() and
        can_ability_be_actually_cast_on_a_target(ai.ability_frostbite, attacker)
end

---@param ai AI_Crystal_Maiden
---@param target CDOTA_BaseNPC
function handle_crystal_maiden_frostbite_cast_on(ai, target)
    target:EmitSound("cm_frostbite")
    target:AddNewModifier(ai.native_unit_proxy, ai.ability_frostbite, "modifier_crystal_maiden_boss_frostbite", { duration = FROSTBITE_DURATION })
end

---@param ai AI_Crystal_Maiden
function handle_crystal_maiden_frost_nova_cast_at(ai, location)
    local targets = crystal_maiden_find_frost_nova_targets_at(ai, location, FROST_NOVA_RADIUS)

    EmitSoundOnLocationWithCaster(location, "cm_frost_nova", ai.native_unit_proxy)

    for _, target in pairs(targets) do
        target:AddNewModifier(ai.native_unit_proxy, ai.ability_frostbite, "modifier_crystal_maiden_boss_frostbite", { duration = FROSTBITE_DURATION })
    end

    fx("particles/econ/items/crystal_maiden/crystal_maiden_cowl_of_ice/maiden_crystal_nova_cowlofice.vpcf", PATTACH_WORLDORIGIN, nil, {
        cp0 = location,
        cp1 = Vector(FROST_NOVA_RADIUS, 0, 0),
        release = true
    })
end

---@param ai AI_Crystal_Maiden
function update_crystal_maiden_on_the_move(ai)
    ai.time_during_movement = ai.time_during_movement + FrameTime()

    local function position_in_time(time)
        local angle = (time / 4) % (math.pi * 2)
        return Vector(math.cos(angle), math.sin(angle)) * 600.0 + ai.initial_position
    end

    local current_position = ai.native_unit_proxy:GetAbsOrigin()
    local target_position = position_in_time(ai.time_during_movement)
    local new_position = LerpVectors(current_position, target_position, 0.1)
    local future_position = position_in_time(ai.time_during_movement + 2.0)

    ai.native_unit_proxy:FaceTowards(future_position)
    ai.native_unit_proxy:SetAbsOrigin(new_position)
    ai.native_unit_proxy:StartGesture(ACT_DOTA_RUN)

    if ai.tick_counter % 30 == 0 then
        GridNav:DestroyTreesAroundPoint(current_position, 256, false)
    end
end

function update_crystal_maiden_spiral_cast(ai)
    ai.native_unit_proxy:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_4, 0.3)

    if ai.tick_counter % 7 == 0 then
        ai.native_unit_proxy:EmitSound("cm_spiral_launch")

        local current_time = GameRules:GetGameTime()
        local initial_angle = (current_time / 4.0) % (math.pi * 2)

        for index = 0, 7 do
            local loop_angle = initial_angle + (math.pi / 4 * index)
            local direction = Vector(math.cos(loop_angle), math.sin(loop_angle))

            ProjectileManager:CreateLinearProjectile({
                Ability = ai.ability_spiral,
                EffectName = "particles/bosses/ice_ball.vpcf",
                vSpawnOrigin = ai.native_unit_proxy:GetAbsOrigin() + Vector(0, 0, 96),
                fDistance = 1600,
                fStartRadius = 48,
                fEndRadius = 48,
                Source = ai.native_unit_proxy,
                bHasFrontalCone = false,
                bReplaceExisting = false,
                iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
                iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
                iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                fExpireTime = current_time + 4.0,
                bDeleteOnHit = true,
                vVelocity = direction * 300,
                bProvidesVision = false
            })
        end
    end
end

function crystal_maiden_freeze_everyone_around_after_event_ended(ai, current_time)
    local radius = (current_time - ai.event_ended_at) / DELAY_BETWEEN_EVENT_END_AND_DESTROY * 1600
    local targets = crystal_maiden_find_frost_nova_targets_at(ai, ai.native_unit_proxy:GetAbsOrigin(), radius)

    for _, target in pairs(targets) do
        target:AddNewModifier(ai.native_unit_proxy, ai.ability_frostbite, "modifier_crystal_maiden_boss_frostbite", { duration = FROSTBITE_DURATION })
    end
end

---@param ai AI_Crystal_Maiden
function update_crystal_maiden_ai(ai)
    ai.tick_counter = ai.tick_counter + 1

    local current_time = GameRules:GetGameTime()

    if ai.event_ended then
        crystal_maiden_freeze_everyone_around_after_event_ended(ai, current_time)

        if current_time - ai.event_ended_at > DELAY_BETWEEN_EVENT_END_AND_DESTROY then
            fx("particles/econ/events/winter_major_2017/blink_dagger_start_wm07.vpcf", PATTACH_WORLDORIGIN, nil, {
                cp0 = ai.native_unit_proxy:GetAbsOrigin(),
                relese = true
            })

            ai.is_destroyed_next_update = true
            ai.native_unit_proxy:RemoveSelf()
        end

        return
    end

    if ai.state == AI_Crystal_Maiden_State.ON_THE_MOVE then
        update_crystal_maiden_on_the_move(ai)

        if ai.queue_spiral_cast then
            ai.native_unit_proxy:RemoveGesture(ACT_DOTA_RUN)
            ai.native_unit_proxy:MoveToPosition(ai.initial_position)
            ai.state = AI_Crystal_Maiden_State.GOING_TO_CAST_SPIRAL
            ai.queue_spiral_cast = false
            ai.native_unit_proxy:EmitSound("cm_voice_before_spiral")
        elseif ai.ability_frost_nova:IsCooldownReady() then
            local found_multiple_targets, point_cluster = find_biggest_ability_target_cluster(
                ai.ability_frost_nova,
                ai.native_unit_proxy:GetAbsOrigin(),
                1600,
                FROST_NOVA_RADIUS,
                1
            )

            if found_multiple_targets then
                --DebugDrawCircle(cluster_average(point_cluster), Vector(255, 0, 0), 0.5, FROST_NOVA_RADIUS, true, 0.1)
                crystal_maiden_cast_frost_nova_at(ai, cluster_average(point_cluster))
            end
        end
    elseif ai.state == AI_Crystal_Maiden_State.CASTING_FROSTBITE then
        if current_time - ai.started_casting_frostbite_at > ai.ability_frostbite:GetCastPoint() + 1.0 then
            ai.state = AI_Crystal_Maiden_State.ON_THE_MOVE
        end
    elseif ai.state == AI_Crystal_Maiden_State.CASTING_FROST_NOVA then
        if current_time - ai.started_casting_frost_nova_at > ai.ability_frost_nova:GetCastPoint() + 1.0 then
            ai.state = AI_Crystal_Maiden_State.ON_THE_MOVE
        end
    elseif ai.state == AI_Crystal_Maiden_State.CASTING_FREEZING_FIELD then
    elseif ai.state == AI_Crystal_Maiden_State.CASTING_SPIRAL then
        update_crystal_maiden_spiral_cast(ai)

        if current_time - ai.started_casting_spiral_at > 14.0 then
            ai.native_unit_proxy:FadeGesture(ACT_DOTA_CAST_ABILITY_4)
            ai.state = AI_Crystal_Maiden_State.ON_THE_MOVE
        end
    elseif ai.state == AI_Crystal_Maiden_State.GOING_TO_CAST_SPIRAL then
        local distance_to_center = (ai.native_unit_proxy:GetAbsOrigin() - ai.initial_position):Length2D()

        if distance_to_center <= 128.0 then
            crystal_maiden_start_casting_spiral(ai)
        elseif ai.tick_counter % 30 == 0 then
            ai.native_unit_proxy:MoveToPosition(ai.initial_position)
        end
    end
end

---@param ai AI_Crystal_Maiden
function finish_crystal_maiden_event(ai)
    ai.event_ended = true
    ai.event_ended_at = GameRules:GetGameTime()
    ai.native_unit_proxy:FadeGesture(ACT_DOTA_RUN)
    ai.native_unit_proxy:StartGesture(ACT_DOTA_CAST_ABILITY_1)

    fx("particles/items2_fx/shivas_guard_active.vpcf", PATTACH_WORLDORIGIN, nil, {
        cp0 = ai.native_unit_proxy:GetAbsOrigin(),
        cp1 = Vector(1600, 1, 1600),
        release = true
    })
end

---@param ai AI_Crystal_Maiden
function handle_crystal_maiden_loot_dropped(ai)
    if ai.loot_dropped % 10 == 0 then
        ai.queue_spiral_cast = true
    end
end

---@param ai AI_Crystal_Maiden
function crystal_maiden_register_damage_taken(ai, attacker, damage)
    if ai.event_ended then
        return
    end

    ai.loot_drop_damage_buffer = ai.loot_drop_damage_buffer + damage

    if crystal_maiden_can_cast_frostbite_on(ai, attacker) then
        crystal_maiden_cast_frostbite_on(ai, attacker)
    end

    if ai.loot_drop_damage_buffer > LOOT_BUFFER_SIZE then
        ai.loot_dropped = ai.loot_dropped + 1
        ai.loot_drop_damage_buffer = ai.loot_drop_damage_buffer - LOOT_BUFFER_SIZE

        generate_and_launch_boss_drop(attacker, ai.native_unit_proxy, ai.loot_dropped % 7 == 0)
        handle_crystal_maiden_loot_dropped(ai)
    end
end