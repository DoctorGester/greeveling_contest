declare class Hero_State {
    bonuses: { [slot_index:number]: Bonus_Slot };
    total_eggs: number;
    egg: Hero_Egg;
    is_hatching_an_egg: boolean;
    big_egg_is_past_the_hatching_state: boolean;
}

declare class Hero_Egg {
    primal_seals: Primal_Seal_Type[];
    greater_seals: Greater_Seal_Type[];
    lesser_seals: Lesser_Seal_Type[];
}

declare class Bonus_Slot {
    seal: number;
    seal_type: Seal_Type;
}

const TOTAL_INVENTORY_SLOTS = 18;
const MAX_HERO_GREATER_SEALS = 2;
const MAX_HERO_LESSER_SEALS = 4;

let primal_seal_slot: Slot_Panel;

const inventory_slots: Slot_Panel[] = [];
const lesser_seal_slots: Slot_Panel[] = [];
const greater_seal_slots: Slot_Panel[] = [];

enum Hatchery_State {
    NONE,
    FEEDING,
    DROPPING
}

let hatchery_state = Hatchery_State.NONE;
let big_eggs_are_past_hatching_state = false;

function convert_primal_seal_type_to_egg_image_url(seal_type: Primal_Seal_Type) {
    const base_folder = "file://{images}/econ/courier/greevil/";

    switch (seal_type) {
        case Primal_Seal_Type.ORANGE: return base_folder + "greevil_egg_orange.png";
        case Primal_Seal_Type.WHITE: return base_folder + "greevil_egg_white.png";
        case Primal_Seal_Type.GREEN: return base_folder + "greevil_egg_green.png";
        case Primal_Seal_Type.BLUE: return base_folder + "greevil_egg_blue.png";
        case Primal_Seal_Type.PURPLE: return base_folder + "greevil_egg_purple.png";
        case Primal_Seal_Type.YELLOW: return base_folder + "greevil_egg_yellow.png";
        case Primal_Seal_Type.BLACK: return base_folder + "greevil_egg_black.png";
        case Primal_Seal_Type.RED: return base_folder + "greevil_egg_red.png";
        default: {
            return base_folder + "greevil_egg_natural.png";
        }
    }
}

function update_hatchery_ui_from_hero_state(hero_state: Hero_State) {
    if (hero_state.big_egg_is_past_the_hatching_state) {
        if (hatchery_state == Hatchery_State.FEEDING) {
            hatchery_state = Hatchery_State.NONE;
        }

        big_eggs_are_past_hatching_state = hero_state.big_egg_is_past_the_hatching_state;
        update_hatchery_ui_from_hatchery_state();
    }

    const egg_counter_text: LabelPanel = <LabelPanel>$("#EggCount");
    egg_counter_text.text = "+" + (hero_state.total_eggs - 1);
    $("#EggCounter").SetHasClass("Visible", hero_state.total_eggs > 1);
    $("#HatchButtonContainer").SetHasClass("IsHatching", hero_state.is_hatching_an_egg);
    $("#HatcheryContainer").SetHasClass("HasEggs", hero_state.total_eggs > 0);
    ($("#Egg") as ImagePanel).SetImage(convert_primal_seal_type_to_egg_image_url(hero_state.egg.primal_seals[1]));

    update_seal_slot_panel_from_seal_type_and_seal(primal_seal_slot, Seal_Type.PRIMAL, hero_state.egg.primal_seals[1]);

    for (let slot_array_index = 0; slot_array_index < MAX_HERO_GREATER_SEALS; slot_array_index++) {
        const seal_slot = hero_state.egg.greater_seals[slot_array_index + 1];
        const corresponding_slot_panel = greater_seal_slots[slot_array_index];

        update_seal_slot_panel_from_seal_type_and_seal(corresponding_slot_panel, Seal_Type.GREATER, seal_slot);
    }

    for (let slot_array_index = 0; slot_array_index < MAX_HERO_LESSER_SEALS; slot_array_index++) {
        const seal_slot = hero_state.egg.lesser_seals[slot_array_index + 1];
        const corresponding_slot_panel = lesser_seal_slots[slot_array_index];

        update_seal_slot_panel_from_seal_type_and_seal(corresponding_slot_panel, Seal_Type.LESSER, seal_slot);
    }

    for (let slot_array_index = 0; slot_array_index < TOTAL_INVENTORY_SLOTS; slot_array_index++) {
        const seal_slot = hero_state.bonuses[slot_array_index + 1] || {};
        const corresponding_slot_panel = inventory_slots[slot_array_index];

        update_seal_slot_panel_from_seal_type_and_seal(corresponding_slot_panel, seal_slot.seal_type, seal_slot.seal);
    }
}

function on_hero_state_update(hero_state_by_player_id: { [player_id: number]: Hero_State }) {
    const hero_state = hero_state_by_player_id[Game.GetLocalPlayerID()];

    if (hero_state) {
        update_hatchery_ui_from_hero_state(hero_state);
    }
}

function make_inventory_slot_clicked_handler_for_slot_index(slot_index: number) {
    return () => {
        hide_slot_tooltip(inventory_slots[slot_index]);

        switch (hatchery_state) {
            case Hatchery_State.NONE: {
                GameEvents.SendCustomGameEventToServer("hatchery_insert_seal", { seal: slot_index });
                break;
            }

            case Hatchery_State.FEEDING: {
                GameEvents.SendCustomGameEventToServer("hatchery_feed_seal", { seal: slot_index });
                break;
            }

            case Hatchery_State.DROPPING: {
                GameEvents.SendCustomGameEventToServer("hatchery_drop_seal", { seal: slot_index });
                break;
            }
        }
    };
}

function fill_inventory_slot_panels() {
    const container = $("#InventoryContainer");

    for (let slot_index = 0; slot_index < TOTAL_INVENTORY_SLOTS; slot_index++) {
        const slot_panel = make_slot_panel(container);

        slot_panel.panel.AddClass("InventorySlotPanel");
        slot_panel.panel.SetPanelEvent("onactivate", make_inventory_slot_clicked_handler_for_slot_index(slot_index));

        inventory_slots[slot_index] = slot_panel;
    }
}

function fill_primal_seal_slot() {
    const primal_seal_container = $("#PrimalSeal");
    primal_seal_slot = make_slot_panel(primal_seal_container);
    primal_seal_slot.panel.AddClass("InventorySlotPanel");
    primal_seal_slot.panel.SetPanelEvent("onactivate", () => {
        hide_slot_tooltip(primal_seal_slot);
        GameEvents.SendCustomGameEventToServer("hatchery_remove_seal", { seal: 0, seal_type: Seal_Type.PRIMAL });
    });
}

function fill_lesser_seal_slots() {
    const lesser_seals_container = $("#LesserSeals");

    for (let slot_index = 0; slot_index < MAX_HERO_LESSER_SEALS; slot_index++) {
        const slot_panel = make_slot_panel(lesser_seals_container);

        slot_panel.panel.AddClass("InventorySlotPanel");
        slot_panel.panel.SetPanelEvent("onactivate", () => {
            hide_slot_tooltip(slot_panel);
            GameEvents.SendCustomGameEventToServer("hatchery_remove_seal", { seal: slot_index, seal_type: Seal_Type.LESSER });
        });

        lesser_seal_slots[slot_index] = slot_panel;
    }
}

function fill_greater_seal_slots() {
    const greater_seal_container = $("#GreaterSeals");

    for (let slot_index = 0; slot_index < MAX_HERO_GREATER_SEALS; slot_index++) {
        const slot_panel = make_slot_panel(greater_seal_container);

        slot_panel.panel.AddClass("InventorySlotPanel");
        slot_panel.panel.SetPanelEvent("onactivate", () => {
            hide_slot_tooltip(slot_panel);
            GameEvents.SendCustomGameEventToServer("hatchery_remove_seal", { seal: slot_index, seal_type: Seal_Type.GREATER });
        });

        greater_seal_slots[slot_index] = slot_panel;
    }
}

function fill_seal_slot_panels() {
    fill_primal_seal_slot();
    fill_greater_seal_slots();
    fill_lesser_seal_slots();
}

function set_hatch_button_events() {
    const hatch_button = $("#HatchButton");
    hatch_button.SetPanelEvent("onmouseout", () => $.DispatchEvent("DOTAHideTextTooltip"));
    hatch_button.SetPanelEvent("onmouseover", () => {
        $.DispatchEvent("DOTAShowTextTooltip", hatch_button, $.Localize("hatch_greevil_tooltip"))
    });

    hatch_button.SetPanelEvent("onactivate", () => {
        GameEvents.SendCustomGameEventToServer("hatchery_hatch_egg", {});
    });
}

function update_hatchery_ui_from_hatchery_state() {
    let inventory_section = $("#InventorySection");

    inventory_section.SetHasClass("Dropping", hatchery_state == Hatchery_State.DROPPING);
    inventory_section.SetHasClass("Feeding", hatchery_state == Hatchery_State.FEEDING);

    $("#InventoryButtonFeed").enabled = hatchery_state != Hatchery_State.DROPPING && !big_eggs_are_past_hatching_state;
    $("#InventoryButtonDrop").enabled = hatchery_state != Hatchery_State.FEEDING;
}

function hatchery_toggle_feeding() {
    if (hatchery_state == Hatchery_State.FEEDING) {
        hatchery_state = Hatchery_State.NONE;
    } else {
        hatchery_state = Hatchery_State.FEEDING;
    }

    update_hatchery_ui_from_hatchery_state();
}

function hatchery_toggle_dropping() {
    if (hatchery_state == Hatchery_State.DROPPING) {
        hatchery_state = Hatchery_State.NONE;
    } else {
        hatchery_state = Hatchery_State.DROPPING;
    }

    update_hatchery_ui_from_hatchery_state();
}

function set_inventory_buttons_events() {
    $("#InventoryButtonDrop").SetPanelEvent("onactivate", hatchery_toggle_dropping);

    const button_feed = $("#InventoryButtonFeed");

    button_feed.SetPanelEvent("onactivate", hatchery_toggle_feeding);
    button_feed.SetPanelEvent("onmouseout", () => $.DispatchEvent("DOTAHideTextTooltip"));
    button_feed.SetPanelEvent("onmouseover", () => {
        $.DispatchEvent("DOTAShowTextTooltip", button_feed, $.Localize("feed_mega_greevil_tooltip"))
    });
}

function set_mouse_callback_filter_to_cancel_hatchery_state() {
    GameUI.SetMouseCallback((event, button) => {
        const container = $("#HatcheryContainer");
        const position = container.GetPositionWithinWindow();
        const cursor = GameUI.GetCursorPosition();

        if (container.BHasClass("Visible")) {
            if (cursor[0] >= position.x &&
                cursor[1] >= position.y &&
                cursor[0] <= position.x  + container.actuallayoutwidth &&
                cursor[1] <= position.y  + container.actuallayoutheight) {
                return;
            }
        }

        if (button == MouseButton.LEFT) {
            container.SetHasClass("Visible", false);
        }

        if (button == MouseButton.RIGHT) {
            hatchery_state = Hatchery_State.NONE;
            update_hatchery_ui_from_hatchery_state();
        }
    });
}

function subscribe_to_hatchery_visibility_handlers() {
    const container = $("#HatcheryContainer");

    GameEvents.Subscribe("hatchery_button_click", () => {
        container.ToggleClass("Visible");

        if (container.BHasClass("Visible")) {
            $.DispatchEvent("SetInputFocus", container);
            Game.EmitSound("Shop.PanelUp");
        } else {
            Game.EmitSound("Shop.PanelDown");
        }
    });

    const shop_button = $.GetContextPanel()
        .GetParent() // HUD root
        .GetParent() // Custom UI root
        .GetParent() // Game HUD
        .FindChildTraverse("ShopButton");

    $.RegisterEventHandler("DOTAHUDToggleShop", shop_button, () => {
        container.SetHasClass("Visible", false);
    });

    container.SetPanelEvent("oncancel", () => container.SetHasClass("Visible", false));
}

function subscribe_to_error_message_event() {
    GameEvents.Subscribe("custom_game_error", function(data) {
        GameEvents.SendEventClientSide("dota_hud_error_message", data);
    });
}

function init_hatchery() {
    $.Msg("Initializing hatchery...");

    fill_inventory_slot_panels();
    fill_seal_slot_panels();

    set_hatch_button_events();
    set_inventory_buttons_events();
    set_mouse_callback_filter_to_cancel_hatchery_state();

    subscribe_to_error_message_event();
    subscribe_to_hatchery_visibility_handlers();
    subscribe_to_net_table_key_and_update_immediately("heroes", "state", on_hero_state_update);

    $.Msg("... Done!");
}

init_hatchery();