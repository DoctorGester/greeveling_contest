---@class modifier_lesser_seal_cooldown_reduction : CDOTA_Modifier_Lua
modifier_lesser_seal_cooldown_reduction = {}

function modifier_lesser_seal_cooldown_reduction:GetTexture()
    return "cooldown_reduction"
end

function modifier_lesser_seal_cooldown_reduction:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE_STACKING
    }
end

function modifier_lesser_seal_cooldown_reduction:GetModifierPercentageCooldownStacking()
    local function log2(x)
        return math.log(x) / math.log(2)
    end

    return 30 * log2(self:GetStackCount() + 1)
end