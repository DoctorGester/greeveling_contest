function init_event_notifications() {
    $.Msg("Initializing event notifications...");

    GameEvents.Subscribe("event_started", () => {
        Game.EmitSound("ui_event_start");

        const notification_container = $("#EventNotificationContainer");
        notification_container.RemoveClass("Hidden");
        notification_container.AddClass("EventNotificationAnimation");

        Game.EmitSound("ui_event_start_notification");

        $.Schedule(5.0, () => {
            notification_container.RemoveClass("EventNotificationAnimation");
            notification_container.AddClass("Hidden");
        })
    });
}

init_event_notifications();