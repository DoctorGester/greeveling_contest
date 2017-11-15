---@class ability_primal_red : CDOTA_Ability_Lua
ability_primal_red = {}

function ability_primal_red:OnSpellStart()
    CreateModifierThinker(
        self:GetCaster(),
        self,
        "modifier_red_aura",
        {
            duration = self:GetSpecialValueFor("duration")
        },
        self:GetCursorPosition(),
        self:GetCaster():GetTeam(),
        false
    )

    self:GetCaster():EmitSound("ability_primal_red_cast")
end

function ability_primal_red:GetAOERadius()
    return 400
end

function ability_primal_red:GetPlaybackRateOverride()
    return 1.5
end

function ability_primal_red:GetCastAnimation()
    if self:GetCaster():GetName() == "npc_dota_mega_greevil" then
        return ACT_DOTA_ATTACK
    end

    return ACT_DOTA_GREEVIL_CAST
end