state("rs2client")
{
	ushort nmwave : 0x69AD38, 0x18, 0x38, 0x28, 0x2E80, 0x32;
	byte hmwave : 0x69AD38, 0x18, 0x38, 0x28, 0xA90, 0x50, 0x30;
	float x : 0x69AD38, 0x60, 0xBB0, 0x2C;
	float y : 0x69AD38, 0x60, 0xBB0, 0x34;
	int pocketID : 0x69AD38, 0x60, 0xCD8, 0x8, 0x70, 0x88;
}

init
{
	vars.first_wave = false;
	vars.wave_completed = false;
	vars.wave_progress = 0;
	vars.in_basement = false;
	vars.pocketIDs = new int[] {
		15445, 15446, 15447, 15448, 15449,  // Attacker 1-5
		15450, 15451, 15452, 15453, 15454,  // Collector 1-5
		15455, 15456, 15457, 15458, 15459,  // Defender 1-5
		15460, 15461, 15462, 15463, 15464   // Healer 1-5
	};
	refreshRate = 30;
}

startup
{
	settings.Add("qs", true, "Split quickstarts");
	settings.SetToolTip("qs", "Split downtime/quickstarts between waves separately.");
}

update
{
	// Wave progress
	current.wave_progress = Math.Max((int)current.hmwave / 0x8, ((int)current.nmwave - 0x2000) / 0x80);

	// Position relative to SW tile of BA basement
	current.x = (int)(current.x / 0x200) - 2573;
	current.y = (int)(current.y / 0x200) - 5251;

	// Skip if nothing has changed
	if (current.x == old.x && current.y == old.y && current.wave_progress == old.wave_progress && current.pocketID == old.pocketID) {
		return false;
	}
	
	// Check if in BA basement
	current.in_basement = current.x >= 0 && current.x <= 41 && current.y >= 0 && current.y <= 57;
	
	// Debug info
	print("x: " + current.x.ToString() +
		"\ny: " + current.y.ToString() +
		"\nWave: " + current.wave_progress.ToString() + 
		"\nBasement: " + current.in_basement.ToString() +
		"\nPocket Slot: " + current.pocketID.ToString());
}

start
{
	// Enter wave
	if ((old.pocketID == -1 || old.pocketID == 0) && Array.IndexOf(vars.pocketIDs, current.pocketID) != -1) {
		vars.wave_completed = false;
		vars.first_wave = true;
		return true;
	}
}

split
{
	// Complete wave
	if ((current.wave_progress == old.wave_progress + 1) || (current.wave_progress == 1 && old.wave_progress == 10)) {
		vars.wave_completed = true;
		vars.first_wave = false;
		return true;
	}
	
	// Enter wave after previous one is completed
	if (settings["qs"] && old.pocketID == -1 && Array.IndexOf(vars.pocketIDs, current.pocketID) != -1 && vars.wave_completed) {
		vars.wave_completed = false;
		return true;
	}
}

reset
{
	// Reset to lower wave
	if (current.wave_progress < old.wave_progress && current.in_basement) {
		vars.wave_completed = false;
		return true;
	}

	// Fail first wave
	if (Array.IndexOf(vars.pocketIDs, old.pocketID) != -1 && current.pocketID == -1 && vars.first_wave == true) {
		vars.first_wave = false;
		return true;
	}
}
