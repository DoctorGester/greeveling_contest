---@class Entity_Type
Entity_Type = {
    HERO = 0,
    BONUS = 1,
    GREEVIL_EGG = 2,
    GREEVIL = 3,
    BIG_EGG = 4,
    MEGA_GREEVIL = 5,
    AI_CRYSTAL_MAIDEN = 6,
    AI_TUSK = 7,
    AI_LICH = 8,
    AI_WINTER_WYVERN = 9,
}

---@class Seal_Type
Seal_Type = {
    PRIMAL = 0,
    GREATER = 1,
    LESSER = 2
}

---@class Primal_Seal_Type
Primal_Seal_Type = {
    BLACK = 0,
    BLUE = 1,
    GREEN = 2,
    ORANGE = 3,
    PURPLE = 4,
    RED = 5,
    WHITE = 6,
    YELLOW = 7,
    LAST = 8
}

---@class Greater_Seal_Type
Greater_Seal_Type = {
    SOUL_BIND = 0,
    GREEVIL_PINATA = 1,
    HEALING_FRENZY = 2,
    TOGETHER_WE_STAND = 3,
    STATIC_DISCHARGE = 4,
    HEAL_LA_KILL = 5,
    MAGIC_WELL = 6,
    LAST = 7
}

---@class Lesser_Seal_Type
Lesser_Seal_Type = {
    HEALTH = 0,
    DAMAGE = 1,
    ARMOR = 2,
    ATTACK_SPEED = 3,
    ABILITY_LEVEL = 4,
    COOLDOWN_REDUCTION = 5,
    LAST = 6
}

Event_Type = {
    CRYSTAL_MAIDEN = 0,
    TUSK = 1,
    LICH = 2,
    WINTER_WYVERN = 3,
    LAST = 4
}

---@class AI_Crystal_Maiden_State
AI_Crystal_Maiden_State = {
    ON_THE_MOVE = 0,
    CASTING_FROSTBITE = 1,
    CASTING_SPIRAL = 2,
    CASTING_FREEZING_FIELD = 3,
    CASTING_FROST_NOVA = 4,
    GOING_TO_CAST_SPIRAL = 5,
    GOING_TO_CAST_FREEZING_FIELD = 6
}