---@class modifier_lesser_seal_damage : CDOTA_Modifier_Lua
modifier_lesser_seal_damage = {}

function modifier_lesser_seal_damage:GetTexture()
    return "attack_damage"
end

function modifier_lesser_seal_damage:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE
    }
end

function modifier_lesser_seal_damage:GetModifierDamageOutgoing_Percentage()
    local function log2(x)
        return math.log(x) / math.log(2)
    end

    return 100 * log2(self:GetStackCount() + 1)
end