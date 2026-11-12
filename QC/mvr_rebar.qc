.float rebar_rounds, rebar_live, rebar_start, rebar_pull, rebar_trigger;
.entity rebar_bundle;
.float rebar_recoil_end;

void(float progress) MVR_RebarPose =
{
    if (time < self.rebar_recoil_end) {
        float kick = min(5,max(0,floor(6 - (self.rebar_recoil_end-time)*20)));
        self.weaponframe = 84 + self.rebar_rounds*6 + kick;
    } else {
        self.weaponframe = self.rebar_rounds*12 + self.rebar_live*6 + floor(progress*5+.5);
    }
}

void() MVR_ReturnRebar =
{
    if (!self.rebar_bundle) return;
    self.ammo_nails += 10*self.rebar_bundle.count;
    remove(self.rebar_bundle);
    self.rebar_bundle = world;
}

void() MVR_RebarFrame =
{
    float pressed = self.button3 && !self.rebar_trigger;
    self.rebar_trigger = self.button3;
    if (!(self.vrbits0 & MVR_TRACKED) || self.weapon != IT_SUPER_NAILGUN ||
        self.health <= 0) {
        self.rebar_pull = 0;
        MVR_ReturnRebar();
        return;
    }
    if (self.nail_off || (self.vrbits0 & 131072)) {
        self.rebar_pull = 0;
        MVR_ReturnRebar();
        MVR_RebarPose(0);
        return;
    }
    makevectors(self.handrot);
    vector delta = self.offhandpos-self.handpos;
    vector feed = v_forward*16 + v_right*7 + v_up;
    vector handle = v_forward*19 - v_right*8 - v_up*2;
    float progress = 0;
    if (self.rebar_bundle) {
        setorigin(self.rebar_bundle,self.offhandpos);
        self.rebar_bundle.angles = self.handrot;
        if (vlen(delta-feed) < 4) {
            self.rebar_rounds = self.rebar_bundle.count;
            remove(self.rebar_bundle);
            self.rebar_bundle = world;
        } else if (!(self.vrbits0 & 2)) MVR_ReturnRebar();
    } else if (self.rebar_pull) {
        float travel = self.rebar_start - delta*v_forward;
        progress = min(1,max(0,travel/4));
        if (!self.button3 || vlen(delta-handle+v_forward*travel) > 6) {
            self.rebar_pull = progress = 0;
        } else if (progress == 1 && !self.rebar_live) {
            self.rebar_rounds--;
            self.rebar_live = 1;
            sound(self, CHAN_ITEM, "rebar/bow_clank.wav", .6, ATTN_NORM);
        }
    } else if (pressed && !self.rebar_live && self.rebar_rounds && vlen(delta-handle) < 5) {
        self.rebar_recoil_end = 0;
        self.rebar_pull = 1;
        self.rebar_start = delta*v_forward;
    } else if ((self.vrbits0 & 2) && !(self.vrbits0 & 4) && self.offhand_hotspot == 12 &&
               !self.rebar_rounds && !self.rebar_live && self.ammo_nails >= 10) {
        self.rebar_bundle = spawn();
        self.rebar_bundle.count = min(6,floor(self.ammo_nails/10));
        self.ammo_nails -= 10*self.rebar_bundle.count;
        setmodel(self.rebar_bundle,"progs/mvr_rebarbundle.mdl");
        self.rebar_bundle.frame = self.rebar_bundle.count-1;
        setorigin(self.rebar_bundle,self.offhandpos);
    }
    MVR_RebarPose(progress);
    self.currentammo = self.rebar_rounds+self.rebar_live;
}


