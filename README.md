# sm_bandb
轻量版SourceBans  
提供多服联封及调试模式

## 数据库配置
在`sourcemod > configs > databases.cfg`中配置数据库信息  
```
"ban"
{
	"driver"			"mysql"
	"host"				"localhost"
	"database"			"l4d2"
	"user"				"l4d2"
	"pass"				"123456"
}
```

## 创建数据库表
```
CREATE TABLE `banned_users` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `steamid` varchar(21) NOT NULL UNIQUE,
  `reason` varchar(255),
  `time` datetime,
  PRIMARY KEY (`Id`)
) DEFAULT CHARSET=utf8;
```

## 插件指令
`sm_debug`: 开启调试模式(踢出所有非管理员玩家)

## 插件特性
1. 带缓存功能: 数据库查询结果保存在本地5分钟  
2. 双检测: 玩家进入连接服务器时首次检测, 玩家SteamID校验完毕后二次检测  
3. 自动记录: 通过OnBanClient回调, 自动将新的封禁记录添加到数据库  
4. 故障保护: 数据库不可用时仅允许管理员进入服务器

## 相关推荐
建议配合[`l4dtoolz`](https://github.com/lakwsh/l4dtoolz)实现拦截家庭共享账号进服
