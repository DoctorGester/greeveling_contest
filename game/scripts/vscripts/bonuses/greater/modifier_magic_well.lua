---@class modifier_magic_well : CDOTA_Modifier_Lua
modifier_magic_well = {}

function modifier_magic_well:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
    }
end

function modifier_magic_well:OnAbilityFullyCast(cast_data)
    if cast_data.unit:GetTeam() ~= self:GetParent():GetTeam() then return end
    if cast_data.unit == self:GetParent() then return end
    if not cast_data.ability:ProcsMagicStick() then return end

    local distance_to_unit = (self:GetParent():GetAbsOrigin() - cast_data.unit:GetAbsOrigin()):Length2D()
    if distance_to_unit > self:GetAbility():GetCastRange(Vector(), nil) then return end

    if self:GetStackCount() == 0 then
        local particle_path = "particles/units/heroes/hero_invoker/invoker_alacrity.vpcf"
        self.particle = fx(particle_path, PATTACH_OVERHEAD_FOLLOW, self:GetParent(), {})
    end

    self:SetDuration(8.0, true)

    if self:GetStackCount() < self:GetAbility():GetSpecialValueFor("maximum_stacks") then
        self:IncrementStackCount()
    end
end

function modifier_magic_well:IsHidden()
    return self:GetStackCount() == 0
end

function modifier_magic_well:GetModifierPreAttack_BonusDamage()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("attack_damage")
end

if IsServer() then
    function modifier_magic_well:OnCreated()
        self:StartIntervalThink(0)
    end

    function modifier_magic_well:OnDestroy()
        if self.particle then
            dfx(self.particle)
        end
    end

    function modifier_magic_well:OnIntervalThink()
        if self:GetRemainingTime() <= 0 and self:GetStackCount() ~= 0 then
            if self.particle then
                dfx(self.particle)
                self.particle = nil
            end

            self:SetStackCount(0)
        end
    end

    function modifier_magic_well:DestroyOnExpire()
        return false
    end
end