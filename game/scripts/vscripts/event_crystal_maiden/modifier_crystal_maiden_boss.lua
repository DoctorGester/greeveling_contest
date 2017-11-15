---@class modifier_crystal_maiden_boss : CDOTA_Modifier_Lua
modifier_crystal_maiden_boss = {}

function modifier_crystal_maiden_boss:IsHidden()
    return true
end

function modifier_crystal_maiden_boss:IsPurgable()
    return false
end

function modifier_crystal_maiden_boss:GetPriority()
    return MODIFIER_PRIORITY_ULTRA
end

function modifier_crystal_maiden_boss:CheckState()
    local state = {
        [MODIFIER_STATE_HEXED] = false,
        [MODIFIER_STATE_ROOTED] = false,
        [MODIFIER_STATE_SILENCED] = false,
        [MODIFIER_STATE_STUNNED] = false,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
    }

    if IsServer() then
        state[MODIFIER_STATE_INVISIBLE] = false
        --state[MODIFIER_STATE_UNSELECTABLE] = true--self:GetCaster().bInTorrents
    end

    return state
end

function modifier_crystal_maiden_boss:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }

    return funcs
end

function modifier_crystal_maiden_boss:GetModifierMoveSpeed_Absolute(params)
    return 200--self:GetAbility():GetSpecialValueFor("normal_speed")
end

if IsServer() then
    function modifier_crystal_maiden_boss:OnTakeDamage(params)
        local attacker = params.attacker
        local victim = params.unit

        if attacker ~= nil and victim == self:GetParent() then
            crystal_maiden_register_damage_taken(victim.attached_entity, attacker, params.damage)
        end

        return 0
    end
end