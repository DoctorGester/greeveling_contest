---@class crystal_maiden_boss_frostbite : CDOTA_Ability_Lua
crystal_maiden_boss_frostbite = {}

function crystal_maiden_boss_frostbite:OnSpellStart()
    handle_crystal_maiden_frostbite_cast_on(self:GetCaster().attached_entity, self:GetCursorTarget())
end

function crystal_maiden_boss_frostbite:GetCastAnimation()
    return ACT_DOTA_CAST_ABILITY_2
end

function crystal_maiden_boss_frostbite:GetPlaybackRateOverride()
    return 0.8
end

function crystal_maiden_boss_frostbite:GetCastPoint()
    return 1.2
end

function crystal_maiden_boss_frostbite:IsHiddenAbilityCastable()
    return true
end