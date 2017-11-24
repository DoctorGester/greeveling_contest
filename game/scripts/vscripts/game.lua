event_queue = event_queue or {}

---@type Entity[]
all_entities = all_entities or {}

big_eggs_hatched = false

---@type table<DOTATeam_t, Big_Egg>
big_egg_by_team_id = {}
next_creep_spawn_at = 0
big_eggs_hatch_at = 0
game_has_started = false
game_has_ended = false

next_event_location = {}
event_start_at = 0
event_type = Event_Type.LAST
event_is_ongoing = false
event_entity = {}
event_announced = false

queue_event_finish = false

event_locations = {}

linked_modifiers = {}

if is_in_debug_mode then
    entity_stats_print_at = 0
end

local EVENT_DURATION = minutes(1)
local EVENT_FREQUENCY = minutes(3)
local FIRST_EVENT_DELAY = minutes(5)

function start_game()
    if is_in_debug_mode then
        --set_up_developer_dummy_hero()
        set_up_developer_initial_bonuses()
    end

    game_has_started = true

    event_locations = {
        Entities:FindByName(nil, "middle_event_spawn"),
        --Entities:FindByName(nil, "side_event_spawn_1"), -- left
        --Entities:FindByName(nil, "side_event_spawn_2"), -- right
    }

    fill_drop_table()
    register_big_eggs()

    local current_time = GameRules:GetGameTime()

    initialize_drop_occurence_counter(current_time)
    schedule_next_event(current_time, FIRST_EVENT_DELAY)

    next_creep_spawn_at = current_time
    big_eggs_hatch_at = current_time + minutes(20.0)

    if is_in_debug_mode then
        --big_eggs_hatch_at = current_time + minutes(0.2)
    end

    update_timers_network_state()
end

function register_big_eggs()
    local radiant_egg = Entities:FindByName(nil, "dota_goodguys_fort")
    local dire_egg = Entities:FindByName(nil, "dota_badguys_fort")

    make_egg_invulnerable(radiant_egg)
    make_egg_invulnerable(dire_egg)

    big_egg_by_team_id[DOTA_TEAM_GOODGUYS] = make_big_egg(radiant_egg)
    big_egg_by_team_id[DOTA_TEAM_BADGUYS] = make_big_egg(dire_egg)

    add_entity(big_egg_by_team_id[DOTA_TEAM_GOODGUYS])
    add_entity(big_egg_by_team_id[DOTA_TEAM_BADGUYS])
end

function make_egg_invulnerable(egg)
    egg:AddNewModifier(egg, nil, "modifier_invulnerable", {})
end

function schedule_next_event(current_time, delay)
    event_start_at = current_time + delay

    if is_in_debug_mode then
        event_start_at = current_time + minutes(0.3)
    end

    next_event_location = event_locations[RandomInt(1, #event_locations)]
    event_type = RandomInt(0, Event_Type.LAST - 1)

    --if is_in_debug_mode then
        event_type = Event_Type.CRYSTAL_MAIDEN
    --end

    event_announced = false
    update_timers_network_state()
end

function schedule_next_creep_spawn(current_time)
    next_creep_spawn_at = current_time + minutes(0.5)
end

function update_timers_network_state()
    CustomNetTables:SetTableValue("events", "timers", {
        next_event_at = event_start_at,
        big_eggs_hatch_at = big_eggs_hatch_at
    })
end

function update_entity(entity)
    if entity.is_destroyed_next_update then
        return
    end

    if entity.entity_type == Entity_Type.HERO then
        update_hero(entity)
    elseif entity.entity_type == Entity_Type.GREEVIL then
        update_greevil(entity)
    elseif entity.entity_type == Entity_Type.BIG_EGG then
        update_big_egg(entity)
    elseif entity.entity_type == Entity_Type.MEGA_GREEVIL then
        update_mega_greevil(entity)
    elseif entity.entity_type == Entity_Type.CANDY then
        update_candy(entity)
    elseif entity.entity_type == Entity_Type.AI_CRYSTAL_MAIDEN then
        update_crystal_maiden_ai(entity)
    end
end

function destroy_entity(entity)
    if entity.entity_type == Entity_Type.CANDY then
        destroy_candy(entity)
    end
end

function on_state_changed()
    local native_state_changed_to = GameRules:State_Get()

    if is_in_debug_mode and native_state_changed_to == DOTA_GAMERULES_STATE_HERO_SELECTION then
        --SendToServerConsole("dota_bot_populate")
    end

    if native_state_changed_to == DOTA_GAMERULES_STATE_PRE_GAME then
        print("Pre-game has started")
        CustomGameEventManager:Send_ServerToAllClients("pregame_started", {})
    end

    if native_state_changed_to == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        print("Game has begun")
        start_game()
    end

    if native_state_changed_to == DOTA_GAMERULES_STATE_POST_GAME then
        print("Game is over")
        game_has_ended = true
    end
end

function on_native_unit_spawned(event)
    local native_unit_proxy = EntIndexToHScript(event.entindex)

    if is_native_unit_a_player_assigned_hero(native_unit_proxy) and native_unit_proxy.attached_entity == nil then
        add_entity(make_hero(native_unit_proxy))
    end
end

function on_native_unit_killed(event)
    local native_unit_proxy = EntIndexToHScript(event.entindex_killed)

    if native_unit_proxy == nil then
        return
    end

    -- Making egg vulnerable after any tower falls
    if native_unit_proxy:GetClassname() == "npc_dota_tower" then
        local egg = big_egg_by_team_id[native_unit_proxy:GetTeam()]

        if egg ~= nil then
            egg.native_unit_proxy:RemoveModifierByName("modifier_invulnerable")
        end

        return
    end

    if native_unit_proxy:GetTeam() == DOTA_TEAM_NEUTRALS then
        handle_neutral_creep_death_in_regard_to_item_drops(native_unit_proxy)
    end

    if native_unit_proxy:GetName() == "npc_dota_creep_lane" then
        local hero_killer = EntIndexToHScript(event.entindex_attacker)

        if not hero_killer:IsRealHero() then
            hero_killer = nil
        end

        handle_lane_creep_death_in_regard_to_item_drops(native_unit_proxy, hero_killer)
    end

    ---@type Entity
    local entity = native_unit_proxy.attached_entity

    if entity then
        if entity.entity_type == Entity_Type.HERO then
            start_hero_drop(entity)
        elseif entity.entity_type == Entity_Type.GREEVIL then
            handle_greevil_death(entity)
        elseif entity.entity_type == Entity_Type.MEGA_GREEVIL then
            local his_team = native_unit_proxy:GetTeam()

            if his_team == DOTA_TEAM_GOODGUYS then
                GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
            end

            if his_team == DOTA_TEAM_BADGUYS then
                GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
            end
        end
    end
end

function handle_event(event)
    --print("Emitting event", event.event_name)
    --print_table("event_table", event)

    local event_handlers = {
        game_rules_state_change = on_state_changed,
        npc_spawned = on_native_unit_spawned,
        entity_killed = on_native_unit_killed,
        hatchery_insert_seal = on_hatchery_insert_seal,
        hatchery_remove_seal = on_hatchery_remove_seal,
        hatchery_hatch_egg = on_hatchery_hero_hatch_egg,
        hatchery_feed_seal = on_hatchery_hero_feed_big_egg,
        hatchery_drop_seal = on_hatchery_hero_drop_seal,
        hatchery_put_greevil_into_slot = on_hatchery_hero_put_greevil_into_slot
    }

    if is_in_debug_mode then
        event_handlers.player_chat = on_developer_chat
    end

    local handler = event_handlers[event.event_name]

    if not handler then
        error("Caught unhandled event " .. event.event_name)
    end

    handler(event)
end

function hatch_big_eggs()
    print("Big eggs are hatching!")

    big_eggs_hatched = true

    start_hatching_big_egg(big_egg_by_team_id[DOTA_TEAM_GOODGUYS])
    start_hatching_big_egg(big_egg_by_team_id[DOTA_TEAM_BADGUYS])

    for_all_players(function(player_id)
        -- Ugh, the data should have been attached to player id in the first place!
        local player_hero = PlayerResource:GetPlayer(player_id):GetAssignedHero()
        local hero_entity = player_hero.attached_entity

        assert(hero_entity ~= nil, "Something went wrong, player " .. tostring(player_id) .. " has no hero entity!")

        update_hero_network_state(hero_entity)
    end)

    CustomGameEventManager:Send_ServerToTeam(DOTA_TEAM_GOODGUYS, "big_eggs_are_hatching", {
        target_entity = big_egg_by_team_id[DOTA_TEAM_GOODGUYS].native_unit_proxy:GetEntityIndex()
    })

    CustomGameEventManager:Send_ServerToTeam(DOTA_TEAM_BADGUYS, "big_eggs_are_hatching", {
        target_entity = big_egg_by_team_id[DOTA_TEAM_BADGUYS].native_unit_proxy:GetEntityIndex()
    })

    CreateModifierThinker(
        big_egg_by_team_id[DOTA_TEAM_GOODGUYS].native_unit_proxy,
        nil,
        "modifier_egg_hatch_pause",
        {
            duration = 5.0
        },
        Vector(),
        DOTA_TEAM_NEUTRALS,
        false
    )
end

function start_next_event()
    event_is_ongoing = true

    announce_and_reveal_event()

    if event_type == Event_Type.CRYSTAL_MAIDEN then
        event_entity = make_crystal_maiden_ai(next_event_location:GetAbsOrigin())

        add_entity(event_entity)
    end

    CustomGameEventManager:Send_ServerToAllClients("event_started", {})
end

function spawn_lane_creeps_for_teams(team, spawn_locations, creep_names)
    local team_egg = big_egg_by_team_id[team]
    local unit_owner = team_egg.native_unit_proxy

    for _, spawn_location in pairs(spawn_locations) do
        for _, creep_name in pairs(creep_names) do
            local location = spawn_location.offset + unit_owner:GetAbsOrigin()
            local spawned_creep = CreateUnitByName(
                creep_name, location, true, unit_owner, unit_owner, team
            )

            spawned_creep:SetInitialGoalEntity(spawn_location.goal_entity)
        end
    end
end

function spawn_lane_creeps()
    local function make_spawn_location(offset, goal_entity_name)
        return {
            offset = offset,
            goal_entity = Entities:FindByName(nil, goal_entity_name)
        }
    end

    local radiant_spawn_locations = {
        make_spawn_location(Vector(-300, 0, 0), "path_radiant_top_1"),
        make_spawn_location(Vector(300, 0, 0), "path_radiant_bot_1")
    }

    local dire_spawn_locations = {
        make_spawn_location(Vector(-300, 0, 0), "path_dire_top_1"),
        make_spawn_location(Vector(300, 0, 0), "path_dire_bot_1")
    }

    local dire_creep_names = {
        "npc_dota_creep_badguys_melee",
        "npc_dota_creep_badguys_melee",
        "npc_dota_creep_badguys_melee",
        "npc_dota_creep_badguys_ranged"
    }

    local radiant_creep_names = {
        "npc_dota_creep_goodguys_melee",
        "npc_dota_creep_goodguys_melee",
        "npc_dota_creep_goodguys_melee",
        "npc_dota_creep_goodguys_ranged"
    }

    spawn_lane_creeps_for_teams(DOTA_TEAM_GOODGUYS, radiant_spawn_locations, radiant_creep_names)
    spawn_lane_creeps_for_teams(DOTA_TEAM_BADGUYS, dire_spawn_locations, dire_creep_names)
end

function finish_ongoing_event(current_time)
    if event_type == Event_Type.CRYSTAL_MAIDEN then
        finish_crystal_maiden_event(event_entity)
    end

    queue_event_finish = false
    event_is_ongoing = false
    schedule_next_event(current_time, EVENT_FREQUENCY)
end

function update_ongoing_event_state(current_time)
    if current_time - event_start_at >= EVENT_DURATION or queue_event_finish then
        finish_ongoing_event(current_time)
    end
end

function announce_and_reveal_event()
    if next_event_location == event_locations[1] then
        EmitAnnouncerSound("announcer_ann_custom_generic_alert_62")
    elseif next_event_location == event_locations[2] then
        EmitAnnouncerSound("announcer_ann_custom_generic_alert_60")
    elseif next_event_location == event_locations[3] then
        EmitAnnouncerSound("announcer_ann_custom_generic_alert_56")
    end

    local location = next_event_location:GetAbsOrigin()

    for _, team in pairs({ DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS }) do
        MinimapEvent(team, big_egg_by_team_id[team].native_unit_proxy, location.x, location.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 5.0)

        AddFOWViewer(team, location, 1450, EVENT_DURATION, false)
    end
end

function announce_event_before()
    if next_event_location == event_locations[1] then
        EmitAnnouncerSound("announcer_ann_custom_generic_alert_52")
    elseif next_event_location == event_locations[2] then
        EmitAnnouncerSound("announcer_ann_custom_generic_alert_50")
    elseif next_event_location == event_locations[3] then
        EmitAnnouncerSound("announcer_ann_custom_generic_alert_46")
    end

    local location = next_event_location:GetAbsOrigin()

    MinimapEvent(DOTA_TEAM_GOODGUYS, big_egg_by_team_id[DOTA_TEAM_GOODGUYS].native_unit_proxy, location.x, location.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 15.0)
    MinimapEvent(DOTA_TEAM_BADGUYS, big_egg_by_team_id[DOTA_TEAM_BADGUYS].native_unit_proxy, location.x, location.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 15.0)
end

function update_game_state(current_time)
    if not game_has_started or game_has_ended then
        return
    end

    if not big_eggs_hatched then
        if current_time >= big_eggs_hatch_at then
            hatch_big_eggs()
        end

        if current_time >= event_start_at and not event_is_ongoing then
            start_next_event()
        end

        if current_time >= event_start_at - 15.0 and not event_announced then
            announce_event_before()
            event_announced = true
        end

        if current_time >= next_creep_spawn_at then
            spawn_lane_creeps()
            schedule_next_creep_spawn(current_time)
        end
    end

    update_hero_drops()

    if event_is_ongoing then
        update_ongoing_event_state(current_time)
    end
end

function print_debug_entity_stats()
    local entity_type_to_string = {
        [Entity_Type.HERO] = "HERO",
        [Entity_Type.BONUS] = "BONUS",
        [Entity_Type.GREEVIL_EGG] = "GREEVIL_EGG",
        [Entity_Type.GREEVIL] = "GREEVIL",
        [Entity_Type.BIG_EGG] = "BIG_EGG",
        [Entity_Type.MEGA_GREEVIL] = "MEGA_GREEVIL",
        [Entity_Type.CANDY] = "CANDY",
        [Entity_Type.AI_CRYSTAL_MAIDEN] = "AI_CRYSTAL_MAIDEN",
        [Entity_Type.AI_TUSK] = "AI_TUSK",
        [Entity_Type.AI_LICH] = "AI_LICH",
        [Entity_Type.AI_WINTER_WYVERN] = "AI_WINTER_WYVERN",
    }

    local entity_stats = {}

    for _, entity in ipairs(all_entities) do
        entity_stats[entity.entity_type] = (entity_stats[entity.entity_type] or 0) + 1
    end

    print("Entity_Stats")

    for entity_type, entity_amount in pairs(entity_stats) do
        print("", entity_type_to_string[entity_type] or "UNKNOWN", entity_amount)
    end
end

function do_one_frame(current_time)
    xpcall(update_game_state, handle_errors, current_time)

    for _, entity in ipairs(all_entities) do
        xpcall(update_entity, handle_errors, entity, current_time)
    end

    for entity_index = #all_entities, 1, -1 do
        if all_entities[entity_index].is_destroyed_next_update then
            xpcall(destroy_entity, handle_errors, all_entities[entity_index])
            table.remove(all_entities, entity_index)
        end
    end

    if is_in_debug_mode then
        if current_time >= entity_stats_print_at then
            entity_stats_print_at = current_time + 120.0

            print_debug_entity_stats()
        end
    end
end

function game_loop(current_time)
    exhaust_native_event_queue_and_emit_events()

    do_one_frame(current_time)
end

function handle_errors(error_text)
    print("[ERROR]", debug.traceback(error_text))
end

function exhaust_native_event_queue_and_emit_events()
    while true do
        next = pairs(event_queue)

        local event_index, first_event_in_queue = next(event_queue, nil)

        if first_event_in_queue then
            xpcall(handle_event, handle_errors, first_event_in_queue)
            table.remove(event_queue, event_index)
        else
            break
        end
    end
end

function add_event_to_queue(event_name, event)
    local new_event = {
        event_name = event_name
    }

    for key, value in pairs(event) do
        new_event[key] = value
    end

    table.insert(event_queue, new_event)
end

function add_entity(entity)
    assert(entity ~= nil, "Attempted to add a nil entity!")

    table.insert(all_entities, entity)
end

---@param native_unit CDOTA_BaseNPC_Hero
function is_native_unit_a_player_assigned_hero(native_unit)
    if native_unit:GetPlayerOwner() == nil then
        return false
    end

    return native_unit:GetPlayerOwner():GetAssignedHero() == native_unit
end

function on_native_heal_received(heal_data)
    local healer_id = heal_data.entindex_healer_const
    local target_id = heal_data.entindex_target_const
    local ability = heal_data.entindex_inflictor_const

    if ability ~= nil and healer_id ~= nil and target_id ~= nil then
        ---@type CDOTA_BaseNPC
        local target_entity = EntIndexToHScript(target_id)
        local heal_amount = heal_data.heal

        local all_units = FindUnitsInRadius(
            0,
            Vector(),
            nil,
            FIND_UNITS_EVERYWHERE,
            DOTA_UNIT_TARGET_TEAM_BOTH,
            DOTA_UNIT_TARGET_ALL,
            DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_ANY_ORDER,
            false
        )

        for _, unit in pairs(all_units) do
            for _, modifier in pairs(unit:FindAllModifiers()) do
                if modifier.OnFilteredHealing then
                    modifier:OnFilteredHealing(target_entity, heal_amount, EntIndexToHScript(healer_id), EntIndexToHScript(ability))
                end
            end
        end
    end

    return true
end

function filter_native_item_added_to_inventory(item_data)
    local item_entity_id = item_data.item_entindex_const
    local inventory_parent_entity_id = item_data.inventory_parent_entindex_const

    if item_entity_id == nil or inventory_parent_entity_id == nil then
        return true
    end

    ---@type CDOTA_Item
    local native_item = EntIndexToHScript(item_entity_id)
    local native_unit = EntIndexToHScript(inventory_parent_entity_id)

    if native_item == nil or native_unit == nil then
        return true
    end

    local main_hero = native_unit

    if native_unit:IsRealHero() and native_unit:GetPlayerOwner() ~= nil and not is_native_unit_a_player_assigned_hero(native_unit) then
        main_hero = native_unit:GetPlayerOwner():GetAssignedHero()

        if main_hero == nil then
            main_hero = native_unit
        end
    end

    ---@type Entity
    local item_entity = native_item.attached_entity

    ---@type Entity
    local picked_up_by = main_hero.attached_entity

    --- If not a special item
    if not item_entity then
        return true
    end

    if item_entity.entity_type == Entity_Type.CANDY then
        return true
    end

    local function recreate_item_container()
        local container = CreateItemOnPositionSync(native_item:GetContainer():GetAbsOrigin(), native_item)

        if item_entity.entity_type == Entity_Type.BONUS then
            item_entity.native_container_proxy = container
            update_bonus_model_skin(item_entity)
        end
    end

    local picked_up_by_a_hero = picked_up_by and picked_up_by.entity_type == Entity_Type.HERO

    if picked_up_by_a_hero then
        if item_entity.entity_type == Entity_Type.GREEVIL_EGG then
            add_egg_to_hero_inventory(picked_up_by)
            native_item:Destroy()
        elseif item_entity.entity_type == Entity_Type.BONUS then
            if hero_has_a_slot_for_another_bonus(picked_up_by) then
                add_bonus_to_hero_inventory(picked_up_by, item_entity)
                native_item:Destroy()
            else
                emit_custom_hud_error_for_player(native_unit:GetPlayerOwner(), "error_hatchery_is_full", 80)
                recreate_item_container()
            end
        end
    else
        emit_custom_hud_error_for_player(native_unit:GetPlayerOwner(), "error_cant_be_picked_up_by_non_heroes", 80)
        recreate_item_container()
    end

    return false
end

function filter_native_experience_added(experience_data)
    if experience_data.experience ~= nil then
        experience_data.experience = experience_data.experience * 1.45
    end

    return true
end

function filter_native_modifier_applied(modifier_data)
    if modifier_data.entindex_parent_const == nil then
        return true
    end

    local parent = EntIndexToHScript(modifier_data.entindex_parent_const)

    if parent == nil or parent.attached_entity == nil then
        return true
    end

    local modifier_name = modifier_data.name_const
    local entity_type = parent.attached_entity.entity_type
    local is_a_boss =
        entity_type == Entity_Type.MEGA_GREEVIL or
        entity_type == Entity_Type.AI_CRYSTAL_MAIDEN or
        entity_type == Entity_Type.AI_LICH or
        entity_type == Entity_Type.AI_TUSK or
        entity_type == Entity_Type.AI_WINTER_WYVERN

    local is_a_modifier_we_do_not_want_on_bosses =
        modifier_name == "modifier_axe_berserkers_call" or
        modifier_name == "modifier_ursa_fury_swipes_damage_increase"

    if is_a_boss and is_a_modifier_we_do_not_want_on_bosses then
        return false
    end

    return true
end

function emit_custom_hud_error_for_player(player, error_text, error_reason)
    CustomGameEventManager:Send_ServerToPlayer(player, "custom_game_error", {
        reason = error_reason,
        message = error_text
    })
end

function link_native_modifiers()
    print("Linking native modifiers")

    link_native_modifier_simple("bonuses/lesser/modifier_lesser_seal_ability_level")
    link_native_modifier_simple("bonuses/lesser/modifier_lesser_seal_armor")
    link_native_modifier_simple("bonuses/lesser/modifier_lesser_seal_attack_speed")
    link_native_modifier_simple("bonuses/lesser/modifier_lesser_seal_cooldown_reduction")
    link_native_modifier_simple("bonuses/lesser/modifier_lesser_seal_damage")
    link_native_modifier_simple("bonuses/lesser/modifier_lesser_seal_health")

    -- Other stuff
    link_native_modifier_simple("modifiers/modifier_big_egg_visual_delta_z_correction")
    link_native_modifier_simple("modifiers/modifier_big_egg_hidden")
    link_native_modifier_simple("modifiers/modifier_greevil")
    link_native_modifier_simple("modifiers/modifier_greevil_respawn")
    link_native_modifier_simple("modifiers/modifier_greevil_spawning")
    link_native_modifier_simple("modifiers/modifier_greevil_deactivated")
    link_native_modifier_simple("modifiers/modifier_mega_greevil")
    link_native_modifier_simple("modifiers/modifier_egg_hatch_pause")
    link_native_modifier_simple("modifiers/modifier_egg_hatch_pause_target")

    -- Bosses
    link_native_modifier_simple("event_crystal_maiden/modifier_crystal_maiden_boss")
    link_native_modifier_simple("event_crystal_maiden/modifier_crystal_maiden_boss_frostbite")

    -- Primal Abilities
    link_native_modifier_simple("bonuses/primal/modifier_green_aura")
    link_native_modifier_simple("bonuses/primal/modifier_green_aura_target")
    link_native_modifier_simple("bonuses/primal/modifier_green_aura_target_root")
    link_native_modifier_simple("bonuses/primal/modifier_blue_aura")
    link_native_modifier_simple("bonuses/primal/modifier_blue_aura_target")
    link_native_modifier_simple("bonuses/primal/modifier_black_aura")
    link_native_modifier_simple("bonuses/primal/modifier_black_aura_target")
    link_native_modifier_simple("bonuses/primal/modifier_orange_aura")
    link_native_modifier_simple("bonuses/primal/modifier_yellow")
    link_native_modifier_simple("bonuses/primal/modifier_red_aura")
    link_native_modifier_simple("bonuses/primal/modifier_red_aura_target")

    -- Greater Abilities
    link_native_modifier_simple("bonuses/greater/modifier_soul_bind")
    link_native_modifier_simple("bonuses/greater/modifier_soul_bind_target")
    link_native_modifier_simple("bonuses/greater/modifier_greevil_pinata")
    link_native_modifier_simple("bonuses/greater/modifier_healing_frenzy")
    link_native_modifier_simple("bonuses/greater/modifier_together_we_stand")
    link_native_modifier_simple("bonuses/greater/modifier_static_discharge")
    link_native_modifier_simple("bonuses/greater/modifier_static_discharge_target")
    link_native_modifier_simple("bonuses/greater/modifier_static_discharge_cooldown")
    link_native_modifier_simple("bonuses/greater/modifier_heal_la_kill")
    link_native_modifier_simple("bonuses/greater/modifier_magic_well")

    -- Animations
    link_native_modifier_simple("bonuses/primal/animations/modifier_animation_black")
    link_native_modifier_simple("bonuses/primal/animations/modifier_animation_blue")
    link_native_modifier_simple("bonuses/primal/animations/modifier_animation_orange")
end

function set_up_game_settings()
    local mode = GameRules:GetGameModeEntity()

    mode:SetHealingFilter(function(_, data) return on_native_heal_received(data) end, {})
    mode:SetItemAddedToInventoryFilter(function(_, data) return filter_native_item_added_to_inventory(data) end, {})
    mode:SetModifyExperienceFilter(function(_, data) return filter_native_experience_added(data) end, {})
    mode:SetModifierGainedFilter(function (_, data) return filter_native_modifier_applied(data) end, {})
    mode:SetRespawnTimeScale(0.5)
    mode:SetFountainPercentageHealthRegen(10.0)
    mode:SetFountainPercentageManaRegen(10.0)

    GameRules:SetGoldPerTick(4)
    GameRules:SetUseUniversalShopMode(true)
    GameRules:SetPreGameTime(20)
    GameRules:SetHeroSelectionTime(30.0)
    GameRules:SetStrategyTime(10.0)

    if is_in_debug_mode then
        mode:SetCustomGameForceHero("npc_dota_hero_juggernaut")
        --mode:SetFogOfWarDisabled(true)

        GameRules:EnableCustomGameSetupAutoLaunch(true)
        GameRules:SetCustomGameSetupAutoLaunchDelay(1)
        GameRules:SetPreGameTime(0)
        GameRules:SetPostGameTime(300000)
        GameRules:SetHeroSelectionTime(1.0)
    end
end

function preload_resources_from_context(context)
    PrecacheUnitByNameSync("npc_unit_mega_greevil", context)
    PrecacheUnitByNameSync("npc_unit_bare_greevil", context)
    PrecacheUnitByNameSync("npc_dota_creature_crystal_maiden_boss", context)

    PrecacheResource("particle", "particles/bosses/ice_ball.vpcf", context)
    PrecacheResource("particle", "particles/bosses/ice_ball_point_targeted.vpcf", context)

    PrecacheResource("soundfile", "soundevents/game_sounds_vo_announcer.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/ability_sounds.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/ui_sounds.vsndevts", context)
end