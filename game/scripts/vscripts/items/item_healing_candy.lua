item_healing_candy = {}

function item_healing_candy:OnSpellStart()
    fx("particles/items3_fx/fish_bones_active.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster(), { release = true })

    self:GetCaster():EmitSound("ability_greater_greevil_pinata_eat_candy")
    self:GetCaster():Heal(self.heal_amount, self:GetCaster())
    self:SpendCharge()
end