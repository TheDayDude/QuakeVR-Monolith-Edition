// A seated rack holds one eight-missile volley. Reserve ammo is paid on pouch pickup.
.float mmml_loaded, mmml_remaining, mmml_next, mmml_wait_release;
.entity mmml_held;

void() MVR_ReturnMMMLRack =
{
    if (!self.mmml_held) return;
    self.ammo_rockets += 4;
    remove(self.mmml_held);
    self.mmml_held = world;
}

void() MVR_StopMMML =
{
    MVR_ReturnMMMLRack();
    if (self.mmml_remaining) self.customflags &~= CFL_WEAPONLOCK;
    self.mmml_remaining = 0;
}

vector() MVR_MMMLSocket =
{
    makevectors(self.handrot);
    return self.handpos + 14.3*v_forward - 9.75*v_right + 7.8*v_up;
}

void() MVR_MMMLMissile =
{
    float index = 8-self.mmml_remaining;
    makevectors(self.handrot);
    vector target = self.handpos + v_forward*24 + v_right*(5.1-3.4*(index & 3))
                    + v_up*(index < 4 ? 9.5 : 6.1);
    traceline(self.handpos,target,FALSE,self);
    vector muzzle = trace_endpos;
    makevectors(self.shotrot);
    MMML_FireSound();
    self.effects |= EF_MUZZLEFLASH;
    launch_spiralrocket(muzzle,v_forward,0);
    self.mmml_remaining--;
    self.weaponframe = self.mmml_remaining;
    if (!self.mmml_remaining) {
        self.customflags &~= CFL_WEAPONLOCK;
        entity spent = spawn();
        setmodel(spent,"progs/mvr_mmmlrack.mdl");
        setorigin(spent,MVR_MMMLSocket());
        spent.angles = self.handrot;
        spent.movetype = MOVETYPE_BOUNCE;
        spent.velocity = v_forward*20 - v_up*45;
        spent.avelocity = '60 0 90';
        spent.think = SUB_Remove;
        spent.nextthink = time+3;
        sound(self,CHAN_ITEM,"mmml/silo_clunk.wav",1,ATTN_NORM);
    }
}

void() MVR_MMMLFrame =
{
    if (!(self.vrbits0 & MVR_TRACKED) || self.weapon != IT_ROCKET_LAUNCHER || self.health <= 0) {
        MVR_StopMMML();
        return;
    }
    if (!self.button0) self.mmml_wait_release = 0;
    if (self.mmml_remaining) {
        while (self.mmml_remaining && time >= self.mmml_next) {
            MVR_MMMLMissile();
            self.mmml_next += .1;
        }
        return;
    }
    if (self.nail_off || (self.vrbits0 & 131072)) MVR_ReturnMMMLRack();
    else if (self.mmml_held) {
        setorigin(self.mmml_held,self.offhandpos);
        self.mmml_held.angles = self.offhandrot;
        if (vlen(self.offhandpos-MVR_MMMLSocket()) <= 4) {
            remove(self.mmml_held);
            self.mmml_held = world;
            self.mmml_loaded = 1;
            self.mmml_wait_release = self.button0;
            sound(self,CHAN_ITEM,"mmml/silo_load.wav",1,ATTN_NORM);
        } else if (!(self.vrbits0 & 2)) MVR_ReturnMMMLRack();
    } else if (!self.mmml_loaded && self.offhand_hotspot == 12 && self.ammo_rockets >= 4 &&
               (self.vrbits0 & 2) && !(self.vrbits0 & 4)) {
        self.ammo_rockets -= 4;
        self.mmml_held = spawn();
        setmodel(self.mmml_held,"progs/mvr_mmmlrack.mdl");
        self.mmml_held.frame = 1;
        self.mmml_held.angles = self.offhandrot;
        setorigin(self.mmml_held,self.offhandpos);
    }
    self.weaponframe = 8*self.mmml_loaded;
    self.currentammo = 4*self.mmml_loaded;
}
