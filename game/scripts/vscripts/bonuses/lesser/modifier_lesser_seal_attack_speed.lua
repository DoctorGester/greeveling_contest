---@class modifier_lesser_seal_attack_speed : CDOTA_Modifier_Lua
modifier_lesser_seal_attack_speed = {}

function modifier_lesser_seal_attack_speed:GetTexture()
    return "attack_speed"
end

function modifier_lesser_seal_attack_speed:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end

function modifier_lesser_seal_attack_speed:GetModifierAttackSpeedBonus_Constant()
    local function log2(x)
        return math.log(x) / math.log(2)
    end

    return 100 * log2(self:GetStackCount() + 1)
end