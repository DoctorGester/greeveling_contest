---@class Mega_Greevil
---@field public native_unit_proxy CDOTA_BaseNPC_Creature
---@field public born_at number
---@field public initial_location vector
---@field public is_returning_back_on_track boolean
---@field public tick_counter number
---@field public last_animation string
---@field public run_animation_started_at number
---@field public run_sound_timer number
---@field public started_casting_at number
---@field public abilities_off_cooldown_at table<CDOTABaseAbility, number>
---@field public abilities_were_on_cooldown table<CDOTABaseAbility, number>
---@field public seal_abilities table<Primal_Seal_Type, CDOTABaseAbility>
---@field public red_cluster_history table
---@field public orange_cluster_history table
---@field public yellow_health_history table

---@param big_egg Big_Egg
function make_mega_greevil(big_egg)
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
        run_sound_timer = 0,
        seal_abilities = {},
        abilities_off_cooldown_at = {},
        abilities_were_on_cooldown = {},
        red_cluster_history = {},
        orange_cluster_history = {},
        yellow_health_history = {},
        started_casting_at = 0
    })

    native_unit_proxy:EmitSound("hatch_scream")
    native_unit_proxy.attached_entity = entity

    local dummy_ability_source = native_unit_proxy:FindAbilityByName("generic_hidden")
    local primal_seals_and_levels, greater_seals_and_levels, lesser_seals_and_levels =
        collapse_abilities_and_levels_into_abilities_with_levels(big_egg.primal_seals, big_egg.greater_seals, big_egg.lesser_seals)

    for _, primal_seal_and_level in pairs(primal_seals_and_levels) do
        local ability = native_unit_proxy:AddAbility(convert_primal_seal_type_to_ability_name(primal_seal_and_level.seal))

        ability:SetLevel(primal_seal_and_level.level)

        entity.seal_abilities[primal_seal_and_level.seal] = ability
        entity.abilities_off_cooldown_at[ability] = GameRules:GetGameTime()
        entity.abilities_were_on_cooldown[ability] = false
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
function update_mega_greevil_abilities_off_cooldown(mega_greevil)
    for _, ability in pairs(mega_greevil.seal_abilities) do
        local was_on_cooldown = mega_greevil.abilities_were_on_cooldown[ability]
        local is_on_cooldown = not ability:IsCooldownReady()

        if was_on_cooldown and not is_on_cooldown then
            mega_greevil.abilities_off_cooldown_at[ability] = GameRules:GetGameTime()
        end

        mega_greevil.abilities_were_on_cooldown[ability] = is_on_cooldown
    end
end

function flatten_cluster_history(cluster_history, cluster_radius)
    local history_clusters = clusterize_points(cluster_history, cluster_radius) -- I reinvented deep learning here, LMAO
    local cluster_found, biggest_cluster = find_biggest_cluster(history_clusters, 8)

    if cluster_found then
        return true, cluster_average(biggest_cluster)
    end

    return false, nil
end

function find_ability_cast_target_based_on_cluster_history(mega_greevil, ability, cluster_history)
    local current_location = mega_greevil.native_unit_proxy:GetAbsOrigin()
    local ability_cast_range = ability:GetCastRange(Vector(), nil)

    -- Cleaning up outdated history
    if #cluster_history > 0 then
        for index = #cluster_history, 1 do
            if (current_location - cluster_history[index]):Length2D() > ability_cast_range then
                table.remove(cluster_history, index)
            end

            index = index - 1
        end
    end

    local ability_radius = ability:GetAOERadius()
    local all_clusters = split_ability_targets_into_circle_clusters(ability, current_location, ability_cast_range, ability_radius)

    for _, cluster in pairs(all_clusters) do
        table.insert(cluster_history, cluster_average(cluster))

        --DebugDrawCircle(cluster_average(cluster), Vector(0, 255, 0), 0.5, ability_radius, true, 20.0)

        if #cluster_history > 60 then
            table.remove(cluster_history, 1)
        end
    end

    return flatten_cluster_history(cluster_history, ability_radius)
end

function clusterize_points_for_black_seal_ability(points, caster_position, maximum_distance)
    local all_clusters = {}

    for index_top, point_top in pairs(points) do
        local current_cluster = {}

        table.insert(current_cluster, point_top)
        table.insert(all_clusters, current_cluster)

        -- This actually shows that the solution is in fact incorrect, but whatever, close enough!
        --[[for i = -300, 300, 30 do
            local perpendicular_length = math.abs(i)
            local direction = (point_top - caster_position):Normalized()
            local direction_rotated = Vector(-direction.y, direction.x)
            local is_left = i < 0 and -1 or 1
            local side_offset = perpendicular_length * direction_rotated * is_left
            local scalar_arc_offset = math.cos((perpendicular_length / 300.0) * math.pi) * 50.0 - 50.0
            local arc_offset = direction * scalar_arc_offset
            local pool_position = point_top + side_offset + arc_offset

            DebugDrawCircle(pool_position, Vector(255, 255, 0), 0.5, 120, true, 0.1)
        end]]

        for index_bottom, point_bottom in pairs(points) do
            -- I'm so bad at maths
            local closest_point = closest_point_to_segment(caster_position, point_top, point_bottom)
            local perpendicular_length = (closest_point - point_bottom):Length2D()

            if perpendicular_length > 300.0 then
                goto too_far_away
            end

            local direction = (point_top - caster_position):Normalized()
            local direction_rotated = Vector(-direction.y, direction.x)
            local is_left = is_left(caster_position, point_top, point_bottom) and 1 or -1
            local side_offset = perpendicular_length * direction_rotated * is_left
            local scalar_arc_offset = math.cos((perpendicular_length / 300.0) * math.pi) * 50.0 - 50.0
            local arc_offset = direction * scalar_arc_offset
            local pool_position = point_top + side_offset + arc_offset

            if index_top ~= index_bottom and (pool_position - point_bottom):Length2D() <= 180.0 then
                -- DebugDrawCircle(pool_position, Vector(0, 255, 0), 0.5, 120, true, 0.1)

                table.insert(current_cluster, point_bottom)
            end

            ::too_far_away::
        end
    end

    return all_clusters
end

---@param mega_greevil Mega_Greevil
function update_mega_greevil_ability_ai(mega_greevil)
    local current_location = mega_greevil.native_unit_proxy:GetAbsOrigin()

    for seal, ability in pairs(mega_greevil.seal_abilities) do
        local ability_cast_range = ability:GetCastRange(Vector(), nil)
        local off_cooldown_for = (GameRules:GetGameTime() - mega_greevil.abilities_off_cooldown_at[ability])
        local inefficient_cooldown = ability:GetCooldown(ability:GetLevel()) * 2.0
        local desperation_factor = math.min(off_cooldown_for / inefficient_cooldown, 1.0)

        if not ability:IsFullyCastable() then
            goto loop_end
        end

        local function cast_ability_on_position(location)
            --DebugDrawCircle(location, Vector(255, 0, 0), 0.5, 255, true, 20.0)
            mega_greevil.native_unit_proxy:Interrupt()
            mega_greevil.native_unit_proxy:CastAbilityOnPosition(location, ability, -1)
            mega_greevil.started_casting_at = GameRules:GetGameTime()
        end

        local function cast_ability_no_target()
            mega_greevil.native_unit_proxy:Interrupt()
            mega_greevil.native_unit_proxy:CastAbilityNoTarget(ability, -1)
            mega_greevil.started_casting_at = GameRules:GetGameTime()
        end

        local function cast_ability_target(target)
            mega_greevil.native_unit_proxy:Interrupt()
            mega_greevil.native_unit_proxy:CastAbilityOnTarget(target, ability, -1)
            mega_greevil.started_casting_at = GameRules:GetGameTime()
        end

        if seal == Primal_Seal_Type.RED then
            local found_cast_target, cast_target = find_ability_cast_target_based_on_cluster_history(mega_greevil, ability, mega_greevil.red_cluster_history)

            if found_cast_target then
                mega_greevil.red_cluster_history = {}
                cast_ability_on_position(cast_target)
            end
        elseif seal == Primal_Seal_Type.ORANGE then
            local found_cast_target, cast_target = find_ability_cast_target_based_on_cluster_history(mega_greevil, ability, mega_greevil.orange_cluster_history)

            if found_cast_target then
                mega_greevil.orange_cluster_history = {}
                cast_ability_on_position(cast_target)
            end
        elseif seal == Primal_Seal_Type.BLACK then
            local all_points = find_predicted_ability_targets_points_at_location(ability, current_location, ability_cast_range)
            local all_clusters = clusterize_points_for_black_seal_ability(all_points, current_location, 0)

            local minimum_targets = desperation_factor > 0.5 and 1 or 2
            local found_cluster, biggest_cluster = find_biggest_cluster(all_clusters, minimum_targets - 1)

            if found_cluster then
                cast_ability_on_position(cluster_average(biggest_cluster))
            end
        elseif seal == Primal_Seal_Type.BLUE then
            local all_targets = find_ability_targets_at_location(ability, current_location, ability_cast_range)

            if mega_greevil.native_unit_proxy:GetHealthPercent() > 35 then
                local targeted_mana_average = 25.0 + 55.0 * desperation_factor
                local minimum_targets = desperation_factor > 0.5 and 2 or 3

                if #all_targets >= minimum_targets then
                    local total_mana_percent = 0

                    for _, unit in pairs(all_targets) do
                        total_mana_percent = total_mana_percent + unit:GetManaPercent() -- I guess buggy in case of low int?
                    end

                    local average_mana_percentage = total_mana_percent / #all_targets

                    if average_mana_percentage <= targeted_mana_average then
                        cast_ability_no_target()
                    end
                end
            end
        elseif seal == Primal_Seal_Type.WHITE then
            local all_targets = find_ability_targets_at_location(ability, current_location, ability_cast_range)
            local minimum_targets = math.ceil((1.0 - desperation_factor) * 3 + 1)
            local actual_targets = 0

            for _, unit in pairs(all_targets) do
                if unit:IsRooted() or unit:IsSilenced() or unit:IsDisarmed() or
                    unit:IsStunned() or unit:IsBlind() or unit:IsCommandRestricted() or
                    unit:IsHexed() or unit:IsMovementImpaired() or unit:IsMuted()
                then
                    actual_targets = actual_targets + 1
                end
            end

            if actual_targets >= minimum_targets then
                cast_ability_no_target()
            end
        elseif seal == Primal_Seal_Type.GREEN then
            local all_targets = find_ability_targets_at_location(ability, current_location, ability_cast_range)
            local minimum_targets = desperation_factor > 0.5 and 1 or 2

            if #all_targets >= minimum_targets then
                cast_ability_no_target()
            end
        elseif seal == Primal_Seal_Type.YELLOW then
            local all_targets = find_ability_targets_at_location(ability, current_location, ability_cast_range)

            -- Clean history up
            for target, _ in pairs(mega_greevil.yellow_health_history) do
                local found = false

                for _, existing_target in pairs(all_targets) do
                    if target == existing_target then
                        found = true
                        break
                    end
                end

                if not found then
                    mega_greevil.yellow_health_history[target] = nil
                end
            end

            for _, target in pairs(all_targets) do
                local history = mega_greevil.yellow_health_history[target]

                if not history then
                    history = {}
                    mega_greevil.yellow_health_history[target] = history
                end

                table.insert(history, target:GetHealthPercent())

                if #history > 90 then
                    table.remove(history, 1)
                end
            end

            local possible_targets = {}

            for target, history in pairs(mega_greevil.yellow_health_history) do
                local health_trend = 0
                for index, this_value in ipairs(history) do
                    if index > 1 then
                        local previous_value = history[index - 1]
                        local difference = this_value - previous_value

                        health_trend = health_trend + difference
                    end
                end

                health_trend = health_trend / #history

                local panic_factor = 1.0 - (history[#history] / 100.0)
                local required_trend = -0.7 + (panic_factor * 0.65)

                if #history > 15 and health_trend <= required_trend then
                    table.insert(possible_targets, target)
                    mega_greevil.yellow_health_history[target] = nil
                end
            end

            if #possible_targets > 0 then
                cast_ability_target(possible_targets[RandomInt(1, #possible_targets)])
            end
        end

        ::loop_end::
    end
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

    local is_casting = false
    local is_moving = mega_greevil.native_unit_proxy:IsMoving()

    for _, ability in pairs(mega_greevil.seal_abilities) do
        if ability:IsInAbilityPhase() then
            is_casting = true
            break
        end
    end

    if not is_casting then
        update_mega_greevil_movement(mega_greevil)
    end

    GridNav:DestroyTreesAroundPoint(mega_greevil.native_unit_proxy:GetAbsOrigin(), 320, false)

    update_mega_greevil_abilities_off_cooldown(mega_greevil)
    update_mega_greevil_animation_effects(mega_greevil)

    if not is_moving and not is_casting and GameRules:GetGameTime() - mega_greevil.started_casting_at > 1.5 then
        update_mega_greevil_ability_ai(mega_greevil)
    end
end