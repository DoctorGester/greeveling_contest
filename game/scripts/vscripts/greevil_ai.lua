---@class Greevil_AI
---@field public native_unit_proxy CDOTA_BaseNPC_Creature
---@field public abilities_off_cooldown_at table<CDOTABaseAbility, number>
---@field public abilities_were_on_cooldown table<CDOTABaseAbility, number>
---@field public seal_abilities table<Primal_Seal_Type, CDOTABaseAbility>
---@field public red_cluster_history table
---@field public orange_cluster_history table
---@field public yellow_health_history table
---@field public started_casting_at number

function make_greevil_ai(native_unit_proxy, seal_to_ability)
    local seal_abilities = {}
    local abilities_off_cooldown_at = {}
    local abilities_were_on_cooldown = {}

    for seal, ability in pairs(seal_to_ability) do
        seal_abilities[seal] = ability
        abilities_off_cooldown_at[ability] = GameRules:GetGameTime()
        abilities_were_on_cooldown[ability] = false
    end

    return {
        native_unit_proxy = native_unit_proxy,
        seal_abilities = seal_abilities,
        abilities_off_cooldown_at = abilities_off_cooldown_at,
        abilities_were_on_cooldown = abilities_were_on_cooldown,
        red_cluster_history = {},
        orange_cluster_history = {},
        yellow_health_history = {},
        started_casting_at = 0
    }
end

function flatten_cluster_history(cluster_history, cluster_radius)
    local history_clusters = clusterize_points(cluster_history, cluster_radius) -- I reinvented deep learning here, LMAO
    local cluster_found, biggest_cluster = find_biggest_cluster(history_clusters, 8)

    if cluster_found then
        return true, cluster_average(biggest_cluster)
    end

    return false, nil
end

function find_ability_cast_target_based_on_cluster_history(ai, ability, cluster_history)
    local current_location = ai.native_unit_proxy:GetAbsOrigin()
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

function greevil_ai_is_casting(ai)
    for _, ability in pairs(ai.seal_abilities) do
        if ability:IsInAbilityPhase() then
            return true
        end
    end

    return false
end

---@param ai Greevil_AI
function update_greevil_ai_abilities_off_cooldown(ai)
    for _, ability in pairs(ai.seal_abilities) do
        local was_on_cooldown = ai.abilities_were_on_cooldown[ability]
        local is_on_cooldown = not ability:IsCooldownReady()

        if was_on_cooldown and not is_on_cooldown then
            ai.abilities_off_cooldown_at[ability] = GameRules:GetGameTime()
        end

        ai.abilities_were_on_cooldown[ability] = is_on_cooldown
    end
end

---@param ai Greevil_AI
function update_greevil_ai_ability_ai(ai)
    local current_location = ai.native_unit_proxy:GetAbsOrigin()

    for seal, ability in pairs(ai.seal_abilities) do
        local ability_cast_range = ability:GetCastRange(Vector(), nil)
        local off_cooldown_for = (GameRules:GetGameTime() - ai.abilities_off_cooldown_at[ability])
        local inefficient_cooldown = ability:GetCooldown(ability:GetLevel()) * 2.0
        local desperation_factor = math.min(off_cooldown_for / inefficient_cooldown, 1.0)

        if not ability:IsFullyCastable() then
            goto loop_end
        end

        local function cast_ability_on_position(location)
            --DebugDrawCircle(location, Vector(255, 0, 0), 0.5, 255, true, 20.0)
            ai.native_unit_proxy:Interrupt()
            ai.native_unit_proxy:CastAbilityOnPosition(location, ability, -1)
            ai.started_casting_at = GameRules:GetGameTime()
        end

        local function cast_ability_no_target()
            ai.native_unit_proxy:Interrupt()
            ai.native_unit_proxy:CastAbilityNoTarget(ability, -1)
            ai.started_casting_at = GameRules:GetGameTime()
        end

        local function cast_ability_target(target)
            ai.native_unit_proxy:Interrupt()
            ai.native_unit_proxy:CastAbilityOnTarget(target, ability, -1)
            ai.started_casting_at = GameRules:GetGameTime()
        end

        if seal == Primal_Seal_Type.RED then
            local found_cast_target, cast_target = find_ability_cast_target_based_on_cluster_history(ai, ability, ai.red_cluster_history)

            if found_cast_target then
                ai.red_cluster_history = {}
                cast_ability_on_position(cast_target)
            end
        elseif seal == Primal_Seal_Type.ORANGE then
            local found_cast_target, cast_target = find_ability_cast_target_based_on_cluster_history(ai, ability, ai.orange_cluster_history)

            if found_cast_target then
                ai.orange_cluster_history = {}
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

            if ai.native_unit_proxy:GetHealthPercent() > 35 then
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
                    unit:IsHexed() or unit:IsMuted()
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
            for target, _ in pairs(ai.yellow_health_history) do
                local found = false

                for _, existing_target in pairs(all_targets) do
                    if target == existing_target then
                        found = true
                        break
                    end
                end

                if not found then
                    ai.yellow_health_history[target] = nil
                end
            end

            for _, target in pairs(all_targets) do
                if target:IsRealHero() then
                    local history = ai.yellow_health_history[target]

                    if not history then
                        history = {}
                        ai.yellow_health_history[target] = history
                    end

                    table.insert(history, target:GetHealthPercent())

                    if #history > 90 then
                        table.remove(history, 1)
                    end
                end
            end

            local possible_targets = {}

            for target, history in pairs(ai.yellow_health_history) do
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
                    ai.yellow_health_history[target] = nil
                end
            end

            if #possible_targets > 0 then
                cast_ability_target(possible_targets[RandomInt(1, #possible_targets)])
            end
        end

        ::loop_end::
    end
end
