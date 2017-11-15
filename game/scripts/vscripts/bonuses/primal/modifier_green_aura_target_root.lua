---@class modifier_green_aura_target_root : CDOTA_Modifier_Lua
modifier_green_aura_target_root = {}

function modifier_green_aura_target_root:CheckState()
    return {
        [MODIFIER_STATE_ROOTED] = true
    }
end

function modifier_green_aura_target_root:GetEffectName()
    return "particles/units/heroes/hero_lone_druid/lone_druid_bear_entangle.vpcf"
end

function modifier_green_aura_target_root:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end