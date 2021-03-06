const slot_panels_by_team: { [team: number]: Slot_Panel[] } = {};
const TOTAL_SLOTS = 14;

function update_big_egg_status(egg_state_by_team_id: { [team_id: number]: Stored_Greevil }) {
    for (const team_id in egg_state_by_team_id) {
        const big_egg_state = egg_state_by_team_id[team_id];
        const team_slot_panels = slot_panels_by_team[team_id];

        if (!team_slot_panels) {
            throw "Unknown team: " + team_id;
        }

        let slot_index = 0;

        for (let seal_index in big_egg_state.primal_seals) {
            const primal_seal = big_egg_state.primal_seals[seal_index];

            if (primal_seal) {
                update_seal_slot_panel_from_seal_type_and_seal(team_slot_panels[slot_index], Seal_Type.PRIMAL, primal_seal.seal, primal_seal.level);
            } else {
                update_seal_slot_panel_from_seal_type_and_seal(team_slot_panels[slot_index], Seal_Type.PRIMAL);
            }

            slot_index++;
        }

        for (let seal_index in big_egg_state.greater_seals) {
            const greater_seal = big_egg_state.greater_seals[seal_index];

            if (greater_seal) {
                update_seal_slot_panel_from_seal_type_and_seal(team_slot_panels[slot_index], Seal_Type.GREATER, greater_seal.seal, greater_seal.level);
            } else {
                update_seal_slot_panel_from_seal_type_and_seal(team_slot_panels[slot_index], Seal_Type.GREATER);
            }

            slot_index++;
        }

        for (let seal_index in big_egg_state.lesser_seals) {
            const lesser_seal = big_egg_state.lesser_seals[seal_index];

            if (lesser_seal) {
                update_seal_slot_panel_from_seal_type_and_seal(team_slot_panels[slot_index], Seal_Type.LESSER, lesser_seal.seal, lesser_seal.level);
            } else {
                update_seal_slot_panel_from_seal_type_and_seal(team_slot_panels[slot_index], Seal_Type.LESSER);
            }

            slot_index++;
        }
    }
}

function fill_mega_greevil_slot_panels(team: DOTATeam_t, parent_panel: Panel) {
    slot_panels_by_team[team] = [];

    for (let slot_index = 0; slot_index < TOTAL_SLOTS; slot_index++) {
        slot_panels_by_team[team][slot_index] = make_slot_panel(parent_panel);
        slot_panels_by_team[team][slot_index].panel.SetHasClass("Empty", true);
    }
}

function init_big_egg_status() {
    $.Msg("Initializing big egg status...");

    fill_mega_greevil_slot_panels(DOTATeam_t.DOTA_TEAM_GOODGUYS, $("#LeftTeamContainer"));
    fill_mega_greevil_slot_panels(DOTATeam_t.DOTA_TEAM_BADGUYS, $("#RightTeamContainer"));

    subscribe_to_net_table_key_and_update_immediately("eggs", "state", update_big_egg_status);
}

init_big_egg_status();