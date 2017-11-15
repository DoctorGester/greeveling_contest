---@class modifier_greevil_respawn : CDOTA_Modifier_Lua
modifier_greevil_respawn = {}

if IsServer() then
    function modifier_greevil_respawn:OnDestroy()
        respawn_greevil(self.attached_entity)
    end
end

function modifier_greevil_respawn:GetTexture()
    return "greevil_dead"
end

function modifier_greevil_respawn:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_greevil_respawn:RemoveOnDeath()
    return false
end