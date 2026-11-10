// The three editor pickups double as signs and gate anchors in Limbo only.
void() mvr_gate_touch =
{
    if (other.classname != "player" || other.health <= 0 || self.attack_finished > time)
        return;
    self.attack_finished = time + 2;
    if (self.classname == "weapon_invoker")
        localcmd("mvr_campaign qbj3\n");
    else if (self.classname == "item_artifact_super_damage")
        localcmd("mvr_campaign quake\n");
    else
        centerprint(other, "Tutorial coming soon\n");
};

float(string marker_model) mvr_gate_marker =
{
    if (mapname != "mvr_start")
        return FALSE;
    precache_model_safe(marker_model);
    setmodel(self, marker_model);
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_TRIGGER;
    self.touch = mvr_gate_touch;
    // The sign hangs above the gate. Walking underneath enters it.
    setsize(self, '-30 -30 -144', '30 30 12');
    setorigin(self, self.origin);
    return TRUE;
};
