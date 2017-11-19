---@class modifier_greevil_spawning : CDOTA_Modifier_Lua
modifier_greevil_spawning = {}

function modifier_greevil_spawning:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true
    }
end