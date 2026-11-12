//=============================================================================================
// multi-hit melee sweeping code by bmFbr, edits by Kebby
//=============================================================================================
/*
	Wrench 
	{0-70}
	v_wrench
	
	0  idle
	1-10  draw > idle
	11-(14)-[26]-30  swing
	31-(34)-[46]-50  swing
	51-(54)-[66]-70  swing
	~~~
	71-80  twirl
	81-101  idle loop
	
	*swing (hit) [skip] > idle
	
	MD3
	v_wrench_gloves
	v_wrench
*/
//=============================================================================================

float() weaponanim_wrench =
{
	if (has_berserk(self))
		return weaponanim_berserk();

	if (self.vrbits0 & MVR_TRACKED) return FALSE;

	if (self.attack_finished > time)
		return FALSE;

	//sound (self, CHAN_OTHER, "weapons/ax1.wav", 1, ATTN_NORM);
	sound (self, CHAN_OTHER, "impact/wrench_swing.wav", 1, ATTN_NORM);
	SuperDamageSound();
	
	self.attack_finished = time + 0.8;
	
	
	local float r = floor(random()*3);
	if 	(r== 0)	self.weaponframe = 11;
	else if (r== 1)	self.weaponframe = 31;
	else		self.weaponframe = 51;
	
	// converts weaponframe to a 0-4 integer selector for the player animation
	//player_axe_start(self.animcontroller, (self.weaponframe - 1)/20);
	
	
	SUB_CallAsSelf(player_wrench1, self.animcontroller);
	
	
	self.think = weaponanim_wrench_loop;
	self.nextthink = time + 0.05;

	return FALSE; // axe swing will never count as fired until it hits something
}

void() weaponanim_wrench_loop =
{
	if (self.weaponframe == 14 || self.weaponframe == 34 || self.weaponframe == 54)
		W_FireWrench();

	if (self.weaponframe == 30 || self.weaponframe == 50 || self.weaponframe == 70)
	{
		self.weaponframe = 10;
		return;
	}
	else 	self.weaponframe++;

	self.think = weaponanim_wrench_loop;
	self.nextthink = time + 0.05;
}

////////////////////////////////////////////////////////////////////////////////////////////////

void() weaponanim_draw_wrench =
{		
	if (has_berserk(self)) {
		weaponanim_draw_berserker();
		return;
	}

	if (self.vrbits0 & MVR_TRACKED) {
        self.weaponmodel = "progs/v_mvrwrench.mdl";
        self.weaponframe = 0;
        return;
    }

    sound (self, CHAN_AUTO, "misc/draw1.wav", 0.1, ATTN_NORM);
	
	self.weaponframe = 1;
	
	self.think = weaponanim_draw_loop;
	self.nextthink = time + 0.033;
}

/*
void() wrench_hitsound =
{
	if (random() < 0.5)	sound (self, CHAN_WEAPON, "weapons/axhit1.wav", 1, ATTN_NORM);
	else			sound (self, CHAN_WEAPON, "weapons/axhit2.wav", 1, ATTN_NORM);
}
*/
//=============================================================================================

void(float wrenchhit_volume) sound_wrench_hit_enemy =
{
	local float r = floor(random()*4);
	if 	(r == 0)	sound (self, CHAN_AUTO, "impact/wrench_impact1.wav", wrenchhit_volume, ATTN_NORM);
	else if (r == 1)	sound (self, CHAN_AUTO, "impact/wrench_impact2.wav", wrenchhit_volume, ATTN_NORM);
	else if (r == 2)	sound (self, CHAN_AUTO, "impact/wrench_impact3.wav", wrenchhit_volume, ATTN_NORM);
	else 			sound (self, CHAN_AUTO, "impact/wrench_impact4.wav", wrenchhit_volume, ATTN_NORM);
}
//=============================================================================================

void(float meleehit_volume) sound_melee_hit_player =
{
	local float r = floor(random()*4);
	if 	(r == 0)	sound (self, CHAN_AUTO, "impact/hit_player1.wav", meleehit_volume, ATTN_NORM);
	else if (r == 1)	sound (self, CHAN_AUTO, "impact/hit_player2.wav", meleehit_volume, ATTN_NORM);
	else if (r == 2)	sound (self, CHAN_AUTO, "impact/hit_player3.wav", meleehit_volume, ATTN_NORM);
	else 			sound (self, CHAN_AUTO, "impact/hit_player4.wav", meleehit_volume, ATTN_NORM);
}
//=============================================================================================

void(float wrenchclank_volume) sound_wrench_hit_world =
{
	sound (self, CHAN_AUTO, "impact/wrench_clink.wav", wrenchclank_volume, ATTN_NORM);
	//if (random() < 0.5)	sound (self, CHAN_AUTO, "impact/wrench_clank1.wav", wrenchclank_volume, ATTN_NORM);
	//else			sound (self, CHAN_AUTO, "impact/wrench_clank2.wav", wrenchclank_volume, ATTN_NORM);
}

//=============================================================================================

.float	wrenchhitme;

void() W_FireWrench =
{
	local	vector	source;
	
	entity hitent1, hitent2;
	vector hitpos1, hitpos2;
	float shortest_hit1 = 1000;
	float shortest_hit2 = 1000;

	makevectors (self.v_angle);
	source = self.origin + self.view_ofs - v_up*0;

	traceline2 (source, source + v_forward*60 - v_right*40, self, FALSE);
	if (trace_fraction < 1) {
		shortest_hit1 = vlen(trace_endpos - source);
		hitent1 = trace_ent;
		hitpos1 = trace_endpos;
 	}

	traceline2 (source, source + v_forward*72 - v_right*20, self, FALSE);
	if (trace_fraction < 1) {
		if (trace_ent == hitent1 && vlen(trace_endpos - source) < shortest_hit1) {
			shortest_hit1 = vlen(trace_endpos - source);
			hitent1 = trace_ent;
			hitpos1 = trace_endpos;
		}
		if (trace_ent != hitent1 && vlen(trace_endpos - source) < shortest_hit2) {
			shortest_hit2 = vlen(trace_endpos - source);
			hitent2 = trace_ent;
			hitpos2 = trace_endpos;
		}
	}

	traceline2 (source, source + v_forward*86, self, FALSE);
	if (trace_fraction < 1) {
		if (trace_ent == hitent1 && vlen(trace_endpos - source) < shortest_hit1) {
			shortest_hit1 = vlen(trace_endpos - source);
			hitent1 = trace_ent;
			hitpos1 = trace_endpos;
		}
		if (trace_ent != hitent1 && vlen(trace_endpos - source) < shortest_hit2) {
			shortest_hit2 = vlen(trace_endpos - source);
			hitent2 = trace_ent;
			hitpos2 = trace_endpos;
		}
	}

	traceline2 (source, source + v_forward*72 + v_right*20, self, FALSE);
	if (trace_fraction < 1) {
		if (trace_ent == hitent1 && vlen(trace_endpos - source) < shortest_hit1) {
			shortest_hit1 = vlen(trace_endpos - source);
			hitent1 = trace_ent;
			hitpos1 = trace_endpos;
		}
		if (trace_ent != hitent1 && vlen(trace_endpos - source) < shortest_hit2) {
			shortest_hit2 = vlen(trace_endpos - source);
			hitent2 = trace_ent;
			hitpos2 = trace_endpos;
		}
	}

	traceline2 (source, source + v_forward*60 + v_right*40, self, FALSE);
	if (trace_fraction < 1) {
		if (trace_ent == hitent1 && vlen(trace_endpos - source) < shortest_hit1) {
			shortest_hit1 = vlen(trace_endpos - source);
			hitent1 = trace_ent;
			hitpos1 = trace_endpos;
		}
		if (trace_ent != hitent1 && vlen(trace_endpos - source) < shortest_hit2) {
			shortest_hit2 = vlen(trace_endpos - source);
			hitent2 = trace_ent;
			hitpos2 = trace_endpos;
		}
	}

	if (shortest_hit1 == 1000 && shortest_hit2 == 1000) {
		return;
	}

	self.show_hostile = time + 1; // hit something, so alert monsters
	
	vector dir = v_right * 20 - v_up*5; // direction for blood particles

	if (shortest_hit1 < 1000) hitwrench(hitent1, hitpos1 - v_forward*4, dir);
	if (shortest_hit2 < 1000 && hitent1 != hitent2) hitwrench(hitent2, hitpos2 - v_forward*4, dir);
};
//=============================================================================================

void(entity hitent, vector org, vector dir) hitwrench =
{
	if (hitent.takedamage) 
	{		
		hitent.wrenchhitme = 1;

		SpawnBlood(org, dir, 60);

		FX_Impact(FX_BLOOD, org, dir);

		if (hitent.classname == "monster_zombie") //keep zombies Unbonkable
			T_Damage(hitent, self, self, 59, DMGTYPE_MELEE);
		else	
			T_Damage(hitent, self, self, 60, DMGTYPE_MELEE);
		
		//johnfitz -- make clank sound when hitting brushmodels
		if (hitent.movetype == MOVETYPE_PUSH || hitent.movetype == MOVETYPE_NONE)
			sound_wrench_hit_world(1);

		if ((hitent.flags & FL_MONSTER) || (hitent.classname == "player"))
		{	
			sound_wrench_hit_enemy(1);
					
			if ((hitent.movetype == MOVETYPE_STEP || hitent.movetype == MOVETYPE_WALK) && 
				// don't swat bosses or other non-standard-sized enemies around
				hitent.maxs_x <= 32 && hitent.health > 0 && hitent.type != "boss")
			{
				local vector toss;
				toss = v_forward;
				toss_z = 0;
				toss = normalize(toss) * 200;
				toss_z = 150;
				hitent.origin_z = hitent.origin_z + 1;
				hitent.velocity = toss;
				hitent.flags = not(hitent.flags, FL_ONGROUND);
			}	
		}
		//johnfitz

		if (hitent.flags & FL_MONSTER)
		{
			if (hitent.type == "zombie")
				zombie_knockdown(hitent);
			
			sound_wrench_hit_enemy(1);
		}
		else
		{
			sound (self, CHAN_WEAPON, "zombie/z_hit.wav", 1, ATTN_IDLE);
			sound_wrench_hit_enemy(1);
		}
				
		// do knockback with a quad
		if (has_quad(self))
		{
			if ((hitent.movetype == MOVETYPE_STEP || hitent.movetype == MOVETYPE_WALK) && 
				// don't swat bosses or other non-standard-sized enemies around
				hitent.maxs_x <= 32 && hitent.health > 0 && hitent.type != "boss")
			{
				toss = v_forward;
				toss_z = 0;
				toss = normalize(toss) * 800;
				toss_z = 150;
				hitent.origin_z = hitent.origin_z + 1;
				hitent.velocity = toss;
				hitent.flags = not(hitent.flags, FL_ONGROUND);
			}
		}
	}
	else	{	// hit wall
		sound (self, CHAN_WEAPON, "player/axhit2.wav", 0.2, ATTN_NORM);
		sound_wrench_hit_world(0.8);
		
		FX_Impact(FX_SPARK, org, dir);

		gunshot(org);
	}
}
.vector wrench_last_grip, wrench_last_tip, wrench_last_origin;
.float vryaw, wrench_last_yaw, wrench_sample, wrench_started, wrench_moving;
.float wrench_swinging;

void(vector grip, vector tip, vector motion) MVR_WrenchContact =
{
    traceline2(grip, tip, self, FALSE);
    if (trace_fraction == 1 || trace_startsolid) return;
    entity target = trace_ent;
    vector contact = trace_endpos;
    // Each player's swing owns its contacts, including a single contact for the world.
    entity mark = world;
    while ((mark = find(mark, classname, "mvr_wrench_contact"))) {
        if (mark.owner == self && mark.enemy == target && mark.ltime == self.wrench_started)
            return;
    }
    mark = spawn();
    mark.classname = "mvr_wrench_contact";
    mark.owner = self;
    mark.enemy = target;
    mark.ltime = self.wrench_started;
    mark.think = SUB_Remove;
    mark.nextthink = time + 0.8;

    self.show_hostile = time + 1;
    makevectors(vectoangles(motion));
    hitwrench(target, contact, motion * 20);
}

void() MVR_WrenchFrame =
{
    if (self.weapon != IT_AXE || has_berserk(self) || !(self.vrbits0 & MVR_TRACKED)) {
        if (self.weapon == IT_AXE && self.weaponmodel == "progs/v_mvrwrench.mdl") {
            self.weaponmodel = "progs/v_wrench.mdl";
            if (has_berserk(self)) self.weaponmodel = "progs/v_berserk.mdl";
            weaponanim_draw_wrench();
        }
        self.wrench_sample = self.wrench_swinging = 0;
        return;
    }

    // Tracking can arrive after the initial weapon selection at spawn.
    if (self.weaponmodel != "progs/v_mvrwrench.mdl") {
        self.weaponmodel = "progs/v_mvrwrench.mdl";
        self.weaponframe = 0;
        self.think = SUB_Null;
        self.wrench_sample = 0;
    }

    vector tip = self.muzzlepos; // anchor on the rendered jaw, including its weight spring
    vector grip = self.handpos;
    vector previous_tip = self.wrench_last_tip;
    vector previous_grip = self.wrench_last_grip;
    vector step = tip - previous_tip;
    vector body_step = self.origin - self.wrench_last_origin;
    float elapsed = time - self.wrench_sample;
    float reset = !self.wrench_sample || elapsed > 0.12 ||
        vlen(step) > 48 || vlen(body_step) > 32 || fabs(self.vryaw - self.wrench_last_yaw) > 15;
    if (!reset && tip == previous_tip && grip == previous_grip) {
        self.wrench_sample = time;
        self.wrench_last_origin = self.origin;
        if (time - self.wrench_moving > 0.09) self.wrench_swinging = FALSE;
        return;
    }
    self.wrench_sample = time;
    self.wrench_last_tip = tip;
    self.wrench_last_grip = grip;
    self.wrench_last_origin = self.origin;
    self.wrench_last_yaw = self.vryaw;
    if (reset || elapsed <= 0 || vlen(tip - grip) < 4) {
        self.wrench_swinging = FALSE;
        return;
    }

    vector swing = step - body_step;
    float speed = vlen(swing) / elapsed;
    if (speed < 32) {
        if (time - self.wrench_moving > 0.09) self.wrench_swinging = FALSE;
        return;
    }
    self.wrench_moving = time;
    if (!self.wrench_swinging) {
        if (speed < 72 || time < self.attack_finished) return;
        self.wrench_swinging = TRUE;
        self.wrench_started = time;
        self.attack_finished = time + 0.8;
        sound(self, CHAN_OTHER, "impact/wrench_swing.wav", 1, ATTN_NORM);
        SuperDamageSound();
        SUB_CallAsSelf(player_wrench1, self.animcontroller);
    }
    if (time - self.wrench_started > 0.55) return;

    // Sweep the length of the wrench through successive poses, stopping each
    // ray at its first obstruction. A later part of the arc may reach another foe.
    float steps = max(1, ceil(max(vlen(step), vlen(grip - previous_grip)) / 3));
    vector direction = normalize(swing);
    for (float i = 1; i <= steps; i++) {
        float t = i / steps;
        MVR_WrenchContact(previous_grip + (grip - previous_grip) * t,
            previous_tip + step * t, direction);
    }
}
