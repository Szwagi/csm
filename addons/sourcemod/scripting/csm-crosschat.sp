#include <sourcemod>

#include <csm/version>
#include <csm/core>

#include <autoexecconfig>
#include <sourcemod-colors>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <basecomm>
#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "CSM Crosschat", 
	author = "Szwagi", 
	version = CSM_VERSION
};

#define CROSSCHAT_MESSAGE_TYPE "chat"

ConVar gCV_server_prefix;
bool gB_BaseComm;


// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("csm-crosschat");
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVars();
}

public void OnAllPluginsLoaded()
{
	gB_BaseComm = LibraryExists("basecomm");
}

public void OnLibraryAdded(const char[] name)
{
	gB_BaseComm = gB_BaseComm || StrEqual(name, "basecomm");
}

public void OnLibraryRemoved(const char[] name)
{
	gB_BaseComm = gB_BaseComm && !StrEqual(name, "basecomm");
}

public void CSM_OnMessageReceived(const char[] type, const char[] arg1, const char[] arg2, const char[] arg3, const char[] arg4)
{
	if (!StrEqual(type, CROSSCHAT_MESSAGE_TYPE))
	{
		return;
	}

	CSkipNextPrefix();
	CPrintToChatAll("{orchid}%s %s{default}: {purple}%s", arg1, arg3, arg4);
}



// =====[ CLIENT EVENTS ]=====

public Action OnClientSayCommand(int client, const char[] command, const char[] args)
{
	if (!IsClientInGame(client))
	{
		return Plugin_Continue;
	}

	if (gB_BaseComm && BaseComm_IsClientGagged(client))
	{
		return Plugin_Continue;
	}

	if (args[0] == 0 || args[0] == '!' || args[0] == '/' || args[0] == '@')
	{
		return Plugin_Continue;
	}

	if (StrEqual(args, "rtv", false) || StrEqual(args, "rockthevote", false) || StrEqual(args, "timeleft", false))
	{
		return Plugin_Continue;
	}

	static char serverPrefix[33];
	gCV_server_prefix.GetString(serverPrefix, sizeof(serverPrefix));
	CProcessVariables(serverPrefix, sizeof(serverPrefix));

	static char clientName[33];
	GetClientName(client, clientName, sizeof(clientName));
	CRemoveColors(clientName, sizeof(clientName));
	Format(clientName, sizeof(clientName), "{purple}%s", clientName);

	static char message[256];
	strcopy(message, sizeof(message), args);
	CRemoveColors(message, sizeof(message));

	if (message[0] == 0)
	{
		return Plugin_Continue;
	}

	// 2nd argument is reserved.
	CSM_PostMessage(CROSSCHAT_MESSAGE_TYPE, serverPrefix, "", clientName, message);

	return Plugin_Continue;
}

// =====[ GENERAL ]=====

void CreateConVars()
{
	AutoExecConfig_SetFile("csm-crosschat", "sourcemod/csm");
	AutoExecConfig_SetCreateFile(true);
	
	gCV_server_prefix = AutoExecConfig_CreateConVar("csm_crosschat_server_prefix", "CSM", "Server prefix for messages.");

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

