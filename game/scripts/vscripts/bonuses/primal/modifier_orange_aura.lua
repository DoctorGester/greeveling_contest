---@class modifier_orange_aura : CDOTA_Modifier_Lua
modifier_orange_aura = {}

if IsServer() then
    function modifier_orange_aura:OnCreated(parameters)
        local attachment = self:GetCaster():ScriptLookupAttachment("attach_attack1")
        local projectile_start_position = self:GetCaster():GetAttachmentOrigin(attachment) + Vector(0, 0, 16)
        local projectile_end_position = self:GetParent():GetAbsOrigin()
        local distance = (projectile_end_position - projectile_start_position):Length2D()
        local travel_time = distance / parameters.projectile_speed

        self.projectile_particle = fx("particles/abilities/orange/orange.vpcf", PATTACH_WORLDORIGIN, GameRules:GetGameModeEntity(), {
            cp0 = projectile_start_position,
            cp1 = projectile_end_position,
            cp2 = Vector(parameters.projectile_speed, 0.0, 0.0)
        })

        self:StartIntervalThink(travel_time)
        self.has_projectile_arrived = false
    end

    function modifier_orange_aura:OnIntervalThink()
        local pool_owner = self:GetParent()

        if not self.has_projectile_arrived then
            dfx(self.projectile_particle)

            pool_owner:EmitSound("ability_primal_orange_impact")
            pool_owner:EmitSound("ability_primal_orange_loop")
            self.has_projectile_arrived = true
            self.arrival_time = GameRules:GetGameTime()
            self:StartIntervalThink(0.25)

            local pool_particle = fx("particles/abilities/orange/orange_lava_pool.vpcf", PATTACH_WORLDORIGIN, GameRules:GetGameModeEntity(), {
                cp0 = pool_owner:GetAbsOrigin(),
                cp2 = Vector(8.0, 0.0, 0.0)
            })

            self:AddParticle(pool_particle, false, false, 0, false, false)
        else
            if GameRules:GetGameTime() - self.arrival_time >= self:GetAbility():GetSpecialValueFor("pool_duration") then
                pool_owner:StopSound("ability_primal_orange_loop")
                pool_owner:RemoveSelf()
            else
                local units_found = FindUnitsInRadius(
                    self:GetCaster():GetTeam(),
                    pool_owner:GetAbsOrigin(),
                    nil,
                    self:GetAbility():GetAOERadius(),
                    DOTA_UNIT_TARGET_TEAM_ENEMY,
                    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP),
                    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                    FIND_ANY_ORDER,
                    false
                )

                for _, unit_found in pairs(units_found) do
                    ApplyDamage({
                        victim = unit_found,
                        attacker = self:GetCaster(),
                        damage = self:GetAbility():GetSpecialValueFor("damage_per_second") / 4.0,
                        damage_type = DAMAGE_TYPE_MAGICAL,
                        ability = self:GetAbility()
                    })
                end
            end
        end
    end
end