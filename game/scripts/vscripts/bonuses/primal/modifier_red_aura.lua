---@class modifier_red_aura : CDOTA_Modifier_Lua
modifier_red_aura = {}

if IsServer() then
    function modifier_red_aura:OnCreated(parameters)
        self:OnIntervalThink()
        self:StartIntervalThink(0.2)
        self:GetParent():EmitSound("ability_primal_red_loop")
    end

    function modifier_red_aura:OnDestroy()
        self:GetParent():StopSound("ability_primal_red_loop")
        self:GetParent():RemoveSelf()
    end

    function modifier_red_aura:OnIntervalThink()
        fx("particles/abilities/red/red.vpcf", PATTACH_WORLDORIGIN, nil, {
            cp0 = self:GetParent():GetAbsOrigin(),
            cp4 = Vector(400, 1, 1),
            cp5 = Vector(1)
        })
    end
end

function modifier_red_aura:IsAura()
    return true
end

function modifier_red_aura:GetAuraDuration()
    return 0.1
end

function modifier_red_aura:GetAuraRadius()
    return 400
end

function modifier_red_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_red_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP
end

function modifier_red_aura:GetModifierAura()
    return "modifier_red_aura_target"
end
