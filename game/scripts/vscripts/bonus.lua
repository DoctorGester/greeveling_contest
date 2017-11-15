---@class Bonus : Entity
---@field public seal_type Seal_Type
---@field public seal number
---@field public native_container_proxy CDOTA_Item_Physical
---@field public native_item_proxy CDOTA_Item

---@return Bonus
---@param at_position vector
---@param seal_type Seal_Type
---@param seal number
function make_bonus(at_position, seal_type, seal)
    local native_item_proxy = CreateItem(convert_seal_type_to_item_name(seal_type, seal), nil, nil)
    local native_container_proxy = CreateItemOnPositionSync(at_position, native_item_proxy)

    return make_bonus_from_existing_item_and_container(native_item_proxy, native_container_proxy, seal_type, seal)
end

---@return Bonus
function make_bonus_from_existing_item_and_container(native_item_proxy, native_container_proxy, seal_type, seal)
    local bonus = make_entity(Entity_Type.BONUS, {
        seal_type = seal_type,
        seal = seal,
        native_item_proxy = native_item_proxy,
        native_container_proxy = native_container_proxy
    })

    update_bonus_model_skin(bonus)

    native_item_proxy.attached_entity = bonus

    return bonus
end

---@param bonus Bonus
function update_bonus_model_skin(bonus)
    local seal_type_to_skin_name = {}

    if bonus.seal_type == Seal_Type.PRIMAL then
        seal_type_to_skin_name = {
            [Primal_Seal_Type.BLACK] = "black",
            [Primal_Seal_Type.BLUE] = "blue",
            [Primal_Seal_Type.ORANGE] = "orange",
            [Primal_Seal_Type.GREEN] = "green",
            [Primal_Seal_Type.YELLOW] = "yellow",
            [Primal_Seal_Type.RED] = "red",
            [Primal_Seal_Type.WHITE] = "white",
            [Primal_Seal_Type.PURPLE] = "black" -- TODO
        }
    elseif bonus.seal_type == Seal_Type.GREATER then
        seal_type_to_skin_name = {
            [Greater_Seal_Type.SOUL_BIND] = "soul_bind",
            [Greater_Seal_Type.GREEVIL_PINATA] = "greevil_pinata",
            [Greater_Seal_Type.HEALING_FRENZY] = "healing_frenzy",
            [Greater_Seal_Type.TOGETHER_WE_STAND] = "together_we_stand",
            [Greater_Seal_Type.STATIC_DISCHARGE] = "static_discharge",
            [Greater_Seal_Type.HEAL_LA_KILL] = "heal_la_kill",
            [Greater_Seal_Type.MAGIC_WELL] = "magic_well"
        }
    elseif bonus.seal_type == Seal_Type.LESSER then
        seal_type_to_skin_name = {
            [Lesser_Seal_Type.HEALTH] = "health",
            [Lesser_Seal_Type.ABILITY_LEVEL] = "ability_level",
            [Lesser_Seal_Type.ARMOR] = "armor",
            [Lesser_Seal_Type.ATTACK_SPEED] = "attack_speed",
            [Lesser_Seal_Type.COOLDOWN_REDUCTION] = "cooldown_reduction",
            [Lesser_Seal_Type.DAMAGE] = "attack_damage"
        }
    end

    local skin_name = seal_type_to_skin_name[bonus.seal]

    assert(skin_name ~= nil, "Unknown seal type " .. tostring(bonus.seal) .. "/" .. tostring(bonus.seal_type))

    bonus.native_container_proxy:SetMaterialGroup(skin_name)
end

---@param seal_type Seal_Type
---@param seal number
function convert_seal_type_to_item_name(seal_type, seal)
    local seal_type_to_item_name = {}

    if seal_type == Seal_Type.PRIMAL then
        seal_type_to_item_name = {
            [Primal_Seal_Type.BLACK] = "item_primal_black",
            [Primal_Seal_Type.BLUE] = "item_primal_blue",
            [Primal_Seal_Type.ORANGE] = "item_primal_orange",
            [Primal_Seal_Type.GREEN] = "item_primal_green",
            [Primal_Seal_Type.YELLOW] = "item_primal_yellow",
            [Primal_Seal_Type.RED] = "item_primal_red",
            [Primal_Seal_Type.WHITE] = "item_primal_white",
            [Primal_Seal_Type.PURPLE] = "item_primal_purple"
        }
    elseif seal_type == Seal_Type.GREATER then
        seal_type_to_item_name = {
            [Greater_Seal_Type.SOUL_BIND] = "item_greater_soul_bind",
            [Greater_Seal_Type.GREEVIL_PINATA] = "item_greater_greevil_pinata",
            [Greater_Seal_Type.HEALING_FRENZY] = "item_greater_healing_frenzy",
            [Greater_Seal_Type.TOGETHER_WE_STAND] = "item_greater_together_we_stand",
            [Greater_Seal_Type.STATIC_DISCHARGE] = "item_greater_static_discharge",
            [Greater_Seal_Type.HEAL_LA_KILL] = "item_greater_heal_la_kill",
            [Greater_Seal_Type.MAGIC_WELL] = "item_greater_magic_well"
        }
    elseif seal_type == Seal_Type.LESSER then
        seal_type_to_item_name = {
            [Lesser_Seal_Type.HEALTH] = "item_lesser_health",
            [Lesser_Seal_Type.ABILITY_LEVEL] = "item_lesser_ability_level",
            [Lesser_Seal_Type.ARMOR] = "item_lesser_armor",
            [Lesser_Seal_Type.ATTACK_SPEED] = "item_lesser_attack_speed",
            [Lesser_Seal_Type.COOLDOWN_REDUCTION] = "item_lesser_cooldown_reduction",
            [Lesser_Seal_Type.DAMAGE] = "item_lesser_damage"
        }
    end

    local item_name = seal_type_to_item_name[seal]

    assert(item_name ~= nil, "Unknown seal type " .. tostring(seal) .. "/" .. tostring(seal_type))

    return item_name
end

---@return Bonus
---@param seal_type Seal_Type
---@param seal number
function make_seal_in_inventory(seal_type, seal)
    return make_entity(Entity_Type.BONUS, {
        seal_type = seal_type,
        seal = seal
    })
end

---@param at_position vector
---@param primal_seal Primal_Seal_Type
---@return Bonus
function make_primal_seal(at_position, primal_seal)
    return make_bonus(at_position, Seal_Type.PRIMAL, primal_seal)
end

---@param at_position vector
---@param greater_seal Greater_Seal_Type
---@return Bonus
function make_greater_seal(at_position, greater_seal)
    return make_bonus(at_position, Seal_Type.GREATER, greater_seal)
end

---@param at_position vector
---@param lesser_seal Lesser_Seal_Type
---@return Bonus
function make_lesser_seal(at_position, lesser_seal)
    return make_bonus(at_position, Seal_Type.LESSER, lesser_seal)
end

---@param primal_seal Primal_Seal_Type
function convert_primal_seal_type_to_ability_name(primal_seal)
    local seal_type_to_ability_name = {
        [Primal_Seal_Type.BLACK] = "ability_primal_black",
        [Primal_Seal_Type.BLUE] = "ability_primal_blue",
        [Primal_Seal_Type.ORANGE] = "ability_primal_orange",
        [Primal_Seal_Type.GREEN] = "ability_primal_green",
        [Primal_Seal_Type.YELLOW] = "ability_primal_yellow",
        [Primal_Seal_Type.RED] = "ability_primal_red",
        [Primal_Seal_Type.WHITE] = "ability_primal_white"
    }

    local ability_name = seal_type_to_ability_name[primal_seal]

    assert(ability_name ~= nil, "Unknown primal seal type " .. tostring(primal_seal))

    return ability_name
end

---@param primal_seal Primal_Seal_Type
function convert_primal_seal_type_to_animation_modifier_name(primal_seal)
    local seal_type_to_ability_name = {
        [Primal_Seal_Type.BLACK] = "modifier_animation_black",
        [Primal_Seal_Type.BLUE] = "modifier_animation_blue",
        [Primal_Seal_Type.ORANGE] = "modifier_animation_orange",
        [Primal_Seal_Type.GREEN] = "modifier_animation_blue",
        [Primal_Seal_Type.YELLOW] = "modifier_animation_orange",
        [Primal_Seal_Type.RED] = "modifier_animation_blue",
        [Primal_Seal_Type.WHITE] = "modifier_animation_blue"
    }

    local animation_modifier_name = seal_type_to_ability_name[primal_seal]

    assert(animation_modifier_name ~= nil, "Unknown primal seal type " .. tostring(primal_seal))

    return animation_modifier_name
end

---@param greater_seal Greater_Seal_Type
function convert_greater_seal_type_to_ability_name(greater_seal)
    local seal_type_to_ability_name = {
        [Greater_Seal_Type.SOUL_BIND] = "ability_soul_bind",
        [Greater_Seal_Type.GREEVIL_PINATA] = "ability_greevil_pinata",
        [Greater_Seal_Type.HEALING_FRENZY] = "ability_healing_frenzy",
        [Greater_Seal_Type.TOGETHER_WE_STAND] = "ability_together_we_stand",
        [Greater_Seal_Type.STATIC_DISCHARGE] = "ability_static_discharge",
        [Greater_Seal_Type.HEAL_LA_KILL] = "ability_heal_la_kill",
        [Greater_Seal_Type.MAGIC_WELL] = "ability_magic_well"
    }

    local ability_name = seal_type_to_ability_name[greater_seal]

    assert(ability_name ~= nil, "Unknown greater seal type " .. tostring(greater_seal))

    return ability_name
end

---@param lesser_seal Lesser_Seal_Type
function convert_lesser_seal_type_to_modifier_name(lesser_seal)
    local seal_type_to_modifier_name = {
        [Lesser_Seal_Type.HEALTH] = "modifier_lesser_seal_health",
        [Lesser_Seal_Type.ABILITY_LEVEL] = "modifier_lesser_seal_ability_level",
        [Lesser_Seal_Type.ARMOR] = "modifier_lesser_seal_armor",
        [Lesser_Seal_Type.ATTACK_SPEED] = "modifier_lesser_seal_attack_speed",
        [Lesser_Seal_Type.COOLDOWN_REDUCTION] = "modifier_lesser_seal_cooldown_reduction",
        [Lesser_Seal_Type.DAMAGE] = "modifier_lesser_seal_damage"
    }

    local modifier_name = seal_type_to_modifier_name[lesser_seal]

    assert(modifier_name ~= nil, "Unknown lesser seal type " .. tostring(lesser_seal))

    return modifier_name
end