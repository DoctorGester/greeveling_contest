---@class modifier_together_we_stand : CDOTA_Modifier_Lua
modifier_together_we_stand = {}

if IsServer() then
    function modifier_together_we_stand:OnCreated()
        self:StartIntervalThink(0)
    end

    function modifier_together_we_stand:OnIntervalThink()
        local units_found = FindUnitsInRadius(
            self:GetParent():GetTeam(),
            self:GetParent():GetAbsOrigin(),
            nil,
            self:GetAbility():GetCastRange(Vector(), nil),
            DOTA_UNIT_TARGET_TEAM_FRIENDLY,
            DOTA_UNIT_TARGET_HERO,
            DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST,
            false
        )

        local unit_count = 0

        for _, unit in pairs(units_found) do
            if unit ~= self:GetParent() then
                unit_count = unit_count + 1
            end
        end

        if self:GetStackCount() == 0 and unit_count > 0 then
            local particle_path = "particles/units/heroes/hero_pangolier/pangolier_tailthump_buff.vpcf"
            self.particle = fx(particle_path, PATTACH_ABSORIGIN_FOLLOW, self:GetParent(), {
                cp1 = { ent = self:GetParent(), pattach = PATTACH_ABSORIGIN_FOLLOW }
            }) -- TODO scale from stacks, needs particle editing/recreation
        end

        if unit_count == 0 and self.particle then
            dfx(self.particle)
            self.particle = nil
        end

        self:SetStackCount(unit_count)
    end
end

function modifier_together_we_stand:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
end

function modifier_together_we_stand:IsHidden()
    return self:GetStackCount() == 0
end

function modifier_together_we_stand:GetModifierPhysicalArmorBonus()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("armor_per_ally")
end