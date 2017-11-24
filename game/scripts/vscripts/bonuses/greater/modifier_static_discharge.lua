---@class modifier_static_discharge : CDOTA_Modifier_Lua
modifier_static_discharge = {}

function modifier_static_discharge:IsHidden()
    return true
end

function modifier_static_discharge:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_static_discharge:OnTakeDamage(damage_data)
    if damage_data.unit:IsBuilding() or damage_data.unit:IsTower() then
        return false
    end

    if damage_data.attacker == self:GetParent() and not damage_data.unit:HasModifier("modifier_static_discharge_cooldown") then
        damage_data.unit:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_static_discharge_target", { duration = 4.0 })
    end
end