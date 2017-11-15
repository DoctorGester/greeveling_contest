---@class modifier_static_discharge_target : CDOTA_Modifier_Lua
modifier_static_discharge_target = {}

function modifier_static_discharge_target:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

if IsServer() then
    function modifier_static_discharge_target:OnCreated()
        self:GetParent():EmitSound("ability_static_discharge_mark")
    end
end

function modifier_static_discharge_target:OnTakeDamage(damage_data)
    local is_attacker_correct = damage_data.attacker and damage_data.attacker ~= self:GetCaster()
    local source_is_not_this_exact_ability = damage_data.inflictor ~= self:GetAbility()

    if damage_data.unit == self:GetParent() and is_attacker_correct and source_is_not_this_exact_ability then
        ApplyDamage({
            victim = self:GetParent(),
            attacker = damage_data.attacker,
            damage = self:GetAbility():GetAbilityDamage(),
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility()
        })

        self:GetParent():EmitSound("ability_static_discharge_trigger")

        local particle_path = "particles/units/heroes/hero_disruptor/disruptor_thunder_strike_bolt.vpcf"
        local parent_position = self:GetParent():GetAbsOrigin()

        fx(particle_path, PATTACH_CUSTOMORIGIN, self:GetParent(), {
            cp0 = parent_position,
            cp1 = parent_position + Vector(0, 0, 200),
            cp2 = parent_position,
            release = true
        })

        damage_data.unit:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_static_discharge_cooldown", { duration = 4.0 })

        self:Destroy()
    end
end

function modifier_static_discharge_target:GetEffectName()
    return "particles/units/heroes/hero_disruptor/disruptor_thunder_strike_buff.vpcf"
end

function modifier_static_discharge_target:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end