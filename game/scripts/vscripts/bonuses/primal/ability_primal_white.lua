---@class ability_primal_white : CDOTA_Ability_Lua
ability_primal_white = {}

function ability_primal_white:OnSpellStart()
    local cast_location = self:GetCaster():GetAbsOrigin()
    local particle_path = "particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_blinding_light_aoe.vpcf"

    self:GetCaster():EmitSound("ability_primal_white_cast")

    fx(particle_path, PATTACH_WORLDORIGIN, nil, {
        cp0 = cast_location,
        cp1 = cast_location,
        cp2 = Vector(self:GetCastRange(Vector(), nil), 0, 0)
    })

    local units_found = FindUnitsInRadius(
        self:GetCaster():GetTeam(),
        cast_location,
        nil,
        self:GetCastRange(Vector(), nil),
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _, unit in pairs(units_found) do
        unit:Purge(false, true, false, true, false)
    end
end

function ability_primal_white:GetCastAnimation()
    if self:GetCaster():GetName() == "npc_dota_mega_greevil" then
        return ACT_DOTA_SPAWN
    end

    return ACT_DOTA_GREEVIL_CAST
end