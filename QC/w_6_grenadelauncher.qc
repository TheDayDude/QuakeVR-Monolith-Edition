//=============================================================================================
// Grenade Launcher
//=============================================================================================
/*
	Grenade Launcher
	{0-31}
	v_grenlauncher
	
	0  idle
	1-10  draw > idle
	11-31  fire > idle
	
	MD3
	v_grenlauncher_gloves
	v_grenlauncher
	v_grenlauncher_muzz
*/
//=============================================================================================

float() weaponanim_qbj3grenade =
{
	if (self.attack_finished > time)
		return FALSE;

    if (self.vrbits0 & MVR_TRACKED) {
        if (!self.gren_loaded || self.gren_wait_release) return FALSE;
        self.gren_loaded--;
        self.currentammo = self.weaponframe = self.gren_loaded;
        self.attack_finished = time + .6;
        self.effects |= EF_MUZZLEFLASH;
        SUB_CallAsSelf(player_rockatt1, self.animcontroller);
        W_FireQBJ3Grenade();
        entity spent = spawn();
        setmodel(spent,"progs/mvr_canister.mdl");
        setorigin(spent,MVR_GrenadeSocket());
        spent.angles = self.handrot;
        spent.movetype = MOVETYPE_BOUNCE;
        spent.velocity = v_up*90 + v_right*35;
        spent.avelocity = '80 0 140';
        spent.think = SUB_Remove;
        spent.nextthink = time+3;
        return TRUE;
    }

	if (W_CheckWeapon(self.weapon, self) != WEAPONSTAT_AVAILABLE)
	{
		W_ChangeWeapon(W_BestWeapon(), FALSE);
		return FALSE;
	}

	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;

	self.attack_finished = time + 0.6;
	
	SUB_CallAsSelf(player_rockatt1, self.animcontroller);
	
	self.effects = self.effects | EF_MUZZLEFLASH;

	W_FireQBJ3Grenade(); //<<<

	self.weaponframe = 11;
	
	self.think = weaponanim_qbj3grenade_loop;
	self.nextthink = time + 0.05;
	
	return TRUE;
}

void() weaponanim_qbj3grenade_loop =
{
	if (self.weaponframe >= 30)
	{
		self.weaponframe = 10;
		return;
	}
	else 	self.weaponframe++;

	self.think = weaponanim_qbj3grenade_loop;
	self.nextthink = time + 0.05;
}
//=============================================================================================

void(float grenfire_volume) sound_grenade_fire =
{
	local float r = floor(random()*3);
	if 	(r == 0)	sound (self, CHAN_AUTO, "grenade/grenade_fire1.wav", grenfire_volume, ATTN_NORM);
	else if (r == 1)	sound (self, CHAN_AUTO, "grenade/grenade_fire2.wav", grenfire_volume, ATTN_NORM);
	else			sound (self, CHAN_AUTO, "grenade/grenade_fire3.wav", grenfire_volume, ATTN_NORM);
}
//=============================================================================================

void() W_FireQBJ3Grenade =
{
	entity g;
	float base;
	vector gvel;
	
	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);	
	sound (self, CHAN_AUTO, "grenade/grenade_reload.wav", 0.5, ATTN_NORM);
	sound_grenade_fire(0.6);
	SuperDamageSound();
	
	self.punchangle_x = -2;

	// set grenade speed	
	makevectors (self.v_angle);
	base = 200;
	if (self.v_angle_x)
		gvel = v_forward * base * 3 + v_up * base + crandom() * v_right * 10 + crandom() * v_up * 10;
	else
	{
		gvel = aim(self, AUTOAIM_DIST);
		gvel = gvel * base * 3;
		gvel_z = base;
	}
	
	if (self.vrbits0 & MVR_TRACKED) {
        makevectors(self.handrot);
        traceline(self.handpos,self.handpos + 29*v_forward + 8*v_up,FALSE,self);
        makevectors(self.shotrot);
        g = launch_qbj3grenade(trace_endpos,v_forward*600 + v_up*200);
    } else g = launch_qbj3grenade(self.origin, gvel);
	g.touch = GrenadeTouch;
	g.th_die = GrenadeExplode;
}

entity(vector org, vector vel) launch_qbj3grenade =
{
	entity grenade;
	
	grenade = toss_projectile(org, vel, "grenade");
	grenade.lifetime_finished = time + 2.5;
	grenade.avelocity = '300 300 300';	//ID1 tumble
	//grenade.avelocity = '-600 0 0';
	SUB_ChangeModel (grenade, "progs/proj_grenade.mdl");
	
	return grenade;
}