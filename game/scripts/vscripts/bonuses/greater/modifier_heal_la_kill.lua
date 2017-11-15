---@class modifier_heal_la_kill : CDOTA_Modifier_Lua
---@field heal_buffer number
modifier_heal_la_kill = {}

function modifier_heal_la_kill:IsHidden()
    return true
end

function modifier_heal_la_kill:OnFilteredHealing(unit_healed, heal_amount)
    if unit_healed:GetTeam() ~= self:GetParent():GetTeam() then return end
    if unit_healed == self:GetParent() then return end

    local distance_to_unit = (self:GetParent():GetAbsOrigin() - unit_healed:GetAbsOrigin()):Length2D()
    if distance_to_unit > self:GetAbility():GetCastRange(Vector(), nil) then return end

    self.heal_buffer = (self.heal_buffer or 0) + heal_amount

    if self.heal_buffer >= 100 then
        self.heal_buffer = self.heal_buffer - 100

        local units_found = FindUnitsInRadius(
            self:GetParent():GetTeam(),
            self:GetParent():GetAbsOrigin(),
            nil,
            1200,
            DOTA_UNIT_TARGET_TEAM_ENEMY,
            DOTA_UNIT_TARGET_HERO,
            DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
            FIND_CLOSEST,
            false
        )

        for _, unit in pairs(units_found) do
            if unit:CanEntityBeSeenByMyTeam(self:GetParent()) then
                local particle_path = "particles/econ/items/sven/sven_warcry_ti5/sven_warcry_cast_lightning_strike.vpcf"
                fx(particle_path, PATTACH_ABSORIGIN, unit, {})

                unit:EmitSound("ability_heal_la_kill_trigger")

                ApplyDamage({
                    victim = unit,
                    attacker = self:GetParent(),
                    damage = self:GetAbility():GetAbilityDamage(),
                    damage_type = DAMAGE_TYPE_MAGICAL,
                    ability = self:GetAbility()
                })
                break
            end
        end
    end
end