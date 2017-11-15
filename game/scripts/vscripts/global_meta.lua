flagged_global_tables = {} -- Has to be out of if scope so it refreshes on reload
at_declaration_stage = false

function start_declaration()
    at_declaration_stage = true
end

function end_declaration()
    at_declaration_stage = false
    flagged_global_tables = {}
end

if not global_metatable_initialized and IsInToolsMode() then
    local backup_global_storage = {}

    global_metatable_initialized = true

    setmetatable(_G, {
        __index = function(_, key)
            return backup_global_storage[key]
        end,
        __newindex = function(_, key, value)
            local already_exists = backup_global_storage[key] ~= nil
            local is_a_function = type(value) == "function"
            local is_a_table = type(value) == "table"
            local is_flagged = flagged_global_tables[key]

            --print(at_declaration_stage, "Setting", key, "to", value, "previous", backup_global_storage[key])

            if at_declaration_stage then
                if not is_flagged then
                    -- Do not overwrite table values
                    if is_a_function or not already_exists then
                        backup_global_storage[key] = value
                    end

                    flagged_global_tables[key] = true
                else
                    error("Attempt to redeclare a global function " .. key, 3)
                    --print("! [WARNING]: Attempt to redeclare a global variable " .. key)
                end
            else
                backup_global_storage[key] = value
            end
        end
    })
end