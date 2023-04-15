# sm_bandb
轻量版SourceBans  
提供多服联封及调试模式

## 数据库配置
在`sourcemod > configs > databases.cfg`中配置数据库信息  
```
	"ban"
	{
		"driver"			"mysql"
		"host"				"192.168.1.66"
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
