---@class modifier_blue_aura : CDOTA_Modifier_Lua
modifier_blue_aura = {}

if IsServer() then
    function modifier_blue_aura:OnCreated()
        local particle = fx(
            "particles/world_shrine/radiant_shrine_active.vpcf",
            PATTACH_ABSORIGIN_FOLLOW,
            self:GetParent(),
            {
                cp10 = Vector(300, 0, 0)
            }
        )

        self:AddParticle(particle, false, false, 0, false, false)
    end
end

function modifier_blue_aura:CheckState()
    if IsServer() and self:GetParent():GetName() == "npc_dota_mega_greevil" then
        return {}
    end

    return {
        [MODIFIER_STATE_FROZEN] = true,
        [MODIFIER_STATE_STUNNED] = true
    }
end

function modifier_blue_aura:IsAura()
    return true
end

function modifier_blue_aura:GetAuraDuration()
    return 0.1
end

function modifier_blue_aura:GetAuraRadius()
    return self:GetAbility():GetCastRange(Vector(), nil)
end

function modifier_blue_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_blue_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_blue_aura:GetAuraEntityReject(entity)
    return entity == self:GetParent()
end

function modifier_blue_aura:GetModifierAura()
    return "modifier_blue_aura_target"
end

function modifier_blue_aura:GetEffectName()
    return "particles/units/heroes/hero_winter_wyvern/wyvern_cold_embrace_buff.vpcf"
end

function modifier_blue_aura:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end