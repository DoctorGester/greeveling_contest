---@class modifier_healing_frenzy : CDOTA_Modifier_Lua
---@field heal_buffer number
modifier_healing_frenzy = {}

function modifier_healing_frenzy:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end

function modifier_healing_frenzy:IsHidden()
    return self:GetStackCount() == 0
end

function modifier_healing_frenzy:GetModifierAttackSpeedBonus_Constant()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("attack_speed")
end

function modifier_healing_frenzy:OnFilteredHealing(unit_healed, heal_amount)
    if unit_healed:GetTeam() ~= self:GetParent():GetTeam() then return end
    if unit_healed == self:GetParent() then return end

    local distance_to_unit = (self:GetParent():GetAbsOrigin() - unit_healed:GetAbsOrigin()):Length2D()
    if distance_to_unit > self:GetAbility():GetCastRange(Vector(), nil) then return end

    self.heal_buffer = (self.heal_buffer or 0) + heal_amount

    if self.heal_buffer >= 50 then
        self.heal_buffer = self.heal_buffer - 50

        if self:GetStackCount() == 0 then
            local particle_path = "particles/units/heroes/hero_lone_druid/lone_druid_battle_cry_buff.vpcf"
            self.particle = fx(particle_path, PATTACH_ABSORIGIN_FOLLOW, self:GetParent(), {
                cp3 = { ent = self:GetParent(), pattach = PATTACH_ABSORIGIN_FOLLOW },
            })
        end

        self:SetDuration(8.0, true)
        self:IncrementStackCount()
    end
end

if IsServer() then
    function modifier_healing_frenzy:OnCreated()
        self:StartIntervalThink(0)
    end

    function modifier_healing_frenzy:OnDestroy()
        if self.particle then
            dfx(self.particle)
        end
    end

    function modifier_healing_frenzy:OnIntervalThink()
        if self:GetRemainingTime() <= 0 and self:GetStackCount() ~= 0 then
            if self.particle then
                dfx(self.particle)
                self.particle = nil
            end

            self:SetStackCount(0)
        end
    end

    function modifier_healing_frenzy:DestroyOnExpire()
        return false
    end
end