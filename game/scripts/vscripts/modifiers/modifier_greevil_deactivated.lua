---@class modifier_greevil_deactivated : CDOTA_Modifier_Lua
modifier_greevil_deactivated = {}

if IsServer() then
    function modifier_greevil_deactivated:OnCreated()
        hide_greevil(self:GetParent().attached_entity)
    end

    function modifier_greevil_deactivated:OnDestroy()
        unhide_greevil(self:GetParent().attached_entity)
    end
end

function modifier_greevil_deactivated:CheckState()
    return {
        [MODIFIER_STATE_OUT_OF_GAME] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_STUNNED] = true
    }
end