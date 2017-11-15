---@class ability_primal_yellow : CDOTA_Ability_Lua
ability_primal_yellow = {}

function ability_primal_yellow:OnSpellStart()
    local duration = self:GetSpecialValueFor("duration")
    self:GetCursorTarget():AddNewModifier(self:GetCaster(), self, "modifier_yellow", { duration = duration })
    self:GetCaster():EmitSound("ability_primal_yellow_voice")
    self:GetCursorTarget():EmitSound("ability_primal_yellow_cast")
end

function ability_primal_yellow:GetCastAnimation()
    if self:GetCaster():GetName() == "npc_dota_mega_greevil" then
        return ACT_DOTA_ATTACK
    end

    return ACT_DOTA_GREEVIL_CAST
end