function init_hatchery_button() {
    $.Msg("Initializing hatchery button...");

    GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_COURIER, false);

    $("#HatcheryButton").SetPanelEvent("onactivate", () => {
        GameEvents.SendEventClientSide("hatchery_button_click", {});
        $.DispatchEvent("DOTAShopHideShop");
    });

    $.Msg("... Done!");
}

init_hatchery_button();