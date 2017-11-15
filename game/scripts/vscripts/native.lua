local last_time_think_was_called = GameRules:GetGameTime()

function bind_native_events()
    listen_to_native_event("player_connect_full")
    listen_to_native_event("player_reconnected")
    listen_to_native_event("player_disconnect")
    listen_to_native_event("game_rules_state_change")
    listen_to_native_event("npc_spawned")
    listen_to_native_event("entity_killed")

    if is_in_debug_mode then
        listen_to_native_event("player_chat")
    end
end

function bind_custom_events()
    listen_to_custom_event("hatchery_insert_seal")
    listen_to_custom_event("hatchery_remove_seal")
    listen_to_custom_event("hatchery_hatch_egg")
    listen_to_custom_event("hatchery_feed_seal")
    listen_to_custom_event("hatchery_drop_seal")
end

function set_up_extra_native_event_bus()
    LinkLuaModifier("modifier_event_bus", LUA_MODIFIER_MOTION_NONE)
    CreateModifierThinker(nil, nil, "modifier_event_bus", {}, Vector(), DOTA_TEAM_GOODGUYS, false)
end

function set_up_native_game_mode_entity()
    GameRules:GetGameModeEntity():SetThink("on_native_think", nil, "GlobalThink", 0)
end

function on_native_think()
    if GameRules:GetGameTime() - last_time_think_was_called > 0 then
        last_time_think_was_called = GameRules:GetGameTime()
        game_loop(last_time_think_was_called)
    end

    return 0.01
end

function listen_to_native_event(event_name)
    ListenToGameEvent(event_name, function(native_event_data)
        add_event_to_queue(event_name, native_event_data)
    end, nil)
end

function listen_to_custom_event(event_name)
    CustomGameEventManager:RegisterListener(event_name, function(_, custom_event_data)
        add_event_to_queue(event_name, custom_event_data)
    end)
end
