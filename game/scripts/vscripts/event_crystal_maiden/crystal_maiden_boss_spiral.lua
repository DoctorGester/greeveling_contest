---@class crystal_maiden_boss_spiral : CDOTA_Ability_Lua
crystal_maiden_boss_spiral = {}

if IsServer() then
    function crystal_maiden_boss_spiral:OnProjectileHit(target, at_location)
        if target and not target:IsMagicImmune() and not target:IsInvulnerable() then
            crystal_maiden_process_spiral_projectile_hit(self:GetCaster().attached_entity, target)
        end

        return true
    end
end

function crystal_maiden_boss_spiral:IsHiddenAbilityCastable() return true end