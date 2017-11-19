---@class modifier_greevil : CDOTA_Modifier_Lua
modifier_greevil = {}

function modifier_greevil:IsHidden()
    return true
end

function modifier_greevil:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_greevil:RemoveOnDeath()
    return false
end

if IsServer() then
    function modifier_greevil:GetModifierMoveSpeed_Absolute()
        if not self:GetParent():GetOwner():IsAlive() then
            return 0
        end

        return self:GetParent():GetOwner():GetIdealSpeed()
    end

    function modifier_greevil:OnAttackLanded(params)
        local attacker = params.attacker
        local target = params.target

        if attacker == self:GetParent() and target ~= nil then
            target:EmitSound("greevil_attack_landed")
        end
    end
end

function modifier_greevil:GetActivityTranslationModifiers()
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