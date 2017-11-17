item_healing_candy = {}

function item_healing_candy:OnSpellStart()
    fx("particles/items3_fx/fish_bones_active.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster(), { release = true })

    if self.attached_entity and self.attached_entity.entity_type == Entity_Type.CANDY then
        self:GetCaster():EmitSound("ability_greater_greevil_pinata_eat_candy")
        self:GetCaster():Heal(self.attached_entity.heal_amount, self:GetCaster())

        self.attached_entity.was_eaten = true
        self.attached_entity.is_destroyed_next_update = true
    end

    self:SpendCharge()
end