---@class modifier_yellow : CDOTA_Modifier_Lua
modifier_yellow = {}

if IsServer() then
    function modifier_yellow:OnCreated(params)
        self:GetParent():EmitSound("ability_primal_yellow_loop")
    end

    function modifier_yellow:OnDestroy()
        self:GetParent():StopSound("ability_primal_yellow_loop")
    end
end

function modifier_yellow:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_REINCARNATION
    }
end

function modifier_yellow:ReincarnateTime()
    return 3.0
end

function modifier_yellow:GetEffectName()
    return "particles/abilities/yellow/yellow.vpcf"
end

function modifier_yellow:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end