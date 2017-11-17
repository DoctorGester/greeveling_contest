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

const MAX_MEGA_PRIMAL_SEALS = 2;
const MAX_MEGA_GREATER_SEALS = MAX_HERO_GREATER_SEALS * 2;
const MAX_MEGA_LESSER_SEALS = MAX_HERO_LESSER_SEALS * 2;

let primal_seal_slot: Slot_Panel;

const inventory_slots: Slot_Panel[] = [];
const lesser_seal_slots: Slot_Panel[] = [];
const greater_seal_slots: Slot_Panel[] = [];

const mega_lesser_seal_slots: Slot_Panel[] = [];
const mega_greater_seal_slots: Slot_Panel[] = [];
const mega_primal_seal_slots: Slot_Panel[] = [];

enum Hatchery_Tab {
    EGGS,
    GREEVILS,
    MEGA_GREEVIL
}

let current_tab = Hatchery_Tab.GREEVILS;
let big_eggs_are_past_hatching_state = false;
let mega_greevil_hatches_at = 0;

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

function on_big_egg_state_update(egg_state_by_team_id: { [team_id: number]: Big_Egg_State }) {
    const team_id = (Game.GetLocalPlayerInfo() as any).player_team_id;
    const egg_state = egg_state_by_team_id[team_id];

    if (!egg_state) {
        return;
    }

    for (let slot_array_index = 0; slot_array_index < MAX_MEGA_PRIMAL_SEALS; slot_array_index++) {
        const seal_slot = egg_state.primal_seals[slot_array_index + 1];
        const corresponding_slot_panel = mega_primal_seal_slots[slot_array_index];

        update_seal_slot_panel_from_seal_type_and_seal(corresponding_slot_panel, Seal_Type.PRIMAL, seal_slot);
    }

    for (let slot_array_index = 0; slot_array_index < MAX_MEGA_GREATER_SEALS; slot_array_index++) {
        const seal_slot = egg_state.greater_seals[slot_array_index + 1];
        const corresponding_slot_panel = mega_greater_seal_slots[slot_array_index];

        update_seal_slot_panel_from_seal_type_and_seal(corresponding_slot_panel, Seal_Type.GREATER, seal_slot);
    }

    for (let slot_array_index = 0; slot_array_index < MAX_MEGA_LESSER_SEALS; slot_array_index++) {
        const seal_slot = egg_state.lesser_seals[slot_array_index + 1];
        const corresponding_slot_panel = mega_lesser_seal_slots[slot_array_index];

        update_seal_slot_panel_from_seal_type_and_seal(corresponding_slot_panel, Seal_Type.LESSER, seal_slot);
    }
}

function update_hatchery_mega_greevil_timer_periodically() {
    $.Schedule(0.1, update_hatchery_mega_greevil_timer_periodically);

    //$("#HatchTimer").visible = big_eggs_hatch_at != 0;
    update_timer_label_from_time_remaining(mega_greevil_hatches_at, ($("#MegaGreevilTimer") as LabelPanel), "NOW");
}

function on_timers_updated(events_data: Events_Data) {
    mega_greevil_hatches_at = events_data.big_eggs_hatch_at;
}

function make_inventory_slot_clicked_handler_for_slot_index(slot_index: number) {
    return () => {
        hide_slot_tooltip(inventory_slots[slot_index]);

        switch (current_tab) {
            case Hatchery_Tab.EGGS: {
                GameEvents.SendCustomGameEventToServer("hatchery_insert_seal", { seal: slot_index });
                break;
            }

            case Hatchery_Tab.MEGA_GREEVIL: {
                GameEvents.SendCustomGameEventToServer("hatchery_feed_seal", { seal: slot_index });
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
        slot_panel.panel.SetPanelEvent("oncontextmenu", () => {
            GameEvents.SendCustomGameEventToServer("hatchery_drop_seal", { seal: slot_index });
        });

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

function fill_mega_greevil_primal_seal_slots() {
    const primal_seal_container = $("#MegaPrimalSeals");

    for (let slot_index = 0; slot_index < MAX_MEGA_PRIMAL_SEALS; slot_index++) {
        const slot_panel = make_slot_panel(primal_seal_container);
        slot_panel.panel.AddClass("InventorySlotPanel");

        mega_primal_seal_slots[slot_index] = slot_panel;
    }
}

function fill_mega_greevil_greater_seal_slots() {
    const greater_seal_container = $("#MegaGreaterSeals");

    for (let slot_index = 0; slot_index < MAX_MEGA_GREATER_SEALS; slot_index++) {
        const slot_panel = make_slot_panel(greater_seal_container);
        slot_panel.panel.AddClass("InventorySlotPanel");

        mega_greater_seal_slots[slot_index] = slot_panel;
    }
}

function fill_mega_greevil_lesser_seal_slots() {
    const lesser_seals_container_top = $("#MegaLesserSealsTop");
    const lesser_seals_container_bottom = $("#MegaLesserSealsBottom");

    for (let slot_index = 0; slot_index < MAX_MEGA_LESSER_SEALS; slot_index++) {
        const slot_panel = make_slot_panel(slot_index < 4 ? lesser_seals_container_top : lesser_seals_container_bottom);
        slot_panel.panel.AddClass("InventorySlotPanel");

        mega_lesser_seal_slots[slot_index] = slot_panel;
    }
}

function fill_seal_slot_panels() {
    fill_primal_seal_slot();
    fill_greater_seal_slots();
    fill_lesser_seal_slots();

    fill_mega_greevil_primal_seal_slots();
    fill_mega_greevil_greater_seal_slots();
    fill_mega_greevil_lesser_seal_slots();
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
    });
}

function subscribe_to_hatchery_visibility_handlers() {
    const container = $("#HatcheryContainer");

    GameEvents.Subscribe("hatchery_button_click", () => {
        container.ToggleClass("Visible");

        if (container.BHasClass("Visible")) {
            Game.EmitSound("Shop.PanelUp");
        } else {
            Game.EmitSound("Shop.PanelDown");
        }
    });

    GameEvents.Subscribe("dota_player_update_selected_unit", () => {
        container.SetHasClass("Visible", false);
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

function switch_hatchery_tab(new_tab: Hatchery_Tab) {
    current_tab = new_tab;

    $("#TabHatchery").SetHasClass("Active", new_tab == Hatchery_Tab.EGGS);
    $("#TabGreevils").SetHasClass("Active", new_tab == Hatchery_Tab.GREEVILS);
    $("#TabMegaGreevil").SetHasClass("Active", new_tab == Hatchery_Tab.MEGA_GREEVIL);

    $("#TabButtonEggs").SetHasClass("CurrentTab", new_tab == Hatchery_Tab.EGGS);
    $("#TabButtonGreevils").SetHasClass("CurrentTab", new_tab == Hatchery_Tab.GREEVILS);
    $("#TabButtonMegaGreevil").SetHasClass("CurrentTab", new_tab == Hatchery_Tab.MEGA_GREEVIL);
}

function init_tabs() {
    $("#TabButtonEggs").SetPanelEvent("onactivate", () => switch_hatchery_tab(Hatchery_Tab.EGGS));
    $("#TabButtonGreevils").SetPanelEvent("onactivate", () => switch_hatchery_tab(Hatchery_Tab.GREEVILS));
    $("#TabButtonMegaGreevil").SetPanelEvent("onactivate", () => switch_hatchery_tab(Hatchery_Tab.MEGA_GREEVIL));
}

function init_hatchery() {
    $.Msg("Initializing hatchery...");

    init_tabs();

    switch_hatchery_tab(Hatchery_Tab.EGGS);

    fill_inventory_slot_panels();
    fill_seal_slot_panels();

    set_hatch_button_events();
    set_mouse_callback_filter_to_cancel_hatchery_state();

    update_hatchery_mega_greevil_timer_periodically();

    subscribe_to_error_message_event();
    subscribe_to_hatchery_visibility_handlers();
    subscribe_to_net_table_key_and_update_immediately("heroes", "state", on_hero_state_update);
    subscribe_to_net_table_key_and_update_immediately("eggs", "state", on_big_egg_state_update);
    subscribe_to_net_table_key_and_update_immediately("events", "timers", on_timers_updated);

    $.Msg("... Done!");
}

init_hatchery();