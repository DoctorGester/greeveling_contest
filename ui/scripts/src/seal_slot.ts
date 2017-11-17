class Slot_Panel {
    panel: Panel;
    image_panel: ImagePanel;
    level_text: LabelPanel;

    last_seal_level?: number;
    last_seal_type?: Seal_Type;
    last_seal?: number;
}

function update_seal_slot_panel_from_seal_type_and_seal(slot_panel: Slot_Panel, seal_type?: Seal_Type, seal?: number, level?: number) {
    slot_panel.panel.SetHasClass("Primal", seal_type == Seal_Type.PRIMAL);
    slot_panel.panel.SetHasClass("Greater", seal_type == Seal_Type.GREATER);
    slot_panel.panel.SetHasClass("Lesser", seal_type == Seal_Type.LESSER);
    slot_panel.panel.SetHasClass("Empty", seal_type == undefined && seal == undefined);
    slot_panel.panel.SetHasClass("LevelOne", level == undefined || level <= 1);

    if (slot_panel.last_seal != seal || slot_panel.last_seal_type != seal_type) {
        slot_panel.panel.AddClass("Appear");

        $.Schedule(0.1, () => slot_panel.panel.SetHasClass("Appear", false));
    }

    slot_panel.last_seal_type = seal_type;
    slot_panel.last_seal = seal;
    slot_panel.last_seal_level = level;
    slot_panel.panel.enabled = seal_type != undefined && seal != undefined;

    if (level != undefined) {
        slot_panel.level_text.text = level.toString(10);
    }

    if (seal_type == undefined || seal == undefined) {
        slot_panel.image_panel.SetImage("");
        return;
    }

    switch (seal_type) {
        case Seal_Type.PRIMAL: {
            slot_panel.image_panel.SetImage(convert_primal_seal_type_to_slot_image_url(seal));
            break;
        }

        case Seal_Type.GREATER: {
            slot_panel.image_panel.SetImage(convert_greater_seal_type_to_slot_image_url(seal));
            break;
        }

        case Seal_Type.LESSER: {
            slot_panel.image_panel.SetImage(convert_lesser_seal_type_to_slot_image_url(seal));
            break;
        }
    }
}

function convert_lesser_seal_type_to_slot_image_url(seal_type: Lesser_Seal_Type) {
    const attributes_folder = "file://{images}/primary_attribute_icons/";

    switch (seal_type) {
        case Lesser_Seal_Type.ABILITY_LEVEL: return attributes_folder + "primary_attribute_icon_intelligence.psd";
        case Lesser_Seal_Type.ARMOR: return "file://{images}/custom_game/armor.png";
        case Lesser_Seal_Type.ATTACK_SPEED: return attributes_folder + "primary_attribute_icon_agility.psd";
        case Lesser_Seal_Type.COOLDOWN_REDUCTION: return "file://{images}/custom_game/cooldown_reduction.png";
        case Lesser_Seal_Type.DAMAGE: return attributes_folder + "primary_attribute_icon_strength.psd";
        case Lesser_Seal_Type.HEALTH: return "file://{images}/custom_game/health.png";
        default: {
            throw "Unrecognized Lesser Seal Type " + seal_type;
        }
    }
}

function convert_greater_seal_type_to_slot_image_url(seal_type: Greater_Seal_Type) {
    const base_folder = "file://{images}/spellicons/";

    switch (seal_type) {
        case Greater_Seal_Type.SOUL_BIND: return base_folder + "wisp_tether.png";
        case Greater_Seal_Type.GREEVIL_PINATA: return base_folder + "roshan_halloween_candy.png";
        case Greater_Seal_Type.HEALING_FRENZY: return base_folder + "troll_warlord_fervor.png";
        case Greater_Seal_Type.TOGETHER_WE_STAND: return base_folder + "pangolier_shield_crash.png";
        case Greater_Seal_Type.STATIC_DISCHARGE: return base_folder + "disruptor_thunder_strike.png";
        case Greater_Seal_Type.HEAL_LA_KILL: return base_folder + "omniknight_repel.png";
        case Greater_Seal_Type.MAGIC_WELL: return base_folder + "invoker_alacrity.png";
        default: {
            throw "Unrecognized Greater Seal Type " + seal_type;
        }
    }
}

function convert_primal_seal_type_to_slot_image_url(seal_type: Primal_Seal_Type) {
    switch (seal_type) {
        case Primal_Seal_Type.ORANGE: return "file://{images}/spellicons/black_dragon_fireball.png";
        case Primal_Seal_Type.WHITE: return "file://{images}/spellicons/keeper_of_the_light_illuminate.png";
        case Primal_Seal_Type.GREEN: return "file://{images}/spellicons/furion_teleportation.png";
        case Primal_Seal_Type.BLUE: return "file://{images}/spellicons/filler_ability.png";
        case Primal_Seal_Type.PURPLE: return "file://{images}/spellicons/spectre_spectral_dagger.png";
        case Primal_Seal_Type.YELLOW: return "file://{images}/spellicons/omniknight_purification.png";
        case Primal_Seal_Type.BLACK: return "file://{images}/spellicons/batrider_sticky_napalm.png";
        case Primal_Seal_Type.RED: return "file://{images}/spellicons/bloodseeker_blood_bath.png";
        default: {
            throw "Unrecognized Lesser Seal Type " + seal_type;
        }
    }
}

function convert_primal_seal_type_to_ability_name(seal_type: Primal_Seal_Type) {
    switch (seal_type) {
        case Primal_Seal_Type.ORANGE: return "ability_primal_orange";
        case Primal_Seal_Type.WHITE: return "ability_primal_white";
        case Primal_Seal_Type.GREEN: return "ability_primal_green";
        case Primal_Seal_Type.BLUE: return "ability_primal_blue";
        // case Primal_Seal_Type.PURPLE: return base_folder + "greevil_egg_purple.png";
        case Primal_Seal_Type.YELLOW: return "ability_primal_yellow";
        case Primal_Seal_Type.BLACK: return "ability_primal_black";
        case Primal_Seal_Type.RED: return "ability_primal_red";
        default: {
            throw "Unrecognized Primal Seal Type " + seal_type;
        }
    }
}

function convert_greater_seal_type_to_ability_name(seal_type: Greater_Seal_Type) {
    switch (seal_type) {
        case Greater_Seal_Type.GREEVIL_PINATA: return "ability_greevil_pinata";
        case Greater_Seal_Type.HEAL_LA_KILL: return "ability_heal_la_kill";
        case Greater_Seal_Type.HEALING_FRENZY: return "ability_healing_frenzy";
        case Greater_Seal_Type.MAGIC_WELL: return "ability_magic_well";
        case Greater_Seal_Type.SOUL_BIND: return "ability_soul_bind";
        case Greater_Seal_Type.STATIC_DISCHARGE: return "ability_static_discharge";
        case Greater_Seal_Type.TOGETHER_WE_STAND: return "ability_together_we_stand";
        default: {
            throw "Unrecognized Greater Seal Type " + seal_type;
        }
    }
}

function convert_lesser_seal_type_to_localization_token(seal_type: Lesser_Seal_Type) {
    switch (seal_type) {
        case Lesser_Seal_Type.ABILITY_LEVEL: return "ability_level";
        case Lesser_Seal_Type.ARMOR: return "armor";
        case Lesser_Seal_Type.ATTACK_SPEED: return "attack_speed";
        case Lesser_Seal_Type.COOLDOWN_REDUCTION: return "cooldown_reduction";
        case Lesser_Seal_Type.DAMAGE: return "damage";
        case Lesser_Seal_Type.HEALTH: return "health";
        default: {
            throw "Unrecognized Lesser Seal Type " + seal_type;
        }
    }
}

function display_slot_tooltip(slot_panel: Slot_Panel) {
    function dispatch_tooltip_event(ability_name: string, ability_level: number | undefined, slot_panel: Panel) {
        if (ability_level != undefined) {
            $.DispatchEvent("DOTAShowAbilityTooltipForLevel", slot_panel, ability_name, ability_level);
        } else {
            $.DispatchEvent("DOTAShowAbilityTooltip", slot_panel, ability_name);
        }
    }

    if (slot_panel.last_seal != undefined) {
        switch (slot_panel.last_seal_type) {
            case Seal_Type.PRIMAL: {
                const ability_name = convert_primal_seal_type_to_ability_name(slot_panel.last_seal);
                dispatch_tooltip_event(ability_name, slot_panel.last_seal_level, slot_panel.panel);
                break;
            }

            case Seal_Type.GREATER: {
                const ability_name = convert_greater_seal_type_to_ability_name(slot_panel.last_seal);
                dispatch_tooltip_event(ability_name, slot_panel.last_seal_level, slot_panel.panel);
                break;
            }

            case Seal_Type.LESSER: {
                const localization_token = convert_lesser_seal_type_to_localization_token(slot_panel.last_seal);
                const title = $.Localize("DOTA_Tooltip_Ability_item_lesser_" + localization_token);
                const text = $.Localize("lesser_seal_" + localization_token);

                $.DispatchEvent("DOTAShowTitleTextTooltip", slot_panel.panel, title, text);
                break;
            }

            default: {
                throw "Unknown seal type " + slot_panel.last_seal_type;
            }
        }
    }
}

function hide_slot_tooltip(slot_panel: Slot_Panel) {
    if (slot_panel.last_seal != undefined) {
        switch (slot_panel.last_seal_type) {
            case Seal_Type.PRIMAL:
            case Seal_Type.GREATER: {
                $.DispatchEvent("DOTAHideAbilityTooltip");
                break;
            }

            case Seal_Type.LESSER: {
                $.DispatchEvent("DOTAHideTitleTextTooltip");
                break;
            }

            default: {
                throw "Unknown seal type " + slot_panel.last_seal_type;
            }
        }
    }
}

function make_slot_panel(container: Panel) {
    const slot_panel: Slot_Panel = new Slot_Panel();
    const top_level_panel = $.CreatePanel("Button", container, "");
    top_level_panel.AddClass("SealPanel");
    top_level_panel.SetPanelEvent("onmouseover", () => display_slot_tooltip(slot_panel));
    top_level_panel.SetPanelEvent("onmouseout", () => hide_slot_tooltip(slot_panel));

    const slot_content = $.CreatePanel("Panel", top_level_panel, "");
    slot_content.AddClass("SealContent");

    const slot_level_container = $.CreatePanel("Panel", top_level_panel, "");
    slot_level_container.AddClass("SealLevelContainer");

    const slot_level_text = $.CreatePanel("Label", slot_level_container, "");
    slot_level_text.AddClass("SealLevelText");

    const slot_overlay = $.CreatePanel("Panel", top_level_panel, "");
    slot_overlay.AddClass("SealOverlay");

    const slot_image = $.CreatePanel("Image", slot_content, "");

    slot_panel.panel = top_level_panel;
    slot_panel.image_panel = slot_image;
    slot_panel.level_text = slot_level_text;

    return slot_panel;
}