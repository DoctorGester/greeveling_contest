editor_last_chat_message = editor_last_chat_message or ""

function on_developer_chat(event)
    process_chat_message(event.playerid, event.text)
end

function process_chat_message(player_id, text)
    local record_last_command = true
    local player = PlayerResource:GetPlayer(player_id)
    local hero
    local hero_location

    if player then
        hero = player:GetAssignedHero()

        if hero then
            hero_location = hero:GetAbsOrigin()
        end
    end

    if text == " " then
        SendToServerConsole("script_reload")
        record_last_command = false
    end

    if text == "  " then
        SendToServerConsole("cl_script_reload")
        record_last_command = false
    end

    if text == "." then
        process_chat_message(player_id, editor_last_chat_message)
        record_last_command = false
    end

    if text == "  " then
        --process_chat_message(" ")
        --process_chat_message(".")
        --record_last_command = false
    end

    if text == "f" then
        SendToServerConsole("host_timescale 4.0")
    end

    if text == "ff" then
        SendToServerConsole("host_timescale 14.0")
    end

    if text == "n" then
        SendToServerConsole("host_timescale 1.0")
    end

    if text == "egg" then
        make_greevil_egg(hero_location + RandomVector(300))
    end

    if text == "b1" then
        make_lesser_seal(hero_location + RandomVector(300), RandomInt(0, Lesser_Seal_Type.LAST - 1))
    end

    if text == "b2" then
        make_greater_seal(hero_location + RandomVector(300), RandomInt(0, Greater_Seal_Type.LAST - 1))
    end

    if text == "b3" then
        make_primal_seal(hero_location + RandomVector(300), RandomInt(0, Primal_Seal_Type.LAST - 1))
    end

    local function break_by_spaces(text)
        local right_side = text
        local split_text = {}

        while true do
            local space_position = string.find(right_side, " ")

            if space_position == nil then
                break
            end

            right_side = string.sub(right_side, space_position + 1)

            local next_space = string.find(right_side, " ")

            if next_space == nil then
                table.insert(split_text, right_side)
            else
                table.insert(split_text, string.sub(right_side, 0, next_space - 1))
            end
        end

        return split_text
    end

    local function strings_to_numbers(strings)
        local numbers = {}

        for _, string in pairs(strings) do
            table.insert(numbers, tonumber(string))
        end

        return numbers
    end

    local function strings_to_seals(strings)
        local targets = {
            {}, {}, {}
        }

        local target_index = 1

        for _, string in pairs(strings) do
            if string == ";" then
                target_index = target_index + 1
            else
                table.insert(targets[target_index], tonumber(string))
            end
        end

        print_table("targets", targets)

        return targets[1], targets[2], targets[3]
    end

    if text == "r" then
        for _, entity in pairs(all_entities) do
            entity.native_unit_proxy:Heal(100000, entity.native_unit_proxy)
            entity.native_unit_proxy:GiveMana(10000)
        end
    end

    if text == "fill" then
        ---@type Big_Egg
        local egg = big_egg_by_team_id[DOTA_TEAM_GOODGUYS]

        --big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.PRIMAL, Primal_Seal_Type.ORANGE))
        --big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.PRIMAL, Primal_Seal_Type.RED))

        --big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.PRIMAL, Primal_Seal_Type.BLUE))
        --big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.PRIMAL, Primal_Seal_Type.WHITE))

        --big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.PRIMAL, Primal_Seal_Type.BLACK))
        --big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.PRIMAL, Primal_Seal_Type.GREEN))

        big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.PRIMAL, Primal_Seal_Type.BLUE))
        big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.PRIMAL, Primal_Seal_Type.BLACK))


        big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.GREATER, Greater_Seal_Type.SOUL_BIND))
        big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.GREATER, Greater_Seal_Type.STATIC_DISCHARGE))
        big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.GREATER, Greater_Seal_Type.GREEVIL_PINATA))
        big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.GREATER, Greater_Seal_Type.HEAL_LA_KILL))

        big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.LESSER, Lesser_Seal_Type.HEALTH))
        big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.LESSER, Lesser_Seal_Type.HEALTH))
        big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.LESSER, Lesser_Seal_Type.DAMAGE))
        big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.LESSER, Lesser_Seal_Type.COOLDOWN_REDUCTION))
        big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.LESSER, Lesser_Seal_Type.ABILITY_LEVEL))
        big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.LESSER, Lesser_Seal_Type.ABILITY_LEVEL))
        big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.LESSER, Lesser_Seal_Type.ATTACK_SPEED))
        big_egg_apply_seal(egg, make_seal_in_inventory(Seal_Type.LESSER, Lesser_Seal_Type.ARMOR))
    end

    if text == "hatch" then
        big_eggs_hatch_at = GameRules:GetGameTime() + 0.01
    end

    if string_starts(text, "ag") then
        local p, g, l = strings_to_seals(break_by_spaces(text))

        add_entity(make_greevil(hero.attached_entity, p[1], g, l))
    end

    if string_starts(text, "pp") then
        local space_position = string.find(text, " ")
        local remaining_text = string.sub(text, space_position + 1)

        make_primal_seal(hero_location + RandomVector(200), tonumber(remaining_text))
    end

    if string_starts(text, "lpp") then
        add_entity(make_greevil(hero.attached_entity, nil, {}, strings_to_numbers(break_by_spaces(text))))
    end

    if string_starts(text, "gpp") then
        local space_position = string.find(text, " ")
        local remaining_text = string.sub(text, space_position + 1)

        add_entity(make_greevil(hero.attached_entity, tonumber(remaining_text), {}, {}))
    end

    if string_starts(text, "ggg") then
        add_entity(make_greevil(hero.attached_entity, nil, strings_to_numbers(break_by_spaces(text)), {}))
    elseif string_starts(text, "gg") then
        local space_position = string.find(text, " ")
        local remaining_text = string.sub(text, space_position + 1)

        make_greater_seal(hero_location + RandomVector(200), tonumber(remaining_text))
    end

    if string_starts(text, "ll") then
        local space_position = string.find(text, " ")
        local remaining_text = string.sub(text, space_position + 1)

        make_lesser_seal(hero_location + RandomVector(200), tonumber(remaining_text))
    end

    if text == "testdmg" then
        local hero_entity = hero.attached_entity
        local free_slot, _ = find_empty_inventory_slot(hero_entity)
        add_egg_to_hero_inventory(hero_entity)

        for i = 1, 4 do
            add_bonus_to_hero_inventory(hero_entity, make_seal_in_inventory(Seal_Type.GREATER, Greater_Seal_Type.MAGIC_WELL))
            hero_insert_seal(hero_entity, free_slot)
            add_bonus_to_hero_inventory(hero_entity, make_seal_in_inventory(Seal_Type.GREATER, Greater_Seal_Type.SOUL_BIND))
            hero_insert_seal(hero_entity, free_slot)
            add_bonus_to_hero_inventory(hero_entity, make_seal_in_inventory(Seal_Type.LESSER, Lesser_Seal_Type.DAMAGE))
            hero_insert_seal(hero_entity, free_slot)
        end

        hero_hatch_egg(hero_entity)
        hero_entity.started_hatching_at = GameRules:GetGameTime() - 10.0
        update_hero(hero_entity)
    end

    if text == "cl" then
        ---@type Hero
        local hero_entity = hero.attached_entity

        hero_entity.primal_seals = {}
        hero_entity.greater_seals = {}
        hero_entity.lesser_seals = {}
        hero_entity.bonuses = {}
        update_hero_network_state(hero_entity)
    end

    if text == "spawn a lot" then
        for i = 0, Lesser_Seal_Type.LAST - 1 do
            make_lesser_seal(RandomVector(250), i)
        end

        for i = 0, Greater_Seal_Type.LAST - 1 do
            make_greater_seal(RandomVector(350), i)
        end

        for i = 0, Primal_Seal_Type.LAST - 1 do
            make_primal_seal(RandomVector(450), i)
        end
    end

    if text == "party" then
        ---@type Hero
        local hero_entity = hero.attached_entity

        for seal = 0, Primal_Seal_Type.LAST - 1 do
            if seal ~= Primal_Seal_Type.PURPLE then
                add_bonus_to_hero_inventory(hero_entity, make_seal_in_inventory(Seal_Type.PRIMAL, seal))
                add_egg_to_hero_inventory(hero_entity)
                hero_insert_seal(hero_entity, 1)
                hero_hatch_egg(hero_entity)
                hero_entity.started_hatching_at = GameRules:GetGameTime() - 10.0
                update_hero(hero_entity)
            end
        end
    end

    if text == "sall" then
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

    if string_starts(text, "kg") then
        ---@type Hero
        local hero_entity = hero.attached_entity

        local space_position = string.find(text, " ")
        local remaining_text = string.sub(text, space_position + 1)

        hero_entity.active_greevils[tonumber(remaining_text)].greevil.native_unit_proxy:Kill(nil, nil)
    end

    if text == "modloc" then
        local localization = LoadKeyValues("resource/addon_english.txt").Tokens
        local all_missing = {}

        for mod_name, mod_path in pairs(linked_modifiers) do
            require(mod_path)

            local defines_is_hidden = _G[mod_name].IsHidden ~= nil
            local is_actually_hidden = true

            if defines_is_hidden then
                local no_errors, result = pcall(function() return _G[mod_name].IsHidden() end)

                if no_errors then
                    is_actually_hidden = result
                else
                    is_actually_hidden = false
                end
            end

            if not is_actually_hidden or not defines_is_hidden then
                local key = localization["DOTA_Tooltip_" .. mod_name]

                if not key then
                    table.insert(all_missing, "DOTA_Tooltip_" .. mod_name)
                end
            end
        end

        print("::: MISSING MODIFIERS")

        table.sort(all_missing)

        for _, text in ipairs(all_missing) do
            print("\"" .. text .. "\" \"\"")
        end
    end

    if record_last_command then
        editor_last_chat_message = text
    end
end

function set_up_developer_dummy_hero()
    local test_player_handle = PlayerResource:GetPlayer(2)
    local native_unit_proxy = CreateUnitByName("npc_dota_hero_juggernaut", Vector(),true, test_player_handle, test_player_handle, DOTA_TEAM_CUSTOM_2)

    native_unit_proxy:AddNewModifier(nil, nil, "modifier_stunned", {})
    add_entity(make_hero(native_unit_proxy))
end

function set_up_developer_initial_bonuses()
    process_chat_message(0,"spawn a lot")
end

-- Re-linking
link_native_modifiers()