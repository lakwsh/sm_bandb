# sm_bandb
轻量版SourceBans, 提供多服联Ban及调试模式  
多服联封: 多个服务端通过数据库方式共享封禁列表  
调试模式: 开启后服务器仅限管理员进入

## 1. 数据库配置
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

## 2. 创建数据库表
```
CREATE TABLE `banned` (
  `auth` char(21) NOT NULL DEFAULT '',
  `reason` varchar(255) DEFAULT NULL,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`auth`)
) DEFAULT CHARSET=utf8;
```

## 3. 插件指令
`sm_debug`: 开启调试模式(踢出所有非管理员玩家)  
`sm_bancheck`: 检测服务器内是否有漏网之鱼(加入游戏后被封禁)

## 4. 插件特性
1. **缓存功能**: 被封禁玩家查询结果会在服务器缓存2分钟, 避免重复查询数据库  
2. **快速检测**: 玩家连接服务器时检测封禁状态  
3. **自动记录**: 通过OnBanClient回调, 自动将新的封禁记录添加到数据库(支持LAC等插件)  
4. 故障保护: 数据库不可用时禁止进入服务器  
5. 封禁提示: 被封禁玩家会看到自己被封禁的时间及原因
6. **多线程查询**: 不阻塞游戏主线程, 减少玩家进入游戏等待时间

## 5. 相关推荐
建议配合[`l4dtoolz`](https://github.com/lakwsh/l4dtoolz)实现拦截家庭共享账号进服(仅限L4D2)

## 6. 常见问题
1. `[SM] Unable to load extension "dbi.mysql.ext": libz.so.1: cannot open shared object file: No such file or directory`  
解: apt install lib32z1  
2. 修改完`databases.cfg`不生效  
解: `sm_reload_databases`或重启服务端(插件也需要重新加载)  
3. mysql数据库连接数超过上限  
解: `MySQL> set global max_connections=200;`

## 7. 关于数据库
如使用远程数据库, 建议设置防火墙白名单, 并且设置专用用户(而非root)
