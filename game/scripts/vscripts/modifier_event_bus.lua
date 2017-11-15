modifier_event_bus = {
    DeclareFunctions = function()
        return {
            MODIFIER_EVENT_ON_ATTACK_LANDED
        }
    end,
    OnAttackLanded = function(_, data)
        --add_event_to_queue("attack_landed", data)
    end
}