declare class Events_Data {
    next_event_at: number;
    big_eggs_hatch_at: number;
}

let next_event_at = 0;
let big_eggs_hatch_at = 0;

function update_event_timers(data: Events_Data) {
    next_event_at = data.next_event_at;
    big_eggs_hatch_at = data.big_eggs_hatch_at;
}

function update_timer_periodically() {
    $.Schedule(0.1, update_timer_periodically);

    $("#EventTimerTop").visible = next_event_at != 0;
    $("#HatchTimerTop").visible = big_eggs_hatch_at != 0;

    function update_timer_label_from_time_remaining(event_time: number, timer_label: LabelPanel, default_text: string) {
        const delta_time = Math.floor(event_time - Game.GetGameTime());

        if (delta_time > 0) {
            const minutes = Math.floor(delta_time / 60);
            const seconds = delta_time % 60;

            const left_pad = (numbers: number) => {
                return (new Array(3).join('0') + numbers).slice(-2);
            };

            timer_label.text = left_pad(minutes) + ':' + left_pad(seconds);
        } else {
            timer_label.text = default_text;
        }
    }

    update_timer_label_from_time_remaining(next_event_at, ($("#EventTimer") as LabelPanel), "IN PROGRESS");
    update_timer_label_from_time_remaining(big_eggs_hatch_at, ($("#BigEggHatchTimer") as LabelPanel), "HATCHED");

    if (next_event_at > big_eggs_hatch_at) {
        ($("#EventTimer") as LabelPanel).text = "OVER";
    }
}

function schedule_periodic_timer_update() {
    update_timer_periodically();
}

function init_event_timer() {
    $.Msg("Initializing event timer...");

    schedule_periodic_timer_update();
    subscribe_to_net_table_key_and_update_immediately("events", "timers", update_event_timers);

    $.Msg("... Done!");
}

init_event_timer();