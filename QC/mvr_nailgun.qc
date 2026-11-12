// A gun keeps its own magazine and charge state even while lying on the floor.

.float spiker, spiker_safe, nail_loaded, nail_ready, nail_rounds, nail_start, nail_pull, nail_full;

string(entity gun) MVR_NailModel =
{
    if (!gun.spiker) return "progs/v_mvrnail.mdl";
    return "progs/v_spiker.mdl";
}


.float nail_eject, nail_trigger, nail_nextshot;
.vector offhandrot, offmuzzlepos, offshotrot;
.float mainhand_hotspot, weaponframe2, weapon2;
.string weaponmodel2;

void(entity gun, vector pos) MVR_PutNailDown =
{
    gun.owner = world;
    gun.classname = "mvr_loose_nailgun";
    gun.nail_pull = gun.nail_full = 0;
    gun.frame = gun.nail_loaded ? 0 : (gun.spiker ? 1 : 6);
    gun.movetype = MOVETYPE_TOSS;
    gun.solid = SOLID_TRIGGER;
    setmodel(gun, MVR_NailModel(gun));
    setsize(gun, '-4 -4 -6', '4 4 5');
    setorigin(gun, pos);
}

void() weapon_spiker =
{
    self.spiker = self.spiker_safe = TRUE;
    MVR_PutNailDown(self, self.origin);
}

void() MVR_SplitNailguns =
{
    makevectors(other.angles);
    vector side = v_right;
    for (float i = -1; i <= 1; i += 2) {
        entity gun = spawn();
        MVR_PutNailDown(gun, self.origin + '0 0 12');
        gun.velocity = side * (60*i) + '0 0 65';
    }
    other.ammo_nails = min(MAX_AMMO_NAILS, other.ammo_nails + self.ammo_nails);
    self.solid = SOLID_NOT;
    ItemTouched();
}

void() MVR_ResetNails =
{
    if (self.nail_main) MVR_PutNailDown(self.nail_main,self.handpos);
    if (self.nail_off) MVR_PutNailDown(self.nail_off,self.offhandpos);
    if (self.nail_mag) {
        self.ammo_nails += self.nail_mag.nail_rounds;
        remove(self.nail_mag);
    }
    self.nail_mag = self.nail_main = self.nail_off = world;
    self.weaponmodel2 = string_null;
    self.weaponframe2 = self.weapon2 = 0;
}

entity(vector pos) MVR_FindNailgun =
{
    entity best = world, gun = world;
    float reach = 12;
    while ((gun = find(gun,classname,"mvr_loose_nailgun"))) {
        float dist = vlen(pos-gun.origin);
        if (dist < reach) { best = gun; reach = dist; }
    }
    return best;
}

void(float off) MVR_NailHand =
{
    entity gun = off ? self.nail_off : self.nail_main;
    vector pos = off ? self.offhandpos : self.handpos;
    vector rot = off ? self.offhandrot : self.handrot;
    vector support = off ? self.handpos : self.offhandpos;
    float grip = off ? 2 : 8;
    float busy = off ? 131072 : 262144;
    float fire = off ? self.button3 : self.button0;
    float helper = off ? self.button0 : self.button3;
    float eject = !!(self.vrbits0 & (off ? 524288 : 1048576));
    if ((self.vrbits0 & grip) && !(self.vrbits0 & (grip*2)) && !(self.vrbits0 & busy) && !self.nail_mag) {
        if (gun && (off || self.weapon == IT_NAILGUN)) {
            MVR_PutNailDown(gun,pos);
            if (off) {
                self.nail_off = world;
                self.weaponmodel2 = string_null;
                self.weapon2 = self.weaponframe2 = 0;
            } else {
                self.nail_main = world;
                self.items &~= IT_NAILGUN;
                W_ChangeWeapon(self.nail_off ? IT_NO_WEAPON : W_BestWeapon(),FALSE);
            }
            return;
        }
        if (!gun) {
            gun = MVR_FindNailgun(pos);
            if (!gun) return;
            if (!off) {
                self.items |= IT_NAILGUN;
                if (W_ChangeWeapon(IT_NAILGUN,FALSE) != WEAPONSTAT_AVAILABLE) {
                    self.items &~= IT_NAILGUN;
                    return;
                }
                self.nail_main = gun;
            } else {
                if (!self.nail_main) W_ChangeWeapon(IT_NO_WEAPON,FALSE);
                self.nail_off = gun;
                self.weapon2 = IT_NAILGUN;
                self.weaponmodel2 = "progs/v_mvrnail.mdl";
            }
            gun.classname = "mvr_held_nailgun";
            gun.owner = self;
            gun.solid = SOLID_NOT;
            gun.movetype = MOVETYPE_NONE;
            gun.model = string_null;
            gun.modelindex = 0;
        }
    }
    if (!gun || (!off && self.weapon != IT_NAILGUN)) return;
    makevectors(rot);
    vector delta = support-pos;
    float available = off ? self.weapon == IT_NO_WEAPON : !self.nail_off;
    available = available && !(self.vrbits0 & (off ? 262144 : 131072));
    if (gun.spiker && eject && !gun.nail_eject) {
        gun.spiker_safe = !gun.spiker_safe;
        if (gun.spiker_safe) centerprint(self, "Spiker safety on");
        else centerprint(self, "Spiker safety off");
    }
    float magselect = gun.spiker && available && helper && !gun.nail_trigger &&
                      vlen(delta-v_forward*8+v_up*2) < 4;
    if ((magselect || (!gun.spiker && eject && !gun.nail_eject)) && gun.nail_loaded) {
        entity spent = spawn();
        setmodel(spent,gun.spiker ? "progs/spikermag.mdl" : "progs/mvr_nailmag.mdl");
        setorigin(spent,pos+v_forward*13-v_up*4);
        spent.movetype = MOVETYPE_TOSS;
        spent.think = SUB_Remove;
        spent.nextthink = time+4;
        gun.nail_ready = gun.nail_loaded = gun.nail_rounds = 0;
    }
    gun.nail_eject = eject;
    float progress = 0;
    float grasp = !!(self.vrbits0 & (off ? 8 : 2));
    if (available && !gun.nail_loaded) {
        if (self.nail_mag && self.nail_mag.owner == gun) {
            setorigin(self.nail_mag,support);
            if (vlen(delta-v_forward*(gun.spiker ? 8 : 13)+v_up*(gun.spiker ? 2 : 3)) < 5) {
                gun.nail_loaded = TRUE;
                gun.nail_rounds = self.nail_mag.nail_rounds;
                remove(self.nail_mag);
                self.nail_mag = world;
            } else if (!grasp) {
                self.ammo_nails += self.nail_mag.nail_rounds;
                remove(self.nail_mag);
                self.nail_mag = world;
            }
        } else if (!self.nail_mag && grasp && !(self.vrbits0 & (off ? 16 : 4)) &&
                   (off ? self.mainhand_hotspot : self.offhand_hotspot) == 12 && self.ammo_nails > 0) {
            self.nail_mag = spawn();
            self.nail_mag.owner = gun;
            self.nail_mag.nail_rounds = min(30,self.ammo_nails);
            self.ammo_nails -= self.nail_mag.nail_rounds;
            setmodel(self.nail_mag,gun.spiker ? "progs/spikermag.mdl" : "progs/mvr_nailmag.mdl");
            setorigin(self.nail_mag,support);
        }
    } else if (gun.spiker) {
        if (available && !gun.spiker_safe && helper && !gun.nail_trigger && !magselect)
            gun.nail_ready = gun.nail_loaded;
    } else if (available && gun.nail_loaded) {
        float along = delta*v_forward;
        if (helper && !gun.nail_trigger && vlen(delta-v_forward*10-v_up*6) < 5) {
            gun.nail_pull = TRUE;
            gun.nail_full = FALSE;
            gun.nail_start = along;
        }
        if (gun.nail_pull) {
            progress = min(1,max(0,(gun.nail_start-along)/2.8));
            if (progress == 1) gun.nail_full = TRUE;
            if (!helper) {
                if (gun.nail_full) gun.nail_ready = TRUE;
                gun.nail_pull = progress = 0;
            }
        }
    } else gun.nail_pull = 0;
    gun.nail_trigger = helper;
    gun.frame = (gun.nail_loaded ? 0 : 6) + floor(progress*5+.5);
    if (gun.spiker) {
        gun.frame = gun.nail_loaded ? 0 : 1;
        if (off) self.weaponmodel2 = MVR_NailModel(gun);
        else self.weaponmodel = MVR_NailModel(gun);
    }
    if (off) self.weaponframe2 = gun.frame;
    else { self.weaponframe = gun.frame; self.currentammo = gun.nail_rounds; }
    if (fire && !gun.spiker_safe && gun.nail_ready && gun.nail_rounds && !gun.nail_pull && time >= gun.nail_nextshot) {
        gun.nail_nextshot = time + (gun.spiker ? .20 : .08);
        gun.nail_rounds--;
        if (!gun.nail_rounds) gun.nail_ready = FALSE;
        SuperDamageSound();
        W_FireNailShot(off ? -1 : 0, gun.spiker ? 24 : 9);
        self.show_hostile = time+1;
    }
}

void() MVR_NailFrame =
{
    if (!(self.vrbits0 & MVR_TRACKED)) return;
    if ((self.items & IT_NAILGUN) && !self.nail_main) {
        // Inventory restored from level parameters or a pre-conversion save.
        self.nail_main = spawn();
        self.nail_main.owner = self;
        self.nail_main.classname = "mvr_held_nailgun";
        if (self.weapon == IT_NAILGUN) W_ChangeWeapon(IT_NAILGUN,TRUE);
    }
    if (self.nail_mag && ((self.nail_mag.owner == self.nail_main && self.weapon != IT_NAILGUN) ||
                          (self.nail_mag.owner == self.nail_off && self.weapon != IT_NO_WEAPON))) {
        self.ammo_nails += self.nail_mag.nail_rounds;
        remove(self.nail_mag);
        self.nail_mag = world;
    }
    MVR_NailHand(FALSE);
    MVR_NailHand(TRUE);
}
