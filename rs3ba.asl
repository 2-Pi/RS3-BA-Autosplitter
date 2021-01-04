state("rs2client")
{
	bool hmtoggle : 0x691868, 0x18, 0x38, 0x28, 0xA98, 0x50, 0x30;
	ushort nmwave : 0x691868, 0x18, 0x38, 0x28, 0x2E80, 0x32;
	byte hmwave : 0x691868, 0x18, 0x38, 0x28, 0xA90, 0x50, 0x30;
	float x : 0x691868, 0x60, 0xBB0, 0x2C;
	float y : 0x691868, 0x60, 0xBB0, 0x34;
}

init
{
	vars.wave = 0;
	vars.basement = false;
	vars.row = 0;
	vars.col = 0;
	vars.room = 0;
	vars.completed = false;
}

update
{
	// Wave progress
	current.nmwave = ((int)current.nmwave - 0x2000) / 0x80;
	current.hmwave = (int)current.hmwave / 0x8;
	current.wave = current.hmtoggle ? current.hmwave : current.nmwave;
	
	// Position relative to SW tile of BA basement
	current.x = (int)(current.x / 0x200) - 2573;
	current.y = (int)(current.y / 0x200) - 5251;
	
	// Skip if position and wave progress are unchanged
	if (current.x == old.x && current.y == old.y && current.wave == old.wave) {
		return false;
	}
	
	// Check if in BA basement
	current.basement = (current.x >= 0 && current.x <= 41 && current.y >= 0 && current.y <= 57) ? true : false;
	
	// Determine room number
	if (!current.basement) {
		// Outside basement
		current.room = 0;
	}
	else {
		if (current.y >= 44 && current.y <= 57) {
			// Rooms 1-4
			current.row = 0;
			current.col = (current.x - 1) / 10 + 1;
		}
		else if (current.y >= 28 && current.y <= 41 && current.x != 20 && current.x != 21) {
			// Rooms 5-8
			current.row = 1;
			current.col = current.x <= 19 ? current.x / 10 + 1 : (current.x - 2) / 10 + 1;
		}
		else if (current.y >= 12 && current.y <= 25 && current.x <= 19) {
			// Rooms 9-10
			current.row = 2;
			current.col = current.x / 10 + 1;
		}
		else {
			// Corridors
			current.row = 0;
			current.col = 0;
		}
		
		// Room number
		current.room = 4 * current.row + current.col;
	}
	
	
	print("x: " + current.x.ToString() +
		"\ny: " + current.y.ToString() +
		"\nHard Mode: " + current.hmtoggle.ToString() + 
		"\nWave: " + current.wave.ToString() + 
		"\nBasement: " + current.basement.ToString() + 
		"\nRoom: " + current.room.ToString());
}

start
{
	// Enter wave
	if (old.room == current.wave && !current.basement) {
		return true;
	}
}

split
{
	// Complete wave
	if (current.wave == old.wave + 1 || (current.wave == 1 && old.wave == 10)) {
		vars.completed = true;
		return true;
	}
	
	// Enter wave after previous one is completed
	if (old.room == current.wave && !current.basement && vars.completed) {
		vars.completed = false;
		return true;
	}
}

reset
{
	// Enter wave 1 room or leave basement
	if ((old.room == 0 && current.room == 1) || (old.room == 0 && old.basement && !current.basement)) {
		return true;
	}
}
