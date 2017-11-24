function init_tutorial() {
    $.Msg("Initializing tutorial...");

    $("#TutorialButton").SetPanelEvent(PanelEvent.ON_LEFT_CLICK, () => {
        $("#TutorialContainer").AddClass("Hidden");
        Game.EmitSound("ui_greevil_click");
    });

    GameEvents.Subscribe("pregame_started", () => $("#TutorialContainer").RemoveClass("Hidden"))
}

init_tutorial();