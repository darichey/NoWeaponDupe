#pragma semicolon 1

#include <sourcemod>

EngineVersion g_Game;

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
	if (GetConVarInt(nwd_drop_cooldown) > 0) {
		if (IsDropBanned(client)) {
			PrintToChat(client, "[NWD] You may not drop your weapon for %i seconds.", GetTimeBanned(client));
			return Plugin_Stop;	
		} else {
			DropBan(client);
		}
	}
	return Plugin_Continue;
}

public bool IsDropBanned(int client) {
	new String:clientKey[2];
	IntToString(client, clientKey, sizeof(clientKey));
	new timeBanned;
	new bool:keyExists = dropBanned.GetValue(clientKey, timeBanned);
	
	if (!keyExists) {
		return false;
	}
	
	if (GetTime() >= timeBanned + GetConVarInt(nwd_drop_cooldown)) {
		dropBanned.Remove(clientKey);
		return false;
	}
	return true;
}

public void DropBan(int client) {
	new String:clientKey[2];
	IntToString(client, clientKey, sizeof(clientKey));
	
	dropBanned.SetValue(clientKey, GetTime(), false);
}

public int GetTimeBanned(int client) {
	new String:clientKey[2];
	IntToString(client, clientKey, sizeof(clientKey));
	new time;
	dropBanned.GetValue(clientKey, time);
	return ((time + GetConVarInt(nwd_drop_cooldown)) - (GetTime()));
}