// Chamber states: 0 empty, 1 live, 2 spent. Tube and rack exclude the chamber.
.float flak_tube, flak_chamber, flak_rack, flak_trigger, flak_stroke, flak_open, flak_start;
.entity flak_held;

entity(vector pos, vector vel, float live) MVR_LooseShell =
{
    entity shell = spawn();
    shell.classname = live ? "mvr_live_flak" : "mvr_spent_flak";
    setmodel(shell, "progs/mvr_flakshell.mdl");
    setsize(shell, '-1 -1 -1', '1 1 1');
    setorigin(shell, pos);
    shell.movetype = MOVETYPE_BOUNCE;
    shell.solid = SOLID_TRIGGER;
    shell.velocity = vel;
    shell.avelocity = '150 100 270';
    if (!live) {
        shell.think = SUB_Remove;
        shell.nextthink = time + 4;
    }
    return shell;
}

void() MVR_DropFlakShell =
{
    if (!self.flak_held) return;
    self.flak_held.classname = "mvr_live_flak";
    self.flak_held.movetype = MOVETYPE_BOUNCE;
    self.flak_held.solid = SOLID_TRIGGER;
    self.flak_held = world;
}

void() MVR_ResetFlak =
{
    MVR_DropFlakShell();
    self.flak_rack = self.flak_tube = self.flak_chamber = 0;
    self.flak_stroke = self.flak_open = self.flak_trigger = 0;
}

void() MVR_FlakFrame =
{
    float pressed = self.button3 && !self.flak_trigger;
    self.flak_trigger = self.button3;
    if (!(self.vrbits0 & MVR_TRACKED) || self.weapon != IT_SUPER_SHOTGUN || self.health <= 0 || self.nail_off) {
        MVR_DropFlakShell();
        self.flak_stroke = self.flak_open = 0;
        return;
    }
    makevectors(self.handrot);
    vector delta = self.offhandpos - self.handpos;
    vector rack = v_forward*3.5 + v_right*2 + v_up*3;
    vector feed = v_forward*7 - v_up;
    vector pump = v_forward*17 + v_up*2;
    float progress = 0;
    if (self.flak_held) {
        setorigin(self.flak_held,self.offhandpos);
        if (vlen(delta-feed) < 2.8 && self.flak_tube + (self.flak_chamber == 1) < 8) {
            self.flak_tube++;
            remove(self.flak_held);
            self.flak_held = world;
        } else if (!self.button3) {
            if (vlen(delta-rack) < 3 && self.flak_rack < 4) {
                self.flak_rack++;
                remove(self.flak_held);
                self.flak_held = world;
            } else if (self.offhand_hotspot == 12) {
                self.ammo_shells++;
                remove(self.flak_held);
                self.flak_held = world;
            } else MVR_DropFlakShell();
        }
    } else if (self.flak_stroke) {
        float travel = delta*v_forward - self.flak_start;
        progress = min(1,max(0,travel/3.3));
        if (!self.button3 || vlen(delta - pump - v_forward*travel) > 6) {
            self.flak_stroke = self.flak_open = 0;
            progress = 0;
        } else if (!self.flak_open && progress >= 1) {
            self.flak_open = 1;
            if (self.flak_chamber)
                MVR_LooseShell(self.handpos+v_forward*7+v_up*5, v_up*70+v_right*22, self.flak_chamber == 1);
            self.flak_chamber = 0;
        } else if (self.flak_open && progress < .15) {
            if (self.flak_tube) {
                self.flak_tube--;
                self.flak_chamber = 1;
            }
            sound(self, CHAN_ITEM, "flak/pump_reload.wav", .7, ATTN_NORM);
            self.flak_open = self.flak_stroke = 0;
        }
    } else if (pressed && !(self.vrbits0 & 131072)) {
        if (vlen(delta-pump) < 5) {
            self.flak_start = delta*v_forward;
            self.flak_stroke = 1;
        } else if (!(self.vrbits0 & 2)) {
            entity shell = world;
            if (vlen(delta-rack) < 3 && self.flak_rack) {
                self.flak_rack--;
                shell = MVR_LooseShell(self.offhandpos,'0 0 0',1);
            } else if (self.offhand_hotspot == 12 && self.ammo_shells > 0) {
                self.ammo_shells--;
                shell = MVR_LooseShell(self.offhandpos,'0 0 0',1);
            } else {
                entity candidate = world;
                float closest = 5;
                while ((candidate = find(candidate,classname,"mvr_live_flak"))) {
                    float distance = vlen(candidate.origin-self.offhandpos);
                    if (distance < closest) { closest = distance; shell = candidate; }
                }
            }
            if (shell) {
                self.flak_held = shell;
                shell.classname = "mvr_held_flak";
                shell.movetype = MOVETYPE_NONE;
                shell.solid = SOLID_NOT;
                shell.velocity = shell.avelocity = '0 0 0';
                setorigin(shell,self.offhandpos);
            }
        }
    }
    self.weaponframe = self.flak_rack*6 + floor(progress*5+.5);
    self.currentammo = self.flak_tube + (self.flak_chamber == 1);
}

