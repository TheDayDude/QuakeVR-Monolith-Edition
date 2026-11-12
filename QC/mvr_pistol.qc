.float vrbits0, button3, offhand_hotspot;
.vector handpos, handrot, offhandpos, muzzlepos, shotrot;
.float mvr_pistol_phase, mvr_grabbing_weapon, mvr_eject_down, mvr_slide_down;
.float mvr_slide_grab, mvr_slide_back, mvr_slide_start;
.entity mvr_mag, nail_main, nail_off, nail_mag;
float MVR_TRACKED = 16384;
float MVR_NO_MAG = 1;
float MVR_NEEDS_SLIDE = 2;

void() MVR_ClearHand =
{
    if (self.mvr_mag) remove(self.mvr_mag);
    self.mvr_mag = world;
    self.mvr_slide_grab = self.mvr_slide_back = 0;
}

void() MVR_ResetPistol =
{
    MVR_ClearHand();
    self.mvr_pistol_phase = self.mvr_eject_down = self.mvr_slide_down = 0;
}

void() MVR_GrabWeapon =
{
    entity player = self;
    entity item = world;
    entity closest = world;
    float reach = 18;
    for (item = findradius(self.handpos, 32); item; item = item.chain) {
        if (item.items != IT_SHOTGUN && item.items != IT_LIGHTNING) continue;
        if (item.touch != weapon_touch || item.solid != SOLID_TRIGGER) continue;
        float distance = vlen(item.origin - self.handpos);
        if (distance < reach) { reach = distance; closest = item; }
    }
    if (!closest) return;
    float weapon = closest.items;
    entity saved_other = other;
    player.mvr_grabbing_weapon = TRUE;
    self = closest;
    other = player;
    weapon_touch();
    self = player;
    other = saved_other;
    player.mvr_grabbing_weapon = FALSE;
    if (player.items & weapon) W_ChangeWeapon(weapon, FALSE);
}

void() MVR_PistolFrame =
{
    if (self.vrbits0 & MVR_TRACKED) {
        if (!self.nail_main && !self.nail_mag && (self.vrbits0 & 8) && !(self.vrbits0 & 16)) MVR_GrabWeapon();
    }
    if (!(self.vrbits0 & MVR_TRACKED) || self.weapon != IT_SHOTGUN || self.nail_off) {
        MVR_ClearHand();
        self.mvr_eject_down = !!(self.vrbits0 & 1048576);
        self.mvr_slide_down = self.button3;
        return;
    }
    float eject = !!(self.vrbits0 & 1048576);
    if (eject && !self.mvr_eject_down && self.mvr_pistol_phase != MVR_NO_MAG) {
        Drop_PistolMag();
        self.mvr_pistol_phase = MVR_NO_MAG;
        self.currentammo = self.pistol_ammo_count = 0;
        self.mvr_slide_grab = 0;
    }
    self.mvr_eject_down = eject;
    makevectors(self.handrot);
    vector delta = self.offhandpos - self.handpos;
    float along = delta * v_forward;
    if (self.mvr_mag) {
        setorigin(self.mvr_mag, self.offhandpos);
        if (vlen(delta + v_up * 3) < 7) {
            MVR_ClearHand();
            self.mvr_pistol_phase = MVR_NEEDS_SLIDE;
            sound(self, CHAN_ITEM, "pistol/deadlock_reload.wav", 0.7, ATTN_NORM);
        } else if (!(self.vrbits0 & 2)) MVR_ClearHand();
    } else if (self.mvr_pistol_phase == MVR_NO_MAG && self.offhand_hotspot == 12 &&
               (self.vrbits0 & 2) && !(self.vrbits0 & 4) && !(self.vrbits0 & 131072)) {
        self.mvr_mag = spawn();
        self.mvr_mag.classname = "mvr_held_mag";
        self.mvr_mag.owner = self;
        setmodel(self.mvr_mag, "progs/pistol_mag.mdl");
        setorigin(self.mvr_mag, self.offhandpos);
    } else if (self.mvr_pistol_phase == MVR_NEEDS_SLIDE) {
        if (self.vrbits0 & (2 | 131072)) self.mvr_slide_grab = FALSE;
        else if (self.button3 && !self.mvr_slide_down && vlen(delta - v_up * 4) < 6) {
            self.mvr_slide_grab = TRUE;
            self.mvr_slide_back = FALSE;
            self.mvr_slide_start = along;
        }
        if (self.mvr_slide_grab) {
            if (self.mvr_slide_start - along >= 3) self.mvr_slide_back = TRUE;
            if (!self.button3) {
                if (self.mvr_slide_back) {
                    self.mvr_pistol_phase = 0;
                    self.currentammo = self.pistol_ammo_count = 10;
                    sound(self, CHAN_ITEM, "pistol/gun_click.wav", 1, ATTN_NORM);
                }
                self.mvr_slide_grab = FALSE;
            }
        }
    }
    self.mvr_slide_down = self.button3;
}
