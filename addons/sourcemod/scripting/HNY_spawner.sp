#define ALLOW_SNOWBALLS

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

static const char files[][] = {
	"models/models_kit/xmas/xmastree.dx80.vtx",
	"models/models_kit/xmas/xmastree.dx90.vtx",
	"models/models_kit/xmas/xmastree.mdl",
	"models/models_kit/xmas/xmastree.phy",
	"models/models_kit/xmas/xmastree.sw.vtx",
	"models/models_kit/xmas/xmastree.vvd",
	"models/models_kit/xmas/xmastree.xbox.vtx",
	"models/logandougall/cel/cel_xmas_snowman.dx80.vtx",
	"models/logandougall/cel/cel_xmas_snowman.dx90.vtx",
	"models/logandougall/cel/cel_xmas_snowman.mdl",
	"models/logandougall/cel/cel_xmas_snowman.phy",
	"models/logandougall/cel/cel_xmas_snowman.sw.vtx",
	"models/logandougall/cel/cel_xmas_snowman.vvd",
	"materials/models/logandougall/cel/snow.vtf",
	"materials/models/logandougall/cel/snow.vmt",
	"materials/models/logandougall/cel/carrot.vtf",
	"materials/models/logandougall/cel/carrot.vmt",
	"materials/models/logandougall/cel/toolsblack.vmt",
	"materials/models/logandougall/cel/bark.vmt",
	"materials/models/logandougall/cel/bark.vtf",
	"models/models_kit/xmas/xmastree_mini.dx80.vtx",
	"models/models_kit/xmas/xmastree_mini.dx90.vtx",
	"models/models_kit/xmas/xmastree_mini.mdl",
	"models/models_kit/xmas/xmastree_mini.phy",
	"models/models_kit/xmas/xmastree_mini.sw.vtx",
	"models/models_kit/xmas/xmastree_mini.vvd",
	"models/models_kit/xmas/xmastree_mini.xbox.vtx",
	"materials/models/models_kit/xmas/xmastree_miscA.vmt",
	"materials/models/models_kit/xmas/xmastree_miscA.vtf",
	"materials/models/models_kit/xmas/xmastree_miscA_skin2.vmt",
	"materials/models/models_kit/xmas/xmastree_miscA_skin2.vtf",
	"materials/models/models_kit/xmas/xmastree_miscB.vmt",
	"materials/models/models_kit/xmas/xmastree_miscB.vtf",
	"materials/models/models_kit/xmas/xmastree_miscB_skin2.vmt",
	"materials/models/models_kit/xmas/xmastree_miscB_skin2.vtf",
	"materials/models/models_kit/xmas/xmastree_miscB_spec.vtf"
};

char
    data_path[PLATFORM_MAX_PATH];

KeyValues
    data;

public Plugin myinfo =
{
	name    = "HappyNewYear Spawner",
	author  = "Danyas, -=HellFire=-, github.com/Classes123",
	version = "1.0.0 b-"...SOURCEMOD_VERSION
};

public void OnPluginStart()
{
    RegAdminCmd("hny_spawn", Command_Spawn, ADMFLAG_ROOT);
    RegAdminCmd("hny_delete", Command_Delete, ADMFLAG_ROOT);

    #if defined ALLOW_SNOWBALLS
        RegConsoleCmd("hny_snowball", Command_Snowball);
    #endif

    HookEvent("round_start", Event_RoundStart);
}

public void OnMapStart()
{
	for (int i = 0; i < sizeof files; i++)
	{
		AddFileToDownloadsTable(files[i]);
	}
	
    PrecacheModel("models/models_kit/xmas/xmastree.mdl", true);
    PrecacheModel("models/models_kit/xmas/xmastree_mini.mdl", true);
    PrecacheModel("models/logandougall/cel/cel_xmas_snowman.mdl", true);

    BuildPath(Path_SM, data_path, sizeof data_path, "data/hny/");
    
    if (!DirExists(data_path))
    {
        CreateDirectory(data_path, 711);
    }

    char map[256];
    GetCurrentMap(map, sizeof map);
    ReplaceString(map, sizeof map, "/", "_");

    StrCat(data_path, sizeof data_path, map);
    StrCat(data_path, sizeof data_path, ".ini");

    if (data)
    {
        delete data;
    }

    data = new KeyValues("hny_data");
    data.ImportFromFile(data_path);
}


void Event_RoundStart(Event event, const char[] name, bool dont_broadcast)
{
    data.Rewind();

    if (data.GotoFirstSubKey())
    {
        char buffer[16];
        float origin[3], angles[3];

        do
        {
            data.GetVector("1", origin);
            data.GetVector("2", angles);
            data.GetString("3", buffer, sizeof buffer);

            int id = SpawnObject(buffer, origin, angles);
            if (id != -1)
            {
                IntToString(id, buffer, sizeof buffer);

                data.SetSectionName(buffer);
            }
        }
        while (data.GotoNextKey());
    }
}


Action Command_Spawn(int client, int argc)
{
    if (!client || argc != 1)
    {
        return Plugin_Handled;
    }

    float angles[3], origin[3];

    GetClientEyeAngles(client, angles);
    GetClientEyePosition(client, origin);

    TR_TraceRayFilter(origin, angles, MASK_SOLID, RayType_Infinite, Trace_FilterPlayers, client);
    
    if (TR_DidHit())
    {
        char arg[16];
        GetCmdArg(1, arg, sizeof arg);

        TR_GetEndPosition(origin);

        angles[0] = 0.0;
        angles[1] += 90.0;

        int id = SpawnObject(arg, origin, angles);
        if (id != -1)
        {
            char id_c[8];
            IntToString(id, id_c, sizeof id_c);

            data.Rewind();
            data.JumpToKey(id_c, true);
            data.SetVector("1", origin);
            data.SetVector("2", angles);
            data.SetString("3", arg);

            data.Rewind();
            data.ExportToFile(data_path);
        }
    }

    return Plugin_Handled;
}

Action Command_Delete(int client, int argc)
{
    if (!client)
    {
        return Plugin_Handled;
    }

    int id = GetClientAimTarget(client, false);
    if (id != -1)
    {
        char id_c[8];
        IntToString(id, id_c, sizeof id_c);

        data.Rewind();
        if (data.JumpToKey(id_c))
        {
            RemoveEdict(id);

            data.DeleteThis();

            UTIL_SaveData();
        }
    }

    return Plugin_Handled;
}

#if defined ALLOW_SNOWBALLS
Action Command_Snowball(int client, int argc)
{
    if (!client)
    {
        return Plugin_Handled;
    }

    GivePlayerItem(client, "weapon_snowball");

    return Plugin_Handled;
}
#endif


int SpawnObject(const char[] type, float origin[3], float angles[3])
{
    if (strcmp(type, "tree") == 0)
    {
        return UTIL_SpawnEntity("prop_dynamic", origin, angles, "models/models_kit/xmas/xmastree_mini.mdl");
    }

    if (strcmp(type, "big_tree") == 0)
    {
        return UTIL_SpawnEntity("prop_dynamic_override", origin, angles, "models/models_kit/xmas/xmastree.mdl");
    }
    
    if (strcmp(type, "snowman") == 0)
    {
        return UTIL_SpawnEntity("prop_dynamic", origin, angles, "models/logandougall/cel/cel_xmas_snowman.mdl");
    }

    return -1;
}

bool Trace_FilterPlayers(int entity, int contents_mask, int client)
{
	return (entity != client && entity > MaxClients);
}

int UTIL_SpawnEntity(const char[] type, float origin[3], float angles[3], const char[] model)
{
    int index = CreateEntityByName(type);
    if (index != -1)
    {
        DispatchKeyValue(index, "model", model);
        DispatchKeyValue(index, "Solid", "6");
        
        DispatchSpawn(index);

        TeleportEntity(index, origin, angles, NULL_VECTOR);

        SetEntityMoveType(index, MOVETYPE_VPHYSICS);
    }

    return index;
}

void UTIL_SaveData()
{
    data.Rewind();
    data.ExportToFile(data_path);
}