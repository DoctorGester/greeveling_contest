function init_hatchery_button() {
    $.Msg("Initializing hatchery button...");

    GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_COURIER, false);

    $("#HatcheryButton").SetPanelEvent(PanelEvent.ON_LEFT_CLICK, () => {
        GameEvents.SendEventClientSide("hatchery_button_click", {});
        $.DispatchEvent("DOTAShopHideShop");
    });

    GameEvents.Subscribe("hatchery_new_things_update", (data: any) => {
        const amount_of_new_things = parseInt(data.amount, 10);

        $("#NewThingsCounterContainer").SetHasClass("Visible", amount_of_new_things > 0);
        ($("#NewThingsCounter") as LabelPanel).text = amount_of_new_things.toString(10);
    });
}

init_hatchery_button();