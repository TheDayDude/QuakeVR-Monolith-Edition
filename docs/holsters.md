# Holsters

Six slots use the existing QuakeVR body anchors, reach thresholds and nearest-hotspot selection: left/right shoulders (hotspots 3/4), hips (5/6), and torso (8/9). Body/crouch calibration continues to apply.

Grip an occupied slot with an empty hand to draw its weapon. Release grip at an empty slot to store the weapon in that hand. A full slot cannot be overwritten. The weapon moves between hand and slot; selecting a stored weapon through the inventory cannot create a second copy. Both hands receive hover feedback only for a valid draw or storage target. Reload components and engine-held objects block holster use in their hand.

Feedback follows `vr_holster_haptics`: 0 disabled, 1 continuous, 2 a fading entry pulse; `vr_holster_haptic_time` controls the pulse duration. Hand IDs follow upstream: 0 off hand, 1 main hand. These interactions use grip release at the target; they do not implement upstream quick-slot copying or sticky-grip mode.

Nailguns and Spikers keep their actual entity, magazine, ready state and safety through transfers. Other weapons keep their existing per-weapon player reload fields. Their off-hand representation supports carrying, storing, and passing to an empty main hand (grip near the other hand, hotspot 7). Firing/reloading those weapons still uses Monolith's existing main-hand implementation; this change does not add generic dual wielding. Nailguns/Spikers retain their existing two-hand firing support.

The engine's extended level parameters 17–42 preserve the six stored weapons, their displayed poses, off-hand contents, nailgun/Spiker state, and pistol reload state. Monolith's map variables and existing ammunition/loaded-state parameters remain in place. New-game and coop-respawn paths clear the new parameters. Spawn/disconnect cleanup releases the records. Quake entity fields also retain the layout in ordinary saves.

## Verification

`Misc/tests/mvr_holsters.qc` is an isolated server fixture, excluded from `QC/progs.src`. Copy QC to a test directory, append this fixture to its progs.src, call `MVR_RunHolsterTests()` at the beginning of the copied StartFrame, and point its progs output at a separate test mod. Supply the runtime asset directories and registered id1 data there. Compile with FTEQCC and run the engine with `-dedicated 1 -basedir <test-runtime> -game mvr -condebug +developer 1 +map mvr_start`. On Windows launch detached from the parent console so the dedicated server can allocate its own console. The fixture exits the process and prints `HOLSTER_TEST_PASS 509 checks` on success; assertion failures stop with a program error.

The checks execute real game bytecode: all eight weapon types across all six slots, transfers through either hand, hover eligibility, occupied slots, busy-hand rejection, simultaneous draw arbitration, pickup-gesture consumption, handoff, cleanup, and level-state reconstruction including a loaded, safe Spiker. Both production programs compile with zero warnings. Headset position/comfort, controller vibration strength, visual placement, real save/load and full campaign transitions still require hands-on acceptance.
