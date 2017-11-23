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

    GameEvents.Subscribe("big_eggs_are_hatching", (data: any) => {
        GameUI.SetCameraTargetPosition(Entities.GetAbsOrigin(data.target_entity), 2.0);
        Game.EmitSound("ui_mega_greevil_spawn");

        $.Schedule(2.0, () => {
            GameUI.SetCameraTarget(data.target_entity);

            $.Schedule(3.0, () => GameUI.SetCameraTarget(-1));
        })
    });
}

init_event_notifications();