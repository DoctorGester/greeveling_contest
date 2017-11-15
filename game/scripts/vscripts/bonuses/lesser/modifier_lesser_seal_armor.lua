---@class modifier_lesser_seal_armor : CDOTA_Modifier_Lua
modifier_lesser_seal_armor = {}

function modifier_lesser_seal_armor:GetTexture()
    return "armor"
end

function modifier_lesser_seal_armor:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
end

function modifier_lesser_seal_armor:GetModifierPhysicalArmorBonus()
    return 12 * self:GetStackCount()
end