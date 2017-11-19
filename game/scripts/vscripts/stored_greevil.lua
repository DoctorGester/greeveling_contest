---@class Seal_With_Level
---@field public seal number
---@field public level number

---@class Stored_Greevil
---@field public primal_seals Seal_With_Level[]
---@field public greater_seals Seal_With_Level[]
---@field public lesser_seals Seal_With_Level[]
---@field public max_primal_seals number
---@field public max_greater_seals number
---@field public max_lesser_seals number
---@field public greevil Greevil


MAX_SEAL_LEVEL = 4

---@return Stored_Greevil
function make_stored_greevil(max_primal_seals, max_greater_seals, max_lesser_seals)
    return {
        primal_seals = {},
        greater_seals = {},
        lesser_seals = {},
        max_primal_seals = max_primal_seals,
        max_greater_seals = max_greater_seals,
        max_lesser_seals = max_lesser_seals
    }
end

function make_seal_with_level(seal)
    return {
        seal = seal,
        level = 0
    }
end

---@param stored_greevil Stored_Greevil
---@param seal_type Seal_Type
---@return Seal_With_Level[]
function stored_greevil_get_seal_table_by_seal_type(stored_greevil, seal_type)
    if seal_type == Seal_Type.PRIMAL then
        return stored_greevil.primal_seals
    elseif seal_type == Seal_Type.GREATER then
        return stored_greevil.greater_seals
    elseif seal_type == Seal_Type.LESSER then
        return stored_greevil.lesser_seals
    else
        assert(false, "Unrecognized seal type " .. tostring(seal_type))
    end
end

---@param stored_greevil Stored_Greevil
---@param seal_type Seal_Type
---@return number
function get_max_stored_greevil_seal_amount_by_seal_type(stored_greevil, seal_type)
    if seal_type == Seal_Type.PRIMAL then
        return stored_greevil.max_primal_seals
    elseif seal_type == Seal_Type.GREATER then
        return stored_greevil.max_greater_seals
    elseif seal_type == Seal_Type.LESSER then
        return stored_greevil.max_lesser_seals
    else
        assert(false, "Unrecognized seal type " .. tostring(seal_type))
    end
end

---@param stored_greevil Stored_Greevil
---@param seal_type Seal_Type
---@param seal number
function find_empty_seal_slot_for_seal_in_stored_greevil(stored_greevil, seal_type, seal)
    local max_seals_of_this_type = get_max_stored_greevil_seal_amount_by_seal_type(stored_greevil, seal_type)
    local seal_table = stored_greevil_get_seal_table_by_seal_type(stored_greevil, seal_type)

    local found_an_empty_slot = false
    local empty_slot_index

    for slot_index = 1, max_seals_of_this_type do
        if seal_table[slot_index] then
            if seal_table[slot_index].seal == seal then
                return slot_index, true
            end
        elseif not found_an_empty_slot then
            found_an_empty_slot = true
            empty_slot_index = slot_index
        end
    end

    return empty_slot_index, found_an_empty_slot
end

---@param stored_greevil Stored_Greevil
---@param seal Bonus
function stored_greevil_apply_seal(stored_greevil, seal)
    local seal_table = stored_greevil_get_seal_table_by_seal_type(stored_greevil, seal.seal_type)
    local empty_slot_index, found = find_empty_seal_slot_for_seal_in_stored_greevil(stored_greevil, seal.seal_type, seal.seal)

    if not found then
        return error_cant_insert_all_slots_are_full
    end

    local seal_with_level = seal_table[empty_slot_index]

    if seal_with_level == nil then
        seal_with_level = make_seal_with_level(seal.seal)
        seal_table[empty_slot_index] = seal_with_level
    end

    if seal_with_level.level == MAX_SEAL_LEVEL then
        return error_max_seal_level
    end

    seal_with_level.level = seal_with_level.level + 1

    return success
end

---@param stored_greevil Stored_Greevil
---@param seal_type Seal_Type
---@param slot_index number
---@return number
function stored_greevil_remove_seal(stored_greevil, seal_type, slot_index)
    local seal_table = stored_greevil_get_seal_table_by_seal_type(stored_greevil, seal_type)

    assert(seal_table[slot_index] ~= nil, string.format("Invalid/empty seal slot %i", slot_index))

    local removed_bonus = seal_table[slot_index]
    seal_table[slot_index].level = seal_table[slot_index].level - 1

    if seal_table[slot_index].level == 0 then
        seal_table[slot_index] = nil
    end

    return removed_bonus.seal
end
