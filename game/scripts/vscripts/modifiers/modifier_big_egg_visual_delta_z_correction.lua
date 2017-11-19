---@class modifier_big_egg_visual_delta_z_correction : CDOTA_Modifier_Lua
modifier_big_egg_visual_delta_z_correction = {}

function modifier_big_egg_visual_delta_z_correction:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_VISUAL_Z_DELTA
    }
end

function modifier_big_egg_visual_delta_z_correction:GetVisualZDelta()
    return -64
end