neutral_creep_drop_time_counter = 0
lane_creep_drop_time_counter = 0
egg_drop_time_counter = 0
remaining_seal_drops = {
    [Seal_Type.PRIMAL] = {},
    [Seal_Type.GREATER] = {},
    [Seal_Type.LESSER] = {}
}

local neutral_drop_occurrence_frequency = minutes(0.15)
local lane_drop_occurence_frequency = minutes(0.15)
local egg_drop_occurence_frequency = minutes(0.75)
local amount_of_each_bonus = 8

local seal_type_factors = {
    [Seal_Type.PRIMAL] = 1,
    [Seal_Type.GREATER] = 2,
    [Seal_Type.LESSER] = 4
}

local seal_enums = {
    [Seal_Type.PRIMAL] = Primal_Seal_Type,
    [Seal_Type.GREATER] = Greater_Seal_Type,
    [Seal_Type.LESSER] = Lesser_Seal_Type
}

function fill_drop_table()
    for seal_type, type_enum in pairs(seal_enums) do
        for type = 0, type_enum.LAST - 1 do
            if seal_type == Seal_Type.PRIMAL and type == Primal_Seal_Type.PURPLE then
                print("I'm a little purple seal, don't forget to add me!")
            else
                remaining_seal_drops[seal_type][type] = amount_of_each_bonus * seal_type_factors[seal_type]
            end
        end
    end
end

-- Who needs RAM anyway?
local function expanding_random(items_with_weights)
    local list = {}
    for item, weight in pairs(items_with_weights) do
        local n = weight
        for i = 1, n do table.insert(list, item) end
    end

    return list[RandomInt(1, #list)]
end

---@return Seal_Type, number, boolean
function get_next_drop_and_update_drop_table()
    local weighted_drop_tables = {}

    for seal_type, drop_table in pairs(remaining_seal_drops) do
        local total_value = 0

        for _, amount in pairs(drop_table) do
            total_value = total_value + amount
        end

        local table_with_type = {
            seal_type = seal_type,
            table = drop_table
        }

        weighted_drop_tables[table_with_type] = total_value
    end

    local selected_drop_table_with_type = expanding_random(weighted_drop_tables)

    if not selected_drop_table_with_type then
        return nil, nil, false
    end

    local selected_type = selected_drop_table_with_type.seal_type
    local selected_table = selected_drop_table_with_type.table
    local selected_seal = expanding_random(selected_table)

    selected_table[selected_seal] = selected_table[selected_seal] - 1

    return selected_type, selected_seal, true
end

function initialize_drop_occurence_counter(current_time)
    neutral_creep_drop_time_counter = current_time - neutral_drop_occurrence_frequency -- First creep killed will drop an item
    lane_creep_drop_time_counter = current_time - lane_drop_occurence_frequency
    egg_drop_time_counter = current_time
end

function handle_neutral_creep_death_in_regard_to_item_drops(neutral_creep)
    local current_time = GameRules:GetGameTime()

    if current_time - egg_drop_time_counter > egg_drop_occurence_frequency then
        egg_drop_time_counter = egg_drop_time_counter + egg_drop_occurence_frequency
        generate_and_launch_egg_drop(neutral_creep)
    elseif current_time - neutral_creep_drop_time_counter > neutral_drop_occurrence_frequency then
        neutral_creep_drop_time_counter = neutral_creep_drop_time_counter + neutral_drop_occurrence_frequency
        generate_and_launch_creep_drop(neutral_creep)
    end
end

function handle_lane_creep_death_in_regard_to_item_drops(lane_creep, hero_killer_optional)
    local current_time = GameRules:GetGameTime()

    local any_heroes_are_around = #FindUnitsInRadius(
        DOTA_TEAM_NEUTRALS,
        lane_creep:GetAbsOrigin(),
        nil,
        900,
        DOTA_UNIT_TARGET_TEAM_BOTH,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    ) > 0

    if any_heroes_are_around then
        if current_time - egg_drop_time_counter > egg_drop_occurence_frequency then
            egg_drop_time_counter = egg_drop_time_counter + egg_drop_occurence_frequency
            generate_and_launch_egg_drop(lane_creep, hero_killer_optional)
        elseif current_time - lane_creep_drop_time_counter > lane_drop_occurence_frequency then
            lane_creep_drop_time_counter = lane_creep_drop_time_counter + lane_drop_occurence_frequency
            generate_and_launch_creep_drop(lane_creep, hero_killer_optional)
        end
    end
end

function generate_and_launch_egg_drop(creep, towards_who_optional)
    local egg_drop_item = CreateItem("item_greevil_egg", nil, nil)
    local egg_drop_container = CreateItemOnPositionForLaunch(creep:GetAbsOrigin(), egg_drop_item)

    EmitSoundOn("item_drop", egg_drop_container)

    make_greevil_egg_from_existing_item(egg_drop_item, egg_drop_container)

    local launch_location = creep:GetAbsOrigin() + RandomVector(100)

    if towards_who_optional then
        local direction_halfway = (towards_who_optional:GetAbsOrigin() - creep:GetAbsOrigin()) / 2.0
        direction_halfway = min_vector_2d(direction_halfway, direction_halfway:Normalized() * 500.0)

        launch_location = creep:GetAbsOrigin() + direction_halfway
    end

    egg_drop_item:LaunchLootInitialHeight(false, 0, 300, 0.75, launch_location)
end

function generate_and_launch_creep_drop(creep, towards_who_optional)
    local seal_type, seal, found = get_next_drop_and_update_drop_table()

    if not found then
        return
    end

    local item_name = convert_seal_type_to_item_name(seal_type, seal)
    local bonus_drop_item = CreateItem(item_name, nil, nil)
    local bonus_drop_container = CreateItemOnPositionForLaunch(creep:GetAbsOrigin(), bonus_drop_item)

    EmitSoundOn("item_drop", bonus_drop_container)

    make_bonus_from_existing_item_and_container(
        bonus_drop_item,
        bonus_drop_container,
        seal_type,
        seal
    )

    local launch_location = creep:GetAbsOrigin() + RandomVector(100)

    if towards_who_optional then
        local direction_halfway = (towards_who_optional:GetAbsOrigin() - creep:GetAbsOrigin()) / 2.0
        direction_halfway = min_vector_2d(direction_halfway, direction_halfway:Normalized() * 500.0)

        launch_location = creep:GetAbsOrigin() + direction_halfway
    end

    bonus_drop_item:LaunchLootInitialHeight(false, 0, 300, 0.75, launch_location)
end

function generate_and_launch_boss_drop(attacker, boss, drop_an_egg)
    local drop_item, drop_container
    local attacker_position = attacker:GetAbsOrigin()
    local boss_position = boss:GetAbsOrigin()
    local drop_direction = (boss_position - attacker_position):Normalized()

    if drop_an_egg then
        drop_item = CreateItem("item_greevil_egg", nil, nil)
        drop_container = CreateItemOnPositionForLaunch(boss_position, drop_item)

        make_greevil_egg_from_existing_item(drop_item, drop_container)
    else
        local seal_type, seal, found = get_next_drop_and_update_drop_table()

        if not found then
            return
        end

        local item_name = convert_seal_type_to_item_name(seal_type, seal)

        drop_item = CreateItem(item_name, nil, nil)
        drop_container = CreateItemOnPositionForLaunch(boss_position, drop_item)

        make_bonus_from_existing_item_and_container(
            drop_item,
            drop_container,
            seal_type,
            seal
        )
    end

    local launch_power = RandomFloat(1.0, 2.0)
    while true do
        local launch_height = 300.0 * launch_power
        local launch_duration = 0.45 * launch_power
        local launch_target = boss_position + drop_direction * 300.0 * launch_power

        if GridNav:CanFindPath(boss_position, launch_target) or launch_power < 0.5 then
            EmitSoundOn("item_drop", drop_container)

            drop_item:LaunchLootInitialHeight(false, 200, launch_height, launch_duration, launch_target)
            break
        else
            launch_power = launch_power - 0.1
        end
    end
end