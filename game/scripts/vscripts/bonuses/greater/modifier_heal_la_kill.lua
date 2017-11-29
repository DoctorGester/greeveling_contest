---@class modifier_heal_la_kill : CDOTA_Modifier_Lua
---@field heal_buffer number
---@field last_strike_at number
modifier_heal_la_kill = {}

function modifier_heal_la_kill:IsHidden()
    return true
end

function modifier_heal_la_kill:OnFilteredHealing(unit_healed, heal_amount)
    if unit_healed:GetTeam() ~= self:GetParent():GetTeam() then print("1"); return end
    if unit_healed == self:GetParent() then print("2"); return end

    local distance_to_unit = (self:GetParent():GetAbsOrigin() - unit_healed:GetAbsOrigin()):Length2D()
    if distance_to_unit > self:GetAbility():GetCastRange(Vector(), nil) then print("3"); return end

    local last_strike_at = self.last_strike_at or 0

    if GameRules:GetGameTime() - last_strike_at < 0.8 then return end

    self.heal_buffer = (self.heal_buffer or 0) + heal_amount

    if self.heal_buffer >= 100 then
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

        local possible_targets = {}

        for _, unit in pairs(units_found) do
            if self:GetParent():CanEntityBeSeenByMyTeam(unit) then
                table.insert(possible_targets, unit)
            end
        end

        if #possible_targets > 0 then
            local final_target = possible_targets[RandomInt(1, #possible_targets)]
            local particle_path = "particles/econ/items/sven/sven_warcry_ti5/sven_warcry_cast_lightning_strike.vpcf"
            fx(particle_path, PATTACH_ABSORIGIN, final_target, {})

            final_target:EmitSound("ability_heal_la_kill_trigger")

            ApplyDamage({
                victim = final_target,
                attacker = self:GetParent(),
                damage = self:GetAbility():GetAbilityDamage(),
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self:GetAbility()
            })

            self.heal_buffer = 0
            self.last_strike_at = GameRules:GetGameTime()
        end
    end
end