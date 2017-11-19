require("global_meta")

start_declaration()

require("util")
require("globals")
require("native")
require("enums")
require("greevil")
require("greevil_ai")
require("greevil_egg")
require("mega_greevil")
require("stored_greevil")
require("big_egg")
require("candy")
require("game")
require("hero")
require("bonus")
require("drops")
require("wearables")

require("event_crystal_maiden.ai_crystal_maiden")

if is_in_debug_mode then
    require("editor")
end

function Precache(context)
    preload_resources_from_context(context)
end

function Activate()
    set_up_game_settings()
    set_up_native_game_mode_entity()
    bind_native_events()
    bind_custom_events()
    link_native_modifiers()
end

end_declaration()