---@class modifier_big_egg_hidden : CDOTA_Modifier_Lua
modifier_big_egg_hidden = {}

function modifier_big_egg_hidden:CheckState()
    return {
        [MODIFIER_STATE_OUT_OF_GAME] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
    }
end