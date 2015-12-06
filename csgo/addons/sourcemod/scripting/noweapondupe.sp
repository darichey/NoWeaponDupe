#pragma semicolon 1

#include <sourcemod>

EngineVersion g_Game;

// Hashmap of players who are on cooldown. ClientID : Time When Banned
new StringMap:dropBanned;
// Hashmap of players who might need to be put on cooldown. ClientID : Array[# weapons dropped, time first weapon was dropped]
new StringMap:watching;

ConVar nwd_drop_cooldown = null;
ConVar nwd_drop_limit = null;
ConVar nwd_drop_limit_time = null;

public Plugin myinfo = {
	name = "No Weapon Dupe",
	author = "Grand_Panda",
	description = "Prevents weapon 'duping' when players try to throw many guns on the ground.",
	version = "1.0",
	url = ""
};

public void OnPluginStart() {	
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS) {
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	LoadTranslations("common.phrases.txt");
	dropBanned = new StringMap();
	watching = new StringMap();
	nwd_drop_cooldown = CreateConVar("nwd_drop_cooldown", "3", "The cooldown time on dropping weapons on the ground.");
	nwd_drop_limit = CreateConVar("nwd_drop_limit", "2", "Number of weapons that can drop in <nwd_drop_limit_time> seconds before cooldown.");
	nwd_drop_limit_time = CreateConVar("nwd_drop_limit_time", "2", "Amount of time a player has to drop <nwd_drop_limit> weapons before cooldown.");
	AutoExecConfig(true, "plugin_noweapondupe");
}

public Action CS_OnCSWeaponDrop(int client, int weaponIndex) {
	// Check if the cooldown time is above 0
	if (GetConVarInt(nwd_drop_cooldown) > 0) {
		// Check if the given client is currently on cooldown
		if (IsDropBanned(client)) {
			// Cancel drop and inform user
			PrintToChat(client, "[NWD] You may not drop your weapon for %i seconds.", GetTimeBanned(client));
			return Plugin_Stop;	
		} else {
			// Convert client to string
			new String:clientKey[2];
			IntToString(client, clientKey, sizeof(clientKey));
			// Get table containing information on when the user first dropped a weapon and how many since then. See StringMap:watching above
			new dropInfo[2];
			new bool:keyExists = watching.GetArray(clientKey, dropInfo, sizeof(dropInfo));
			
			// Check if the client is already being watched
			if (keyExists) {
				// Check if they should still be on the watch list.
				if (GetTime() <= dropInfo[1] + GetConVarInt(nwd_drop_limit_time)) {
					// If they should still be watched, check if the amount of guns they've dropped since then exceeds the amount they are allowed
					new gunsDropped = dropInfo[0] + 1;
					if (gunsDropped >= GetConVarInt(nwd_drop_limit)) {
						// If so, put them on cooldown
						DropBan(client);
					} else {
						// If not, update the information in the table
						Watch(client, gunsDropped, dropInfo[1]);
					}
				} else {
					// If they should no longer be watched, remove them from the watch list
					watching.Remove(clientKey);	
				}
			} else {
				// If they aren't being watched, add them to the watch list
				Watch(client, 1, GetTime());
			}
		}
	}
	return Plugin_Continue;
}

// Adds or modifies an entry on the watching StringMap
public void Watch(int client, int gunsDropped, int time) {
		// Convert client to string
		new String:clientKey[2];
		IntToString(client, clientKey, sizeof(clientKey));
		
		// Create array with new information
		new storeArray[2];
		storeArray[0] = gunsDropped;
		storeArray[1] = time;
		watching.SetArray(clientKey, storeArray, sizeof(storeArray), true);
}

// Returns if a player is on cooldown
public bool IsDropBanned(int client) {
	// Convert client to string
	new String:clientKey[2];
	IntToString(client, clientKey, sizeof(clientKey));
	// Get the time at which the user was put on cooldown
	new timeBanned;
	new bool:keyExists = dropBanned.GetValue(clientKey, timeBanned);
	
	// If the user's ID isn't on the list, they aren't on cooldown
	if (!keyExists) {
		return false;
	}
	
	// Check if the user should still be on cooldown
	if (GetTime() >= timeBanned + GetConVarInt(nwd_drop_cooldown)) {
		// If not, remove them from the list
		dropBanned.Remove(clientKey);
		return false;
	}
	return true;
}

// Put a player on cooldown
public void DropBan(int client) {
	// Convert client to string
	new String:clientKey[2];
	IntToString(client, clientKey, sizeof(clientKey));
	
	// Create new entry in hashmap with Key: client and Value: Current Time
	dropBanned.SetValue(clientKey, GetTime(), false);
	
	PrintToChat(client, "You have been put on drop cooldown for %i seconds.", GetConVarInt(nwd_drop_cooldown));
}

// Returns the amount of time a player's cooldown will last
public int GetTimeBanned(int client) {
	// Convert client to string
	new String:clientKey[2];
	IntToString(client, clientKey, sizeof(clientKey));
	// Get the time at which they were banned
	new time;
	dropBanned.GetValue(clientKey, time);
	// Calculate time remaining
	return ((time + GetConVarInt(nwd_drop_cooldown)) - (GetTime()));
}