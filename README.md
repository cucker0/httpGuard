http-guard
==========

prevent cc attack


## 变更情况：

### v3.7.6.5
* 优化生成随机的ID方法

### v3.7.6.4
* 添加TraceId、SpanId处理功能

### v3.7.6.3
* 优化获取验证码裂图功能
* 增加needVerify名单，把原来perUrlRateLimit验证功能分离出来
* 修改弹出验证页面的http status code为298, 并添加http header Cache-Control参数，值为 no-cache，设置不不缓存


### v3.7.6.2
* 修复urlFilter模块对 urlAllow 白名单IP不能直接放行bug
* runtime.lua中调整urlFilter与rateLimit顺序

### v3.7.6.1
* 新增随机延时处理URL功能，即randomDelayProcessing模块
* 优化urlFilter处理访求，优化 runtime.lua access流程的in byDeny请求处理
* 修复rateLimit打印debug信息bug

### v3.7.6.0
* perUrlRateLimit增加direct2byDeny直接黑名单过滤，直接byDeny,不做验证尝试, 触发规则一次直接byDeny, byDeny时间为inByDenyTime

### v3.7.5.0
* 修复从http header X-FORWARDED-FOR获取用户IP问题, 用正则获取X-FORWARDED-FOR中的第一个IP

### v3.7.4.3
* 修改forbiddenAction动作返回状态码为299
* in byDeny list中的IP访问 urlAllow中的url直接放行

### v3.7.4.2
* perUrlRateLimit添加model应用模式，根据model的模块去判断是否要应用perUrlRateLimit模块规则进行过滤


### v3.7.4.1
* 验证码对应的cookieID添加随机因子
* perUrlRateLimit添加最大验证码成功验证次数限制,可防止验证码被破解后任意访问, 管理台显示验证码验证成功次数,格式ip.."Verified",记录于dict_perUrlRateLimit字典

### v3.7.4.0
* 新增每URL频率限制功能
* 成功验证验证码后(verifyCaptcha)清除每URL相关名单的记录
* HttpGuard Management WEB管理界面添加perUrlRateLimitList、perUrlRateLimitNeed2Verify 列表



### v3.7.3.8
* 修改带参数以?结尾的URI点击验证bug

### v3.7.3.7
* 修复ReqUri请求地址带参的bug


### v3.7.3.6
* 添加一键开启验证功能
* 修改verifyCaptcha验证验证码 删除challenge列表中验证失败计数器 bug
* 修改verifyCaptcha中 preurl返回值(若上次访问的URL为ico、js、css、图片等则返回preurl为首页) 


### v3.7.3.5
* 修复 getRealIp 获取真实IP函数在 realIpFromHeader 为table类型时的bug
* 修复 cookieModules 验证函数 cookie_expire 转数字类型失败的bug
* 修复 rateLimit访问频率限制 函数 获取 challengeTimesValueBig 为空的bug
* others 杂项函数中添加输出 PostArg、CookieArg值功能


### v3.7.3.4
* 优化httpGuard管理页面显示，统计条信息放在后面加载，解决有些列表在条目比较多时加载报500报错


### v3.7.3.3
* 修复POST Args值为 boolean 类型的bug
* 修复GET Args值为 boolean 类型的bug
* 经过click点击验证、验证验证码正常验证自动删除 challenge列表中验证失败计数器
* 添加others功能，该功能目前包含注册页面无referer时直接拒绝，并把该IP加入到blackList中
* .ashx文件非正常传参将被拒绝
* httpGuard管理页面添加expire时间显示, blackList显示value值


### v3.7.3.2
* 修改在 inRateLimitDeny名单中的动作返回首页


### v3.7.3.1
* 添加ratelimit管理功能，新增、删除记录
* 修改 guard_static rateLimit 新增记录到 ratelimit中的value


### v3.7.3.0
* 新增rateLimit页面访问频率限制功能，包含小频率、大频率限制
* 新增rateLimit 列表查看页面 rlist


### v3.7.2.1
* 修复updateList.lua 追加IP到List文件 函数bug


### v3.7.2.0
* 添加 系统参数dynamic动态管理方式，系统参数dynamic动态管理方式 执行效率比 系统参数static静态管理方式低，所以建议使用 static静态管理方式，默认使用static方式，此方式HttpGuard Management WEB管理中不能更新系统参数，只有查看.
 static、dnynamic分别对应guard_static.lua、guard_dynamic.lua Config函数库存文件
* http guard byDenyIpList、byDenyIpList页面添加Flag注释显示，并可在向这两个列表添加IP时添加注释
* 修改init.lua中readIp2Dict读取IP到字典函数中，向字典插入key时添加 flag项
* init.lua中添加readConfig2Dict读取设置到字典函数，添加动态管理设置初始化动态


### V3.7.1.0
* 新增 GET Args过滤模块
* 新增 COOKIE Args过滤模块
* 修改 POST Args模块


### v3.7.0.0
* ngx.re.mmatch匹配模式: ijo,安装pcre时加上  ./configure --enable-jit   ，这样效率更高
* 新增 user agent过滤模块
* 新增 http referer过滤模块
* 新增 URL过滤过滤模块
* 新增 POST Args过滤过滤模块
* HttpGuard Management管理后台添加显示版本号，hgsystem页面添加 urlDeny、postDeny显示
* 调整runtime.lua访问控制流程
* 多worker-process情况下，含hgsystem管理页面的都存在更改设置后，worker-process之间的设置不同步，主要是因为nginx fork中c-o-w导致


### v3.6.9.2
* 修正captch、click验证中上次访问url含 verify-captch.do自动截断preurl到 verify-captch.do

### v3.6.9.1
* hg管理后*台添加click隐式验证、click显式验证
* 显示click验证页面调整样式，内容垂直左右居中




## 设置说明：
在 nginx http {}  中添加如下内容，请根据具体的路径更改相关路径

### HttpGuard
```
lua_package_path "/etc/nginx/httpGuard/?.lua";
lua_shared_dict dict_system 10m;
lua_shared_dict dict_black 50m;
lua_shared_dict dict_white 50m;
lua_shared_dict dict_challenge 100m;
lua_shared_dict dict_byDenyIp 30m;
lua_shared_dict dict_byWhiteIp 30m;
lua_shared_dict dict_captcha 70m;
lua_shared_dict dict_others 30m;
lua_shared_dict dict_perUrlRateLimit 30m;
lua_shared_dict dict_needVerify 30m;
init_by_lua_file "/etc/nginx/httpGuard/init.lua";
access_by_lua_file "/etc/nginx/httpGuard/runtime.lua";
lua_max_running_timers 1;
```

### 查看HttpGuard 黑/白名单列表
在 server { } 块中添加以下内容, 重启Nginx, 通过 http://[server_name]/hgman  进行管理

### man page
```
        location /man {
                index index.html;
                alias /etc/nginx/man/;
        }
```


## HttpGuard Management
```


        location /hgman {
                default_type 'text/html';
                content_by_lua_file /etc/nginx/httpGuard/html/man/hgmanPage.lua;
        }

        location /hgman2 {
                default_type 'text/html';
                content_by_lua_file /etc/nginx/httpGuard/html/man/hgmanPage2.lua;
        }

        location /hg_src {
                root    /etc/nginx/httpGuard/html/man/;
                auth_basic off;
        }

        location /bywlist {
                default_type 'text/html';
                content_by_lua_file /etc/nginx/httpGuard/html/man/byWhite.lua;
        }

        location /bydlist {
                default_type 'text/html';
                content_by_lua_file /etc/nginx/httpGuard/html/man/byDeny.lua;
        }

        location /blist {
                default_type 'text/html';
                content_by_lua_file /etc/nginx/httpGuard/html/man/blackList.lua;
        }

        location /wlist {
                default_type 'text/html';
                content_by_lua_file /etc/nginx/httpGuard/html/man/whiteList.lua;
        }       

        location /clist {
                default_type 'text/html';
                content_by_lua_file /etc/nginx/httpGuard/html/man/challengeList.lua;
        }       

        location /rlist {
                default_type 'text/html';
                content_by_lua_file /etc/nginx/httpGuard/html/man/othersList.lua;
        }

        location /hgsystem {
                default_type 'text/html';
                content_by_lua_file /etc/nginx/httpGuard/html/man/hgSystem.lua;
        }

        location /update_list {
                default_type 'text/html';
                content_by_lua_file /etc/nginx/httpGuard/html/man/updateList.lua;
        }

        location /update_system {
                default_type 'text/html';
                content_by_lua_file /etc/nginx/httpGuard/html/man/updateSystem.lua;
        }

        location /perUrlRateLimit {
                default_type 'text/html';
                content_by_lua_file /etc/nginx/httpGuard/html/man/perUrlRateLimit.lua;
        }

        location /needVerify {
                default_type 'text/html';
                content_by_lua_file /etc/nginx/httpGuard/html/man/needVerify.lua;
        }

```


## 模块功能说明
```


1.byWhiteIpModule
  在byWhite列表中的IP直接通过

2.byDenyIpModule
  在byDeny列表中的IP直接拒绝访问

3.limitReqModule
  限制访问频率,超过限制频率的将其IP加到 black列表,在black列表中的IP受 blockAction 限制动作控制, blockAction可选 captcha,click,forbidden,iptables

4.redirectModule(302跳转)
  302跳转防护

5.JsJumpModule(JS跳转)
  JS跳转防护

6.cookieModule(Cookie验证)
  cookie验证防护

7.click验证
  blockAction动作限制方法之一：点击验证

8.HttpGuard management后台管理WEB
  查看管理 byDeny, byWhite, black, white, challenge列表
  管理httpguard系统配置

9.others杂项控制
  打印PostArg、CookieArg值，控制指定页面等

10.rateLimit 访问频率限制
  特定页面符合条件的请求直接丢弃

11.perUrlRateLimit 每URL访问频率限制, 在perUrlRateLimitVerify字典中的IP需要成功验证验证码才能继续访问


```

## 更新操作* 说明：
* click验证（clickAction）中添加 由 captcha验证失败过来的请求不再发送 preurl 上次请求的URL

* 更改init.lua初始化时加载字典条件，直接加载验证码、byWhite列表IP、byDeny列表IP到字典

* All-:让所选字典里的Key都过期

* w+:把byDeny, byWhite初始化后添加的IP到文件
