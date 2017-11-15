---@class modifier_blue_aura_target : CDOTA_Modifier_Lua
modifier_blue_aura_target = {}

if IsServer() then
    function modifier_blue_aura_target:OnCreated(params)
        self:StartIntervalThink(0.25)
    end

    function modifier_blue_aura_target:OnIntervalThink()
        local amount = self:GetAbility():GetSpecialValueFor("mana_per_second") / 4
        self:GetParent():GiveMana(amount)
        SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, self:GetParent(), amount, self:GetParent():GetPlayerOwner())
    end
end

function modifier_blue_aura_target:GetEffectName()
    return "particles/world_shrine/radiant_shrine_regen.vpcf"
end

function modifier_blue_aura_target:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end