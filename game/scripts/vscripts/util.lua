function copy_struct_into(from, to)
    for key, value in pairs(from) do
        to[key] = value
    end
end

local function do_print_table(name, table, indent, visited_tables)
    if not indent then indent = "" end

    visited_tables[table] = true

    if name == "FDesc" and #indent > 0 then
        print(indent, "Skipping", name)
        return
    end

    print(indent .. name .. "/" .. tostring(table) .. ": ")
    for k, v in pairs(table) do
        local k_string = tostring(k)

        if type(v) == "table" then
            if not visited_tables[v] then
                visited_tables[v] = true
                do_print_table(k_string, v, indent .. "  ", visited_tables)
            else
                print(indent .. "  " .. k_string, v, "(already referenced)")
            end
        else
            print(indent .. "  " .. k_string, v)
        end
    end
end

-- IDE helper
function print_table(name, table)
    do_print_table(name, table, "", {})
end

function string_starts(str,start)
    return string.sub(str, 1, string.len(start)) == start
end

function string_ends(str, ending)
    return ending == '' or string.sub(str, -string.len(ending)) == ending
end

function string_split(str, sep)
    local result = {}
    local regex = ("([^%s]+)"):format(sep)

    for each in str:gmatch(regex) do
        table.insert(result, each)
    end

    return result
end

---@class Entity
---@field public entity_type Entity_Type
---@field public is_destroyed_next_update false
---@field public created_at number
function make_entity(entity_type, entity_data)
    assert(entity_type ~= nil, "Entity type can't be nil!")

    local result_entity = {
        entity_type = entity_type,
        is_destroyed_next_update = false,
        created_at = GameRules:GetGameTime()
    }

    copy_struct_into(entity_data, result_entity)

    return result_entity
end

function minutes(minutes)
    return minutes * 60.0
end

function for_all_players(callback)
    for player_id = 0, DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayer(player_id) then
            callback(player_id)
        end
    end
end

---@param modifier_path string
function link_native_modifier_simple(modifier_path)
    local last_slash_position = string.find(modifier_path, "/[^/]*$")

    if last_slash_position == nil then
        LinkLuaModifier(modifier_path, modifier_path, LUA_MODIFIER_MOTION_NONE)
        linked_modifiers[modifier_path] = modifier_path

        print("Linking", modifier_path)
    else
        local remaining_file_name = string.sub(modifier_path, last_slash_position + 1)

        LinkLuaModifier(remaining_file_name, modifier_path, LUA_MODIFIER_MOTION_NONE)
        linked_modifiers[remaining_file_name] = modifier_path

        print("Linking", remaining_file_name, "from", modifier_path)
    end
end

function spairs(table_to_iterate, order_function)
    local keys = {}
    for k in pairs(table_to_iterate) do keys[#keys + 1] = k end

    if order_function then
        table.sort(keys, function(a,b) return order_function(table_to_iterate, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], table_to_iterate[keys[i]]
        end
    end
end

---@param path string
---@param pattach ParticleAttachment_t
---@param parent CBaseEntity
---@param options table
function fx(path, pattach, parent, options)
    local index = ParticleManager:CreateParticle(path, pattach, parent)

    if parent == nil then
        parent = GameRules:GetGameModeEntity()
    end

    for i = 0, 16 do
        local cp = options["cp"..tostring(i)]
        local cpf = options["cp"..tostring(i).."f"]

        if cp then
            -- Probably vector
            if type(cp) == "userdata" then
                ParticleManager:SetParticleControl(index, i, cp)
            end

            -- Entity
            if type(cp) == "table" then
                if not cp.pattach then
                    cp.pattach = PATTACH_POINT_FOLLOW
                end

                local ent = cp.ent or parent

                ParticleManager:SetParticleControlEnt(index, i, ent, cp.pattach, cp.attachment, ent:GetAbsOrigin(), true)
            end
        end

        if cpf then
            ParticleManager:SetParticleControlForward(index, i, cpf)
        end
    end

    if options.release then
        ParticleManager:ReleaseParticleIndex(index)
    else
        return index
    end
end

function dfx(index, force)
    force = force ~= nil

    ParticleManager:DestroyParticle(index, force)
    ParticleManager:ReleaseParticleIndex(index)
end

function aoe_marker(at_location, with_radius, is_thick, color, for_duration, alpha_optional)
    local path = is_thick and "particles/aoe_marker_filled.vpcf" or "particles/aoe_marker_filled_thin.vpcf"

    fx(path, PATTACH_WORLDORIGIN, nil, {
        cp0 = at_location,
        cp1 = Vector(with_radius, 1, 1),
        cp2 = Vector(color[1], color[2], color[3]),
        cp3 = Vector(alpha_optional or 0.0, 0, 0),
        cp4 = Vector(for_duration or 1.0, 0, 0),
        release = true
    })
end

function max_vector_2d(vector, max_vector)
    if max_vector:Length2D() > vector:Length2D() then return max_vector end

    return vector
end

function min_vector_2d(vector, min_vector)
    if min_vector:Length2D() < vector:Length2D() then return min_vector end

    return vector
end

function can_ability_be_actually_cast_on_a_target(ability, target)
    return UnitFilter(
        target,
        ability:GetAbilityTargetTeam(),
        ability:GetAbilityTargetType(),
        ability:GetAbilityTargetFlags(),
        ability:GetMoveParent():GetTeam()
    ) == UF_SUCCESS
end

---@return CDOTA_BaseNPC[]
function find_ability_targets_at_location(ability, at_location, with_radius)
    return FindUnitsInRadius(
        ability:GetMoveParent():GetTeam(),
        at_location,
        nil,
        with_radius,
        ability:GetAbilityTargetTeam(),
        ability:GetAbilityTargetType(),
        ability:GetAbilityTargetFlags(),
        FIND_ANY_ORDER,
        false
    )
end

function clusterize_points(points, cluster_radius)
    local all_clusters = {}

    for index_top, point_top in pairs(points) do
        local current_cluster = {}

        table.insert(current_cluster, point_top)
        table.insert(all_clusters, current_cluster)

        for index_bottom, point_bottom in pairs(points) do
            if index_top ~= index_bottom and (point_bottom - point_top):Length2D() <= cluster_radius * 2 then
                table.insert(current_cluster, point_bottom)
            end
        end
    end

    return all_clusters
end

function find_predicted_ability_targets_points_at_location(ability, at_location, initial_search_radius, optional_target_filter)
    local units_in_radius = find_ability_targets_at_location(ability, at_location, initial_search_radius)
    local all_points = {}

    for _, unit in pairs(units_in_radius) do
        if not optional_target_filter or optional_target_filter(unit) then
            local point = unit:GetAbsOrigin()

            if unit:IsMoving() then
                point = point + unit:GetForwardVector() * unit:GetIdealSpeed()
            end

            table.insert(all_points, point)
        end
    end

    return all_points
end

---@param ability CDOTABaseAbility
---@param at_location vector
---@param initial_search_radius number
---@param cluster_radius number
---@return boolean, vector[]
function split_ability_targets_into_circle_clusters(ability, at_location, initial_search_radius, cluster_radius, optional_target_filter)
    local all_points = find_predicted_ability_targets_points_at_location(ability, at_location, initial_search_radius, optional_target_filter)

    return clusterize_points(all_points, cluster_radius)
end

function find_biggest_cluster(all_clusters, bigger_than)
    local biggest_cluster
    local biggest_cluster_size = bigger_than

    for _, current_cluster in pairs(all_clusters) do
        if #current_cluster > biggest_cluster_size then
            biggest_cluster_size = #current_cluster
            biggest_cluster = current_cluster
        end
    end

    return biggest_cluster ~= nil, biggest_cluster
end

function find_biggest_ability_target_cluster(ability, at_location, initial_search_radius, cluster_radius, bigger_than)
    local all_clusters = split_ability_targets_into_circle_clusters(ability, at_location, initial_search_radius, cluster_radius)

    return find_biggest_cluster(all_clusters, bigger_than)
end

function cluster_average(cluster)
    local cluster_center = cluster[1]

    for _, cluster_point in pairs(cluster) do
        cluster_center = (cluster_center + cluster_point) / 2.0
    end

    return cluster_center
end

function closest_point_to_segment(start, finish, point)
    local segment = finish - start
    local point_vector = point - start

    local normalized = segment:Normalized()
    local dot = point_vector:Dot(normalized)

    if dot <= 0 then
        return start
    end

    if dot >= segment:Length2D() then
        return finish
    end

    return start + (normalized * dot)
end

function is_left(a, b, c)
    return ((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)) > 0
end

function get_random_respawn_location_for_unit(native_unit_proxy)
    local respawn_locations_by_team = {
        [DOTA_TEAM_GOODGUYS] = Entities:FindAllByClassname("info_player_start_goodguys"),
        [DOTA_TEAM_BADGUYS] = Entities:FindAllByClassname("info_player_start_badguys")
    }

    local respawn_locations = respawn_locations_by_team[native_unit_proxy:GetTeam()]

    return respawn_locations[RandomInt(1, #respawn_locations)]:GetAbsOrigin()
end