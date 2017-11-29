---@class modifier_greevil_pinata : CDOTA_Modifier_Lua
---@field public damage_buffer number
---@field public last_drop_at number
modifier_greevil_pinata = {}

function modifier_greevil_pinata:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_greevil_pinata:IsHidden()
    return true
end

function modifier_greevil_pinata:OnTakeDamage(damage_data)
    if damage_data.unit == self:GetParent() then
        local last_drop_at = self.last_drop_at or 0

        if GameRules:GetGameTime() - last_drop_at < 1.0 then return end

        self.damage_buffer = (self.damage_buffer or 0) + damage_data.damage

        if self.damage_buffer > 200 then
            self.last_drop_at = GameRules:GetGameTime()
            self.damage_buffer = self.damage_buffer - 200

            local heal_amount = self:GetAbility():GetSpecialValueFor("heal_amount")
            local candy_item = CreateItem("item_healing_candy", nil, nil)
            local launch_target = self:GetParent():GetAbsOrigin() + RandomVector(300)
            local container = CreateItemOnPositionForLaunch(self:GetParent():GetAbsOrigin(), candy_item)
            candy_item:LaunchLootInitialHeight(true, 32, 200, 0.6, launch_target)
            self:GetParent():EmitSound("ability_greater_greevil_pinata")

            add_entity(make_candy(container, candy_item, heal_amount))
        end
    end
end