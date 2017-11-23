---@class modifier_egg_hatch_pause_target : CDOTA_Modifier_Lua
modifier_egg_hatch_pause_target = {}

function modifier_egg_hatch_pause_target:IsHidden()
    return true
end

function modifier_egg_hatch_pause_target:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_STUNNED] = true
    }
end