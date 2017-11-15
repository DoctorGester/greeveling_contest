---@class modifier_animation_orange : CDOTA_Modifier_Lua
modifier_animation_orange = {}

function modifier_animation_orange:IsHidden()
    return true
end

function modifier_animation_orange:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS
    }
end

function modifier_animation_orange:GetActivityTranslationModifiers()
    return "greevil_miniboss_black_brain_sap"
end