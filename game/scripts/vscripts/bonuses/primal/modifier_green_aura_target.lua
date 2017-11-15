---@class modifier_green_aura_target : CDOTA_Modifier_Lua
modifier_green_aura_target = {}

if IsServer() then
    function modifier_green_aura_target:OnDestroy(params)
        local aura_has_expired = not self:GetCaster():HasModifier("modifier_green_aura")
        local is_already_rooted = self:GetParent():HasModifier("modifier_green_aura_target_root")
        local root_duration = self:GetAbility():GetSpecialValueFor("root_duration")

        if not aura_has_expired and not is_already_rooted then
            self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_green_aura_target_root", { duration = root_duration })

            ApplyDamage({
                victim = self:GetParent(),
                attacker = self:GetCaster(),
                damage = self:GetAbility():GetAbilityDamage(),
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self:GetAbility()
            })
        end
    end
end

function modifier_green_aura_target:GetEffectName()
    return "particles/units/heroes/hero_enchantress/enchantress_enchant_slow.vpcf"
end

function modifier_green_aura_target:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end