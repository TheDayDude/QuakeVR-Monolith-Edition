float mvr_test_ran, mvr_test_checks;
void(float ok, string message) MVR_TestAssert =
{
    mvr_test_checks += 1;
    if (!ok) { bprint("HOLSTER TEST FAILED: "); error(message); }
}
void(float off, float hotspot, float bits) MVR_TestGesture =
{
    self.vrbits0 = MVR_TRACKED | bits;
    if (off) self.offhand_hotspot = hotspot;
    else self.mainhand_hotspot = hotspot;
    MVR_HolsterFrame();
}
void() MVR_RunHolsterTests =
{
    if (mvr_test_ran) return;
    mvr_test_ran = TRUE;
    entity saved = self;
    self = spawn();
    self.animcontroller = spawn();
    self.animcontroller.owner = self;
    self.items = IT_WEAPONS;
    self.health = 100;
    self.vrbits0 = MVR_TRACKED;
    cvar_set("vr_holster_haptics", "2");
    // Every generic weapon: release into every slot, hover, draw into either hand, reholster, draw main.
    for (float w = 1; w <= 8; w += 1) {
        for (float i = 0; i < 6; i += 1) {
            float hs = i < 4 ? i+3 : i+4;
            float id = weaponsclass[w].id;
            self.nail_main = world;
            self.mvr_drawing = TRUE;
            W_ChangeWeapon(id,TRUE);
            self.mvr_drawing = FALSE;
            if (id == IT_NAILGUN) {
                self.nail_main = spawn();
                self.nail_main.weapon = id;
                self.nail_main.nail_loaded = self.nail_main.nail_ready = 1;
                self.nail_main.nail_rounds = 17;
            }
            string mdl = self.weaponmodel;
            MVR_TestGesture(FALSE,hs,8);
            MVR_TestAssert(self.mvr_hover_main == i+1,"held hover target");
            MVR_TestGesture(FALSE,hs,16);
            entity gun = self.mvr_holsters[i];
            MVR_TestAssert(gun && gun.weapon == id,"release stores weapon");
            MVR_TestAssert(self.weapon == IT_NO_WEAPON && !self.nail_main,"release empties hand");
            MVR_TestAssert(MVR_WeaponStored(id),"stored inventory unavailable");
            MVR_TestGesture(TRUE,hs,0);
            MVR_TestAssert(self.mvr_hover_off == i+1,"empty offhand hover");
            MVR_TestGesture(TRUE,hs,2);
            MVR_TestAssert(!self.mvr_holsters[i] && self.weapon2 == id,"offhand draw transfers");
            MVR_TestAssert(self.weaponmodel2 == mdl,"offhand model preserved");
            MVR_TestGesture(TRUE,hs,4);
            MVR_TestAssert(self.mvr_holsters[i] && !self.weapon2,"offhand release stores");
            MVR_TestGesture(FALSE,hs,8);
            MVR_TestAssert(!self.mvr_holsters[i] && self.weapon == id,"main draw transfers");
            MVR_TestAssert(self.mvr_holster_used & 2,"draw consumes grip");
            if (id == IT_NAILGUN) {
                MVR_TestAssert(self.nail_main == gun && gun.nail_rounds == 17 && gun.nail_ready,"nail identity and load preserved");
                remove(gun);
                self.nail_main = world;
            }
        }
    }
    // Storing a different inventory weapon must not discard a previously acquired nailgun's record.
    self.nail_main = spawn();
    self.nail_main.weapon = IT_NAILGUN;
    self.nail_main.nail_rounds = 13;
    entity cachedNail = self.nail_main;
    self.mvr_drawing = TRUE;
    W_ChangeWeapon(IT_SHOTGUN,TRUE);
    self.mvr_drawing = FALSE;
    MVR_TestGesture(FALSE,3,16);
    MVR_TestAssert(self.nail_main == cachedNail && cachedNail.nail_rounds == 13,"other weapon storage preserves nail inventory record");
    MVR_ResetHolsters();
    remove(cachedNail);
    self.nail_main = world;
    // Occupied slot does not overwrite either gun; busy hands cannot draw or hover.
    self.mvr_drawing = TRUE;
    W_ChangeWeapon(IT_SHOTGUN,TRUE);
    self.mvr_drawing = FALSE;
    MVR_TestGesture(FALSE,3,16);
    entity pistol = self.mvr_holsters[0];
    W_ChangeWeapon(IT_AXE,TRUE);
    MVR_TestGesture(FALSE,3,16);
    MVR_TestAssert(self.weapon == IT_AXE && self.mvr_holsters[0] == pistol,"full slot rejects release");
    MVR_TestAssert(!self.mvr_hover_main,"full slot does not buzz held gun");
    W_ChangeWeapon(IT_NO_WEAPON,TRUE);
    MVR_TestGesture(FALSE,3,8 | 262144);
    MVR_TestAssert(self.weapon == IT_NO_WEAPON && self.mvr_holsters[0] == pistol,"busy hand cannot draw");
    MVR_TestAssert(!self.mvr_hover_main,"busy hand cannot hover");
    // Two hands grabbing the same slot in one frame yields exactly one weapon.
    self.offhand_hotspot = self.mainhand_hotspot = 3;
    self.vrbits0 = MVR_TRACKED | 8 | 2;
    MVR_HolsterFrame();
    MVR_TestAssert(self.weapon == IT_SHOTGUN && !self.weapon2 && !self.mvr_holsters[0],"simultaneous draw is atomic");
    MVR_TestGesture(FALSE,3,16);
    // Nailgun drop code must ignore a draw's grip edge.
    MVR_TestGesture(FALSE,3,8);
    self.handpos = '10000 10000 10000';
    MVR_PistolFrame();
    MVR_TestAssert(self.weapon == IT_SHOTGUN,"pickup handler cannot replace draw");
    // Off-hand gun handoff.
    MVR_TestGesture(FALSE,3,16);
    MVR_TestGesture(TRUE,3,2);
    MVR_TestGesture(FALSE,7,8);
    MVR_TestAssert(self.weapon == IT_SHOTGUN && !self.weapon2 && !self.mvr_offweapon,"offhand pass to main");
    // Persist all six slots, off hand, and nailgun's identity/state across a level reconstruction.
    MVR_ResetHolsters();
    for (float j = 0; j < 6; j += 1) {
        self.mvr_holsters[j] = MVR_RestoreHolstered(j+1,0,j);
    }
    entity spikerGun = MVR_RestoreHolstered(9,17+32+64+128,2);
    MVR_HolsterEquip(TRUE,spikerGun);
    self.pistol_ammo_count = 7;
    self.mvr_pistol_phase = 2;
    MVR_SaveHolsterParms();
    MVR_ResetNails();
    MVR_ResetHolsters();
    MVR_RestoreHolsterParms();
    for (float k = 0; k < 6; k += 1) {
        MVR_TestAssert(self.mvr_holsters[k].weapon == weaponsclass[k+1].id,"level restore weapon type");
        MVR_TestAssert(self.mvr_holsters[k].frame == k,"level restore pose");
    }
    MVR_TestAssert(self.nail_off && self.nail_off.spiker && self.nail_off.spiker_safe && self.nail_off.nail_rounds == 17 && self.nail_off.nail_ready,"level restore Spiker state");
    MVR_TestAssert(self.pistol_ammo_count == 7 && self.mvr_pistol_phase == 2,"level restore pistol reload state");
    MVR_ResetNails();
    MVR_ResetHolsters();
    MVR_TestAssert(!self.holsterweapon0 && !self.holsterweapon5 && !self.weapon2,"cleanup clears rendered slots");
    localcmd("echo HOLSTER_TEST_PASS "); localcmd(ftos(mvr_test_checks)); localcmd(" checks\n");
    self = saved;
    localcmd("quit\n");
}
