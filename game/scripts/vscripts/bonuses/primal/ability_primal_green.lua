---@class ability_primal_green : CDOTA_Ability_Lua
ability_primal_green = {}

function ability_primal_green:OnSpellStart()
    local ring_duration = self:GetSpecialValueFor("ring_duration")
    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_green_aura", { duration = ring_duration })
end

function ability_primal_green:GetCastAnimation()
    if self:GetCaster():GetName() == "npc_dota_mega_greevil" then
        return ACT_DOTA_SPAWN
    end

    return ACT_DOTA_GREEVIL_CAST
end