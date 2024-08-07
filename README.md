httpGuard
==========

## httpGuard 是什么
httpGuard 是一个基于 Lua 语言开发的应用于 Nginx 的 WEB 应用防火墙（WAF）。用于阻断恶意非法的请求，放行合法的请求。

## 功能
* CC、DDoS 恶意攻击防护。
* 防御 SQL 注入、XSS 跨站、目录遍历、命令注入等。
* 支持 IP 黑名单、IP 白名单。
* 支持 URL 过滤（URL 黑名单、URL 白名单）。
* 人机识别（验证码、HTTP 重定向 、JS跳转等方式实现）。
* 异常 Referer、User-Agent 特征识别过滤。
* 基于 源IP 的 URL 访问频率限制。
* 支持 POST 参数过滤、GET 参数过滤（Query Args 过滤）、Cookie过滤等。

## 快速体验
参考 https://hub.docker.com/r/cucker/waf

```bash
docker run --name waf \
 -d \
 -p 80:80/tcp \
 -p 443:443/tcp \
 -p 17818:17818/tcp \
 cucker/waf:latest


// 或
mkdir -p /data/docker-volume/waf /data/docker-volume/waf-log

docker run --name waf \
 -d \
 -p 80:80/tcp \
 -p 443:443/tcp \
 -p 17818:17818/tcp \
 -v /data/docker-volume/waf:/etc/nginx \
 -v /data/docker-volume/waf-log:/usr/local/nginx/logs \
 cucker/waf:latest
```

## HTTP请求处理流程
![](https://github.com/cucker0/file_store/blob/master/httpGuard/waf_process_flow.jpg)

## 部署 httpGuard
1. 编译安装nginx

要求扩展lua-nginx-module、ngx_devel_kit、luajit2 等模块

参考 https://github.com/cucker0/nginx-install

2. 生成验证码图片

a. 要求安装有 php。
```bash
// 下载安装包及其依赖包
mkdir -p /usr/local/src/php
yum -y install --downloadonly --downloaddir=/usr/local/src/php php php-gd

// 
cd /usr/local/src/php
rpm -ivh ./php-common-*.rpm ./php-cli-*.rpm ./php-gd-*.rpm
```

把本项目的克隆到 /etc/nginx/ 目录下，如 /etc/nginx/httpGuard

b. 执行命令
```bash
cd /etc/nginx/httpGuard/captcha

// 生成验证码图片
// 要求安装有 php
php ./getImg.php
```
生成验证码图片到 etc/nginx/httpGuard/captcha 目录下。

c. 文件权限设置

允许通过 httpGard 管理后台，在IP白名单、IP黑名单中手动添加IP。

假设运行 nginx 服务的用户是 nginx。
```bash
chown nginx:nginx /etc/nginx/httpGuard/url-protect/byDeny_ip_list.txt /etc/nginx/httpGuard/url-protect/byWhite_ip_list.txt
chown nginx:nginx /etc/nginx/httpGuard/logs
```

3. 配置 HttpGuard

编辑 /etc/nginx/nginx.conf，

在 nginx http {} 中添加如下内容，请根据具体的路径更改相关路径
```
user nginx nginx;
worker_processes auto;

error_log logs/error.log;
pid logs/nginx.pid;
worker_rlimit_nofile 65535;

events {
    use epoll;
    worker_connections 65535;
}

http {
    # ...
    lua_package_path "/usr/local/share/lua/5.1/resty/?.lua;;/etc/nginx/httpGuard/?.lua;;";
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
    
    include /etc/nginx/conf.d/*.conf;
}
```
`lua_package_path "/usr/local/share/lua/5.1/resty/?.lua;;"` 用于解决 Nginx 启动时报 "failed to load the 'resty.core' module" 的问题。


4. 配置 HttpGuard 管理后台

a. 开启基于Basic的认证
```bash
// 安装 httpd-tools
yum -y install httpd-tools

touch /etc/nginx/auth_basic

// 创建用户、密码，并保存到指定文件
htpasswd -c /etc/nginx/auth_basic admin
New password:  // 输入密码
Re-type new password:  // 再次输入密码
Adding password for user admin
```
需要记住上面输入的密码。

/etc/nginx/auth_basic 文件内容格式示例
```bash
admin:/QpgJCY6zT5j..
```
这里的密码是加密的

b. 文件权限设置
```bash
chown nginx:nginx /etc/nginx/auth_basic
chmod 400 /etc/nginx/auth_basic
```

c. 新建一个 server 配置，创建 /etc/nginx/conf.d/wafman.conf
```bash
server {
    listen 17818;
    server_name localhost;
    set $hg_module off;
    access_log off;
    allow 127.0.0.1;
    allow 192.168.1.23;
    allow 192.168.1.126;
    allow 172.16.3.183;
    deny all;

    # 密码认证
    auth_basic "My_HTTP_Basic_Authentication";
    auth_basic_user_file /etc/nginx/auth_basic;

    # man page
    location /man {
        index index.html;
        alias /etc/nginx/man/;
    }

    # nginx_upstream_check
    location /check {
        check_status;
        # access_log off;
    }

    # nginx_status
    location /nginx_status {
        stub_status on;
    }

    ## HttpGuard Management
    location /hgman {
        default_type 'text/html';
        content_by_lua_file /etc/nginx/httpGuard/html/man/hgmanPage.lua;
    }

    location /hgman2 {
        default_type 'text/html';
        content_by_lua_file /etc/nginx/httpGuard/html/man/hgmanPage2.lua;
    }

    location /hg_src {
        root /etc/nginx/httpGuard/html/man/;
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
    
    ## Dynamic Upstream
    location /du {
        dynamic_upstream;
        # allow 127.0.0.1;
        # deny all;
    }
}
```

## 配置 httpGuard
配置过程中把它看作 nginx 代理 + WAF

* /etc/nginx 目录结构  
    包含 httpGuard 配置、Nginx 配置
    ```bash
    $  tree -L 2 /etc/nginx
    /etc/nginx
    ├── auth_basic
    ├── conf.d  // nginx Web Server 配置文件
    │   ├── default.conf
    │   └── wafman.conf
    ├── fastcgi.conf
    ├── fastcgi.conf.default
    ├── fastcgi_params
    ├── fastcgi_params.default
    ├── httpGuard
    │   ├── captcha
    │   ├── configBackup
    │   ├── config.lua  // httpGuard 主要配置文件
    │   ├── guard_dynamic.lua
    │   ├── guard_static.lua
    │   ├── html  // httpGuard 管理后台 API
    │   ├── init.lua
    │   ├── logs  // httpGuard 调试日志
    │   ├── README.md
    │   ├── runtime.lua
    │   └── url-protect  // httpGuard IP黑名单、IP白名单等模块的ACL
    ├── koi-utf
    ├── koi-win
    ├── man  // http://<IP>:17818/man 管理后台
    │   ├── index.html
    │   └── src
    ├── mime.types
    ├── mime.types.default
    ├── nginx.conf  // 入口配置文件
    ├── nginx.conf.default
    ├── scgi_params
    ├── scgi_params.default
    ├── stream.d
    │   └── README.md
    ├── uwsgi_params
    ├── uwsgi_params.default
    └── win-utf
    ```
    httpGuard 的主要配置文件：/etc/nginx/httpGuard/config.lua
    
    httpGuard IP黑名单、IP白名单等模块的ACL 位置：/etc/nginx/httpGuard/url-protect/
    
1. 开启 httpGuard

    编辑 /etc/nginx/httpGuard/config.lua
    ```lua
    local Config = {
        --HttpGuard是否开启
        --state : 为此模块的状态, 表示开启或关闭, 可选值为 "On" 或 "Off". 此项为全局开关,还可以针对单个网站设置开关. 当全局开关为off时,在某一网站的server{}代码块中加入set $hg_module on;, 表示单独对这个网站开启防攻击,当全局开关为on时,在某一网站的server{}代码块中加入set $hg_module off;,表示单独对这个网站关闭防攻击.
        --manType 管理模式,可选值: static, dynamic
        --    static : 静态管理模式,即 init.lua初始化参数 到 nginx worker processes,这样执行效率更高,如无需动态管理 init初始参数强烈建议使用 state 模式。
        --    dynamic : 动态管理模式,即 init.lua初始化参数 到 ngx.shared.DICT 字典中,可以在不nginx不重启/重载的情况下更新init初始化参数,
        --        从字典get key, ngx.shared.DICT:get("表名_key")  。如果不是表的 ngx.shared.DICT:get("项目名"),.
        --urlIgnoreCase : URL是否全部转换成小写, On/Off.
        --    On : 是,把URL中所有大写字母转成小写.
        --    Off : 否,保持用户请求的URL不变.
        hgModules = { state = "On", manType = "dynamic", urlIgnoreCase = "On" },
        
        --...
    }
    ```
    state = "On"  // 开启 HttpGuard，全局生效，对该 nginx 主机上的所有 server 生效。
    
    manType = "static"  // 静态管理模式。
    
    manType = "dynamic"  // 动态管理模式。动态开启/关闭相应的模块，动态修改各模块的ACL规则、IP黑名单、IP白名单、URL黑名单、URL白名单等
2. 单独关闭个别 server 的httpGuard 防护

    场景：在全局开启 httpGuard 的情况下，需要单独关闭 指定 server 的 httpGuard 防护功能。
    
    编辑 该 server 的配置
    ```nginx
    server {
        listen 80;
        server_name www.qq.com;
        set $hg_module off;
        
        # ...
    }
    ```
    添加变量`set $hg_module off;`

    当 server {} 中没有定义变量 `$hg_module`，则该 server 是否启用 httpGuard 只受全局 httpGuard 开关的影响。

3. 单独开启个别 server 的 httpGuard 防护

    场景：在全局关闭 httpGuard 的情况下，需要开启 指定 server 的 httpGuard 防护功能。
    
    编辑 该 server 的配置
    ```nginx
    server {
        listen 80;
        server_name www.qq.com;
        set $hg_module on;
        
        # ...
    }
    ```
    添加变量`set $hg_module on;`
4. httpGuard 各模块的ACL
    
    格式请参考文档的格式。有些支持正则。
    ```bash
    $ tree /etc/nginx/httpGuard/url-protect/
    /etc/nginx/httpGuard/url-protect/
    ├── 302.txt  // HTTP 302 验证 ACL
    ├── byDeny_ip_list.txt  // IP 黑名单
    ├── byWhite_ip_list.txt  // IP 白名单
    ├── cookieArgsDeny_tab.txt  // cookie 参数黑名单
    ├── cookie.txt  // cookie 挑战 URL 名单
    ├── getArgsDeny_tab.txt  // HTTP GET 方法的参数黑名单
    ├── httpRefererAllow.txt  // HTTP Referer 白名单
    ├── httpRefererDeny.txt  // HTTP Referer 黑名单
    ├── js.txt  // js 验证挑战 URL 名单
    ├── limit.txt  // HTTP 请求限速挑战 URL 名单
    ├── noneRefererPages.txt  // 允许无 HTTP Referer 的 URL 名单
    ├── perUrlRateLimit.txt  // 每 URL 限速 ACL
    ├── postArgsDeny_tab.txt  // HTTP POST 方法的参数黑名单
    ├── preurlVerifyCaptcha.txt  // 定义上次访问 URL 中包含的静态资源的类型。这些URL验证后跳转到首页。
    ├── randomDelayProcessing.txt  // 随机延时处理 URL 名单
    ├── rateLimit.txt  // 访问频率限速名单
    ├── showPostArgAndCookieArgPages.txt  // Post 参数、 Cookie 参数 需要输出日志的 URL 名单
    ├── urlAllow.txt  // URL 白名单
    ├── urlAllow.txt_bak
    ├── urlDeny_tab.txt  // URL 黑名单
    ├── userAgentAllow.txt  // User Agent 白名单
    └── userAgentDeny.txt  // User Agent 黑名单
    ```
5. 验证测试

    重启 nginx 服务
    ```bash
    systemctl restart nginx
    ```

    通过 `http://[server_name]/man` 进行访问管理
    
    后台管理界面

![](https://github.com/cucker0/file_store/blob/master/httpGuard/man.png)

![](https://github.com/cucker0/file_store/blob/master/httpGuard/hgman_updateList1.png)

![](https://github.com/cucker0/file_store/blob/master/httpGuard/hgman_updateList2.png)

![](https://github.com/cucker0/file_store/blob/master/httpGuard/hgman_updateList3.png)

![](https://github.com/cucker0/file_store/blob/master/httpGuard/hgman_updateSystem1.png)

![](https://github.com/cucker0/file_store/blob/master/httpGuard/hgman_updateSystem2.png)

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

## 更新操作说明
* click验证（clickAction）中添加 由 captcha验证失败过来的请求不再发送 preurl 上次请求的URL
* 更改 init.lua 初始化时加载字典条件，直接加载验证码、byWhite列表IP、byDeny列表IP到字典
* All-: 让所选字典里的Key都过期
* w+: 把byDeny, byWhite初始化后添加的IP写到文件

## 更新日志
```bash
### v3.7.6.3
* 优化获取验证码裂图功能
* 增加needVerify名单，把原来perUrlRateLimit验证功能分离出来
* 修改弹出验证页面的http status code为298, 并添加http header Cache-Control参数，值为 no-cache，设置为不缓存

### v3.7.6.2
* 修复urlFilter模块对 urlAllow 白名单IP不能直接放行bug
* runtime.lua中调整urlFilter与rateLimit顺序

### v3.7.6.1
* 新增随机延时处理URL功能，即randomDelayProcessing模块
* 优化urlFilter处理访求，优化 runtime.lua access流程的in byDeny请求处理
* 修复rateLimit打印debug信息bug

### v3.7.6.0
* perUrlRateLimit增加direct2byDeny直接黑名单过滤，直接byDeny,不做验证挑战尝试, 触发规则一次直接byDeny, byDeny时间为inByDenyTime

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
* hg管理后台添加click隐式验证、click显式验证
* 显示click验证页面调整样式，内容垂直左右居中
```