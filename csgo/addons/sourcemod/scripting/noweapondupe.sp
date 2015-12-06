#pragma semicolon 1

#include <sourcemod>

EngineVersion g_Game;

// Hashmap of players who are on cooldown. ClientID : Time When Banned
new StringMap:dropBanned;
ConVar nwd_drop_cooldown = null;

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
	nwd_drop_cooldown = CreateConVar("nwd_drop_cooldown", "3", "The cooldown time on dropping weapons on the ground.");
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
			// Allow them to drop but put them on cooldown
			DropBan(client);
		}
	}
	return Plugin_Continue;
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