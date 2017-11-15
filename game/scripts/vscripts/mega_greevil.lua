---@class Mega_Greevil
---@field public native_unit_proxy CDOTA_BaseNPC_Creature
---@field public born_at number
---@field public initial_location vector
---@field public is_returning_back_on_track boolean
---@field public tick_counter number
---@field public last_animation string
---@field public run_animation_started_at number
---@field public run_sound_timer number
---@field public ai Greevil_AI

---@param big_egg Big_Egg
function make_mega_greevil(big_egg, abilities)
    local native_unit_proxy = CreateUnitByName(
        "npc_unit_mega_greevil",
        big_egg.native_unit_proxy:GetAbsOrigin(),
        true,
        big_egg.native_unit_proxy,
        big_egg.native_unit_proxy,
        big_egg.native_unit_proxy:GetTeam()
    )

    native_unit_proxy:SetForwardVector(-big_egg.native_unit_proxy:GetAbsOrigin())

    local entity = make_entity(Entity_Type.MEGA_GREEVIL, {
        native_unit_proxy = native_unit_proxy,
        born_at = GameRules:GetGameTime(),
        initial_location = big_egg.native_unit_proxy:GetAbsOrigin(),
        is_returning_back_on_track = false,
        tick_counter = 0,
        last_animation = "",
        run_animation_started_at = 0,
        run_sound_timer = 0
    })

    native_unit_proxy:EmitSound("hatch_scream")
    native_unit_proxy.attached_entity = entity

    local dummy_ability_source = native_unit_proxy:FindAbilityByName("generic_hidden")
    local primal_seals_and_levels, greater_seals_and_levels, lesser_seals_and_levels =
        collapse_abilities_and_levels_into_abilities_with_levels(big_egg.primal_seals, big_egg.greater_seals, big_egg.lesser_seals)

    local seal_to_ability = {}

    for _, primal_seal_and_level in pairs(primal_seals_and_levels) do
        local ability = native_unit_proxy:AddAbility(convert_primal_seal_type_to_ability_name(primal_seal_and_level.seal))
        ability:SetLevel(primal_seal_and_level.level)

        seal_to_ability[primal_seal_and_level.seal] = ability
    end

    for _, greater_seal_and_level in pairs(greater_seals_and_levels) do
        local ability = native_unit_proxy:AddAbility(convert_greater_seal_type_to_ability_name(greater_seal_and_level.seal))
        ability:SetLevel(greater_seal_and_level.level)
    end

    for _, lesser_seal_and_level in pairs(lesser_seals_and_levels) do
        local modifier_name = convert_lesser_seal_type_to_modifier_name(lesser_seal_and_level.seal)
        local new_modifier = native_unit_proxy:AddNewModifier(native_unit_proxy, dummy_ability_source, modifier_name, {})
        new_modifier:SetStackCount(lesser_seal_and_level.level)

        if lesser_seal_and_level.seal == Lesser_Seal_Type.HEALTH then
            new_modifier:RefreshCustomHealth()
        end
    end

    entity.ai = make_greevil_ai(native_unit_proxy, seal_to_ability)

    native_unit_proxy:AddNewModifier(native_unit_proxy, dummy_ability_source, "modifier_mega_greevil", {})

    return entity
end

---@param mega_greevil Mega_Greevil
function update_mega_greevil_animation_effects(mega_greevil)
    local current_sequence = mega_greevil.native_unit_proxy:GetSequence()
    local current_time = GameRules:GetGameTime()

    if current_sequence == "mg_run" and mega_greevil.last_animation ~= "mg_run" then
        mega_greevil.run_animation_started_at = current_time
        mega_greevil.run_sound_timer = 0
    end

    if current_sequence == "mg_run" then
        local delta_time = current_time - mega_greevil.run_animation_started_at

        if delta_time >= mega_greevil.run_sound_timer then
            mega_greevil.run_sound_timer = mega_greevil.run_sound_timer + 0.7
            mega_greevil.native_unit_proxy:EmitSound("greevil_step")

            ScreenShake(mega_greevil.native_unit_proxy:GetAbsOrigin(), 5, 150, 0.25, 3000, 0, true)
        end
    end

    mega_greevil.last_animation = current_sequence
end

---@param mega_greevil Mega_Greevil
function mega_greevil_handle_attack_landed(mega_greevil, target)
    mega_greevil.native_unit_proxy:EmitSound("greevil_attack")
    ScreenShake(mega_greevil.native_unit_proxy:GetAbsOrigin(), 5, 150, 0.25, 3000, 0, true)
end

---@param mega_greevil Mega_Greevil
function update_mega_greevil_movement(mega_greevil)
    local current_location = mega_greevil.native_unit_proxy:GetAbsOrigin()
    local map_center = Vector()
    local direction = (map_center - current_location):Normalized() * 200

    local other_greevil

    for _, entity in pairs(all_entities) do
        if entity.entity_type == Entity_Type.MEGA_GREEVIL and mega_greevil ~= entity then
            other_greevil = entity
            break
        end
    end

    local can_see_other_greevil = false
    local distance_between_the_two

    if other_greevil then
        distance_between_the_two = (other_greevil.native_unit_proxy:GetAbsOrigin() - mega_greevil.native_unit_proxy:GetAbsOrigin()):Length2D()
        can_see_other_greevil = other_greevil.native_unit_proxy:IsAlive() and
        mega_greevil.native_unit_proxy:CanEntityBeSeenByMyTeam(other_greevil.native_unit_proxy)
    end

    if mega_greevil.tick_counter % 30 == 0 then
        if can_see_other_greevil and distance_between_the_two <= 1300 then
            mega_greevil.native_unit_proxy:MoveToTargetToAttack(other_greevil.native_unit_proxy)
        else
            local closest_point = closest_point_to_segment(mega_greevil.initial_location, map_center, current_location)

            if mega_greevil.is_returning_back_on_track then
                if (closest_point - current_location):Length2D() < 250 then
                    mega_greevil.is_returning_back_on_track = false
                end

                mega_greevil.native_unit_proxy:MoveToPosition(closest_point)
            else
                if (closest_point - current_location):Length2D() > 600 then
                    mega_greevil.is_returning_back_on_track = true
                end

                mega_greevil.native_unit_proxy:MoveToPositionAggressive(current_location + direction)
            end
        end
    end
end

---@param mega_greevil Mega_Greevil
function update_mega_greevil(mega_greevil)
    if not mega_greevil.native_unit_proxy:IsAlive() then
        mega_greevil.is_destroyed_next_update = true
        return
    end

    if GameRules:GetGameTime() - mega_greevil.born_at <= 1.5 then
        return
    end

    mega_greevil.tick_counter = mega_greevil.tick_counter + 1

    local is_casting = greevil_ai_is_casting(mega_greevil.ai)
    local is_moving = mega_greevil.native_unit_proxy:IsMoving()

    if not is_casting then
        update_mega_greevil_movement(mega_greevil)
    end

    GridNav:DestroyTreesAroundPoint(mega_greevil.native_unit_proxy:GetAbsOrigin(), 320, false)

    update_greevil_ai_abilities_off_cooldown(mega_greevil.ai)
    update_mega_greevil_animation_effects(mega_greevil)

    if not is_moving and not is_casting and GameRules:GetGameTime() - mega_greevil.ai.started_casting_at > 1.5 then
        update_greevil_ai_ability_ai(mega_greevil.ai)
    end
end