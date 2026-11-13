.float gren_loaded, gren_wait_release;
.entity gren_held;

void() MVR_ReturnGrenade =
{
    if (!self.gren_held) return;
    self.ammo_rockets++;
    remove(self.gren_held);
    self.gren_held = world;
}

vector() MVR_GrenadeSocket =
{
    makevectors(self.handrot);
    return self.handpos + 10.7*v_forward + 8.1*v_up;
}

void() MVR_GrenadeFrame =
{
    if (!(self.vrbits0 & MVR_TRACKED) || self.weapon != IT_GRENADE_LAUNCHER || self.health <= 0) {
        MVR_ReturnGrenade();
        return;
    }
    if (!self.button0) self.gren_wait_release = 0;
    if (self.nail_off || self.mvr_offweapon || (self.vrbits0 & 131072)) MVR_ReturnGrenade();
    else if (self.gren_held) {
        setorigin(self.gren_held,self.offhandpos);
        self.gren_held.angles = self.offhandrot;
        if (vlen(self.offhandpos-MVR_GrenadeSocket()) <= 4) {
            remove(self.gren_held);
            self.gren_held = world;
            self.gren_loaded++;
            self.gren_wait_release = self.button0;
            sound(self,CHAN_ITEM,"grenade/grenade_reload.wav",1,ATTN_NORM);
        } else if (!(self.vrbits0 & 2)) MVR_ReturnGrenade();
    } else if (self.gren_loaded < 6 && self.offhand_hotspot == 12 && self.ammo_rockets >= 1 &&
               (self.vrbits0 & 2) && !(self.vrbits0 & 4)) {
        self.ammo_rockets--;
        self.gren_held = spawn();
        setmodel(self.gren_held,"progs/mvr_canister.mdl");
        self.gren_held.angles = self.offhandrot;
        setorigin(self.gren_held,self.offhandpos);
    }
    self.weaponframe = self.gren_loaded;
    self.currentammo = self.gren_loaded;
}
