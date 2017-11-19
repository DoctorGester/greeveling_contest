---@class modifier_mega_greevil : CDOTA_Modifier_Lua
modifier_mega_greevil = {}

function modifier_mega_greevil:IsHidden()
    return true
end

function modifier_mega_greevil:IsPurgable()
    return false
end

function modifier_mega_greevil:GetPriority()
    return MODIFIER_PRIORITY_ULTRA
end

function modifier_mega_greevil:CheckState()
    local state = {
        [MODIFIER_STATE_HEXED] = false,
        [MODIFIER_STATE_ROOTED] = false,
        [MODIFIER_STATE_SILENCED] = false,
        [MODIFIER_STATE_STUNNED] = false
    }

    if IsServer() then
        local map_center = Vector()
        local distance_to_center = (map_center - self:GetParent():GetAbsOrigin()):Length2D()

        state[MODIFIER_STATE_INVISIBLE] = false
        state[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = distance_to_center > 900
        state[MODIFIER_STATE_NO_UNIT_COLLISION] = distance_to_center > 900
    end

    return state
end

function modifier_mega_greevil:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_mega_greevil:GetModifierMoveSpeed_Absolute(params)
    return 160
end

if IsServer() then
    function modifier_mega_greevil:OnAttackLanded(params)
        local attacker = params.attacker
        local target = params.target

        if attacker == self:GetParent() and target ~= nil then
            mega_greevil_handle_attack_landed(attacker.attached_entity, target)
        end
    end
end