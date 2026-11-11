-- ============================================================================
-- Body Accessories — Cherax port
-- Based on the Stand script "Body Accessories" v1.0.0
-- Attaches cosmetic props to your own character (72 props)
-- Multi-slot placement, saved configs, EN/FR interface
-- 100% local and cosmetic — no stats written, no other players affected
-- ============================================================================

local J   = Utils.Joaat
local IV  = Natives.InvokeVoid
local IB  = Natives.InvokeBool
local II  = Natives.InvokeInt
local IV3 = Natives.InvokeV3

local H_PLAYER_PED_ID       = 0xD80958FC74E988A6
local H_GET_ENTITY_COORDS   = 0x3FEF770D40960D5A
local H_REQUEST_MODEL       = 0x963D27A58DF860AC
local H_HAS_MODEL_LOADED    = 0x98A4EB5D89A0C952
local H_MODEL_NO_LONGER     = 0xE532F5D78798DAAB
local H_ATTACH_ENTITY       = 0x6B9BBD38AB0796DF
local H_DETACH_ENTITY       = 0x961AC54BF0613F5D
local H_GET_PED_BONE_INDEX  = 0x3F428D08BE5AAE31
local H_DOES_ENTITY_EXIST   = 0x7239B21A38F536BA
local H_DELETE_OBJECT       = 0x539E0AE3E6634B9F
local H_SET_AS_MISSION_ENT  = 0xAD738C3085FE7E11
local H_NET_HAS_CONTROL     = 0x01BF60A500E28887
local H_NET_REQUEST_CONTROL = 0xB69317BF5E782347
local H_NET_GET_NET_ID      = 0xA11700682F3AD45C
local H_SET_NET_ID_EXISTS_ALL  = 0xE05E81A888FA63C8
local H_SET_NET_ID_CAN_MIGRATE = 0x299EEB23175895FC
local H_SET_ENTITY_COORDS_NC = 0x239A3351AC1DA385
local H_SET_ENTITY_VISIBLE  = 0xEA1C610A04DB6BBB
local H_SET_ENTITY_COLLISION = 0x1A9205C1B9EE827F

-- ============================================================================
-- LANGUAGE
-- ============================================================================
local LANG  = "en"
local LANGS = { "en", "fr" }

local STR = {
    en = {
        tab              = "Body Accessories",
        category         = "Category",
        cat_desc         = "Pick a prop category",
        settings         = "Settings",
        settings_desc    = "Language and saved configs",
        accessories      = "Accessories",
        remove_all       = "Remove all props",
        remove_all_desc  = "Detaches every attached prop",
        real_delete      = "Real deletion (unstable)",
        real_delete_desc = "Off: props are hidden (safe). On: attempts DELETE_OBJECT, which may crash the game.",
        slot             = "Slot",
        slot_desc        = "Where the next prop you enable will be placed",
        attached_count   = "Attached props: ",
        empty            = "empty",
        model            = "Model: ",
        placed_on_slot   = "  |  placed on the slot selected above",
        ped_not_found    = "Ped not found",
        model_not_found  = "Model not found: ",
        pos_not_found    = "Position not found",
        spawn_failed     = "Spawn failed",
        attached         = " attached",
        removed          = " removed",
        no_props         = "No props attached",
        props_available  = " props available",
        language         = "Language",
        language_desc    = "Interface language",
        config_name      = "Config name",
        config_name_desc = "Name used when saving the current setup",
        save_config      = "Save config",
        save_config_desc = "Saves every prop currently attached, with its slot",
        saved_configs    = "Saved configs",
        saved_desc       = "Pick a saved config",
        load_config      = "Load config",
        load_config_desc = "Removes current props and applies the selected config",
        delete_config    = "Delete config",
        delete_desc      = "Deletes the selected config file",
        refresh_configs  = "Refresh list",
        refresh_desc     = "Reloads the list of saved configs",
        saved_ok         = "Config saved: ",
        save_empty       = "Nothing attached — nothing to save",
        save_noname      = "Enter a config name first",
        loaded_ok        = "Config loaded: ",
        load_fail        = "Could not read that config",
        deleted_ok       = "Config deleted: ",
        no_config        = "No saved config",
        configs_found    = " config(s) found",
        folder           = "Folder: ",
        -- slot labels
        left_shoulder    = "left shoulder",
        right_shoulder   = "right shoulder",
        head             = "head",
        back             = "back",
        belly            = "belly",
    },
    fr = {
        tab              = "Body Accessories",
        category         = "Categorie",
        cat_desc         = "Choisir la categorie de props",
        settings         = "Parametres",
        settings_desc    = "Langue et configs enregistrees",
        accessories      = "Accessoires",
        remove_all       = "Retirer tous les props",
        remove_all_desc  = "Detache tous les props attaches",
        real_delete      = "Suppression reelle (instable)",
        real_delete_desc = "Desactive : les props sont masques (sans risque). Active : tente DELETE_OBJECT, qui peut faire crasher le jeu.",
        slot             = "Emplacement",
        slot_desc        = "Ou placer le prochain prop que tu coches",
        attached_count   = "Props attaches : ",
        empty            = "libre",
        model            = "Modele : ",
        placed_on_slot   = "  |  place sur l'emplacement selectionne ci-dessus",
        ped_not_found    = "Ped introuvable",
        model_not_found  = "Modele introuvable : ",
        pos_not_found    = "Position introuvable",
        spawn_failed     = "Echec du spawn",
        attached         = " attache",
        removed          = " retire",
        no_props         = "Aucun prop attache",
        props_available  = " props disponibles",
        language         = "Langue",
        language_desc    = "Langue de l'interface",
        config_name      = "Nom de la config",
        config_name_desc = "Nom utilise pour enregistrer la tenue actuelle",
        save_config      = "Enregistrer la config",
        save_config_desc = "Enregistre tous les props portes, avec leur emplacement",
        saved_configs    = "Configs enregistrees",
        saved_desc       = "Choisir une config enregistree",
        load_config      = "Charger la config",
        load_config_desc = "Retire les props actuels et applique la config choisie",
        delete_config    = "Supprimer la config",
        delete_desc      = "Supprime le fichier de la config choisie",
        refresh_configs  = "Actualiser la liste",
        refresh_desc     = "Recharge la liste des configs enregistrees",
        saved_ok         = "Config enregistree : ",
        save_empty       = "Rien d'attache — rien a enregistrer",
        save_noname      = "Entre d'abord un nom de config",
        loaded_ok        = "Config chargee : ",
        load_fail        = "Impossible de lire cette config",
        deleted_ok       = "Config supprimee : ",
        no_config        = "Aucune config enregistree",
        configs_found    = " config(s) trouvee(s)",
        folder           = "Dossier : ",
        left_shoulder    = "epaule gauche",
        right_shoulder   = "epaule droite",
        head             = "tete",
        back             = "dos",
        belly            = "ventre",
    },
}

local function T(key)
    local t = STR[LANG] or STR.en
    return t[key] or (STR.en[key] or key)
end

local CAT_PROP = {
    { name = "Backpack1", model = "sf_prop_sf_backpack_03a", bone = 24818, off = { 0.07, -0.11, -0.05, 0.0, 90.0, 175.0 } },
    { name = "Backpack2", model = "p_michael_backpack_s", bone = 24818, off = { 0.07, -0.11, -0.05, 0.0, 90.0, 175.0 } },
    { name = "Wings", model = "vw_prop_art_wings_01a", bone = 24818, off = { -1.4, -0.2, 0.0, 0.0, 90.0, 175.0 } },
    { name = "Backpack3", model = "xm3_prop_xm3_backpack_01a", bone = 24817, off = { 0.150, -0.2, 0.0, 65.0, 90.0, 10.0 } },
    { name = "Guitar", model = "sf_prop_sf_guitar_case_01a", bone = 24817, off = { -0.05, -0.09, 0.0, 90.0, 90.0, 0.0 } },
    { name = "Shield", model = "prop_ballistic_shield", bone = 24817, off = { 0.20, 0.25, 0.0, 180.0, 270.0, 0.0 } },
    { name = "Golf Bag", model = "sf_prop_sf_golf_bag_01b", bone = 24817, off = { 0.0, -0.3, 0.0, 0.0, 90.0, 0.0 } },
    { name = "Tennis Bag", model = "prop_tennis_bag_01", bone = 24817, off = { 0.1, -0.25, 0.0, 0.0, 180.0, 0.0 } },
    { name = "SurfBoard", model = "prop_surf_board_ldn_02", bone = 24817, off = { 0.5, -0.2, 0.0, 0.0, 90.0, 0.0 } },
}

local CAT_DUFFEL = {
    { name = "Duffel Bag Blue", model = "ch_p_m_bag_var01_arm_s", bone = 24817, off = { -0.19, -0.01, 0.0, 0.0, 90.0, 180.0 } },
    { name = "Duffel Bag Brown", model = "ch_p_m_bag_var10_arm_s", bone = 24817, off = { -0.19, -0.01, 0.0, 0.0, 90.0, 180.0 } },
    { name = "Duffel Bag Black", model = "h4_p_h4_m_bag_var22_arm_s", bone = 24817, off = { -0.19, -0.01, 0.0, 0.0, 90.0, 180.0 } },
    { name = "Duffel Camo Blue", model = "ch_p_m_bag_var08_arm_s", bone = 24817, off = { -0.19, -0.01, 0.0, 0.0, 90.0, 180.0 } },
    { name = "Duffel Dark Green", model = "p_ld_heist_bag_s_pro2_s", bone = 24817, off = { -0.08, -0.18, 0.0, 0.0, 90.0, 180.0 } },
    { name = "Duffel Camo Brown", model = "ch_p_m_bag_var06_arm_s", bone = 24817, off = { -0.19, -0.01, 0.0, 0.0, 90.0, 180.0 } },
    { name = "Duffel Gold", model = "xm3_p_xm3_m_bag_var22_arm_s", bone = 24817, off = { -0.19, -0.01, 0.0, 0.0, 90.0, 180.0 } },
    { name = "Duffel Bag Red", model = "ch_p_m_bag_var03_arm_s", bone = 24817, off = { -0.19, -0.01, 0.0, 0.0, 90.0, 180.0 } },
    { name = "Duffel Red Blue", model = "ch_p_m_bag_var04_arm_s", bone = 24817, off = { -0.19, -0.01, 0.0, 0.0, 90.0, 180.0 } },
    { name = "Duffel Camo", model = "ch_p_m_bag_var07_arm_s", bone = 24817, off = { -0.19, -0.01, 0.0, 0.0, 90.0, 180.0 } },
    { name = "Duffel Bag Green", model = "m23_2_p_m32_m_bag_var22_arm_s_g", bone = 24817, off = { -0.19, -0.01, 0.0, 0.0, 90.0, 180.0 } },
    { name = "Duffel Camo Green", model = "ch_p_m_bag_var09_arm_s", bone = 24817, off = { -0.19, -0.01, 0.0, 0.0, 90.0, 180.0 } },
}

local CAT_PLUSHIE = {
    { name = "Plushie Purple Cat", model = "sum_prop_sum_arcade_plush_01a", bone = 24818, off = { 0.25, 0.0, 0.22, 0.0, 90.0, 180.0 } },
    { name = "Plushie Green Cat", model = "sum_prop_sum_arcade_plush_02a", bone = 24818, off = { 0.25, 0.0, 0.22, 0.0, 90.0, 180.0 } },
    { name = "Plushie Blue Cat", model = "sum_prop_sum_arcade_plush_03a", bone = 24818, off = { 0.25, 0.0, 0.22, 0.0, 90.0, 180.0 } },
    { name = "Plushie Brown Cat", model = "sum_prop_sum_arcade_plush_04a", bone = 24818, off = { 0.25, 0.0, 0.22, 0.0, 90.0, 180.0 } },
    { name = "Plushie Yellow Cat", model = "sum_prop_sum_arcade_plush_05a", bone = 24818, off = { 0.25, 0.0, 0.22, 0.0, 90.0, 180.0 } },
    { name = "Plushie Red Cat", model = "sum_prop_sum_arcade_plush_06a", bone = 24818, off = { 0.25, 0.0, 0.22, 0.0, 90.0, 180.0 } },
    { name = "Plushie Princess", model = "sum_prop_sum_arcade_plush_07a", bone = 24818, off = { 0.25, 0.0, 0.22, 0.0, 90.0, 180.0 } },
    { name = "Plushie Wasabi Cat", model = "sum_prop_sum_arcade_plush_08a", bone = 24818, off = { 0.25, 0.0, 0.22, 0.0, 90.0, 180.0 } },
    { name = "Plushie Sensei", model = "sum_prop_sum_arcade_plush_09a", bone = 24818, off = { 0.25, 0.0, 0.22, 0.0, 90.0, 180.0 } },
    { name = "Bobble Head Green", model = "sf_prop_sf_art_bobble_bb_01b", bone = 24818, off = { 0.25, 0.0, 0.22, 0.0, 90.0, 180.0 } },
    { name = "Bobble Head Purple", model = "sf_prop_sf_art_bobble_bb_01a", bone = 24818, off = { 0.25, 0.0, 0.22, 0.0, 90.0, 180.0 } },
}

local CAT_PLUSHIEPACK = {
    { name = "Backpack Purple Cat", model = "ch_prop_arcade_claw_plush_01a", bone = 24817, off = { 0.19, -0.15, 0.0, 0.0, 90.0, 0.0 } },
    { name = "Backpack Green Cat", model = "ch_prop_arcade_claw_plush_02a", bone = 24817, off = { 0.19, -0.15, 0.0, 0.0, 90.0, 0.0 } },
    { name = "Backpack Blue Cat", model = "ch_prop_arcade_claw_plush_03a", bone = 24817, off = { 0.19, -0.15, 0.0, 0.0, 90.0, 0.0 } },
    { name = "Backpack Brown Cat", model = "ch_prop_arcade_claw_plush_04a", bone = 24817, off = { 0.19, -0.15, 0.0, 0.0, 90.0, 0.0 } },
    { name = "Backpack Yellow Cat", model = "ch_prop_arcade_claw_plush_05a", bone = 24817, off = { 0.19, -0.15, 0.0, 0.0, 90.0, 0.0 } },
    { name = "Backpack Red Cat", model = "ch_prop_arcade_claw_plush_06a", bone = 24817, off = { 0.19, -0.15, 0.0, 0.0, 90.0, 0.0 } },
    { name = "Backpack Princess", model = "ch_prop_princess_robo_plush_07a", bone = 24817, off = { 0.19, -0.15, 0.0, 0.0, 90.0, 0.0 } },
    { name = "Backpack Wasabi Cat", model = "ch_prop_shiny_wasabi_plush_08a", bone = 24817, off = { 0.19, -0.15, 0.0, 0.0, 90.0, 0.0 } },
    { name = "Backpack Space Ranger", model = "xs_prop_trinket_republican_01a", bone = 24817, off = { -0.0, -0.25, 0.0, 0.0, 90.0, 0.0 } },
    { name = "Backpack Princess Figure", model = "vw_prop_vw_colle_prbubble", bone = 24817, off = { 0.0, -0.2, 0.0, 0.0, 90.0, 0.0 } },
}

local CAT_WEAPON = {
    { name = "Weapon Katana Left", model = "prop_cs_katana_01", bone = 24817, off = { 0.5, -0.12, 0.14, 5.0, -122.0, 0.0 } },
    { name = "Weapon Katana Right", model = "prop_cs_katana_01", bone = 24817, off = { 0.5, -0.18, -0.14, 5.0, -62.0, 180.0 } },
    { name = "Weapon Bat", model = "w_me_bat", bone = 24817, off = { -0.13, -0.16, -0.14, 5.0, 62.0, 0.0 } },
    { name = "Weapon Heavy Sniper", model = "w_sr_heavysniper", bone = 24817, off = { 0.2, -0.20, 0.1, 0.0, 160.5, 0.0 } },
    { name = "Weapon Bag", model = "m23_2_prop_m32_bag_weapons_01a", bone = 24817, off = { -0.25, -0.3, 0.0, -25.0, 90.0, 0.0 } },
    { name = "Weapon Special Carbine", model = "w_ar_specialcarbine_m32", bone = 24817, off = { 0.2, -0.15, 0.0, 0.0, 150.0, 0.0 } },
    { name = "Weapon Carbine Rifle", model = "w_ar_carbinerifle_m31", bone = 24817, off = { 0.2, -0.15, 0.0, 0.0, 150.0, 0.0 } },
    { name = "Weapon Assault Rifle", model = "w_ar_assaultrifle", bone = 24817, off = { 0.2, -0.15, 0.0, 0.0, 150.0, 0.0 } },
    { name = "Weapon Combat PDW", model = "w_sb_pdw", bone = 24817, off = { 0.2, -0.15, 0.0, 0.0, 150.0, 0.0 } },
    { name = "Weapon Military Rifle", model = "w_ar_bullpuprifleh4", bone = 24817, off = { 0.2, -0.15, 0.0, 0.0, 150.0, 0.0 } },
    { name = "Weapon Homing Launcher", model = "w_lr_homing", bone = 24817, off = { 0.35, -0.18, 0.0, 0.0, 0.0, 0.0 } },
    { name = "Weapon Heavy Rifle", model = "w_ar_heavyrifleh", bone = 24817, off = { 0.2, -0.15, 0.0, 0.0, 150.0, 0.0 } },
    { name = "Weapon Railgun", model = "w_ar_railgun_xm3", bone = 24817, off = { 0.2, -0.17, 0.1, 0.0, 150.0, 0.0 } },
    { name = "Weapon Assault Shotgun", model = "w_sg_assaultshotgun", bone = 24817, off = { 0.2, -0.17, 0.1, 0.0, 150.0, 0.0 } },
    { name = "Weapon Assault SMG", model = "w_sb_assaultsmg", bone = 24817, off = { 0.1, -0.15, 0.0, 0.0, 150.0, 0.0 } },
    { name = "Weapon Musket", model = "w_ar_musket", bone = 24817, off = { 0.3, -0.15, 0.1, 0.0, 150.0, 0.0 } },
    { name = "Weapon Combat MG", model = "w_mg_combatmg", bone = 24817, off = { 0.2, -0.15, 0.0, 0.0, 150.0, 0.0 } },
    { name = "Weapon Heavy Sniper MK2", model = "w_sr_heavysnipermk2", bone = 24817, off = { 0.2, -0.15, 0.0, 0.0, 150.0, 0.0 } },
    { name = "Weapon Carbine MK2", model = "w_ar_carbineriflemk2", bone = 24817, off = { 0.2, -0.15, 0.0, 0.0, 150.0, 0.0 } },
    { name = "Weapon Gusenberg", model = "w_sb_gusenberg", bone = 24817, off = { 0.2, -0.15, 0.0, 0.0, 150.0, 0.0 } },
    { name = "Weapon RPG", model = "w_lr_rpg_m31", bone = 24817, off = { 0.35, -0.18, 0.0, 0.0, 0.0, 0.0 } },
    { name = "Weapon MG", model = "w_mg_mg_luxe", bone = 24817, off = { 0.2, -0.15, 0.1, 0.0, 150.0, 0.0 } },
    { name = "Weapon Shotgun", model = "w_sg_pumpshotgun_luxe", bone = 24817, off = { 0.2, -0.15, 0.0, 0.0, 150.0, 0.0 } },
    { name = "Weapon Combat Shotgun", model = "h4_prop_h4_pumpshotgunh4", bone = 24817, off = { 0.2, -0.15, 0.0, 0.0, 150.0, 0.0 } },
    { name = "Weapon FireWork", model = "w_lr_firework", bone = 24817, off = { 0.35, -0.18, 0.0, 0.0, 0.0, 0.0 } },
    { name = "Weapon Sniper", model = "w_sr_sniperrifle_luxe", bone = 24817, off = { 0.2, -0.15, 0.0, 0.0, 150.0, 0.0 } },
    { name = "Weapon Service Carbine", model = "w_ar_carbinerifle_reh", bone = 24817, off = { 0.2, -0.15, 0.0, 0.0, 150.0, 0.0 } },
    { name = "Weapon Wrench", model = "w_me_wrench", bone = 24817, off = { -0.05, -0.15, -0.15, 0.0, 0.0, 0.0 } },
}
-- ============================================================================
-- CATEGORIES
-- ============================================================================
local BONE_HEAD = 31086

local CATEGORIES = {
    { name = "Any Prop",   list = CAT_PROP   },
    { name = "Duffel Bag", list = CAT_DUFFEL },
    {
        name = "Plushie & Figure",
        list = CAT_PLUSHIE,
        -- X = height, Y = front/back, Z = lateral. Head slot overrides the bone.
        slots = {
            { key = "left_shoulder",  off = { 0.25, 0.0,  0.22, 0.0, 90.0, 180.0 } },
            { key = "right_shoulder", off = { 0.25, 0.0, -0.22, 0.0, 90.0, 180.0 } },
            { key = "head",           off = { 0.18, 0.0,  0.0,  0.0, 90.0, 180.0 }, bone = BONE_HEAD },
        }
    },
    {
        name = "Backpack Figure",
        list = CAT_PLUSHIEPACK,
        -- Negative Y = back, positive Y = belly.
        slots = {
            { key = "back",  off = { 0.19, -0.15, 0.0, 0.0, 90.0,   0.0 } },
            { key = "belly", off = { 0.19,  0.15, 0.0, 0.0, 90.0, 180.0 } },
        }
    },
    { name = "Weapon Prop", list = CAT_WEAPON },
}


-- ============================================================================
-- STATE
-- ============================================================================
local attached    = {}
local current_cat = 1
local try_real_delete = false

local CONFIG_DIR = FileMgr.GetMenuRootPath() .. "\\Lua\\BodyAccessories"
FileMgr.CreateDir(CONFIG_DIR)

local function notify(msg)
    GUI.AddToast("Body Accessories", msg, 2500, eToastPos.BOTTOM_RIGHT)
end

local function my_ped()
    return II(H_PLAYER_PED_ID)
end

-- Finds a prop entry by name, returns entry + category index
local function find_entry(name)
    for ci, cat in ipairs(CATEGORIES) do
        for _, e in ipairs(cat.list) do
            if e.name == name then return e, ci end
        end
    end
    return nil, nil
end

-- ============================================================================
-- ATTACH
-- ============================================================================

local function attach_prop(entry, override_off, slot_index, slot_key, override_bone)
    Script.QueueJob(function()
        local ped = my_ped()
        if not ped or ped == 0 then notify(T("ped_not_found")); return end

        local mhash = J(entry.model)
        IV(H_REQUEST_MODEL, mhash)
        local t = 0
        while not IB(H_HAS_MODEL_LOADED, mhash) and t < 50 do
            Script.Yield(20); t = t + 1
        end
        if not IB(H_HAS_MODEL_LOADED, mhash) then
            notify(T("model_not_found") .. entry.model); return
        end

        local ok_pos, px, py, pz = pcall(IV3, H_GET_ENTITY_COORDS, ped, true)
        if not ok_pos or not px then notify(T("pos_not_found")); return end

        local ok_obj, prop = pcall(GTA.CreateObject, mhash, px, py, pz + 0.2, true, true)
        if not ok_obj or not prop or prop == 0 then
            notify(T("spawn_failed")); return
        end

        -- Mission entity: prevents the game's automatic cleanup
        pcall(IV, H_SET_AS_MISSION_ENT, prop, true, true)

        pcall(function()
            local nid = II(H_NET_GET_NET_ID, prop)
            if nid and nid ~= 0 then
                IV(H_SET_NET_ID_EXISTS_ALL, nid, true)
                IV(H_SET_NET_ID_CAN_MIGRATE, nid, true)
            end
        end)

        local bone_idx = II(H_GET_PED_BONE_INDEX, ped, override_bone or entry.bone)
        local o = override_off or entry.off
        pcall(IV, H_ATTACH_ENTITY, prop, ped, bone_idx,
            o[1] or 0.0, o[2] or 0.0, o[3] or 0.0,
            o[4] or 0.0, o[5] or 0.0, o[6] or 0.0,
            true, true, false, true, 1, true)

        IV(H_MODEL_NO_LONGER, mhash)

        attached[entry.name] = attached[entry.name] or { handles = {} }
        attached[entry.name].slot = slot_index
        table.insert(attached[entry.name].handles, prop)

        if slot_key then
            notify(entry.name .. " — " .. T(slot_key))
        else
            notify(entry.name .. T("attached"))
        end
    end)
end

-- ============================================================================
-- REMOVE
-- DELETE_OBJECT proved unstable in Cherax: it works sometimes and crashes the
-- game other times. Props are hidden instead of deleted by default.
-- ============================================================================

local function remove_handle(h)
    if not IB(H_DOES_ENTITY_EXIST, h) then return true end

    for _ = 1, 20 do
        if IB(H_NET_HAS_CONTROL, h) then break end
        IV(H_NET_REQUEST_CONTROL, h)
        Script.Yield(10)
    end

    pcall(IV, H_DETACH_ENTITY, h, true, true)
    Script.Yield(20)

    if try_real_delete then
        pcall(IV, H_SET_AS_MISSION_ENT, h, true, true)
        Script.Yield(10)
        pcall(IV, H_DELETE_OBJECT, h)
        Script.Yield(20)
        if not IB(H_DOES_ENTITY_EXIST, h) then return true end
    end

    pcall(function()
        local nid = II(H_NET_GET_NET_ID, h)
        if nid and nid ~= 0 then IV(H_SET_NET_ID_EXISTS_ALL, nid, false) end
    end)
    pcall(IV, H_SET_ENTITY_VISIBLE,   h, false, false)
    pcall(IV, H_SET_ENTITY_COLLISION, h, false, false)
    pcall(IV, H_SET_ENTITY_COORDS_NC, h, 0.0, 0.0, -1000.0, false, false, false)
    return false
end

local function detach_prop(label, silent)
    local data = attached[label]
    if not data then return end
    attached[label] = nil

    Script.QueueJob(function()
        for _, h in ipairs(data.handles) do
            pcall(remove_handle, h)
        end
        if not silent then notify(label .. T("removed")) end
    end)
end

local function detach_all(silent)
    local count = 0
    for label, _ in pairs(attached) do
        detach_prop(label, true)
        count = count + 1
    end
    if count == 0 and not silent then notify(T("no_props")) end
    return count
end

-- ============================================================================
-- CONFIGS (save / load)
-- Format : one line per prop -> category_index|prop_name|slot_index
-- ============================================================================

local config_list = {}   -- names, no extension

local function config_path(name)
    return CONFIG_DIR .. "\\" .. name .. ".json"
end

-- Ancien format, encore lu pour ne pas perdre les configs deja enregistrees
local function legacy_path(name)
    return CONFIG_DIR .. "\\" .. name .. ".txt"
end

local INDEX_PATH = CONFIG_DIR .. "\\_index.txt"

-- ── JSON minimal ──
-- Cherax n'expose pas de bibliotheque JSON en Lua. Nos donnees se limitent a
-- un entier, un nom et un entier, donc un encodeur/decodeur maison suffit.

local function json_escape(s)
    return tostring(s):gsub("\\", "\\\\"):gsub('"', '\\"')
end

local function json_unescape(s)
    return tostring(s):gsub('\\"', '"'):gsub("\\\\", "\\")
end

local function encode_config(entries)
    local parts = {}
    for _, e in ipairs(entries) do
        parts[#parts + 1] = string.format(
            '    { "cat": %d, "name": "%s", "slot": %d }',
            e.cat, json_escape(e.name), e.slot or 0)
    end
    return '{\n  "format": "Body Accessories",\n  "version": 1,\n  "props": [\n'
        .. table.concat(parts, ",\n") .. "\n  ]\n}"
end

-- Tolerant a l'ordre des cles et aux espaces, pour rester lisible si tu
-- modifies un fichier a la main.
local function decode_config(content)
    local entries = {}
    -- On isole d'abord le contenu du tableau "props" : sinon %b{} capturerait
    -- le document entier d'un seul bloc au lieu de chaque objet.
    local arr = tostring(content):match('"props"%s*:%s*%[(.*)%]') or tostring(content)
    for block in arr:gmatch("%b{}") do
        local cat  = block:match('"cat"%s*:%s*(%-?%d+)')
        local name = block:match('"name"%s*:%s*"(.-)"')
        local slot = block:match('"slot"%s*:%s*(%-?%d+)')
        if cat and name then
            entries[#entries + 1] = {
                cat  = tonumber(cat),
                name = json_unescape(name),
                slot = tonumber(slot) or 0,
            }
        end
    end
    return entries
end

-- Ancien format texte : cat|nom|slot
local function decode_legacy(content)
    local entries = {}
    for line in tostring(content):gmatch("[^\r\n]+") do
        local ci, label, slot = line:match("^(%d+)|(.-)|(%-?%d+)$")
        if ci and label then
            entries[#entries + 1] = {
                cat = tonumber(ci), name = label, slot = tonumber(slot) or 0
            }
        end
    end
    return entries
end

-- Index maintenu par le script : FindFiles n'etant pas fiable ici, on garde
-- notre propre liste de noms. Chaque entree est verifiee avec DoesFileExist.
local function read_index()
    local names, seen = {}, {}
    local ok, content = pcall(FileMgr.ReadFileContent, INDEX_PATH)
    if ok and content then
        for line in tostring(content):gmatch("[^\r\n]+") do
            local n = line:match("^%s*(.-)%s*$")
            if n ~= "" and not seen[n] then
                seen[n] = true
                table.insert(names, n)
            end
        end
    end
    return names, seen
end

local function write_index(names)
    pcall(FileMgr.WriteFileContent, INDEX_PATH, table.concat(names, "\n"), false)
end

local function refresh_config_list()
    config_list = {}
    local seen = {}

    -- On n'ecarte un nom que si DoesFileExist repond explicitement false.
    -- Si l'appel echoue ou renvoie autre chose, on garde l'entree : mieux
    -- vaut afficher une config fantome que perdre une config valide.
    local function add(n)
        if not n or n == "" or n == "_index" or seen[n] then return end
        -- Accepte si l'un des deux formats existe, ou si la verification echoue
        local okj, ej = pcall(FileMgr.DoesFileExist, config_path(n))
        local okt, et = pcall(FileMgr.DoesFileExist, legacy_path(n))
        if okj and ej == false and okt and et == false then return end
        seen[n] = true
        table.insert(config_list, n)
    end

    -- 1) Notre index
    for _, n in ipairs((read_index())) do add(n) end

    -- 2) FindFiles en complement : l'extension s'ecrit "json", ".json" ou
    --    "*.json" selon les versions, et le retour peut etre un chemin
    --    complet ou un simple nom.
    for _, ext in ipairs({ "json", ".json", "*.json", "txt", ".txt", "*.txt", "" }) do
        local ok, files = pcall(FileMgr.FindFiles, CONFIG_DIR, ext, false)
        if ok and files then
            for _, f in ipairs(files) do
                local path = tostring(f)
                add(path:match("([^\\/]+)%.[Jj][Ss][Oo][Nn]$")
                    or path:match("([^\\/]+)%.[Tt][Xx][Tt]$")
                    or path:match("^([^\\/%.]+)$"))
            end
        end
    end

    table.sort(config_list)
    -- Ne jamais ecraser un index rempli par une liste vide
    if #config_list > 0 then write_index(config_list) end
    return config_list
end

local function save_config(name)
    if not name or name == "" then notify(T("save_noname")); return false end

    local entries = {}
    for label, data in pairs(attached) do
        local _, ci = find_entry(label)
        if ci then
            entries[#entries + 1] = { cat = ci, name = label, slot = data.slot or 0 }
        end
    end

    if #entries == 0 then notify(T("save_empty")); return false end

    table.sort(entries, function(a, b)
        if a.cat ~= b.cat then return a.cat < b.cat end
        return a.name < b.name
    end)

    local ok = FileMgr.WriteFileContent(config_path(name), encode_config(entries), false)
    if ok then
        -- Inscrit le nom dans l'index immediatement, sans dependre du balayage
        local names, seen = read_index()
        if not seen[name] then table.insert(names, name) end
        table.sort(names)
        write_index(names)

        notify(T("saved_ok") .. name)
        refresh_config_list()
        return true
    end
    return false
end

-- load_config is defined after the slot tables exist (see below)
local load_config

local function delete_config(name)
    if not name or name == "" then return end
    pcall(FileMgr.DeleteFile, config_path(name))
    pcall(FileMgr.DeleteFile, legacy_path(name))

    -- Retire le nom de l'index, sinon il reapparaitrait au rafraichissement
    local names = read_index()
    local kept = {}
    for _, n in ipairs(names) do
        if n ~= name then table.insert(kept, n) end
    end
    write_index(kept)

    notify(T("deleted_ok") .. name)
    refresh_config_list()
end

-- ============================================================================
-- FEATURES
-- ============================================================================

local function saf(h, label, ftype, desc, cb)
    pcall(FeatureMgr.RemoveFeature, J(h))
    return FeatureMgr.AddFeature(J(h), label, ftype, desc, cb)
end

-- Every feature whose label must follow the language, with its string keys
local localized = {}
local function reg(feat, name_key, desc_key)
    localized[#localized + 1] = { f = feat, n = name_key, d = desc_key }
    return feat
end

local function category_labels()
    local t = {}
    for i, c in ipairs(CATEGORIES) do t[i] = c.name end
    return t
end

local cat_feat = reg(saf("BACategory", T("category"), eFeatureType.Combo, T("cat_desc"),
    function(f)
        local ok, i = pcall(f.GetListIndex, f)
        if ok then current_cat = i + 1 end
    end), "category", "cat_desc")
cat_feat:SetList(category_labels())
cat_feat:SetListIndex(0)

local delete_feat = reg(saf("BARealDelete", T("real_delete"), eFeatureType.Toggle,
    T("real_delete_desc"),
    function(x) try_real_delete = x:IsToggled() end), "real_delete", "real_delete_desc")
delete_feat:SetDefaultValue(false)
delete_feat:SetValue(false)

local reset_everything

local clear_feat = reg(saf("BAClearAll", T("remove_all"), eFeatureType.Button,
    T("remove_all_desc"),
    function()
        if reset_everything then reset_everything() else detach_all() end
    end), "remove_all", "remove_all_desc")

-- ── Slots ──

local slot_usage      = {}
local selected_slot   = {}
local toggles_by_name = {}

for ci, cat in ipairs(CATEGORIES) do
    if cat.slots then
        slot_usage[ci]      = {}
        selected_slot[ci]   = 1
        toggles_by_name[ci] = {}
    end
end

local slot_combos = {}
local function slot_labels(cat)
    local t = {}
    for i, s in ipairs(cat.slots) do t[i] = T(s.key) end
    return t
end

for ci, cat in ipairs(CATEGORIES) do
    if cat.slots then
        local cat_idx = ci
        local f = reg(saf("BASlotSel_" .. ci, T("slot"), eFeatureType.Combo, T("slot_desc"),
            function(x)
                local ok, i = pcall(x.GetListIndex, x)
                if ok then selected_slot[cat_idx] = i + 1 end
            end), "slot", "slot_desc")
        f:SetList(slot_labels(cat))
        f:SetListIndex(0)
        slot_combos[ci] = f
    end
end

local function free_slot(ci, label)
    local usage = slot_usage[ci]
    local cat   = CATEGORIES[ci]
    if not usage or not cat or not cat.slots then return end
    for i = 1, #cat.slots do
        if usage[i] == label then usage[i] = nil end
    end
end

-- ── One toggle per prop ──

local cat_toggles = {}
-- Metadonnees des toggles, gardees dans une table Lua : on ne peut pas
-- ajouter de champs sur un objet Feature (userdata C++), ca fait crasher.
local toggle_meta = {}

local function apply_prop(e, ci, slot_index)
    local cat = CATEGORIES[ci]
    if cat.slots then
        local target = slot_index or selected_slot[ci] or 1
        local slot = cat.slots[target]
        if not slot then return end

        local usage = slot_usage[ci]
        local occupant = usage[target]
        if occupant and occupant ~= e.name then
            usage[target] = nil
            detach_prop(occupant, true)
            local other = toggles_by_name[ci][occupant]
            if other then pcall(function() other:SetValue(false) end) end
        end

        free_slot(ci, e.name)
        usage[target] = e.name
        attach_prop(e, slot.off, target, slot.key, slot.bone)
    else
        attach_prop(e)
    end
end

for ci, cat in ipairs(CATEGORIES) do
    cat_toggles[ci] = {}
    for pi, entry in ipairs(cat.list) do
        local e       = entry
        local cat_idx = ci
        local slots   = cat.slots

        local f
        f = saf("BAProp_" .. ci .. "_" .. pi, e.name, eFeatureType.Toggle,
            T("model") .. e.model .. (slots and T("placed_on_slot") or ""),
            function(x)
                if x:IsToggled() then
                    apply_prop(e, cat_idx)
                else
                    if slots then free_slot(cat_idx, e.name) end
                    detach_prop(e.name)
                end
            end)
        f:SetDefaultValue(false)
        f:SetValue(false)
        table.insert(cat_toggles[ci], f)
        toggle_meta[ci] = toggle_meta[ci] or {}
        toggle_meta[ci][#cat_toggles[ci]] = { model = e.model, slots = (slots and true or false), name = e.name }
        if slots then toggles_by_name[ci][e.name] = f end
    end
end

-- Now that the slot tables exist, define config loading
load_config = function(name)
    if not name or name == "" then return end

    -- Essaie le JSON, puis l'ancien format texte
    local entries = nil
    local okj, cj = pcall(FileMgr.ReadFileContent, config_path(name))
    if okj and cj and cj ~= "" then
        entries = decode_config(cj)
    end
    if (not entries) or #entries == 0 then
        local okt, ct = pcall(FileMgr.ReadFileContent, legacy_path(name))
        if okt and ct and ct ~= "" then
            entries = decode_legacy(ct)
        end
    end

    if (not entries) or #entries == 0 then
        notify(T("load_fail")); return
    end

    -- Clear everything first
    detach_all(true)
    for ci, _ in pairs(slot_usage) do slot_usage[ci] = {} end
    for _, list in ipairs(cat_toggles) do
        for _, f in ipairs(list) do pcall(function() f:SetValue(false) end) end
    end

    Script.QueueJob(function()
        Script.Yield(300)
        local n = 0
        for _, item in ipairs(entries) do
            local ci, label, slot = item.cat, item.name, item.slot
            local e = find_entry(label)
            if e and ci and CATEGORIES[ci] then
                apply_prop(e, ci, (slot and slot > 0) and slot or nil)
                local tg = cat_toggles[ci]
                if tg then
                    for pi, f in ipairs(tg) do
                        local m = toggle_meta[ci] and toggle_meta[ci][pi]
                        if m and m.name == label then
                            pcall(function() f:SetValue(true) end)
                        end
                    end
                end
                n = n + 1
                Script.Yield(120)
            end
        end
        notify(T("loaded_ok") .. name .. " (" .. n .. ")")
    end)
end

reset_everything = function()
    detach_all()
    for _, list in ipairs(cat_toggles) do
        for _, f in ipairs(list) do
            pcall(function() f:SetValue(false) end)
        end
    end
    for ci, _ in pairs(slot_usage) do
        slot_usage[ci] = {}
    end
end

-- ============================================================================
-- SETTINGS TAB FEATURES
-- ============================================================================

local selected_config = 1

local lang_feat = reg(saf("BALang", T("language"), eFeatureType.Combo, T("language_desc"),
    function(f)
        local ok, i = pcall(f.GetListIndex, f)
        if ok then
            LANG = LANGS[i + 1] or "en"
            if apply_language then apply_language() end
        end
    end), "language", "language_desc")
lang_feat:SetList({ "English", "Francais" })
lang_feat:SetListIndex(0)

local name_feat = reg(saf("BAConfigName", T("config_name"), eFeatureType.InputText,
    T("config_name_desc"), nil), "config_name", "config_name_desc")
name_feat:SetStringValue("")

local save_feat = reg(saf("BASaveConfig", T("save_config"), eFeatureType.Button,
    T("save_config_desc"),
    function()
        local n = ""
        pcall(function() n = name_feat:GetStringValue() end)
        save_config(n)
    end), "save_config", "save_config_desc")

local configs_feat = reg(saf("BAConfigList", T("saved_configs"), eFeatureType.Combo,
    T("saved_desc"),
    function(f)
        local ok, i = pcall(f.GetListIndex, f)
        if ok then selected_config = i + 1 end
    end), "saved_configs", "saved_desc")

local function push_config_list()
    local list = refresh_config_list()
    if #list == 0 then list = { T("no_config") } end
    pcall(function() configs_feat:SetList(list) end)
end
push_config_list()
configs_feat:SetListIndex(0)

local load_feat = reg(saf("BALoadConfig", T("load_config"), eFeatureType.Button,
    T("load_config_desc"),
    function()
        local n = config_list[selected_config]
        if n then load_config(n) else notify(T("no_config")) end
    end), "load_config", "load_config_desc")

local del_feat = reg(saf("BADelConfig", T("delete_config"), eFeatureType.Button,
    T("delete_desc"),
    function()
        local n = config_list[selected_config]
        if n then
            delete_config(n)
            push_config_list()
            selected_config = 1
            pcall(function() configs_feat:SetListIndex(0) end)
        else
            notify(T("no_config"))
        end
    end), "delete_config", "delete_desc")

local refresh_feat = reg(saf("BARefreshConfigs", T("refresh_configs"), eFeatureType.Button,
    T("refresh_desc"),
    function()
        push_config_list()
        notify(#config_list .. T("configs_found"))
    end), "refresh_configs", "refresh_desc")

-- Sous-onglets : Accessories / Settings
-- On tente une vraie barre d'onglets ImGui ; si l'API ne repond pas comme
-- attendu dans ClickGUI, on retombe sur un combo (methode deja validee).
local current_sub = 1
local tabbar_ok   = nil

local sub_feat = reg(saf("BASubTab", T("settings"), eFeatureType.Combo,
    T("settings_desc"),
    function(x)
        local ok, i = pcall(x.GetListIndex, x)
        if ok then current_sub = i + 1 end
    end), "settings", "settings_desc")
sub_feat:SetList({ T("accessories"), T("settings") })
sub_feat:SetListIndex(0)

-- Re-applies every label when the language changes
function apply_language()
    for _, item in ipairs(localized) do
        pcall(function()
            if item.n then item.f:SetName(T(item.n)) end
            if item.d then item.f:SetDesc(T(item.d)) end
        end)
    end
    -- Prop toggles : only the description is translated
    for ci, list in ipairs(cat_toggles) do
        for pi, f in ipairs(list) do
            local m = toggle_meta[ci] and toggle_meta[ci][pi]
            if m then
                pcall(function()
                    f:SetDesc(T("model") .. tostring(m.model) ..
                        (m.slots and T("placed_on_slot") or ""))
                end)
            end
        end
    end
    -- Combos whose entries are translated
    pcall(function() cat_feat:SetList(category_labels()) end)
    pcall(function() sub_feat:SetList({ T("accessories"), T("settings") }) end)
    for ci, cat in ipairs(CATEGORIES) do
        if cat.slots and slot_combos[ci] then
            pcall(function() slot_combos[ci]:SetList(slot_labels(cat)) end)
        end
    end
    push_config_list()
end

-- ============================================================================
-- GUI
-- ============================================================================

local function render_settings()
    if ClickGUI.BeginCustomChildWindow(T("settings")) then
        ClickGUI.RenderFeature(lang_feat:GetHash())
        ClickGUI.RenderFeature(delete_feat:GetHash())
    end
    ClickGUI.EndCustomChildWindow()

    if ClickGUI.BeginCustomChildWindow(T("save_config")) then
        ClickGUI.RenderFeature(name_feat:GetHash())
        ClickGUI.RenderFeature(save_feat:GetHash())
    end
    ClickGUI.EndCustomChildWindow()

    if ClickGUI.BeginCustomChildWindow(T("saved_configs")) then
        ClickGUI.RenderFeature(configs_feat:GetHash())
        ClickGUI.RenderFeature(load_feat:GetHash())
        ClickGUI.RenderFeature(del_feat:GetHash())
        ClickGUI.RenderFeature(refresh_feat:GetHash())
        pcall(function()
            ImGui.Text(T("folder") .. CONFIG_DIR)
        end)
    end
    ClickGUI.EndCustomChildWindow()
end

-- Vue Accessoires
local function render_accessories()
    if ClickGUI.BeginCustomChildWindow("Body Accessories") then
        ClickGUI.RenderFeature(cat_feat:GetHash())
        ClickGUI.RenderFeature(clear_feat:GetHash())
        pcall(function()
            local n = 0
            for _ in pairs(attached) do n = n + 1 end
            ImGui.Text(T("attached_count") .. tostring(n))
        end)
    end
    ClickGUI.EndCustomChildWindow()

    local cat = CATEGORIES[current_cat]
    if not cat then return end

    if ClickGUI.BeginCustomChildWindow(cat.name .. "  (" .. #cat.list .. ")") then
        if cat.slots then
            if slot_combos[current_cat] then
                ClickGUI.RenderFeature(slot_combos[current_cat]:GetHash())
            end
            pcall(function()
                local usage = slot_usage[current_cat] or {}
                local sel   = selected_slot[current_cat] or 1
                for i, s in ipairs(cat.slots) do
                    local mark = (i == sel) and " <" or ""
                    ImGui.Text(T(s.key) .. ": " .. (usage[i] or T("empty")) .. mark)
                end
            end)
        end
        for _, f in ipairs(cat_toggles[current_cat]) do
            ClickGUI.RenderFeature(f:GetHash())
        end
    end
    ClickGUI.EndCustomChildWindow()
end

local SUB_DRAW = { render_accessories, render_settings }

local function render_tab()
    -- 1) Vraie barre d'onglets, facon BunnyScript
    if tabbar_ok ~= false then
        local ok_bar, opened = pcall(ImGui.BeginTabBar, "BodyAccessoriesTabs")
        if ok_bar and opened then
            tabbar_ok = true
            local names = { T("accessories"), T("settings") }
            for i = 1, 2 do
                local ok_item, item_open = pcall(ImGui.BeginTabItem, names[i])
                if ok_item and item_open then
                    current_sub = i
                    SUB_DRAW[i]()
                    pcall(ImGui.EndTabItem)
                end
            end
            pcall(ImGui.EndTabBar)
            return
        elseif not ok_bar then
            tabbar_ok = false
        end
    end

    -- 2) Repli : selecteur en liste deroulante
    if ClickGUI.BeginCustomChildWindow("Body Accessories") then
        ClickGUI.RenderFeature(sub_feat:GetHash())
    end
    ClickGUI.EndCustomChildWindow()

    local draw = SUB_DRAW[current_sub]
    if draw then draw() end
end

pcall(ClickGUI.RemoveTab, "Body Accessories")
ClickGUI.AddTab("Body Accessories", render_tab)

local total = 0
for _, c in ipairs(CATEGORIES) do total = total + #c.list end

Logger.LogInfo("Body Accessories loaded — " .. total .. " props")
notify(total .. T("props_available"))

Script.RegisterLooped(function()
    if ShouldUnload() then
        for _, data in pairs(attached) do
            for _, h in ipairs(data.handles) do
                pcall(remove_handle, h)
            end
        end
        attached = {}
        return
    end
    Script.Yield(500)
end)
