---@class modifier_animation_blue : CDOTA_Modifier_Lua
modifier_animation_blue = {}

function modifier_animation_blue:IsHidden()
    return true
end

function modifier_animation_blue:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS
    }
end

function modifier_animation_blue:GetActivityTranslationModifiers()
    return "greevil_cold_snap"
end