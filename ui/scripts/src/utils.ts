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