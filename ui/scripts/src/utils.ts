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