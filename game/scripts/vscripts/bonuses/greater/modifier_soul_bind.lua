---@class modifier_soul_bind : CDOTA_Modifier_Lua
---@field public currently_bound_to CDOTA_BaseNPC_Hero
---@field public bind_particle number
modifier_soul_bind = {}

function modifier_soul_bind:IsHidden()
    return true
end

if IsServer() then
    function modifier_soul_bind:OnCreated()
        self:StartIntervalThink(0)
    end

    function modifier_soul_bind:OnIntervalThink()
        local aura_radius = self:GetAbility():GetCastRange(Vector(), nil)

        if self.currently_bound_to then
            local distance_to_guy = (self:GetParent():GetAbsOrigin() - self.currently_bound_to:GetAbsOrigin()):Length2D()

            if not self.currently_bound_to:IsAlive() or distance_to_guy > aura_radius then
                self.currently_bound_to = nil
                dfx(self.bind_particle)
                self.bind_particle = nil
            end
        end

        if not self.currently_bound_to then
            local units_found = FindUnitsInRadius(
                self:GetParent():GetTeam(),
                self:GetParent():GetAbsOrigin(),
                nil,
                aura_radius,
                DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                DOTA_UNIT_TARGET_HERO,
                DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST,
                false
            )

            for _, unit in ipairs(units_found) do
                local true_distance_to_guy = (self:GetParent():GetAbsOrigin() - unit:GetAbsOrigin()):Length2D()

                if unit ~= self:GetParent() and true_distance_to_guy <= aura_radius then
                    self.currently_bound_to = unit
                    break
                end
            end

            if self.currently_bound_to then
                self.bind_particle = fx("particles/units/heroes/hero_wisp/wisp_tether.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent(), {
                    cp0 = { ent = self:GetParent(), attachment = "attach_hitloc" },
                    cp1 = { ent = self.currently_bound_to, attachment = "attach_hitloc" },
                })

                self:GetParent():EmitSound("ability_greater_soul_bind")
            end

        end
    end

    function modifier_soul_bind:OnDestroy()
        if self.bind_particle then
            dfx(self.bind_particle)
        end
    end

    function modifier_soul_bind:GetAuraEntityReject(entity)
        if not self.currently_bound_to then
            return true
        end

        return entity ~= self:GetParent() and entity ~= self.currently_bound_to
    end
end

function modifier_soul_bind:IsAura()
    return true
end

function modifier_soul_bind:GetAuraDuration()
    return 0.1
end

function modifier_soul_bind:GetAuraRadius()
    return self:GetAbility():GetCastRange(Vector(), nil)
end

function modifier_soul_bind:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_soul_bind:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_soul_bind:GetModifierAura()
    return "modifier_soul_bind_target"
end
