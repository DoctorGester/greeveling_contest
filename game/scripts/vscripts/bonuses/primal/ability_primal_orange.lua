---@class ability_primal_orange : CDOTA_Ability_Lua
ability_primal_orange = {}

function ability_primal_orange:OnSpellStart()
    CreateModifierThinker(
        self:GetCaster(),
        self,
        "modifier_orange_aura",
        {
            projectile_speed = 1400
        },
        self:GetCursorPosition(),
        self:GetCaster():GetTeam(),
        false
    )

    self:GetCaster():EmitSound("ability_primal_orange_cast")
end

function ability_primal_orange:GetAOERadius()
    return 200
end

function ability_primal_orange:GetPlaybackRateOverride()
    return 1.5
end

function ability_primal_orange:GetCastAnimation()
    if self:GetCaster():GetName() == "npc_dota_mega_greevil" then
        return ACT_DOTA_ATTACK
    end

    return ACT_DOTA_GREEVIL_CAST
end