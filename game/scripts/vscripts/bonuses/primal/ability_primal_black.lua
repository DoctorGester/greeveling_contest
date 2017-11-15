---@class ability_primal_black : CDOTA_Ability_Lua
ability_primal_black = {}

function ability_primal_black:ResetVariables()
    self.accumulated_time = 0
    self.has_actually_launched = 0
end

function ability_primal_black:OnChannelThink(interval)
    if interval == 0 then
        self:ResetVariables()
    end

    self.accumulated_time = self.accumulated_time + interval

    local total_projectiles = 7
    local should_have_launched = math.ceil(self.accumulated_time / (self:GetChannelTime() / total_projectiles))
    local middle_projectile_index = math.floor(total_projectiles / 2.0)
    local caster_location = self:GetCaster():GetAbsOrigin()
    local caster_to_target = self:GetCursorPosition() - caster_location

    if caster_to_target:Length2D() <= 0.01 then
        caster_to_target = self:GetCaster():GetForwardVector()
        caster_to_target.z = 0.0
    end

    local direction = caster_to_target:Normalized()
    local direction_rotated = Vector(-direction.y, direction.x)
    local corrected_cast_target = max_vector_2d(caster_to_target, direction * 200) + caster_location

    for index = 0, (should_have_launched - self.has_actually_launched) - 1 do
        local projectile_index = self.has_actually_launched + index
        local offset_projectile_index = projectile_index - middle_projectile_index
        local side_offset = direction_rotated * 100.0 * offset_projectile_index
        local projectile_target = corrected_cast_target + side_offset
        local scalar_arc_offset = math.sin(projectile_index / total_projectiles * math.pi) * 200.0 - 200.0
        local arc_offset = (projectile_target - caster_location):Normalized() * scalar_arc_offset

        if projectile_index == 0 then
            self:GetCaster():EmitSound("ability_primal_black_cast")
        end

        if projectile_index % 2 == 0 then
            self:GetCaster():EmitSound("ability_primal_black_cast_layer")
        end

        projectile_target = projectile_target + arc_offset

        self.last_launched = CreateModifierThinker(
            self:GetCaster(),
            self,
            "modifier_black_aura",
            {
                projectile_speed = 1200,
                projectile_index = projectile_index
            },
            projectile_target,
            self:GetCaster():GetTeam(),
            false
        )
    end

    self.has_actually_launched = should_have_launched
end

function ability_primal_black:OnChannelFinish()
    self:ResetVariables()
end

function ability_primal_black:GetChannelTime()
    return 0.5
end

function ability_primal_black:GetCastAnimation()
    if self:GetCaster():GetName() == "npc_dota_mega_greevil" then
        return ACT_DOTA_ATTACK
    end

    return ACT_DOTA_GREEVIL_CAST
end