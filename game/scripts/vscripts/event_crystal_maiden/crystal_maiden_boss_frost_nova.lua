---@class crystal_maiden_boss_frost_nova : CDOTA_Ability_Lua
crystal_maiden_boss_frost_nova = {}

function crystal_maiden_boss_frost_nova:OnSpellStart()
    handle_crystal_maiden_frost_nova_cast_at(self:GetCaster().attached_entity, self:GetCursorPosition())
end

function crystal_maiden_boss_frost_nova:GetCastAnimation()
    return ACT_DOTA_CAST_ABILITY_1
end

function crystal_maiden_boss_frost_nova:GetPlaybackRateOverride()
    return 0.8
end

function crystal_maiden_boss_frost_nova:GetCastPoint()
    return 1.5
end

function crystal_maiden_boss_frost_nova:IsHiddenAbilityCastable()
    return true
end