// Upstream body hotspots: shoulders 3/4, hips 5/6, torso 8/9.
// Keep the engine's named fields so its existing holster rendering and climbing arbitration work.
void(float hand, float delay, float duration, float frequency, float amplitude) haptic = #0;
.entity mvr_holsters[6];
.float holsterweapon0, holsterweapon1, holsterweapon2, holsterweapon3, holsterweapon4, holsterweapon5;
.string holsterweaponmodel0, holsterweaponmodel1, holsterweaponmodel2, holsterweaponmodel3, holsterweaponmodel4, holsterweaponmodel5;
.float mvr_hover_main, mvr_hover_off, mvr_holster_used, mvr_drawing;
.entity mvr_offweapon;

float(float hotspot) MVR_HolsterIndex =
{
    if (hotspot >= 3 && hotspot <= 6) return hotspot-3;
    if (hotspot == 8 || hotspot == 9) return hotspot-4;
    return -1;
}

void(float slot) MVR_SyncHolster =
{
    entity gun = self.mvr_holsters[slot];
    float id = gun ? gun.weapon : 0;
    string mdl = gun ? gun.weaponmodel : string_null;
    if (slot == 0) { self.holsterweapon0 = id; self.holsterweaponmodel0 = mdl; }
    if (slot == 1) { self.holsterweapon1 = id; self.holsterweaponmodel1 = mdl; }
    if (slot == 2) { self.holsterweapon2 = id; self.holsterweaponmodel2 = mdl; }
    if (slot == 3) { self.holsterweapon3 = id; self.holsterweaponmodel3 = mdl; }
    if (slot == 4) { self.holsterweapon4 = id; self.holsterweaponmodel4 = mdl; }
    if (slot == 5) { self.holsterweapon5 = id; self.holsterweaponmodel5 = mdl; }
}

float(float id) MVR_WeaponStored =
{
    if (self.mvr_drawing || id == IT_NO_WEAPON) return FALSE;
    if (id == IT_NAILGUN && self.nail_main) return FALSE;
    if (id == IT_NAILGUN && self.nail_off) return TRUE;
    if (self.mvr_offweapon && self.mvr_offweapon.weapon == id) return TRUE;
    for (float i = 0; i < 6; i += 1)
        if (self.mvr_holsters[i] && self.mvr_holsters[i].weapon == id) return TRUE;
    return FALSE;
}

void(float hand) MVR_HolsterBuzz =
{
    float mode = cvar("vr_holster_haptics");
    if (mode == 1) haptic(hand, 0, 0.1, 75, 0.02);
    if (mode == 2) {
        float t = max(0.05, cvar("vr_holster_haptic_time"));
        haptic(hand, 0, t*0.45, 80, 0.65);
        haptic(hand, t*0.4, t*0.35, 80, 0.4);
        haptic(hand, t*0.7, t*0.3, 80, 0.2);
    }
}

void(float off, entity gun) MVR_HolsterEquip =
{
    if (off) {
        self.weapon2 = gun.weapon;
        self.weaponmodel2 = gun.weaponmodel;
        self.weaponframe2 = gun.frame;
        if (gun.weapon == IT_NAILGUN) self.nail_off = gun;
        else self.mvr_offweapon = gun;
    } else {
        self.mvr_drawing = TRUE;
        self.items |= gun.weapon;
        W_ChangeWeapon(gun.weapon, TRUE);
        self.mvr_drawing = FALSE;
        self.weaponmodel = gun.weaponmodel;
        self.weaponframe = gun.frame;
        if (gun.weapon == IT_NAILGUN) {
            self.nail_main = gun;
            gun.classname = "mvr_held_nailgun";
        }
        else remove(gun); // Other weapons' reload state remains in the player's per-weapon fields.
    }
}

void(float off) MVR_HolsterHand =
{
    float hand = off ? 0 : 1;
    float grip = off ? 2 : 8;
    float down = !!(self.vrbits0 & grip);
    float prev = !!(self.vrbits0 & (grip*2));
    float busy = !!(self.vrbits0 & (off ? 131072 : 262144));
    float hotspot = off ? self.offhand_hotspot : self.mainhand_hotspot;
    float slot = MVR_HolsterIndex(hotspot);
    float id = off ? self.weapon2 : self.weapon;
    float holding = id && id != IT_NO_WEAPON;
    float oldhover = off ? self.mvr_hover_off : self.mvr_hover_main;
    float hover = 0;
    // A reload component or engine-held prop owns its grip until released.
    if (self.nail_mag || (off && (self.mvr_mag || self.flak_held || self.rebar_bundle || self.mmml_held || self.gren_held))) busy = TRUE;
    if (slot >= 0 && !busy && self.animcontroller.owner == self && !(self.customflags & CFL_WEAPONLOCK)) {
        entity stored = self.mvr_holsters[slot];
        if ((holding && !stored) || (!holding && stored)) hover = slot+1;
        if (holding && hover) self.mvr_holster_used |= off ? 1 : 2;
        if (hover && (cvar("vr_holster_haptics") == 1 || hover != oldhover)) MVR_HolsterBuzz(hand);
        if (holding && !stored && !down && prev) {
            entity gun = off ? self.nail_off : self.nail_main;
            if (id != IT_NAILGUN) gun = off ? self.mvr_offweapon : spawn();
            if (!gun) return;
            gun.weapon = id;
            gun.weaponmodel = off ? self.weaponmodel2 : self.weaponmodel;
            gun.frame = off ? self.weaponframe2 : self.weaponframe;
            gun.classname = "mvr_holstered_weapon";
            gun.owner = self;
            gun.solid = SOLID_NOT;
            gun.movetype = MOVETYPE_NONE;
            gun.model = string_null;
            gun.modelindex = 0;
            self.mvr_holsters[slot] = gun;
            if (off) {
                if (self.mvr_offweapon && self.mvr_offweapon != gun) remove(self.mvr_offweapon);
                self.mvr_offweapon = self.nail_off = world;
                self.weapon2 = self.weaponframe2 = 0;
                self.weaponmodel2 = string_null;
            } else {
                if (id == IT_NAILGUN) self.nail_main = world;
                W_ChangeWeapon(IT_NO_WEAPON, TRUE);
            }
            self.mvr_holster_used |= off ? 1 : 2;
            MVR_SyncHolster(slot);
        } else if (!holding && stored && down && !prev) {
            self.mvr_holsters[slot] = world;
            MVR_HolsterEquip(off, stored);
            MVR_SyncHolster(slot);
            self.mvr_holster_used |= off ? 1 : 2;
        }
    }
    // An off-hand carried weapon can be passed to the empty firing hand.
    if (!off && !holding && !busy && self.animcontroller.owner == self && !(self.customflags & CFL_WEAPONLOCK) && hotspot == 7 && down && !prev && (self.mvr_offweapon || self.nail_off)) {
        entity passed = self.mvr_offweapon ? self.mvr_offweapon : self.nail_off;
        self.nail_off = world;
        self.mvr_offweapon = world;
        self.weapon2 = self.weaponframe2 = 0;
        self.weaponmodel2 = string_null;
        MVR_HolsterEquip(FALSE, passed);
        self.mvr_holster_used |= 3;
    }
    if (off) self.mvr_hover_off = hover;
    else self.mvr_hover_main = hover;
}

void() MVR_HolsterFrame =
{
    self.mvr_holster_used = 0;
    if (!(self.vrbits0 & MVR_TRACKED)) return;
    MVR_HolsterHand(FALSE);
    MVR_HolsterHand(TRUE);
}

void() MVR_ResetHolsters =
{
    for (float i = 0; i < 6; i += 1) {
        if (self.mvr_holsters[i]) remove(self.mvr_holsters[i]);
        self.mvr_holsters[i] = world;
        MVR_SyncHolster(i);
    }
    if (self.mvr_offweapon) remove(self.mvr_offweapon);
    self.mvr_offweapon = world;
    self.mvr_hover_main = self.mvr_hover_off = self.mvr_holster_used = 0;
    self.weapon2 = self.weaponframe2 = 0;
    self.weaponmodel2 = string_null;
}

float(entity player, float id) MVR_WeaponStoredFor =
{
    entity saved = self;
    self = player;
    float result = MVR_WeaponStored(id);
    self = saved;
    return result;
}

// parms 17..42 are carried by the engine separately from Monolith's 16 parameters.
float parm17, parm18, parm19, parm20, parm21, parm22, parm23, parm24, parm25, parm26, parm27, parm28, parm29, parm30, parm31, parm32, parm33, parm34, parm35, parm36, parm37, parm38, parm39, parm40, parm41, parm42;

float(entity gun) MVR_HolsterCode =
{
    if (!gun) return 0;
    if (gun.spiker) return 9;
    if (gun == self.nail_main || gun == self.nail_off) return 4;
    return getWeapon(gun.weapon);
}

float(entity gun) MVR_HolsterNailState =
{
    if (!gun) return 0;
    if (gun.weapon != IT_NAILGUN && gun != self.nail_main && gun != self.nail_off) return 0;
    return gun.nail_rounds + 32*gun.nail_loaded + 64*gun.nail_ready + 128*gun.spiker_safe;
}

string(float id, float spiker) MVR_HolsterModel =
{
    if (id == IT_SHOTGUN) return "progs/v_pistol.mdl";
    if (id == IT_SUPER_SHOTGUN) return "progs/v_mvrflak.mdl";
    if (id == IT_NAILGUN) return spiker ? "progs/v_spiker.mdl" : "progs/v_mvrnail.mdl";
    if (id == IT_SUPER_NAILGUN) return "progs/v_mvrrebar.mdl";
    if (id == IT_GRENADE_LAUNCHER) return "progs/v_mvrgren.mdl";
    if (id == IT_ROCKET_LAUNCHER) return "progs/v_mvrmmml.mdl";
    if (id == IT_LIGHTNING) return "progs/v_mvrinvoker.mdl";
    return weaponsclass[getWeapon(id)].model;
}

entity(float code, float state, float pose) MVR_RestoreHolstered =
{
    if (code < 1 || code > 9) return world;
    entity gun = spawn();
    gun.owner = self;
    gun.classname = "mvr_holstered_weapon";
    gun.spiker = code == 9;
    gun.weapon = gun.spiker ? IT_NAILGUN : weaponsclass[code].id;
    gun.weaponmodel = MVR_HolsterModel(gun.weapon,gun.spiker);
    gun.frame = pose;
    gun.nail_rounds = state & 31;
    gun.nail_loaded = !!(state & 32);
    gun.nail_ready = !!(state & 64);
    gun.spiker_safe = !!(state & 128);
    self.items |= gun.weapon;
    return gun;
}

void() MVR_SaveHolsterParms =
{
    parm17 = MVR_HolsterCode(self.mvr_holsters[0]);
    parm24 = MVR_HolsterNailState(self.mvr_holsters[0]);
    parm33 = self.mvr_holsters[0] ? self.mvr_holsters[0].frame : 0;
    parm18 = MVR_HolsterCode(self.mvr_holsters[1]);
    parm25 = MVR_HolsterNailState(self.mvr_holsters[1]);
    parm34 = self.mvr_holsters[1] ? self.mvr_holsters[1].frame : 0;
    parm19 = MVR_HolsterCode(self.mvr_holsters[2]);
    parm26 = MVR_HolsterNailState(self.mvr_holsters[2]);
    parm35 = self.mvr_holsters[2] ? self.mvr_holsters[2].frame : 0;
    parm20 = MVR_HolsterCode(self.mvr_holsters[3]);
    parm27 = MVR_HolsterNailState(self.mvr_holsters[3]);
    parm36 = self.mvr_holsters[3] ? self.mvr_holsters[3].frame : 0;
    parm21 = MVR_HolsterCode(self.mvr_holsters[4]);
    parm28 = MVR_HolsterNailState(self.mvr_holsters[4]);
    parm37 = self.mvr_holsters[4] ? self.mvr_holsters[4].frame : 0;
    parm22 = MVR_HolsterCode(self.mvr_holsters[5]);
    parm29 = MVR_HolsterNailState(self.mvr_holsters[5]);
    parm38 = self.mvr_holsters[5] ? self.mvr_holsters[5].frame : 0;
    entity off = self.nail_off ? self.nail_off : self.mvr_offweapon;
    parm23 = MVR_HolsterCode(off);
    parm30 = MVR_HolsterNailState(off);
    parm39 = off ? off.frame : 0;
    parm31 = MVR_HolsterNailState(self.nail_main);
    parm40 = self.nail_main ? MVR_HolsterCode(self.nail_main) : 0;
    parm41 = self.pistol_ammo_count + 16*self.mvr_pistol_phase;
    parm42 = 1; // distinguishes old saves with no pistol state
}

void() MVR_NewHolsterParms =
{
    parm17 = 0;
    parm18 = 0;
    parm19 = 0;
    parm20 = 0;
    parm21 = 0;
    parm22 = 0;
    parm23 = 0;
    parm24 = 0;
    parm25 = 0;
    parm26 = 0;
    parm27 = 0;
    parm28 = 0;
    parm29 = 0;
    parm30 = 0;
    parm31 = 0;
    parm32 = 0;
    parm33 = 0;
    parm34 = 0;
    parm35 = 0;
    parm36 = 0;
    parm37 = 0;
    parm38 = 0;
    parm39 = 0;
    parm40 = 0;
    parm41 = 0;
    parm42 = 0;
}

void() MVR_RestoreHolsterParms =
{
    self.mvr_holsters[0] = MVR_RestoreHolstered(parm17,parm24,parm33);
    MVR_SyncHolster(0);
    self.mvr_holsters[1] = MVR_RestoreHolstered(parm18,parm25,parm34);
    MVR_SyncHolster(1);
    self.mvr_holsters[2] = MVR_RestoreHolstered(parm19,parm26,parm35);
    MVR_SyncHolster(2);
    self.mvr_holsters[3] = MVR_RestoreHolstered(parm20,parm27,parm36);
    MVR_SyncHolster(3);
    self.mvr_holsters[4] = MVR_RestoreHolstered(parm21,parm28,parm37);
    MVR_SyncHolster(4);
    self.mvr_holsters[5] = MVR_RestoreHolstered(parm22,parm29,parm38);
    MVR_SyncHolster(5);
    entity off = MVR_RestoreHolstered(parm23,parm30,parm39);
    if (off) MVR_HolsterEquip(TRUE,off);
    self.nail_main = MVR_RestoreHolstered(parm40,parm31,0);
    if (self.nail_main) self.nail_main.classname = "mvr_held_nailgun";
    if (parm42) {
        self.pistol_ammo_count = parm41 & 15;
        self.mvr_pistol_phase = floor(parm41/16);
    }
}
