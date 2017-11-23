declare class Primal_Seal_With_Level {
    seal: Primal_Seal_Type;
    level: number;
}

declare class Greater_Seal_With_Level {
    seal: Greater_Seal_Type;
    level: number;
}

declare class Lesser_Seal_With_Level {
    seal: Lesser_Seal_Type;
    level: number;
}

declare class Hero_State {
    bonuses: { [slot_index:number]: Bonus_Slot };
    total_eggs: number;
    egg: Stored_Greevil;
    active_greevils: Stored_Greevil_With_State[];
    stored_greevils: Stored_Greevil_With_State[];
    is_hatching_an_egg: boolean;
    big_egg_is_past_the_hatching_state: boolean;
}

declare class Stored_Greevil {
    primal_seals: { [index: number] : Primal_Seal_With_Level };
    greater_seals: { [index: number] : Greater_Seal_With_Level };
    lesser_seals: { [index: number] : Lesser_Seal_With_Level };
}

declare class Stored_Greevil_With_State {
    storage: Stored_Greevil;
    respawn_at: number;
}

declare class Bonus_Slot {
    seal: number;
    seal_type: Seal_Type;
}

class Greevil_Slot {
    container_panel: Panel;
    image_panel: ImagePanel;
    respawn_timer: LabelPanel;
    level_text: LabelPanel;
    button: Panel;
    seal_slots: Slot_Panel[];
    cached_respawn_at: number;
}

const TOTAL_INVENTORY_SLOTS = 18;
const MAX_HERO_PRIMAL_SEALS = 1;
const MAX_HERO_GREATER_SEALS = 2;
const MAX_HERO_LESSER_SEALS = 4;
const MAX_ABILITY_LEVEL = 4;

const MAX_MEGA_PRIMAL_SEALS = MAX_HERO_PRIMAL_SEALS * 2;
const MAX_MEGA_GREATER_SEALS = MAX_HERO_GREATER_SEALS * 2;
const MAX_MEGA_LESSER_SEALS = MAX_HERO_LESSER_SEALS * 2;

const MAX_ACTIVE_GREEVILS = 2;
const MAX_STORED_GREEVILS = 12;

let primal_seal_slot: Slot_Panel;

const inventory_slots: Slot_Panel[] = [];
const lesser_seal_slots: Slot_Panel[] = [];
const greater_seal_slots: Slot_Panel[] = [];

const mega_lesser_seal_slots: Slot_Panel[] = [];
const mega_greater_seal_slots: Slot_Panel[] = [];
const mega_primal_seal_slots: Slot_Panel[] = [];

const active_greevil_slots: Greevil_Slot[] = [];
const stored_greevil_slots: Greevil_Slot[] = [];

enum Hatchery_Tab {
    EGGS,
    GREEVILS,
    MEGA_GREEVIL
}

let current_tab = Hatchery_Tab.GREEVILS;
let currently_reassinged_slot = -1;
let big_eggs_are_past_hatching_state = false;
let mega_greevil_hatches_at = 0;

let new_seals_counter = 0;
let new_greevils_counter = 0;

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

function convert_primal_seal_type_to_greevil_image_url(seal_type: Primal_Seal_Type) {
    const base_folder = "file://{images}/custom_game/greevils/";

    switch (seal_type) {
        case Primal_Seal_Type.ORANGE: return base_folder + "greevil_orange_1.png";
        case Primal_Seal_Type.WHITE: return base_folder + "greevil_white_1.png";
        case Primal_Seal_Type.GREEN: return base_folder + "greevil_green_1.png";
        case Primal_Seal_Type.BLUE: return base_folder + "greevil_blue_1.png";
        case Primal_Seal_Type.PURPLE: return base_folder + "greevil_naked_1.png";
        case Primal_Seal_Type.YELLOW: return base_folder + "greevil_yellow_1.png";
        case Primal_Seal_Type.BLACK: return base_folder + "greevil_black_2.png";
        case Primal_Seal_Type.RED: return base_folder + "greevil_red_1.png";
        default: {
            return base_folder + "greevil_naked_1.png";
        }
    }
}

function make_greevil_slot(parent_panel: Panel) {
    const slot_container = $.CreatePanel("Panel", parent_panel, "");
    slot_container.AddClass("GreevilSlot");

    const content_container = $.CreatePanel("Panel", slot_container, "");
    content_container.AddClass("GreevilSlotContent");

    const greevil_button = $.CreatePanel("Button", content_container, "");
    greevil_button.AddClass("GreevilButton");

    const greevil_image = $.CreatePanel("Image", greevil_button, "");
    greevil_image.SetScaling(ScalingFunction.STRETCH_TO_COVER_PRESERVE_ASPECT);
    greevil_image.AddClass("GreevilImage");

    const total_level = $.CreatePanel("Panel", content_container, "");
    total_level.AddClass("GreevilLevel");
    total_level.SetPanelEvent(PanelEvent.ON_MOUSE_OUT, () => $.DispatchEvent("DOTAHideTextTooltip"));
    total_level.SetPanelEvent(PanelEvent.ON_MOUSE_OVER,() => {
        $.DispatchEvent("DOTAShowTextTooltip", total_level, $.Localize("greevil_level_tooltip"))
    });

    const total_level_text = $.CreatePanel("Label", total_level, "");
    total_level_text.AddClass("GreevilLevelText");

    const seal_container = $.CreatePanel("Panel", content_container, "");
    seal_container.AddClass("GreevilSeals");

    const respawn_timer = $.CreatePanel("Label", slot_container, "");
    respawn_timer.AddClass("RespawnTimer");

    const greevil_slot = new Greevil_Slot();
    greevil_slot.container_panel = slot_container;
    greevil_slot.button = greevil_button;
    greevil_slot.image_panel = greevil_image;
    greevil_slot.respawn_timer = respawn_timer;
    greevil_slot.level_text = total_level_text;
    greevil_slot.seal_slots = [];


    for (let slot_index = 0; slot_index < MAX_HERO_GREATER_SEALS + MAX_HERO_PRIMAL_SEALS; slot_index++) {
        greevil_slot.seal_slots[slot_index] = make_slot_panel(seal_container);
        greevil_slot.seal_slots[slot_index].panel.enabled = false;
        greevil_slot.seal_slots[slot_index].panel.hittest = false;
    }

    return greevil_slot;
}

function can_insert_seal(primal_slots: Slot_Panel[], greater_slots: Slot_Panel[], lesser_slots: Slot_Panel[], seal_type?: Seal_Type, seal?: number) {
    let slot_panels;

    switch (seal_type) {
        case Seal_Type.PRIMAL: {
            slot_panels = primal_slots;
            break;
        }

        case Seal_Type.GREATER: {
            slot_panels = greater_slots;
            break
        }

        case Seal_Type.LESSER: {
            slot_panels = lesser_slots;
            break
        }

        default: {
            return false;
        }
    }

    let found_an_empty_slot = false;

    for (let slot_panel of slot_panels) {
        if (slot_panel.last_seal != undefined && slot_panel.last_seal_level != undefined) {
            const is_at_max_level = slot_panel.last_seal_level >= MAX_ABILITY_LEVEL;
            const is_the_same_seal = slot_panel.last_seal == seal;

            if (is_the_same_seal) {
                return !is_at_max_level;
            }
        } else {
            found_an_empty_slot = true;
        }
    }

    return found_an_empty_slot;
}

function update_eggs_tab_from_hero_state(hero_state: Hero_State) {
    const egg_counter_text: LabelPanel = <LabelPanel>$("#EggCount");
    egg_counter_text.text = "+" + (hero_state.total_eggs - 1);
    $("#EggCounter").SetHasClass("Visible", hero_state.total_eggs > 1);
    $("#HatchButtonContainer").SetHasClass("IsHatching", hero_state.is_hatching_an_egg);
    $("#HatcheryContainer").SetHasClass("HasEggs", hero_state.total_eggs > 0);

    const seal_slot = hero_state.egg.primal_seals[1];

    if (seal_slot) {
        ($("#Egg") as ImagePanel).SetImage(convert_primal_seal_type_to_egg_image_url(seal_slot.seal));

        update_seal_slot_panel_from_seal_type_and_seal(primal_seal_slot, Seal_Type.PRIMAL, seal_slot.seal, seal_slot.level);
    } else {
        ($("#Egg") as ImagePanel).SetImage(convert_primal_seal_type_to_egg_image_url(-1));

        update_seal_slot_panel_from_seal_type_and_seal(primal_seal_slot, Seal_Type.PRIMAL);
    }

    for (let slot_array_index = 0; slot_array_index < MAX_HERO_GREATER_SEALS; slot_array_index++) {
        const seal_slot = hero_state.egg.greater_seals[slot_array_index + 1];
        const corresponding_slot_panel = greater_seal_slots[slot_array_index];

        if (seal_slot) {
            update_seal_slot_panel_from_seal_type_and_seal(corresponding_slot_panel, Seal_Type.GREATER, seal_slot.seal, seal_slot.level);
        } else {
            update_seal_slot_panel_from_seal_type_and_seal(corresponding_slot_panel, Seal_Type.GREATER);
        }
    }

    for (let slot_array_index = 0; slot_array_index < MAX_HERO_LESSER_SEALS; slot_array_index++) {
        const seal_slot = hero_state.egg.lesser_seals[slot_array_index + 1];
        const corresponding_slot_panel = lesser_seal_slots[slot_array_index];

        if (seal_slot) {
            update_seal_slot_panel_from_seal_type_and_seal(corresponding_slot_panel, Seal_Type.LESSER, seal_slot.seal, seal_slot.level);
        } else {
            update_seal_slot_panel_from_seal_type_and_seal(corresponding_slot_panel, Seal_Type.LESSER);
        }
    }

    for (let slot_array_index = 0; slot_array_index < TOTAL_INVENTORY_SLOTS; slot_array_index++) {
        const seal_slot = hero_state.bonuses[slot_array_index + 1] || {};
        const corresponding_slot_panel = inventory_slots[slot_array_index];

        update_seal_slot_panel_from_seal_type_and_seal(corresponding_slot_panel, seal_slot.seal_type, seal_slot.seal);
    }
}

function update_greevil_slot_from_stored_greevil(greevil_slot: Greevil_Slot, stored_greevil: Stored_Greevil_With_State) {
    greevil_slot.container_panel.SetHasClass("NoGreevil", !stored_greevil);

    if (!stored_greevil) {
        return;
    }

    greevil_slot.cached_respawn_at = stored_greevil.respawn_at;

    const primal_seal = stored_greevil.storage.primal_seals[1];
    let total_level = 0;

    if (primal_seal) {
        greevil_slot.image_panel.SetImage(convert_primal_seal_type_to_greevil_image_url(primal_seal.seal));
        update_seal_slot_panel_from_seal_type_and_seal(greevil_slot.seal_slots[0], Seal_Type.PRIMAL, primal_seal.seal, primal_seal.level);

        total_level += primal_seal.level;
    } else {
        greevil_slot.image_panel.SetImage(convert_primal_seal_type_to_greevil_image_url(-1));
        update_seal_slot_panel_from_seal_type_and_seal(greevil_slot.seal_slots[0], Seal_Type.PRIMAL);
    }

    const greater_seals = stored_greevil.storage.greater_seals;

    for (let slot_index = 0; slot_index < MAX_HERO_GREATER_SEALS; slot_index++) {
        const greater_seal = greater_seals[slot_index + 1];
        const adjusted_slot_index = MAX_HERO_PRIMAL_SEALS + slot_index;

        if (greater_seal) {
            update_seal_slot_panel_from_seal_type_and_seal(greevil_slot.seal_slots[adjusted_slot_index], Seal_Type.GREATER, greater_seal.seal, greater_seal.level);

            total_level += greater_seal.level;
        } else {
            update_seal_slot_panel_from_seal_type_and_seal(greevil_slot.seal_slots[adjusted_slot_index], Seal_Type.GREATER);
        }
    }

    const lesser_seals = stored_greevil.storage.lesser_seals;

    for (let slot_index = 0; slot_index < MAX_HERO_GREATER_SEALS; slot_index++) {
        const lesser_seal = lesser_seals[slot_index + 1];

        if (lesser_seal) {
            total_level += lesser_seal.level;
        }
    }

    greevil_slot.level_text.text = total_level.toString(10);
}

function reset_currently_reassigned_slot() {
    currently_reassinged_slot = -1;

    for (let greevil_slot of stored_greevil_slots) {
        greevil_slot.container_panel.SetHasClass("ExcludedFromSelection", false);
    }

    for (let greevil_slot of active_greevil_slots) {
        greevil_slot.container_panel.SetHasClass("Highlighted", false);
    }
}

function set_currently_reassigned_slot(to_slot: number) {
    currently_reassinged_slot = to_slot;

    for (let slot_index in stored_greevil_slots) {
        const slot_index_number = parseInt(slot_index); // Javascript is a piece of shit
        const greevil_slot = stored_greevil_slots[slot_index];

        greevil_slot.container_panel.SetHasClass("ExcludedFromSelection", slot_index_number != to_slot);
    }

    for (let greevil_slot of active_greevil_slots) {
        greevil_slot.container_panel.SetHasClass("Highlighted", true);
    }
}

function update_greevils_tab_from_hero_state(hero_state: Hero_State) {
    let has_greevils = false;
    let has_stored_greevils = false;

    for (let slot_array_index = 0; slot_array_index < MAX_ACTIVE_GREEVILS; slot_array_index++) {
        const stored_greevil = hero_state.active_greevils[slot_array_index + 1];
        const greevil_slot = active_greevil_slots[slot_array_index];

        update_greevil_slot_from_stored_greevil(greevil_slot, stored_greevil);

        greevil_slot.button.SetPanelEvent(PanelEvent.ON_LEFT_CLICK, () => {
            if (currently_reassinged_slot != -1) {
                Game.EmitSound("ui_greevil_swap");
                GameEvents.SendCustomGameEventToServer("hatchery_put_greevil_into_slot", {
                    greevil_slot: currently_reassinged_slot,
                    target_slot: slot_array_index
                });

                reset_currently_reassigned_slot();
            }
        });

        if (stored_greevil) {
            has_greevils = true;
        }
    }

    for (let slot_array_index = 0; slot_array_index < MAX_STORED_GREEVILS; slot_array_index++) {
        const stored_greevil = hero_state.stored_greevils[slot_array_index + 1];
        const greevil_slot = stored_greevil_slots[slot_array_index];

        update_greevil_slot_from_stored_greevil(greevil_slot, stored_greevil);

        greevil_slot.button.SetPanelEvent(PanelEvent.ON_LEFT_CLICK, () => {
            if (stored_greevil_slots[slot_array_index].cached_respawn_at >= Game.GetGameTime()) {
                GameEvents.SendEventClientSide("dota_hud_error_message", {
                    message: "error_greevil_is_dead",
                    reason: 80
                });
                return;
            }

            Game.EmitSound("ui_greevil_click");

            if (currently_reassinged_slot == slot_array_index) {
                reset_currently_reassigned_slot();
            } else {
                set_currently_reassigned_slot(slot_array_index);
            }
        });

        if (stored_greevil) {
            has_greevils = true;
            has_stored_greevils = true;
        }
    }

    $("#PutGreevilIntoPartyTip").SetHasClass("Visible", has_stored_greevils);
    $("#NoGreevilsInStorageTip").SetHasClass("Visible", !has_stored_greevils);

    $("#TabGreevils").SetHasClass("HasGreevils", has_greevils);
}

function update_hatchery_ui_from_hero_state(hero_state: Hero_State) {
    update_eggs_tab_from_hero_state(hero_state);
    update_greevils_tab_from_hero_state(hero_state);
}

function update_inventory_seal_statuses_from_tab(hatchery_tab: Hatchery_Tab) {
    switch (hatchery_tab) {
        case Hatchery_Tab.EGGS: {
            update_inventory_seal_statuses([ primal_seal_slot ], greater_seal_slots, lesser_seal_slots);
            break;
        }

        case Hatchery_Tab.GREEVILS: {
            disable_all_inventory_seals();
            break;
        }

        case Hatchery_Tab.MEGA_GREEVIL: {
            update_inventory_seal_statuses(mega_primal_seal_slots, mega_greater_seal_slots, mega_lesser_seal_slots);
            break;
        }
    }
}

function update_inventory_seal_statuses(primal_slots: Slot_Panel[], greater_slots: Slot_Panel[], lesser_slots: Slot_Panel[]) {
    for (let inventory_slot of inventory_slots) {
        inventory_slot.panel.SetHasClass("CantInsert", !can_insert_seal(primal_slots, greater_slots, lesser_slots, inventory_slot.last_seal_type, inventory_slot.last_seal));
    }
}

function disable_all_inventory_seals() {
    for (let inventory_slot of inventory_slots) {
        inventory_slot.panel.SetHasClass("CantInsert", true);
    }
}

function on_hero_state_update(hero_state_by_player_id: { [player_id: number]: Hero_State }) {
    const hero_state = hero_state_by_player_id[Game.GetLocalPlayerID()];

    if (hero_state) {
        update_hatchery_ui_from_hero_state(hero_state);
    }

    update_inventory_seal_statuses_from_tab(current_tab);
}

function on_big_egg_state_update(egg_state_by_team_id: { [team_id: number]: Stored_Greevil }) {
    const team_id = (Game.GetLocalPlayerInfo() as any).player_team_id;
    const egg_state = egg_state_by_team_id[team_id];

    if (!egg_state) {
        return;
    }

    for (let slot_array_index = 0; slot_array_index < MAX_MEGA_PRIMAL_SEALS; slot_array_index++) {
        const seal_slot = egg_state.primal_seals[slot_array_index + 1];
        const corresponding_slot_panel = mega_primal_seal_slots[slot_array_index];

        if (seal_slot) {
            update_seal_slot_panel_from_seal_type_and_seal(corresponding_slot_panel, Seal_Type.PRIMAL, seal_slot.seal, seal_slot.level);
        } else {
            update_seal_slot_panel_from_seal_type_and_seal(corresponding_slot_panel, Seal_Type.PRIMAL);
        }
    }

    for (let slot_array_index = 0; slot_array_index < MAX_MEGA_GREATER_SEALS; slot_array_index++) {
        const seal_slot = egg_state.greater_seals[slot_array_index + 1];
        const corresponding_slot_panel = mega_greater_seal_slots[slot_array_index];

        if (seal_slot) {
            update_seal_slot_panel_from_seal_type_and_seal(corresponding_slot_panel, Seal_Type.GREATER, seal_slot.seal, seal_slot.level);
        } else {
            update_seal_slot_panel_from_seal_type_and_seal(corresponding_slot_panel, Seal_Type.GREATER);
        }
    }

    for (let slot_array_index = 0; slot_array_index < MAX_MEGA_LESSER_SEALS; slot_array_index++) {
        const seal_slot = egg_state.lesser_seals[slot_array_index + 1];
        const corresponding_slot_panel = mega_lesser_seal_slots[slot_array_index];

        if (seal_slot) {
            update_seal_slot_panel_from_seal_type_and_seal(corresponding_slot_panel, Seal_Type.LESSER, seal_slot.seal, seal_slot.level);
        } else {
            update_seal_slot_panel_from_seal_type_and_seal(corresponding_slot_panel, Seal_Type.LESSER);
        }
    }

    update_inventory_seal_statuses_from_tab(current_tab);
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

        function emit_sound_if_can_insert() {
            if (!inventory_slots[slot_index].panel.BHasClass("CantInsert")) {
                Game.EmitSound("ui_seal_add");
            }
        }

        switch (current_tab) {
            case Hatchery_Tab.EGGS: {
                emit_sound_if_can_insert();
                GameEvents.SendCustomGameEventToServer("hatchery_insert_seal", { seal: slot_index });
                break;
            }

            case Hatchery_Tab.MEGA_GREEVIL: {
                emit_sound_if_can_insert();
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
        slot_panel.panel.SetPanelEvent(PanelEvent.ON_LEFT_CLICK, make_inventory_slot_clicked_handler_for_slot_index(slot_index));
        slot_panel.panel.SetPanelEvent(PanelEvent.ON_RIGHT_CLICK, () => {
            Game.EmitSound("ui_seal_drop");
            GameEvents.SendCustomGameEventToServer("hatchery_drop_seal", { seal: slot_index });
        });

        inventory_slots[slot_index] = slot_panel;
    }
}

function set_egg_seal_slot_click_event(slot_panel: Slot_Panel, seal_type: Seal_Type, slot_index: number) {
    slot_panel.panel.SetPanelEvent(PanelEvent.ON_LEFT_CLICK, () => {
        hide_slot_tooltip(slot_panel);
        Game.EmitSound("ui_seal_remove");
        GameEvents.SendCustomGameEventToServer("hatchery_remove_seal", { seal: slot_index, seal_type: seal_type });
    });
}

function fill_primal_seal_slot() {
    const primal_seal_container = $("#PrimalSeal");
    primal_seal_slot = make_slot_panel(primal_seal_container);
    primal_seal_slot.panel.AddClass("InventorySlotPanel");

    set_egg_seal_slot_click_event(primal_seal_slot, Seal_Type.PRIMAL, 0);
}

function fill_greater_seal_slots() {
    const greater_seal_container = $("#GreaterSeals");

    for (let slot_index = 0; slot_index < MAX_HERO_GREATER_SEALS; slot_index++) {
        const slot_panel = make_slot_panel(greater_seal_container);

        slot_panel.panel.AddClass("InventorySlotPanel");
        set_egg_seal_slot_click_event(slot_panel, Seal_Type.GREATER, slot_index);

        greater_seal_slots[slot_index] = slot_panel;
    }
}

function fill_lesser_seal_slots() {
    const lesser_seals_container = $("#LesserSeals");

    for (let slot_index = 0; slot_index < MAX_HERO_LESSER_SEALS; slot_index++) {
        const slot_panel = make_slot_panel(lesser_seals_container);

        slot_panel.panel.AddClass("InventorySlotPanel");
        set_egg_seal_slot_click_event(slot_panel, Seal_Type.LESSER, slot_index);

        lesser_seal_slots[slot_index] = slot_panel;
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

function fill_greevil_slots() {
    const active_greevils_container = $("#ActiveGreevils");
    const stored_greevils_container = $("#StoredGreevils");

    for (let slot_array_index = 0; slot_array_index < MAX_ACTIVE_GREEVILS; slot_array_index++) {
        active_greevil_slots[slot_array_index] = make_greevil_slot(active_greevils_container);
    }

    for (let slot_array_index = 0; slot_array_index < MAX_STORED_GREEVILS; slot_array_index++) {
        stored_greevil_slots[slot_array_index] = make_greevil_slot(stored_greevils_container);
    }
}

function set_hatch_button_events() {
    const hatch_button = $("#HatchButton");
    hatch_button.SetPanelEvent(PanelEvent.ON_MOUSE_OUT, () => $.DispatchEvent("DOTAHideTextTooltip"));
    hatch_button.SetPanelEvent(PanelEvent.ON_MOUSE_OVER, () => {
        $.DispatchEvent("DOTAShowTextTooltip", hatch_button, $.Localize("hatch_greevil_tooltip"))
    });

    hatch_button.SetPanelEvent(PanelEvent.ON_LEFT_CLICK, () => {
        Game.EmitSound("ui_hatch");
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

        if (is_hatchery_open()) {
            switch_hatchery_tab(current_tab); // Refresh the state

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

    container.SetPanelEvent(PanelEvent.ON_ESCAPE_PRESS, () => container.SetHasClass("Visible", false));
}

function subscribe_to_error_message_event() {
    GameEvents.Subscribe("custom_game_error", data => {
        GameEvents.SendEventClientSide("dota_hud_error_message", data);
    });
}

function is_hatchery_open() {
    return $("#HatcheryContainer").BHasClass("Visible");
}

function update_new_things_counters() {
    $("#NewSealsCounterContainer").SetHasClass("Visible", new_seals_counter > 0);
    $("#NewGreevilsCounterContainer").SetHasClass("Visible", new_greevils_counter > 0);

    ($("#NewSealsCounter") as LabelPanel).text = new_seals_counter.toString(10);
    ($("#NewGreevilsCounter") as LabelPanel).text = new_greevils_counter.toString(10);

    GameEvents.SendEventClientSide("hatchery_new_things_update", { amount: new_seals_counter + new_greevils_counter });
}

function increment_new_seals_counter_if_not_in_eggs_tab() {
    if (!is_hatchery_open() || current_tab != Hatchery_Tab.EGGS) {
        new_seals_counter++;

        update_new_things_counters();
    }
}

function increment_new_greevils_counter_if_not_in_greevils_tab() {
    if (!is_hatchery_open() || current_tab != Hatchery_Tab.GREEVILS) {
        new_greevils_counter++;

        update_new_things_counters();
    }
}

function subscribe_to_hatchery_new_things_notifications() {
    GameEvents.Subscribe("hatchery_new_seal_picked_up", () => {
        increment_new_seals_counter_if_not_in_eggs_tab();
    });

    GameEvents.Subscribe("hatchery_new_greevil_added_to_collection", () => {
        increment_new_greevils_counter_if_not_in_greevils_tab();
    });
}

function switch_hatchery_tab(new_tab: Hatchery_Tab) {
    current_tab = new_tab;

    if (new_tab == Hatchery_Tab.GREEVILS) {
        new_greevils_counter = 0;
        update_new_things_counters();
    }

    if (new_tab == Hatchery_Tab.EGGS) {
        new_seals_counter = 0;
        update_new_things_counters();
    }

    $("#TabHatchery").SetHasClass("Active", new_tab == Hatchery_Tab.EGGS);
    $("#TabGreevils").SetHasClass("Active", new_tab == Hatchery_Tab.GREEVILS);
    $("#TabMegaGreevil").SetHasClass("Active", new_tab == Hatchery_Tab.MEGA_GREEVIL);

    $("#TabButtonEggs").SetHasClass("CurrentTab", new_tab == Hatchery_Tab.EGGS);
    $("#TabButtonGreevils").SetHasClass("CurrentTab", new_tab == Hatchery_Tab.GREEVILS);
    $("#TabButtonMegaGreevil").SetHasClass("CurrentTab", new_tab == Hatchery_Tab.MEGA_GREEVIL);

    $("#InventorySection").SetHasClass("InGreevilsTab", new_tab == Hatchery_Tab.GREEVILS);

    update_inventory_seal_statuses_from_tab(new_tab);
    reset_currently_reassigned_slot();
}

function init_tabs() {
    $("#TabButtonEggs").SetPanelEvent(PanelEvent.ON_LEFT_CLICK, () => switch_hatchery_tab(Hatchery_Tab.EGGS));
    $("#TabButtonGreevils").SetPanelEvent(PanelEvent.ON_LEFT_CLICK, () => switch_hatchery_tab(Hatchery_Tab.GREEVILS));
    $("#TabButtonMegaGreevil").SetPanelEvent(PanelEvent.ON_LEFT_CLICK, () => switch_hatchery_tab(Hatchery_Tab.MEGA_GREEVIL));
}

function update_respawn_timers_periodically() {
    $.Schedule(0.1, update_respawn_timers_periodically);

    const current_time = Game.GetGameTime();
    function update_greevil_slot_respawn_timer(greevil_slot: Greevil_Slot) {
        const delta = greevil_slot.cached_respawn_at - current_time;

        greevil_slot.container_panel.SetHasClass("IsDead", delta > 0);

        if (delta > 0) {
            greevil_slot.respawn_timer.text = Math.ceil(delta).toString(10)
        }
    }

    for (let greevil_slot of active_greevil_slots) {
        update_greevil_slot_respawn_timer(greevil_slot);
    }

    for (let greevil_slot of stored_greevil_slots) {
        update_greevil_slot_respawn_timer(greevil_slot);
    }
}

function schedule_periodic_respawn_timers_update() {
    update_respawn_timers_periodically();
}

function init_hatchery() {
    $.Msg("Initializing hatchery...");

    init_tabs();

    switch_hatchery_tab(Hatchery_Tab.EGGS);

    fill_inventory_slot_panels();
    fill_seal_slot_panels();
    fill_greevil_slots();

    set_hatch_button_events();
    set_mouse_callback_filter_to_cancel_hatchery_state();

    schedule_periodic_respawn_timers_update();

    update_hatchery_mega_greevil_timer_periodically();

    subscribe_to_error_message_event();
    subscribe_to_hatchery_visibility_handlers();
    subscribe_to_hatchery_new_things_notifications();
    subscribe_to_net_table_key_and_update_immediately("heroes", "state", on_hero_state_update);
    subscribe_to_net_table_key_and_update_immediately("eggs", "state", on_big_egg_state_update);
    subscribe_to_net_table_key_and_update_immediately("events", "timers", on_timers_updated);

    $.Msg("... Done!");
}

init_hatchery();