-- http-guard安装目录, 修改为实际的安装目录
baseDir = '/etc/nginx/httpGuard/'

local Config = {
	-- HttpGuard是否开启
	-- state : 为此模块的状态, 表示开启或关闭, 可选值为On或Off. 此项为全局开关,还可以针对单个网站设置开关. 当全局开关为off时,在某一网站的server{}代码块中加入set $hg_module on;, 表示单独对这个网站开启防攻击,当全局开关为on时,在某一网站的server{}代码块中加入set $hg_module off;,表示单独对这个网站关闭防攻击.
	-- manType是否动态生成,可选 static, dynamic
	-- 		static : 静态管理模式,即 init.lua初始化参数 到 nginx worker processes,这样执行效率更高,如无需动态管理 init初始参数强烈建议使用 state 模式。
	-- 		dynamic : 动态管理模式,即 init.lua初始化参数 到 ngx.shared.DICT 字典中,可以在不nginx不重启/重载的情况下更新init初始化参数,
	-- 				从字典get key, ngx.shared.DICT:get("表名_key")  。如果不是表的 ngx.shared.DICT:get("项目名"),.
	-- urlIgnoreCase : URL是否全部转换成小写, On/Off.
		-- On : 是,把URL中所有大写字母转成小写.
		-- Off : 否,保持用户请求的URL不变.
	hgModules = { state = "Off", manType = "static", urlIgnoreCase="On" },

	-- key是否动态生成,可选static,dynamic,如果选dynamic,下面所有的keySecret不需要更改,如果选static,手动修改下面的keySecret .
	keyDefine = "dynamic",

	-- 被动防御,限制请求模块. 根据在一定时间内统计到的请求次数作限制,建议始终开启.
	-- state : 为此模块的状态,表示开启或关闭,可选值为On或Off; 单站点 set $limit_module = on/off .
	-- maxReqs, amongTime : 在amongTime秒内允许请求的最大次数maxReqs,如默认的是在10s内最大允许请求50次.
	-- urlProtect : 指定限制请求次数的url正则表达式文件,默认值为\.php$, 表示只限制php的请求(当然,当urlMatchMode = "uri"时,此正则才能起作用).
	limitReqModules = { state = "On" , maxReqs = 1000 , amongTime = 1800, urlProtect = baseDir.."url-protect/limit.txt" },

	-- 主动防御在同一时刻建议只开 302、js、cookie中的一种
	-- 		302跳转、js跳转在检测时都会在 浏览器地址栏中添加 key与expire信息, cookie则不会, 用户基本无感知.

	-- 主动防御,302响应头跳转模块. 利用cc控制端不支持解析响应头的特点,来识别是否为正常用户,当有必要时才建议开启.
	-- state : 为此模块的状态,表示开启或关闭,可选值为On或Off; 单站点 set $redirect_module = on/off .
	-- verifyMaxFail  amongTime : 因为此模块会发送带有cckey及keyexpire的302响应头,如果访客在amongTime时间内超过verifyMaxFail次没有跳转到302响应头里的url,就会被添加到黑名单,默认值为5次.
	-- keySecret : 用于生成token的密码,如果上面的keyDefine为dynamic,就不需要修改.
	-- urlProtect : 同limitReqModules模块中的urlProtect的解释.
	redirectModules = { state = "Off" ,verifyMaxFail = 5, keySecret = 'yK48J276hg', amongTime = 60 ,urlProtect = baseDir.."url-protect/302.txt"},

	-- 主动防御,发送js跳转代码模块. 利用cc控制端无法解析js跳转的特点,来识别是否为正常用户,当有必要时才建议开启.
	-- state : 为此模块的状态,表示开启或关闭,可选值为On或Off; 单站点 set $js_module = on/off .
	-- verifyMaxFail, amongTime : 因为此模块会发送带有js跳转代码的响应体,如果访客在amongTime时间内超过verifyMaxFail次没有跳转到js跳转代码里的url,就会被添加到黑名单,默认值为5次.
	-- keySecret : 用于生成token的密码,如果上面的keyDefine为dynamic,就不需要修改.
	-- urlProtect : 同limitReqModules模块中的urlProtect的解释.
	JsJumpModules = { state = "Off" ,verifyMaxFail = 5, keySecret = 'QSjL6p38h9', amongTime = 60 , urlProtect = baseDir.."url-protect/js.txt"},

	-- 主动防御,发送cookie验证模块. 此模块会向访客发送cookie,然后等待访客返回正确的cookie,此模块利用cc控制端无法支持cookie的特点,来识别cc攻击,当有必要时才建议开启.
	-- state : 为此模块的状态,表示开启或关闭,可选值为On或Off; 单站点 set $cookie_module = on/off .
	-- verifyMaxFail  amongTime : 因为此模块会发送cookie,如果访客在amongTime时间内超过verifyMaxFail次没有返回正确的cookie,就会被添加到黑名单,默认值为5次.
	-- keySecret : 用于生成token的密码,如果上面的keyDefine为dynamic,就不需要修改.
	-- urlProtect : 同limitReqModules模块中的urlProtect的解释.	
	cookieModules = { state = "Off" ,verifyMaxFail = 2, keySecret = 'bGMfY2D5t3', amongTime = 3600 , urlProtect = baseDir.."url-protect/cookie.txt"},

	-- 自动开启主动防御,原理是根据protectPort端口的已连接数超过maxConnection来确定
	-- state : 为此模块的状态,表示开启或关闭,可选值为On或Off .
	-- interval : 间隔30秒检查一次连接数,默认为30秒.
	-- protectPort, maxConnection, normalTimes, exceedTimes :  enableModule中的模块为关闭状态时,当端口protectPort的连接数连续exceedTimes次超过maxConnection时,开启enableModule中的模块.
	-- enableModule : 中的模块为开启状态时,当端口protectPort的连接数连续normalTimes次低于maxConnection时,关闭enableModule中的模块.
	-- ssCommand  : 我们是使用ss命令来检查特定端口的已连接的连接数, ss命令比同类的命令netstat快得多. 请把ss命令的路径改为自己系统上的路径.
	-- enableModules : 自动启动哪个主动防御模块,可选值为redirectModules JsJumpModules cookieModules .
	autoEnable = { state = "off", protectPort = "80", interval = 30, normalTimes = 3,exceedTimes = 2,maxConnection = 500, ssCommand = "/usr/sbin/ss" ,enableModule = "redirectModules"},

	-- 用于当输入验证码验证通过时,生成key的密码.如果上面的keyDefine为dynamic, 就不需要修改.
	captchaKey = "K4QEaHjwyF",
	clickKey = "N5a7eyxOfo",

	-- ip在黑名单时执行的动作(可选值 captcha, click, forbidden, iptables)
	-- 值为 captcha 时 : 在黑名单中的IP访问网站将返回带有验证码的页面,输入正确的验证码后才允许继续访问网站.
	-- 值为 click 时 : 在黑名单中的IP访问网站将返回点击验证页面, 点击链接后才允许继续访问网站（或倒计时9秒后自动打开链接）.
	-- iddenClickState : 该选项只对 type = click 时启作用. 当 type = click 且 hiddenClickState = "On"时,返回的点击验证页面不显示,并自动完成验证.
	-- 值为forbidden时 : 在黑名单中的IP访问网站,服务器会直接断开与用户的连接.
	-- 值为iptables时 : 在黑名单中的IP访问网站, 服务器会用 iptables 拒绝此ip的连接,
	-- 		需要为nginx运行用户设置密码及添加到sudo以便能执行iptables命令.假设nginx运行用户为www,设置方法为:
	-- 		1.设置www密码, 命令为passwd www
	-- 		2.以root用户执行 visudo 命令, 添加www  ALL=(root) /sbin/iptables -I INPUT -p tcp -s [0-9.]* --dport 80 -j DROP
	-- 		3.以root户执行 visudo 命令, 找到 Default requiretty 并注释它, 即更改为#Default requiretty, 如果找不到此设置, 就不需要改, 默认 sudo 需要tty终端,注释掉就可以在后台执行了.
	blockAction = { type= "forbidden", hiddenClickState = "On" },

	-- nginx运行用户的sudo密码,blockAction值为iptables需要设置,否则不需要.
	sudoPass = '',

	-- 表示http-guard封锁ip的时间
	blockTime = 7200,

	-- JsJumpModules redirectModules cookieModules验证通过后,ip在白名单的时间
	whiteTime = 30,

	-- 用于生成token密码的key过期时间
	keyExpire = 600,

	-- 匹配url模式, 可选值 "requestUri", "uri"
	-- 值requestUri时, url-protect目录下的正则匹配的是浏览器最初请求的地址且没有被decode,带参数的链接.
	-- 值为uri时, url-protect目录下的正则匹配的是经过重写过的地址,不带参数,且已经decode .
	urlMatchMode = "uri",

	-- 验证码页面路径,一般不需要修改.
	captchaPage = baseDir.."html/captcha.do",

	-- 输入验证码错误时显示的页面路径,一般不需要修改.
	reCaptchaPage = baseDir.."html/reCatchaPage.do",
	
	-- 验证js、css样式等页面跳转到首页
	preurlVerifyCaptcha_regex = baseDir.."url-protect/preurlVerifyCaptcha.txt",

	-- manPage 管理页面路径
	manPage = baseDir.."html/man/hgman.do",

	-- 白名单ip文件,文件内容为正则表达式.
	byWhiteIpModules = { state = "On", ipList = baseDir.."url-protect/byWhite_ip_list.txt" },

	-- ByDeny黑名单ip文件,文件内容为正则表达式.
	-- 访客在 amongTime 秒时间内出现在 black黑名单次数超过 inBlackMax 次,则该IP将添加到 byDenyIp名单中,锁定时间为 blockTime 秒
	-- black2byDenyState : 是否开启IP从 black黑名单到到 byDeny直接拒绝名单的检测
	-- blockTime = 0 时表示,表示锁定时间为无限期
	byDenyIpModules = { state = "On", ipList = baseDir.."url-protect/byDeny_ip_list.txt", black2byDenyState = "Off", inBlackMax = 5, blockTime = 0, amongTime = 3600 },

	-- 如果需要从请求头获取真实ip,此值就需要设置,如x-forwarded-for
	-- 当state为on时,此设置才有效
	realIpFromHeader = { state = "On", header = "x-forwarded-for"},

	-- 指定验证码图片目录,一般不需要修改
	captchaDir = baseDir.."captcha/",

	-- debug日志模块
	-- state : 为此模块的状态,表示开启或关闭,可选值为On或Off .
	-- logPath : 日志目录,一般不需要修改.但需要设置logs所有者为nginx运行用户,如nginx运行用户为www,则命令为chown www logs
	debug = { state = "Off", logPath = baseDir.."logs/" },

	-- captcha验证 自动转 click验证
	-- 1. captcha在amongTime时间内验证失败verifyMaxFail次后自动改成 click验证, 比较适用于禁用了 cookie 的情况,
	-- 		仅对 符合条件 1 的访问生效.
	captcha2click = { state = "Off", verifyMaxFail = 3, amongTime = 70 },

	-- user agent 过滤模块
	-- 此模块利用 user agent特征可过滤扫描软件扫描网站或开放搜索引擎的访问.
	-- state : 为此模块的状态,表示开启或关闭,可选值为On或Off .
	-- allowState : user agent 允许名单的状态,表示开启或关闭,可选值为On或Off ,
	-- 		若不需对 搜索引擎的访问 做单独开放, 请关闭此功能!!! 以免伪造	搜索引擎 user agent进行攻击.
	-- userAgentAllow : 指定 user agent 允许名单正则表达式文件,只有 state、allowState 都开启时才生效,
	-- 		主要用于开放来自搜索引擎的访问,把 搜索引擎 的 user agent 特征添加到 userAgentAllow 文件,
	-- 		但是对于伪造搜索引擎user agent信息的访问无法过滤,对于这种情况建议使用智能DNS为搜索引擎添加额外的解析线路.
	-- userAgentDeny : 指定 user agent 拒绝名单正则表达式文件.
	userAgent = { state = "Off", allowState = "Off", userAgentAllow = baseDir.."url-protect/userAgentAllow.txt", userAgentDeny = baseDir.."url-protect/userAgentDeny.txt" },

	-- http referer 过滤模块
	-- 此模块可过滤借助于大流量网站引流(如iframe)的攻击. 把引流的网站域名增加到httpRefererDeny,或者在httpRefererAllow添加要保护的本站域名,httpRefererDeny设置为所有 ^.*$
	-- 当无此类攻击的时候建议关 闭此 模块.
	-- state : 为此模块的状态,表示开启或关闭,可选值为On或Off .
	-- allowState : http referer 允许名单的状态,表示开启或关闭,可选值为On或Off .
	-- httpRefererAllow : 指定 http referer 允许名单正则表达式文件,只有 state、allowState 都开启的时候才生效.
	-- httpRefererDeny : 指定 http referer 拒绝名单正则表达式文件.
	httpReferer = { state = "Off", allowState = "On", httpRefererAllow = baseDir.."url-protect/httpRefererAllow.txt", httpRefererDeny = baseDir.."url-protect/httpRefererDeny.txt" },

	-- URL过滤模块
	-- 此模块可用于开放一些API接口,拒绝访问敏感URL .
	-- state : 为此模块的状态,表示开启或关闭,可选值为On或Off .
	-- allowState : urlFilter 允许名单的状态,表示开启或关闭,可选值为On或Off .
	-- urlAllowProtect : 指定 urlFilter 允许名单正则表达式文件.
	-- denyState :  urlFilter 拒绝名单的状态,表示开启或关闭,可选值为On或Off .
	-- urlDenyProtect : 指定 urlFilter 拒绝名单正则表达式文件. 此正则在init.lua 中生成了table, 即在匹配时,与此文件正则逐行匹配. 所以各行之间不需要用 | 边起来
	urlFilterModules = { state = "On", denyState = "On", urlAllowProtect = baseDir.."url-protect/urlAllow.txt", urlDenyProtect = baseDir.."url-protect/urlDeny_tab.txt" },

	-- POST Args过滤模块
	-- state : 为此模块的状态,表示开启或关闭,可选值为On或Off .
	-- postArgsDeny : 指定 post args拒绝名单正则表达式文件. 同 urlDenyProtect 说明
	postArgsFilter = { state = "Off", postArgsDeny = baseDir.."url-protect/postArgsDeny_tab.txt" },

	-- GET Args过滤模块
	-- state : 为此模块的状态,表示开启或关闭,可选值为On或Off .
	-- postArgsDeny : 指定 getArgs拒绝名单正则表达式文件. 同 urlDenyProtect 说明
	getArgsFilter = { state = "Off", getArgsDeny = baseDir.."url-protect/getArgsDeny_tab.txt" },

	-- Cookie过滤模块
	-- state : 为此模块的状态,表示开启或关闭,可选值为On或Off .
	-- cookieArgsDeny : 指定 cookieArgs拒绝名单正则表达式文件. 同 urlDenyProtect 说明
	cookieArgsFilter = { state = "Off", cookieArgsDeny = baseDir.."url-protect/cookieArgsDeny_tab.txt" },

	-- 访问频率限制
	-- state : 为此模块的状态,表示开启或关闭,可选值为On或Off .
	-- amongTime : 小频率限制访问周期.
	-- blockTime : 进入rateLimitDeny列表的 IP+URL 锁定时间.
	-- bigMaxReqs bigAmongTime : maxReqs, amongTime : 在bigAmongTime秒内允许请求的最大次数bigMaxReqs .
	-- bigBlockTime : 达到大频率受限条件后的 IP+URL 进入rateLimitDeny列表的锁定时间 
	-- urlProtect : 访问频率受限制URL及小频率最大请求数
	rateLimit = { state = "On", rateState = "On", bigRateState = "On", rate2byDenyState = "On", amongTime = 120, blockTime = 120, bigAmongTime = 1800, bigBlockTime = 7200, urlProtect = baseDir.."url-protect/rateLimit.txt" },

	-- 杂项访问控制
	-- state : 为此模块的状态,表示开启或关闭,可选值为On或Off .
	-- noneRefererPages：不带http referer受限制URL .
	others = { state = "On", noneRefererPages = baseDir.."url-protect/noneRefererPages.txt", showPostArgAndCookieArgState = "Off", showPostArgAndCookieArgPages = baseDir.."url-protect/showPostArgAndCookieArgPages.txt" },

	-- 一键开启验证
	-- 所有用户必须经过验证验证码才允许访问网站, 未记录的IP直接进入黑名单.
	-- state : 为此模块的状态,表示开启或关闭,可选值为On或Off .
	-- whiteTime : 验证码验证通过后,ip在白名单的时间 .
	oneKeyOpenVerification = { state = "Off", whiteTime = 3600 },
	
	-- 每URL访问频率限制
	-- state : 为此模块的状态,表示开启或关闭,可选值为On或Off .
	-- amongTime : 频率限制访问周期.
	-- inPerUrlRateLimitAmongTime : 在PerUrlRateLimit列表的挑战时间.
	-- defaultMaxReqs : 默认最大请求次数.
	-- inPerUrlRateLimitMaxTimes : 允许进入PerUrlRateLimit名单最大次数.
	-- verifyBlockTime : 未认证验证码锁定时间.
	-- verifyOkTime : 认证验证码白名单时间.
	-- perUrlRateLimit2ByDenyState : perUrlRateLimit到ByDeny开关.
	-- toByDenyAmongTime : perUrlRateLimit名单到ByDeny名单挑战时间.
	-- perUrlRateLimitVerifySuccessMax : perUrlRateLimitNeed2Verify列表中允许成功认证验证码的最大次数.
	-- inByDenyTime : 在byDeny名单中的时间.
	-- urlProtect : 访问频率受限制URL及频率最大请求数.
	-- 验证方式：验证码验证
	-- model: 0 表示不判断IP是否white临时白名单或是否含cookie都应用此模块规则
		-- 1 表示 若IP在white临白时名单时不应用此模块规则过滤，否则应用
		-- 2 表示 若request中含cookie信息时不应用此模块规则过滤，否则应用
	-- direct2byDeny : 直接byDeny,不做验证尝试, 触发规则一次直接byDeny, byDeny时间为inByDenyTime. 使用此项建议开启 urlIgnoreCase.
		-- 0 : 不开.
		-- 1 ：开启,触发规则后,IP加入black临时黑名单, 过期时间为blockTime.
		-- 2 ：开启,触发规则后,IP加入byDeny临时黑名单,过期时间为 inByDenyTime.
		
	perUrlRateLimit = { state = "On", amongTime = 600, inPerUrlRateLimitAmongTime = 900, defaultMaxReqs = 200, inPerUrlRateLimitMaxTimes = 2, verifyBlockTime = 86400, verifyOkTime = 30, perUrlRateLimit2ByDenyState = "On", toByDenyAmongTime=86400, perUrlRateLimitVerifySuccessMax = 4,  inByDenyTime=7200, model = 1, direct2byDeny = 2, urlProtect = baseDir.."url-protect/perUrlRateLimit.txt" },
	
	-- 随机延时处理URL
		-- state : 为此模块的状态,表示开启或关闭,可选值为On或Off .
		-- timeRange : 随机时间范围[s, e], 单位毫秒.
			-- s : 最小时间, 最小为0.
			-- e : 最大时间.
		-- urlProtect : 需要做随机延时处理的URL.
	randomDelayProcessing = { state = "Off", timeRange = { s=400, e=1000 },urlProtect = baseDir.."url-protect/randomDelayProcessing.txt" },		
	
}


return Config










