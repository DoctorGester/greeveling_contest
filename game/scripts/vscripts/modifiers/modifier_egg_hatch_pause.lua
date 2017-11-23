---@class modifier_egg_hatch_pause : CDOTA_Modifier_Lua
modifier_egg_hatch_pause = {}

function modifier_egg_hatch_pause:IsAura()
    return true
end

function modifier_egg_hatch_pause:GetAuraDuration()
    return 0.1
end

function modifier_egg_hatch_pause:GetAuraRadius()
    return 65536
end

function modifier_egg_hatch_pause:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_egg_hatch_pause:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_egg_hatch_pause:GetAuraSearchFlags()
    return
        DOTA_UNIT_TARGET_FLAG_INVULNERABLE +
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES +
        DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES +
        DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD
end

function modifier_egg_hatch_pause:GetModifierAura()
    return "modifier_egg_hatch_pause_target"
end