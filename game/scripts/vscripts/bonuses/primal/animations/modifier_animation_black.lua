---@class modifier_animation_black : CDOTA_Modifier_Lua
modifier_animation_black = {}

function modifier_animation_black:IsHidden()
    return true
end

function modifier_animation_black:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS
    }
end

function modifier_animation_black:GetActivityTranslationModifiers()
    return "greevil_miniboss_red_overpower"
end