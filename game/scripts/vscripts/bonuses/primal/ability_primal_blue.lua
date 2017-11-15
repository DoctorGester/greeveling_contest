---@class ability_primal_blue : CDOTA_Ability_Lua
ability_primal_blue = {}

function ability_primal_blue:OnSpellStart()
    local caster = self:GetCaster()
    caster:AddNewModifier(self:GetCaster(), self, "modifier_blue_aura", { duration = 5.0 })
    caster:EmitSound("ability_primal_blue_cast")
    caster:EmitSound("ability_primal_blue_cast_secondary")
end

function ability_primal_blue:GetCastAnimation()
    if self:GetCaster():GetName() == "npc_dota_mega_greevil" then
        return ACT_DOTA_SPAWN
    end

    return ACT_DOTA_GREEVIL_CAST
end