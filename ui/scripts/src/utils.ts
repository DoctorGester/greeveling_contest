function subscribe_to_net_table_key_and_update_immediately(table_name: string, table_key: string, callback: (value: any) => void) {
    const listener = CustomNetTables.SubscribeNetTableListener(table_name, function(unused_table_name, received_key, received_data){
        if (table_key == received_key){
            if (!received_data) {
                return;
            }

            callback(received_data);
        }
    });

    const immediate_data = CustomNetTables.GetTableValue(table_name, table_key);

    if (immediate_data) {
        callback(immediate_data);
    }

    return listener;
}

declare type Timer_Callback = (minutes: number, seconds: number, timer_label: LabelPanel) => any;

function update_timer_label_from_time_remaining(event_time: number, timer_label: LabelPanel, default_text: string, on_time_change?: Timer_Callback) {
    const delta_time = Math.floor(event_time - Game.GetGameTime());

    if (delta_time > 0) {
        const minutes = Math.floor(delta_time / 60);
        const seconds = delta_time % 60;

        const left_pad = (numbers: number) => {
            return (new Array(3).join('0') + numbers).slice(-2);
        };

        const new_timer_text = left_pad(minutes) + ':' + left_pad(seconds);

        if (on_time_change && new_timer_text != timer_label.text) {
            on_time_change(minutes, seconds, timer_label);
        }

        timer_label.text = new_timer_text;
    } else {
        timer_label.text = default_text;
    }
}