---@class modifier_lesser_seal_health : CDOTA_Modifier_Lua
modifier_lesser_seal_health = {}

function modifier_lesser_seal_health:GetTexture()
    return "health"
end

if IsServer() then
    function modifier_lesser_seal_health:RefreshCustomHealth()
        local function log2(x)
            return math.log(x) / math.log(2)
        end

        local base_health = self:GetParent():GetMaxHealth()
        local new_health = base_health + base_health * log2(self:GetStackCount() + 0.5)

        self:GetParent():SetMaxHealth(new_health)
        self:GetParent():SetBaseMaxHealth(new_health)
        self:GetParent():SetHealth(new_health)
    end
end