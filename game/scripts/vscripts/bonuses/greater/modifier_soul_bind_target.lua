---@class modifier_soul_bind_target : CDOTA_Modifier_Lua
modifier_soul_bind_target = {}

function modifier_soul_bind_target:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
    }
end

function modifier_soul_bind_target:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_soul_bind_target:OnAttackLanded(attack_data)
    if attack_data.attacker == self:GetParent() and attack_data.target then
        local lifesteal_percentage = self:GetAbility():GetSpecialValueFor("lifesteal_percentage") / 100.0
        local heal_amount = attack_data.damage * lifesteal_percentage

        self:GetParent():Heal(heal_amount, self:GetParent())
        SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self:GetParent(), heal_amount, self:GetParent():GetPlayerOwner())
        fx("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent(), { release = true })
    end
end
