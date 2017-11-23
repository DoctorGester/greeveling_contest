declare class Events_Data {
    next_event_at: number;
    big_eggs_hatch_at: number;
}

let next_event_at = 0;
let big_eggs_hatch_at = 0;

const game_hud =  $.GetContextPanel()
    .GetParent() // HUD root
    .GetParent() // Custom UI root
    .GetParent(); // Game HUD

const shop_panel = game_hud.FindChildTraverse("shop");

function update_event_timers(data: Events_Data) {
    if (next_event_at == 0 && data.next_event_at != 0) {
        $("#EventTimerTop").AddClass("EventTimerSlideOut");
        $("#HatchTimerTop").AddClass("EventTimerSlideOut");

        Game.EmitSound("ui_timers_slide_out");
    }

    next_event_at = data.next_event_at;
    big_eggs_hatch_at = data.big_eggs_hatch_at;

    const boss_event_image = ($("#BossEventImage") as ImagePanel);
    boss_event_image.SetImage("file://{images}/custom_game/boss_crystal_maiden.png");
    boss_event_image.SetScaling(ScalingFunction.STRETCH_TO_COVER_PRESERVE_ASPECT);

    const big_egg_hatch_image = ($("#BigEggHatchEventImage") as ImagePanel);
    big_egg_hatch_image.SetImage("file://{images}/custom_game/event_egg.png");
    big_egg_hatch_image.SetScaling(ScalingFunction.STRETCH_TO_COVER_PRESERVE_ASPECT);
}

function update_timers_visibility(is_shop_open: boolean) {
    $("#EventTimerTop").visible = next_event_at != 0 && !is_shop_open;
    $("#HatchTimerTop").visible = big_eggs_hatch_at != 0 && !is_shop_open;
}

function update_timer_periodically() {
    $.Schedule(0.1, update_timer_periodically);

    update_timers_visibility(shop_panel.BHasClass("ShopOpen"));

    const timer_callback: Timer_Callback = (minutes, seconds, timer_label) => {
        if (minutes == 0 && seconds <= 5) {
            Game.EmitSound("ui_event_last_seconds_tick");

            timer_label.RemoveClass("AnimationTimerClose");
            timer_label.AddClass("AnimationTimerClose");
        }
    };

    update_timer_label_from_time_remaining(next_event_at, ($("#EventTimer") as LabelPanel), "IN PROGRESS", timer_callback);
    update_timer_label_from_time_remaining(big_eggs_hatch_at, ($("#BigEggHatchTimer") as LabelPanel), "HATCHED", timer_callback);

    if (next_event_at > big_eggs_hatch_at) {
        ($("#EventTimer") as LabelPanel).text = "OVER";
    }
}

function subscribe_to_shop_visibility_event() {
    const shop_button = game_hud.FindChildTraverse("ShopButton");

    $.RegisterEventHandler("DOTAHUDToggleShop", shop_button, () => {
        update_timers_visibility(shop_panel.BHasClass("ShopOpen"));
    });
}

function schedule_periodic_timer_update() {
    update_timer_periodically();
}

function init_event_timer() {
    $.Msg("Initializing event timer...");

    schedule_periodic_timer_update();
    subscribe_to_shop_visibility_event();
    subscribe_to_net_table_key_and_update_immediately("events", "timers", update_event_timers);

    $.Msg("... Done!");
}

init_event_timer();