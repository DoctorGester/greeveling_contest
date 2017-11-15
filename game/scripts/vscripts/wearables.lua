game_items = game_items or LoadKeyValues("scripts/items/items_game.txt")

LinkLuaModifier("modifier_wearable_visuals", LUA_MODIFIER_MOTION_NONE)

function load_wearables(native_unit_proxy, ...)
    -- TODO remove this junk
    native_unit_proxy.slot_visual_parameters = native_unit_proxy.slot_visual_parameters or {}
    native_unit_proxy.wearable_slots = native_unit_proxy.wearable_slots or {}
    native_unit_proxy.mapped_particles = native_unit_proxy.mapped_particles or {}
    native_unit_proxy.wearable_particles = native_unit_proxy.wearable_particles or {}

    local items = find_default_items(native_unit_proxy)
    local ignored = {}
    local styles = {}

    for _, arg in pairs({ ... }) do
        if type(arg) == "number" then
            local item = game_items.items[tostring(arg)]

            if item then
                items[item.item_slot or "weapon"] = item
                item.id = arg
            end
        end

        if type(arg) == "string" then
            if string_ends(arg, ".vmdl") then
                local split = string_split(arg,":")

                items[split[1]] = {
                    model_player = split[2]
                }
            else
                local set = self:FindSetItems(arg)

                for slot, item in pairs(set) do
                    items[slot] = item
                end
            end
        end

        if type(arg) == "table" then
            if type(arg.style) == "number" and type(arg.id) == "number" then
                styles[arg.id] = arg.style
            elseif type(arg.ignore) == "number" then
                ignored[arg.ignore] = true
            else
                for slot, item in pairs(arg) do
                    items[slot] = item
                end
            end
        end
    end

    local session_wearables = {}

    for slot, item in pairs(items) do
        if not item.id or not ignored[item.id] then
            native_unit_proxy.slot_visual_parameters[slot] = { native_unit_proxy, nil, item.visuals or {}, styles[item.id], slot }

            if item.model_player then
                local wearable = attach_wearable(native_unit_proxy, item.model_player)
                native_unit_proxy.slot_visual_parameters[slot][2] = wearable

                table.insert(session_wearables, wearable)
                native_unit_proxy.wearable_slots[slot] = wearable
            end

            attach_wearable_visuals(unpack(native_unit_proxy.slot_visual_parameters[slot]))
        end
    end

    return session_wearables
end

function attach_wearable(native_unit_proxy, model_path)
    local wearable = CreateUnitByName("wearable_model", Vector(0, 0, 0), false, nil, nil, DOTA_TEAM_NOTEAM)

    local oldSet = wearable.SetModel

    wearable.SetModel = function(self, model)
        oldSet(self, model)
        self:SetOriginalModel(model)
    end

    wearable:SetModel(model_path)
    wearable:FollowEntity(native_unit_proxy, true)
    wearable:AddNewModifier(wearable, nil, "modifier_wearable_visuals", {})

    --table.insert(self.wearables, wearable)

    return wearable
end

function attach_wearable_visuals(native_unit_proxy, wearable, visuals, style, slot)
    local attachTypes = {
        customorigin = PATTACH_CUSTOMORIGIN,
        point_follow = PATTACH_POINT_FOLLOW,
        absorigin_follow = PATTACH_ABSORIGIN_FOLLOW
    }

    local particle_queue = {}

    for name, visual in pairs(visuals) do
        if string.find(name, "asset_modifier") and (style == nil or visual.style == style) then
            local t = visual.type

            if t == "particle_create" then
                for _, system in pairs(game_items.attribute_controlled_attached_particles) do
                    if system.system == visual.modifier then
                        particle_queue[visual] = system
                    end
                end
            elseif t == "additional_wearable" then
                attach_wearable(native_unit_proxy, visual.asset)
            elseif t == "particle" then
                native_unit_proxy.mapped_particles[visual.asset] = visual.modifier
            elseif t == "activity" then
                CustomNetTables:SetTableValue("wearables", "activity_" .. tostring(wearable:GetEntityIndex()), { activity = visual.modifier })
                native_unit_proxy:AddNewModifier(wearable, nil, "modifier_wearable_visuals_activity", {})
            else
                print("Unknown modifier type", t, "with mod", visual.modifier)
            end
        end
    end

    for visual, system in pairs(particle_queue) do
        local target = wearable

        if system.attach_entity == "parent" then
            target = native_unit_proxy
        end

        local mainAt = attachTypes[system.attach_type] or PATTACH_POINT_FOLLOW
        local particle = ParticleManager:CreateParticle(get_mapped_particle(native_unit_proxy, system.system), mainAt, target)
        print("Attaching", get_mapped_particle(native_unit_proxy, system.system), mainAt, target)

        for _, cp in pairs(system.control_points or {}) do
            local at = attachTypes[cp.attach_type]

            if at == nil then
                print("Unknown attachment type", cp.attach_type)
                at = PATTACH_ABSORIGIN_FOLLOW
            end

            ParticleManager:SetParticleControlEnt(particle, cp.control_point_index, target, at, cp.attachment, target:GetAbsOrigin(), true)

            print("CP", cp.control_point_index, at, cp.attachment)
        end

        native_unit_proxy.wearable_particles[slot] = native_unit_proxy.wearable_particles[slot] or {}
        table.insert(native_unit_proxy.wearable_particles[slot], particle)
    end
end

function find_default_items(native_unit_proxy)
    local hero_name = native_unit_proxy:GetName()
    local result = {}

    for id, item in pairs(game_items.items) do
        if item.prefab == "default_item" and item.used_by_heroes and item.used_by_heroes[hero_name] == 1 then
            result[item.item_slot or "weapon"] = item
            item.id = tonumber(id)
        end
    end

    return result
end

function get_mapped_particle(native_unit_proxy, original)
    return native_unit_proxy.mapped_particles[original] or original
end