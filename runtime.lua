--local Guard = require "guard"
local Guard = _Conf.Guard
local remoteIp = ngx.var.remote_addr
local headers = ngx.req.get_headers()
local ip = Guard:getRealIp(remoteIp, headers)
--用户请求的原生URL，求未经docode
local reqUri = ngx.var.request_uri
--不带参数,且已经decode 
local uri = ngx.var.uri
local address = ''
local userAgent = ngx.var.http_user_agent or "user_agent_NONE"
local httpReferer = ngx.var.http_referer or "http_refere_NONE"

local hgModule = ngx.var.hg_module
local limitModule = ngx.var.limit_module
local redirectModule = ngx.var.redirect_module
local byPassModule = ngx.var.byPass_module
local jsModule = ngx.var.js_module
local cookieModule = ngx.var.cookie_module
local byDenyModule = ngx.var.byDeny_module

--URL是否全部转换成小写
local function stringLower(s)
    if string.lower(Config.hgModules.urlIgnoreCase) == "on" then
        s = string.lower(s)
    end
    return s
end

--判断是某种url匹配模式
if _Conf.uriMode then
    address = uri
elseif _Conf.requestUriMode then
    address = reqUri
end
--address = stringLower(address)

--判断流程
local hgOn = _Conf.hgModulesIsOn
if (hgOn and not (hgModule == "off")) or hgModule == "on" then
    --判断是否应用HttpGuard


    if not Guard:ipInByDenyList(ip) then
        --not in byDeny名单
        --随机延时处理URL
        Guard:randomDelayProcessing(ip, reqUri, address, userAgent, httpReferer)

        --定时检查连接数
        if _Conf.autoEnableIsOn then
            ngx.timer.at(0, Guard.autoSwitch)
        end

        if not Guard:ipInByWhiteList(ip) then
            --not in 白名单
            --在needVerify列表的的IP弹出验证页面
            Guard:needVerify(ip, reqUri, address)

            --URL过滤(URL过滤在needVerify前是考虑到CDN缓存问题)
            if Guard:urlFilter(userAgent, httpReferer, ip, reqUri, address) then

                --RATE LIMIT访问频率限制
            elseif Guard:rateLimit(ip, reqUri, address, userAgent, httpReferer) then

                --GET Args过滤
            elseif Guard:getArgsFilter(ip, reqUri) then

                --POST Args过滤
            elseif Guard:postFilter(ip, reqUri) then

                --COOKIE Args过滤
            elseif Guard:cookieArgsFilter(ip, reqUri) then

                --USER Agent过滤
            elseif Guard:userAgent(userAgent, httpReferer, ip, reqUri) then

                --HTTP Referer过滤
            elseif Guard:httpReferer(userAgent, httpReferer, ip, reqUri) then

                --perUrlRateLimite每URL频率限制
            elseif Guard:perUrlRateLimit(ip, reqUri, address, userAgent, httpReferer) then

                --杂项访问控制
            elseif Guard:others(userAgent, httpReferer, ip, reqUri, address) then

            else
                --黑名单模块
                Guard:blackListModules(ip, reqUri, address, userAgent, httpReferer)

                --限制请求速率模块.
                Guard:limitReqModules(ip, reqUri, address, limitModule)

                local oneKeyOpenVerificationOn = _Conf.dict_system:get("oneKeyOpenVerificationOn")
                if oneKeyOpenVerificationOn == 1 then
                    Guard:oneKeyOpenVerification(ip, reqUri, address, userAgent, httpReferer)
                else
                    --302转向模块
                    local redirectOn = _Conf.dict_system:get("redirectOn")
                    if redirectOn == 1 then
                        --判断转向模块是否开启
                        if not (redirectModule == "off") then
                            --Guard:debug("[redirectModules] redirectModules is on.",ip,reqUri)
                            Guard:redirectModules(ip, reqUri, address)
                        end
                    elseif redirectModule == "on" then
                        --Guard:debug("[redirectModules] redirectModules is on.",ip,reqUri)
                        Guard:redirectModules(ip, reqUri, address)
                    end

                    --js跳转模块
                    local jsOn = _Conf.dict_system:get("jsOn")
                    if jsOn == 1 then
                        --判断js跳转模块是否开启
                        if not (jsModule == "off") then
                            --Guard:debug("[JsJumpModules] JsJumpModules is on.",ip,reqUri)
                            Guard:JsJumpModules(ip, reqUri, address)
                        end
                    elseif jsModule == "on" then
                        --Guard:debug("[JsJumpModules] JsJumpModules is on.",ip,reqUri)
                        Guard:JsJumpModules(ip, reqUri, address)
                    end

                    --cookie验证模块
                    local cookieOn = _Conf.dict_system:get("cookieOn")
                    if cookieOn == 1 then
                        --判断是否开启cookie模块
                        if not (cookieModule == "off") then
                            --Guard:debug("[cookieModules] cookieModules is on.",ip,reqUri)
                            Guard:cookieModules(ip, reqUri, address, userAgent, httpReferer)
                        end
                    elseif cookieModule == "on" then
                        --Guard:debug("[cookieModules] cookieModules is on.",ip,reqUri)
                        Guard:cookieModules(ip, reqUri, address, userAgent, httpReferer)
                    end

                end
            end

        end
    else
        if not Guard:urlFilterAllow(userAgent, httpReferer, ip, reqUri, address) then
            --除了允许所有IP访问的URL外,其他执行拒绝操作.
            Guard:forbiddenAction()
        end

    end

end
