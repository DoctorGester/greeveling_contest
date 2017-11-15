---@class modifier_greevil_animation : CDOTA_Modifier_Lua
modifier_greevil_animation = {}

function modifier_greevil_animation:IsHidden()
    return true
end

function modifier_greevil_animation:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS
    }
end

function modifier_greevil_animation:GetActivityTranslationModifiers()
    local stacks = self:GetStackCount()

    if stacks == 0 then return "black"
    elseif stacks == 1 then return "white"
    elseif stacks == 2 then return "miniboss"
    elseif stacks == 3 then return "level_1"
    elseif stacks == 4 then return "level_2"
    elseif stacks == 5 then return "level_3"
    elseif stacks == 6 then return ""
    end
end