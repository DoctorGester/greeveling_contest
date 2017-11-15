---@class modifier_black_aura : CDOTA_Modifier_Lua
modifier_black_aura = {}

if IsServer() then
    function modifier_black_aura:OnCreated(parameters)
        local projectile_start_position = self:GetCaster():GetAbsOrigin() + Vector(0, 0, 96)
        local projectile_end_position = self:GetParent():GetAbsOrigin()
        local distance = (projectile_end_position - projectile_start_position):Length2D()
        local travel_time = distance / parameters.projectile_speed

        self.projectile_particle = fx("particles/abilities/black/black_proj.vpcf", PATTACH_WORLDORIGIN, GameRules:GetGameModeEntity(), {
            cp0 = projectile_start_position,
            cp1 = projectile_end_position,
            cp2 = Vector(parameters.projectile_speed, 0.0, 0.0)
        })

        self:StartIntervalThink(travel_time)
        self.has_projectile_arrived = false
        self.is_first_or_middle = parameters.projectile_index == 0 or parameters.projectile_index == 2
    end

    function modifier_black_aura:IsAura()
        return self.has_projectile_arrived
    end

    function modifier_black_aura:OnIntervalThink()
        if not self.has_projectile_arrived then
            dfx(self.projectile_particle)

            self.has_projectile_arrived = true
            self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("pool_duration"))

            local pool_particle = fx("particles/abilities/black_aura/black_aura.vpcf", PATTACH_WORLDORIGIN, GameRules:GetGameModeEntity(), {
                cp0 = self:GetParent():GetAbsOrigin()
            })

            local is_last = self:GetAbility().last_launched == self:GetParent()

            if self.is_first_or_middle or is_last then
                self:GetParent():EmitSound("ability_primal_black_impact")
            end

            self:AddParticle(pool_particle, false, false, 0, false, false)
        else
            self:GetParent():RemoveSelf()
        end
    end
end

function modifier_black_aura:GetAuraDuration()
    return 0.1
end

function modifier_black_aura:GetAuraRadius()
    return 180
end

function modifier_black_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_black_aura:GetAuraSearchType()
    return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP)
end

function modifier_black_aura:GetModifierAura()
    return "modifier_black_aura_target"
end
