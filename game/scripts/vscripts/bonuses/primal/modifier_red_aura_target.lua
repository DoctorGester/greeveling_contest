---@class modifier_red_aura_target : CDOTA_Modifier_Lua
modifier_red_aura_target = {}

if IsServer() then
    function modifier_red_aura_target:OnCreated()
        local particle_path = "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff_e.vpcf"
        local particle = fx(particle_path, PATTACH_POINT_FOLLOW, self:GetParent(), {
            cp0 = { attach = "attach_attack1" }
        })

        self:AddParticle(particle, false, false, 0, false, false)
    end
end

function modifier_red_aura_target:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end

function modifier_red_aura_target:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("attack_speed")
end
