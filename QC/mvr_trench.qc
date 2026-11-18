// Each drop grants one full reload. Reserves count shells, magazines, or rockets.
const float WID_TRENCH = 103, WID_PLASMA = 104, WID_QUAD = 105;
.float knight_owned, knight_reserve[3], knight_loaded[3], knight_ready[3];
.float knight_stroke, knight_origin, knight_pressed, knight_next, knight_dropped;
.entity knight_part, knight_dot;
.vector knight_target;
float parm43, parm44, parm45, parm46, parm47, parm48, parm49;

float(float id) KnightWeapon = { return id >= WID_TRENCH && id <= WID_QUAD; }
float(float k) KnightBit = { return k == 0 ? 1 : k == 1 ? 2 : 4; }
float(float k) KnightCapacity = { return k == 0 ? 8 : k == 1 ? 20 : 4; }

void() KnightPackTouch =
{
    if (other.classname != "player" || other.health <= 0) return;
    float k = self.weapon-WID_TRENCH;
    float first = !(other.knight_owned & KnightBit(k));
    other.knight_owned |= KnightBit(k);
    other.knight_reserve[k] += k == 1 ? 1 : KnightCapacity(k);
    sprint(other, k == 0 ? "Trenchgun + 8 trench shells\n" :
           k == 1 ? "Plasma Trenchgun + 20-round magazine\n" : "Quad Launcher + 4 guided rockets\n");
    sound(other,CHAN_ITEM,"weapons/lock4.wav",1,ATTN_NORM);
    entity pack = self;
    if (first) {
        self = other;
        W_ChangeWeapon(pack.weapon,TRUE);
        self = pack;
    }
    if (pack.classname == "knight_backpack") remove(pack);
    else {
        pack.solid = SOLID_NOT;
        ItemTouched();
    }
}

void(float id, string pickupmodel) KnightMapWeapon =
{
    self.weapon = id;
    self.touch = KnightPackTouch;
    setmodel(self,pickupmodel);
    setsize(self,'-16 -16 -4','16 16 12');
    StartItem();
}

void() weapon_trenchgun = { KnightMapWeapon(WID_TRENCH,"progs/v_trenchgun.mdl"); }
void() weapon_plasma_trenchgun = { KnightMapWeapon(WID_PLASMA,"progs/v_plasmatrench.mdl"); }
void() weapon_quad_launcher = { KnightMapWeapon(WID_QUAD,"progs/v_quadlauncher.mdl"); }

void(float id) KnightDrop =
{
    if (self.knight_dropped) return;
    self.knight_dropped = TRUE;
    entity pack = spawn();
    pack.classname = "knight_backpack";
    pack.weapon = id;
    pack.movetype = MOVETYPE_TOSS;
    pack.solid = SOLID_TRIGGER;
    pack.flags = FL_ITEM;
    setmodel(pack,"progs/backpack.mdl");
    setsize(pack,'-10 -10 0','10 10 16');
    setorigin(pack,self.origin);
    pack.velocity_z = 140;
    pack.touch = KnightPackTouch;
    pack.think = SUB_Remove;
    pack.nextthink = time+120;
}

void() KnightClearHands =
{
    if (self.knight_part) { remove(self.knight_part); self.knight_part = world; }
    if (self.knight_dot) { remove(self.knight_dot); self.knight_dot = world; }
    self.knight_stroke = 0;
}

void() KnightGuide =
{
    entity player = self.trueowner;
    if (time >= self.lifetime_finished) { SoldierMissileExplode(); return; }
    if (player.health > 0 && player.weapon == WID_QUAD)
        self.velocity = min(900,vlen(self.velocity)*2)*ShalTurnToward(player.knight_target-'0 0 10',180);
    self.angles = vectoangles(self.velocity);
    self.nextthink = time+.05;
}

void() KnightFrame =
{
    float pressed = self.button3 && !self.knight_pressed;
    self.knight_pressed = self.button3;
    if (!KnightWeapon(self.weapon) || self.health <= 0) { KnightClearHands(); return; }
    float k = self.weapon-WID_TRENCH;
    float vr = self.vrbits0 & MVR_TRACKED;
    makevectors(vr ? self.handrot : self.v_angle);
    vector hand = vr ? self.handpos : self.origin+self.view_ofs;
    float model_factor = vr ? (k == 2 ? 0.55 : k == 1 ? 0.65 : 0.70) : 1;
    vector feed = hand+model_factor*(v_forward*(k == 2 ? 18 : 5) + v_up*(k == 2 ? 10 : -1));
    vector action = hand+model_factor*(v_forward*(k == 0 ? 16 : 5)+v_up*(k == 0 ? 0 : 5));
    vector barrel = hand+model_factor*(v_forward*(k == 2 ? 18 : k == 1 ? 26 : 30)+v_up*(k == 2 ? 10 : 5));
    traceline(hand,barrel,FALSE,self);
    vector muzzle = trace_endpos;
    if (vr && !self.nail_off && !self.mvr_offweapon && !(self.vrbits0 & 131072)) {
        if (self.knight_part) {
            setorigin(self.knight_part,self.offhandpos);
            self.knight_part.angles = self.offhandrot;
            if (vlen(self.offhandpos-feed) < (k == 2 ? 5 : 3) && self.knight_loaded[k] < KnightCapacity(k)) {
                self.knight_reserve[k]--;
                if (k == 1) { self.knight_loaded[k] = 20; self.knight_ready[k] = 0; }
                else self.knight_loaded[k]++;
                sound(self,CHAN_ITEM,"mmml/silo_load.wav",.65,ATTN_NORM);
                remove(self.knight_part); self.knight_part = world;
            } else if (!self.button3) { remove(self.knight_part); self.knight_part = world; }
        } else if (pressed && self.offhand_hotspot == 12 && self.knight_reserve[k] > 0) {
            self.knight_part = spawn();
            setmodel(self.knight_part,k == 2 ? "progs/proj_missile.mdl" : k == 1 ? "progs/mvr_nailmag.mdl" : "progs/mvr_flakshell.mdl");
            setorigin(self.knight_part,self.offhandpos);
        } else if (pressed && k != 2 && vlen(self.offhandpos-action) < 4) {
            self.knight_origin = (self.offhandpos-hand)*v_forward;
            self.knight_stroke = 1;
        } else if (self.knight_stroke) {
            float travel = self.knight_origin-(self.offhandpos-hand)*v_forward;
            if (!self.button3 || vlen(self.offhandpos-action+travel*v_forward)>6) self.knight_stroke = 0;
            else if (self.knight_stroke == 1 && travel >= 2.5*model_factor) {
                self.knight_stroke = 2;
                if (!k && self.knight_ready[k] == 2)
                    MVR_LooseShell(hand+model_factor*(7*v_forward+5*v_up),65*v_up+40*v_right,0);
                if (!k && self.knight_ready[k] == 1) self.knight_loaded[k]--;
                self.knight_ready[k] = 0;
            } else if (self.knight_stroke == 2 && travel < .6*model_factor) {
                self.knight_ready[k] = self.knight_loaded[k] > 0;
                self.knight_stroke = 0;
                sound(self,CHAN_ITEM,"flak/pump_reload.wav",.7,ATTN_NORM);
            }
        }
    } else if (vr) KnightClearHands();
    if (!vr && !self.knight_loaded[k] && self.knight_reserve[k] > 0) {
        float units = k == 1 ? 1 : min(KnightCapacity(k),self.knight_reserve[k]);
        self.knight_reserve[k] -= units;
        self.knight_loaded[k] = k == 1 ? 20 : units;
    }
    self.weaponframe = !k && self.knight_stroke == 2;
    makevectors(vr ? self.shotrot : self.v_angle);
    vector dir = v_forward;
    if (k == 2) {
        traceline(muzzle,muzzle+dir*8192,FALSE,self);
        self.knight_target = trace_endpos;
        if (!self.knight_dot) {
            self.knight_dot = spawn();
            setmodel(self.knight_dot,"progs/fx/spark_laser1.mdl");
        }
        setorigin(self.knight_dot,trace_endpos-dir);
    }
    self.currentammo = self.knight_loaded[k];
    if (!self.button0 || self.attackhold || time < self.knight_next || !self.currentammo ||
        (vr && k != 2 && self.knight_ready[k] != 1) || self.knight_stroke) return;
    self.currentammo = --self.knight_loaded[k];
    self.knight_next = time+(k == 1 ? .16 : .45);
    self.show_hostile = time+1;
    self.effects |= EF_MUZZLEFLASH;
    if (k == 0) {
        sound(self,CHAN_WEAPON,"weapons/sgun1.wav",1,ATTN_NORM);
        ClearMultiDamage();
        FireBulletsFrom(8,dir,'0.035 0.035 0',TRUE,muzzle);
        ApplyMultiDamage();
        self.knight_ready[k] = 2;
    } else if (k == 1) {
        sound(self,CHAN_WEAPON,"enforcer/enfire.wav",1,ATTN_NORM);
        launch_laser(muzzle,dir*600);
    } else {
        MMML_FireSound();
        entity rocket = launch_projectile(muzzle,dir*72,"voreball");
        SUB_ChangeModel(rocket,"progs/proj_missile.mdl");
        rocket.touch = SoldierMissileTouch;
        rocket.think = KnightGuide;
        rocket.nextthink = time+.05;
        rocket.lifetime_finished = time+5;
    }
}
