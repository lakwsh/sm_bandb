#include <sourcemod>

#define STEAMID_SIZE 21
#define MSG_SIZE 128
#define CACHE_DURATION 120

#define isPlayer(%1) (IsClientInGame(%1) && !IsFakeClient(%1))
#define isAdmin(%1) GetAdminFlag(GetUserAdmin(%1), Admin_Reservation)

Database g_db;
ArrayList g_bannedList;
bool g_debug = false, g_init = false;

public Plugin myinfo = {
	name = "[Any] Ban DB",
	author = "lakwsh",
	version = "1.0.4",
	url = "https://github.com/lakwsh/sm_bandb"
};

enum struct BanInfo {
	int SteamID;
	char Reason[MSG_SIZE];
	int Expiration;
}

public void OnPluginStart() {
	g_bannedList = new ArrayList(sizeof(BanInfo));
	LoadDatabase();

	RegAdminCmd("sm_debug", Command_Debug, ADMFLAG_KICK, "切换调试模式");
}

public void OnPluginEnd() {
	delete g_bannedList;
}

public Action Command_Debug(int client, int args) {
	if(!g_debug) {
		g_debug = true;
		int count = 0;
		for(int i = 1; i <= MaxClients; i++) {
			if(isPlayer(i) && !isAdmin(i)) {
				KickClient(i, "服务器已进入调试模式,不便之处敬请谅解");
				count++;
			}
		}
		ServerCommand("sv_cookie 0");
		PrintToChatAll("\x04[提示]\x05服务器已进入调试模式.");
		ReplyToCommand(client, "[DebugMode] %d 个非管理员玩家被踢出服务器.", count);
		ReplyToCommand(client, "[DebugMode] 已进入调试模式.");
	} else {
		g_debug = false;
		PrintToChatAll("\x04[提示]\x05服务器已退出调试模式.");
		ReplyToCommand(client, "[DebugMode] 已退出调试模式.");
	}
	return Plugin_Handled;
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen) {
	if(IsFakeClient(client)) return true;
	return !IsPlayerBanned(client, rejectmsg, maxlen);
}

public void OnClientAuthorized(int client, const char[] auth) {
	if(IsFakeClient(client)) return;
	char msg[MSG_SIZE];
	if(IsPlayerBanned(client, msg, sizeof(msg))) KickClient(client, "%s", msg);
}

// BanClient的command参数不能为空
public Action OnBanClient(int client, int time, int flags, const char[] reason, const char[] kick_message, const char[] command, any source) {
	if(!g_init) LoadDatabase();
	if(time) return Plugin_Continue;
	AddToCache(GetSteamAccountID(client, false), reason);

	char auth[STEAMID_SIZE];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
	if(!g_init) {
		LogError("数据库连接错误,无法封禁玩家: %s", auth);
		return Plugin_Continue;
	}
	char error[MSG_SIZE];
	DBStatement query = SQL_PrepareQuery(g_db, "INSERT INTO `banned_users` (`steamid`, `reason`,`time`) VALUES (?, ?, NOW())", error, sizeof(error));
	if(!query) {
		g_init = false;
		LogError("无法创建预编译查询,无法封禁玩家: %s", auth);
		return Plugin_Continue;
	}
	query.BindString(0, auth, false);
	query.BindString(1, reason, false);
	if(!SQL_Execute(query)) {
		g_init = false;
		LogError("数据插入失败,无法封禁玩家: %s", auth);
	}
	delete query;
	return Plugin_Handled;  // 阻止文件写入
}

void AddToCache(int id, const char[] reason) {
	BanInfo info;
	info.SteamID = id;
	strcopy(info.Reason, sizeof(info.Reason), reason);
	info.Expiration = GetTime() + CACHE_DURATION;
	g_bannedList.PushArray(info);
}

void LoadDatabase() {
	char error[MSG_SIZE];
	g_db = SQL_Connect("ban", true, error, sizeof(error));
/*
	KeyValues kv = new KeyValues("");
	kv.SetString("driver", "mysql");
	kv.SetString("host", "localhost");
	kv.SetString("database", "l4d2");
	kv.SetString("user", "l4d2");
	kv.SetString("pass", "123456");
	kv.SetString("port", "3306");
	g_db = SQL_ConnectCustom(kv, error, sizeof(error), true);
	delete kv;
*/
	g_init = g_db && g_db.SetCharset("utf8");
	if(!g_init) PrintToServer("[BanDB] %s", error);
	else PrintToServer("[BanDB] 数据库连接成功");
}

bool IsPlayerBanned(int client, char[] msg, int maxlen) {
	int id = GetSteamAccountID(client, false);
	for(int i = 0; i < g_bannedList.Length; ++i) {
		BanInfo info;
		g_bannedList.GetArray(i, info);
		if(GetTime() > info.Expiration) {
			g_bannedList.Erase(i--);
			continue;
		}
		if(id == info.SteamID) {
			strcopy(msg, maxlen, info.Reason);
			return true;
		}
	}

	char auth[STEAMID_SIZE];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth), false);
	bool admin = GetAdminFlag(FindAdminByIdentity(AUTHMETHOD_STEAM, auth), Admin_Reservation);
	if(g_debug && !admin) {
		strcopy(msg, maxlen, "服务器处于调试模式,仅限管理员进入");
		return true;
	}

	if(!g_init || !SQL_FastQuery(g_db, "SELECT 1 FROM `banned_users` LIMIT 1;")) LoadDatabase();
	if(!g_init) {
		if(!admin) {
			strcopy(msg, maxlen, "数据库状态异常,仅限管理员进入");
			return true;
		}
		return false;
	}

	char error[MSG_SIZE];
	DBStatement query = SQL_PrepareQuery(g_db, "SELECT `reason` FROM `banned_users` WHERE `steamid` LIKE ?", error, sizeof(error));
	if(!query) {
		g_init = false;
		LogError("无法创建预编译查询,非管理员默认封禁状态: %s", auth);
		strcopy(msg, maxlen, "数据库状态异常,仅限管理员进入");
		return true;
	}
	auth[6] = '%';
	auth[8] = '%';
	query.BindString(0, auth, false);
	bool banned = true;
	if(SQL_Execute(query)) {
		if(!SQL_GetRowCount(query)) {
			banned = false;
		} else {
			strcopy(msg, maxlen, "你已被封禁");
			if(SQL_FetchRow(query)) SQL_FetchString(query, 0, msg, maxlen);
			AddToCache(id, msg);
		}
	} else {
		g_init = false;
		strcopy(msg, maxlen, "数据库状态异常,仅限管理员进入");
		LogError("数据查询失败,默认封禁状态: %s", auth);
	}
	delete query;
	return banned;
}
