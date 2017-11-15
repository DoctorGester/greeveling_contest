---@class modifier_green_aura : CDOTA_Modifier_Lua
modifier_green_aura = {}

if IsServer() then
    function modifier_green_aura:OnRefresh()
        local particle = fx(
            "particles/abilities/green/green.vpcf",
            PATTACH_ABSORIGIN_FOLLOW,
            self:GetParent(),
            {
                cp1 = Vector(self:GetAbility():GetCastRange(Vector(), nil), 0, 0),
                cp2 = Vector(self:GetDuration(), 0.0, 0.0)
            }
        )

        self:AddParticle(particle, false, false, 0, false, false)
    end

    function modifier_green_aura:GetAuraEntityReject(entity)
        return entity:HasModifier("modifier_green_aura_target_root")
    end

    modifier_green_aura.OnCreated = modifier_green_aura.OnRefresh
end

function modifier_green_aura:IsAura()
    return true
end

function modifier_green_aura:GetAuraDuration()
    return 0.1
end

function modifier_green_aura:GetAuraRadius()
    return self:GetAbility():GetCastRange(Vector(), nil)
end

function modifier_green_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_green_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_green_aura:GetModifierAura()
    return "modifier_green_aura_target"
end
