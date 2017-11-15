---@class modifier_crystal_maiden_boss_frostbite : CDOTA_Modifier_Lua
modifier_crystal_maiden_boss_frostbite = {}

function modifier_crystal_maiden_boss_frostbite:IsDebuff()
    return true
end

function modifier_crystal_maiden_boss_frostbite:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_FROZEN] = true,
    }

    return state
end

function modifier_crystal_maiden_boss_frostbite:GetEffectName()
    return "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf"
end

function modifier_crystal_maiden_boss_frostbite:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end