---@type table<DOTATeam_t, table>
big_egg_state_by_team_id = {}

---@class Big_Egg : Entity
---@field public native_unit_proxy CDOTA_BaseNPC
---@field public storage Stored_Greevil
---@field public started_hatching_at number
---@field public is_hatching boolean
---@field public has_hatched boolean
---@field public hatch_model CBaseAnimating
---@field public hide_countdown boolean

MAX_BIG_EGG_PRIMAL_SEALS = 2
MAX_BIG_EGG_GREATER_SEALS = 4
MAX_BIG_EGG_LESSER_SEALS = 8

---@param native_unit_proxy CDOTA_BaseNPC_Building
---@return Big_Egg
function make_big_egg(native_unit_proxy)
    local big_egg = make_entity(Entity_Type.BIG_EGG, {
        native_unit_proxy = native_unit_proxy,
        storage = make_stored_greevil(MAX_BIG_EGG_PRIMAL_SEALS, MAX_BIG_EGG_GREATER_SEALS, MAX_BIG_EGG_LESSER_SEALS),
        is_hatching = false,
        hide_countdown = 0
    })

    native_unit_proxy.attached_entity = big_egg

    update_big_egg_network_state(big_egg)

    return big_egg
end

---@param big_egg Big_Egg
---@param seal Bonus
function big_egg_apply_seal(big_egg, seal)
    local result = stored_greevil_apply_seal(big_egg.storage, seal)

    if result ~= success then
        return result
    end

    update_big_egg_network_state(big_egg)

    return success
end

---@param big_egg Big_Egg
function start_hatching_big_egg(big_egg)
    big_egg.is_hatching = true
    big_egg.started_hatching_at = GameRules:GetGameTime()
    big_egg.hide_countdown = 3
    big_egg.native_unit_proxy:EmitSound("hatch_rumble")
    big_egg.native_unit_proxy:EmitSound("hatch_cracking")
    big_egg.hatch_model = SpawnEntityFromTableSynchronous("prop_dynamic", {
        model = "models/creeps/ice_boss/ice_boss_egg_dest.vmdl",
        origin = big_egg.native_unit_proxy:GetAbsOrigin(),
        angles = big_egg.native_unit_proxy:GetAnglesAsVector(),
        scales = Vector(8, 8, 8)
    })
end

-- Can't just kill the egg since it's also our ancient!
---@param big_egg Big_Egg
function hide_big_egg(big_egg)
    big_egg.native_unit_proxy:AddNoDraw()
    big_egg.native_unit_proxy:AddNewModifier(big_egg, nil, "modifier_big_egg_hidden", {})
end

---@param big_egg Big_Egg
function finish_hatching_big_egg(big_egg)
    big_egg.is_hatching = false
    big_egg.has_hatched = true

    local random_animation = ({
        "ice_boss_egg_dest_break_a",
        "ice_boss_egg_dest_break_b",
        "ice_boss_egg_dest_break_c"
    })[RandomInt(1, 3)]

    big_egg.native_unit_proxy:EmitSound("hatch_boom")
    ScreenShake(big_egg.native_unit_proxy:GetAbsOrigin(), 5, 150, 0.45, 3000, 0, true)

    fx("particles/econ/items/antimage/antimage_ti7/antimage_blink_start_ti7_smoke.vpcf", PATTACH_WORLDORIGIN, nil, {
        cp0 = big_egg.native_unit_proxy:GetAbsOrigin(),
        release = true
    })

    DoEntFireByInstanceHandle(big_egg.hatch_model, "SetAnimation", random_animation, 0.0, nil, nil)

    return make_mega_greevil(big_egg)
end

local BIG_EGG_HATCH_TIME = 5.0

---@param big_egg Big_Egg
function update_big_egg(big_egg)
    local current_time = GameRules:GetGameTime()

    if big_egg.hide_countdown > 0 then
        big_egg.hide_countdown = big_egg.hide_countdown - 1

        if big_egg.hide_countdown == 0 then
            hide_big_egg(big_egg)
        end
    end

    if big_egg.is_hatching then
        local progress = ((current_time - big_egg.started_hatching_at) % BIG_EGG_HATCH_TIME) / BIG_EGG_HATCH_TIME
        local curve_point = progress * progress * progress * 200
        local current_angle = math.sin(curve_point) * (8 * (1.2 - progress))

        local remaining = curve_point % math.pi
        if (remaining > math.pi / 2 and remaining < math.pi) then

            if progress < 0.4 then
                ScreenShake(big_egg.native_unit_proxy:GetAbsOrigin(), 5, 150, 0.15, 3000, 0, true)
            end

            big_egg.native_unit_proxy:EmitSound("hatch_kicking")
        end

        if RandomInt(1, 10) == 5 then
            big_egg.native_unit_proxy:EmitSound("hatch_cracking")
        end

        big_egg.hatch_model:SetLocalAngles(current_angle, 0, 0)

        if current_time - big_egg.started_hatching_at >= BIG_EGG_HATCH_TIME then
            add_entity(finish_hatching_big_egg(big_egg))
        end
    end
end

---@param big_egg Big_Egg
function update_big_egg_network_state(big_egg)
    local team_id = big_egg.native_unit_proxy:GetTeamNumber()
    local egg_state = {}

    egg_state.primal_seals = big_egg.storage.primal_seals
    egg_state.greater_seals = big_egg.storage.greater_seals
    egg_state.lesser_seals = big_egg.storage.lesser_seals
    egg_state.past_the_hatching_state = big_egg.is_hatching or big_egg.has_hatched

    big_egg_state_by_team_id[team_id] = egg_state

    CustomNetTables:SetTableValue("eggs", "state", big_egg_state_by_team_id)
end
