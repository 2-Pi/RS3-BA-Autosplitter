state("rs2client")
{
	bool hardmode : 0x691868, 0x18, 0x38, 0x28, 0xA98, 0x50, 0x30;
	ushort nmwave : 0x691868, 0x18, 0x38, 0x28, 0x2E80, 0x32;
	byte hmwave : 0x691868, 0x18, 0x38, 0x28, 0xA90, 0x50, 0x30;
	float x : 0x691868, 0x60, 0xBB0, 0x2C;
	float y : 0x691868, 0x60, 0xBB0, 0x34;
}

init
{
	vars.first_wave = false;
	vars.wave_completed = false;
	vars.wave_progress = 0;
	vars.in_basement = false;
	vars.room = 0;
	
}

startup
{
	settings.Add("qs", true, "Split quickstarts");
	settings.SetToolTip("qs", "Split downtime/quickstarts between waves separately.");
}

update
{
	// Wave progress
	current.wave_progress = current.hardmode ? (int)current.hmwave / 0x8 : ((int)current.nmwave - 0x2000) / 0x80;
	
	// Position relative to SW tile of BA basement
	current.x = (int)(current.x / 0x200) - 2573;
	current.y = (int)(current.y / 0x200) - 5251;
	
	// Skip if position is unchanged
	if (current.x == old.x && current.y == old.y && current.wave_progress == old.wave_progress) {
		return false;
	}
	
	// Check if in BA basement
	current.in_basement = current.x >= 0 && current.x <= 41 && current.y >= 0 && current.y <= 57;
	
	// Determine room number
	if (!current.in_basement) {
		// Outside basement
		current.room = 0;
	}
	else {
		int row;
		int col;
		if (current.y >= 44 && current.y <= 57) {
			// Rooms 1-4
			row = 0;
			col = (current.x - 1) / 10 + 1;
		}
		else if (current.y >= 28 && current.y <= 41 && current.x != 20 && current.x != 21) {
			// Rooms 5-8
			row = 1;
			col = current.x <= 19 ? current.x / 10 + 1 : (current.x - 2) / 10 + 1;
		}
		else if (current.y >= 12 && current.y <= 25 && current.x <= 19) {
			// Rooms 9-10
			row = 2;
			col = current.x / 10 + 1;
		}
		else {
			// Corridors
			row = 0;
			col = 0;
		}

		current.room = 4 * row + col;
	}
	
	// Debug info
	print("x: " + current.x.ToString() +
		"\ny: " + current.y.ToString() +
		"\nHard Mode: " + current.hardmode.ToString() + 
		"\nWave: " + current.wave_progress.ToString() + 
		"\nBasement: " + current.in_basement.ToString() + 
		"\nRoom: " + current.room.ToString());
}

start
{
	// Enter wave
	if (old.room == current.wave_progress && !current.in_basement) {
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
	if (settings["qs"] && old.room == current.wave_progress && !current.in_basement && vars.wave_completed) {
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
	if (old.room == 0 && current.room != 0 && vars.first_wave) {
		vars.first_wave = false;
		return true;
	}

	// Leave basement
	if (old.room == 0 && old.in_basement && !current.in_basement) {
		vars.wave_completed = false;
		return true;
	}
}
