---@class modifier_black_aura_target : CDOTA_Modifier_Lua
modifier_black_aura_target = {}

function modifier_black_aura_target:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_black_aura_target:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end