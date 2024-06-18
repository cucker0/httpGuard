-- ++++++++++++++++++++++++++++++
-- 对黑名单、白名单=进行增删管理 
-- ++++++++++++++++++++++++++++++

ngx.req.read_body()
local hh = "<br>"
local kg = "&nbsp;&nbsp;"
local dict_system = ngx.shared.dict_system
local dict_byDenyIp = ngx.shared.dict_byDenyIp
local dict_byWhiteIp = ngx.shared.dict_byWhiteIp
local dict_black = ngx.shared.dict_black
local dict_white = ngx.shared.dict_white
local dict_challenge = ngx.shared.dict_challenge
local dict_others = ngx.shared.dict_others
local dict_perUrlRateLimit = ngx.shared.dict_perUrlRateLimit
local dict_needVerify = ngx.shared.dict_needVerify
local args = ngx.req.get_post_args()  --获取post参数
local addDel = args["addDel"]  --获取 addDel post 值
local ipPut = args["ip_put"]  --获取 ipPut post value参数
local get_customTime = args["custom_Time"] or 3600
local customTime = ngx.re.match(get_customTime, "[0-9]+")
local list_type = args["list_type"]  --获取list_type post value参数
local comment = args["comment"] or 0  --获取 comment post value参数
local byDenyTime = ''
local byWhiteTime = ''
local blockTime = _Conf.blockTime
local whiteTime = _Conf.whiteTime
local rateLimitBlockTime = _Conf.rateLimit.bigBlockTime
local XFFon, XFFerr = ngx.re.match(ipPut, ",")  --判断是否为单个经过 proxy 带 X-Forwarded-For IP
local ipRegular = "[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}"  --IP正则表达式
local ipUrlRegular = "[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}ratelimit[0-9]{1,2}"  --rateLimit ipURL正则表达式
local rateXFFon, rateXFFerr = ngx.re.match(ipPut, ".*,.*ratelimit[0-9]{1,2}")  --含 , ratelimit一到两位数字
local expire = -1
if comment == '' or not comment then
    comment = 0
end

--判断是否有 customTime,否则 blockTime、whiteTime 使用默认配置时间
if customTime then
    byDenyTime = tonumber(customTime[0])
    byWhiteTime = tonumber(customTime[0])
    blockTime = tonumber(customTime[0])
    whiteTime = tonumber(customTime[0])
    rateLimitBlockTime = tonumber(customTime[0])
    expire = tonumber(customTime[0])
end

--追加IP到List文件
function append2List(filePath, dict)
    key = dict:get_keys(0)
    local file = io.open(filePath, "a+")
    for k, v in pairs(key) do
        local val, fla = dict:get(v)
        if fla and not (fla == 0) then
            if val == 0 then
                file:write(v .. "\n")
            else
                file:write(v .. "#" .. val .. "\n")
            end
            dict:replace(v, comment, 0, 0)
        end
    end
    file:close()
end

-- byDeny名单
if list_type == "byDeny" then
    --判断更新的类型是否为 byDeny
    if addDel == "add" then
        --增加IP记录
        if XFFon then
            --提交IP为单个的含 , 的经过 proxy IP
            if byDenyTime == "" or byDenyTime == 0 then
                local byDenyKey = ipPut
                dict_byDenyIp:set(byDenyKey, comment, 0, 1)  --增加IP到byDeny名单, Flag 为 1 的表示不过期
            else
                local byDenyKey = ipPut
                dict_byDenyIp:set(byDenyKey, comment, byDenyTime, 2)  --增加IP到byDeny名单, Flag 为 2 的表示有过期时间
            end
        else
            if byDenyTime == "" or byDenyTime == 0 then
                local ip, err = ngx.re.gmatch(ipPut, ipRegular)
                if not ip then
                    ngx.log(ngx.ERR, "error: ", err)
                    ngx.say("error" .. err)
                    return
                end

                while true do
                    --批量添加匹配的IP
                    local p, err = ip()
                    if err then
                        ngx.log(ngx.ERR, "error: ", err)
                        return
                    end
                    if not p then
                        --no match found (any more)
                        break
                    end
                    local matchIp = p[0]  --匹配的IP
                    local byDenyKey = matchIp
                    dict_byDenyIp:set(byDenyKey, comment, 0, 1)  --增加IP到byDeny名单, Values 为 1 的表示不过期
                end
                ngx.say("200")
            else
                local ip, err = ngx.re.gmatch(ipPut, ipRegular)
                if not ip then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end

                while true do
                    --批量添加匹配的IP
                    local p, err = ip()
                    if err then
                        ngx.log(ngx.ERR, "error: ", err)
                        return
                    end
                    if not p then
                        --no match found (any more)
                        break
                    end
                    local matchIp = p[0]  --匹配的IP
                    local byDenyKey = matchIp
                    dict_byDenyIp:set(byDenyKey, comment, byDenyTime, 2)  --增加IP到byDeny名单, Values 为 2 的表示有过期时间
                end
                ngx.say("200")

            end
        end

    elseif addDel == "del" then
        --删除IP记录
        if XFFon then
            local byDenyKey = ipPut
            dict_byDenyIp:delete(byDenyKey)  --byDeny名单中删除该IP
        else
            local ip, err = ngx.re.gmatch(ipPut, ipRegular)
            if not ip then
                ngx.log(ngx.ERR, "error: ", err)
                return
            end

            while true do
                local p, err = ip()
                if err then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end
                if not p then
                    --no match found (any more)
                    break
                end
                local matchIp = p[0]
                local byDenyKey = matchIp  --byDeny名单中删除该IP
                dict_byDenyIp:delete(byDenyKey)
            end
        end

    elseif addDel == "all-" then
        dict_byDenyIp:flush_all()

    elseif addDel == "w+" then
        append2List(_Conf.byDenyIpPath, _Conf.dict_byDenyIp)
    end
end


-- byWhite名单
if list_type == "byWhite" then
    --判断更新的类型是否为 byWhite
    if addDel == "add" then
        --增加IP记录
        if XFFon then
            --提交IP为单个的含 , 的经过 proxy IP
            if byWhiteTime == "" or byWhiteTime == 0 then
                local byWhiteKey = ipPut
                dict_byWhiteIp:set(byWhiteKey, comment, 0, 1)  --增加IP到byWhite名单, Values 为 1 的表示不过期
            else
                local byWhiteKey = ipPut
                dict_byWhiteIp:set(byWhiteKey, comment, byWhiteTime, 2)  --增加IP到byWhite名单, Values 为 2 的表示有过期时间
            end
        else
            if byWhiteTime == "" or byWhiteTime == 0 then
                local ip, err = ngx.re.gmatch(ipPut, ipRegular)
                if not ip then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end

                while true do
                    --批量添加匹配的IP
                    local p, err = ip()
                    if err then
                        ngx.log(ngx.ERR, "error: ", err)
                        return
                    end
                    if not p then
                        --no match found (any more)
                        break
                    end
                    local matchIp = p[0]  --匹配的IP
                    local byWhiteKey = matchIp
                    dict_byWhiteIp:set(byWhiteKey, comment, 0, 1)  --增加IP到byWhite名单, Values 为 1 的表示不过期
                end
            else
                local ip, err = ngx.re.gmatch(ipPut, ipRegular)
                if not ip then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end

                while true do
                    --批量添加匹配的IP
                    local p, err = ip()
                    if err then
                        ngx.log(ngx.ERR, "error: ", err)
                        return
                    end
                    if not p then
                        --no match found (any more)
                        break
                    end
                    local matchIp = p[0]  --匹配的IP
                    local byWhiteKey = matchIp
                    dict_byWhiteIp:set(byWhiteKey, comment, byWhiteTime, 2)  --增加IP到byWhite名单, Values 为 2 的表示有过期时间
                end

            end
        end

    elseif addDel == "del" then
        --删除IP记录
        if XFFon then
            local byWhiteKey = ipPut
            dict_byWhiteIp:delete(byWhiteKey)  --byWhite名单中删除该IP
        else
            local ip, err = ngx.re.gmatch(ipPut, ipRegular)
            if not ip then
                ngx.log(ngx.ERR, "error: ", err)
                return
            end

            while true do
                local p, err = ip()
                if err then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end
                if not p then
                    --no match found (any more)
                    break
                end
                local matchIp = p[0]
                local byWhiteKey = matchIp  --byWhite名单中删除该IP
                dict_byWhiteIp:delete(byWhiteKey)
            end
        end
    elseif addDel == "all-" then
        dict_byWhiteIp:flush_all()

    elseif addDel == "w+" then
        append2List(_Conf.byWhiteIpPath, _Conf.dict_byWhiteIp)
    end
end


-- Black黑名单
if list_type == "black" then
    --判断更新的类型是否为 black
    if addDel == "add" then
        --增加IP记录
        if XFFon then
            --提交IP为单个的含 , 的经过 proxy IP
            local blackKey = ipPut .. list_type
            dict_black:set(blackKey, 0, blockTime)  --增加IP到黑名单
        else
            local ip, err = ngx.re.gmatch(ipPut, ipRegular)
            if not ip then
                ngx.log(ngx.ERR, "error: ", err)
                return
            end

            while true do
                --批量添加匹配的IP
                local p, err = ip()
                if err then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end
                if not p then
                    --no match found (any more)
                    break
                end
                local matchIp = p[0]  --匹配的IP
                local blackKey = matchIp .. list_type
                dict_black:set(blackKey, 0, blockTime)  --增加IP到黑名单
            end
        end

    elseif addDel == "del" then
        --删除IP记录
        if XFFon then
            local blackKey = ipPut .. list_type
            dict_black:delete(blackKey)  --黑名单中删除该IP
        else
            local ip, err = ngx.re.gmatch(ipPut, ipRegular)  --删除批量规范IP
            if not ip then
                ngx.log(ngx.ERR, "error: ", err)
                return
            end

            while true do
                local p, err = ip()
                if err then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end
                if not p then
                    --no match found (any more)
                    break
                end
                local matchIp = p[0]
                local blackKey = matchIp .. list_type  --黑名单中删除该IP
                dict_black:delete(blackKey)
            end
        end
    elseif addDel == "all-" then
        dict_black:flush_all()
    end
end


-- 302跳转
if list_type == "white302" then
    --判断更新的类型是否为 white302
    if addDel == "add" then
        --增加记录
        if XFFon then
            --添加单个经过 proxy IP
            local whiteKey = ipPut .. list_type
            dict_white:set(whiteKey, 0, whiteTime)  --增加IP到white302名单
        else
            local ip, err = ngx.re.gmatch(ipPut, ipRegular)  --添加批量规范IP
            if not ip then
                ngx.log(ngx.ERR, "error: ", err)
                return
            end

            while true do
                local p, err = ip()
                if err then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end
                if not p then
                    --no match found (any more)
                    break
                end
                local matchIp = p[0]
                local whiteKey = matchIp .. list_type
                dict_white:set(whiteKey, 0, whiteTime)  --增加IP到white302名单
            end
        end
    elseif addDel == "del" then
        --删除IP
        if XFFon then
            local whiteKey = ipPut .. list_type
            dict_white:delete(whiteKey)  --white302名单中删除该IP
        else
            local ip, err = ngx.re.gmatch(ipPut, ipRegular)  --删除批量规范IP
            if not ip then
                ngx.log(ngx.ERR, "error: ", err)
                return
            end

            while true do
                local p, err = ip()
                if err then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end
                if not p then
                    --no match found (any more)
                    break
                end
                local matchIp = p[0]
                local whiteKey = matchIp .. list_type
                dict_white:delete(whiteKey)  --white302名单中删除IP
            end
        end
    elseif addDel == "all-" then
        dict_white:flush_all()
    end
end


-- JS跳转
if list_type == "whitejs" then
    --判断更新的类型是否为 whitejs
    if addDel == "add" then
        --增加记录
        if XFFon then
            --添加单个经过 proxy IP
            local whiteKey = ipPut .. list_type
            dict_white:set(whiteKey, 0, whiteTime)  --增加IP到whitejs名单
        else
            local ip, err = ngx.re.gmatch(ipPut, ipRegular)  --添加批量规范IP
            if not ip then
                ngx.log(ngx.ERR, "error: ", err)
                return
            end

            while true do
                local p, err = ip()
                if err then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end
                if not p then
                    --no match found (any more)
                    break
                end
                local matchIp = p[0]
                local whiteKey = matchIp .. list_type
                dict_white:set(whiteKey, 0, whiteTime)  --增加IP到whitejs名单
            end
        end
    elseif addDel == "del" then
        --删除IP
        if XFFon then
            local whiteKey = ipPut .. list_type
            dict_white:delete(whiteKey)  --whitejs名单中删除IP
        else
            local ip, err = ngx.re.gmatch(ipPut, ipRegular)  --删除批量规范IP
            if not ip then
                ngx.log(ngx.ERR, "error: ", err)
                return
            end

            while true do
                local p, err = ip()
                if err then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end
                if not p then
                    --no match found (any more)
                    break
                end
                local matchIp = p[0]
                local whiteKey = matchIp .. list_type
                dict_white:delete(whiteKey)  --whitejs名单中删除该IP
            end
        end
    elseif addDel == "all-" then
        dict_white:flush_all()
    end
end


-- Cookie
if list_type == "whitecookie" then
    --判断更新的类型是否为 whitecookie
    if addDel == "add" then
        --增加记录
        if XFFon then
            --添加单个经过 proxy IP
            local whiteKey = ipPut .. list_type
            dict_white:set(whiteKey, 0, whiteTime)  --增加IP到whitecookie名单
        else
            local ip, err = ngx.re.gmatch(ipPut, ipRegular)  --添加批量规范IP
            if not ip then
                ngx.log(ngx.ERR, "error: ", err)
                return
            end

            while true do
                local p, err = ip()
                if err then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end
                if not p then
                    --no match found (any more)
                    break
                end
                local matchIp = p[0]
                local whiteKey = matchIp .. list_type
                dict_white:set(whiteKey, 0, whiteTime)  --增加IP到whitecookie名单
            end
        end
    elseif addDel == "del" then
        --删除IP
        if XFFon then
            local whiteKey = ipPut .. list_type
            dict_white:delete(whiteKey)  --whitecookie名单中删除该IP
        else
            local ip, err = ngx.re.gmatch(ipPut, ipRegular)  --删除批量规范IP
            if not ip then
                ngx.log(ngx.ERR, "error: ", err)
                return
            end

            while true do
                local p, err = ip()
                if err then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end
                if not p then
                    --no match found (any more)
                    break
                end
                local matchIp = p[0]
                local whiteKey = matchIp .. list_type
                dict_white:delete(whiteKey)  --whitecookie名单中删除该IP
            end
        end
    elseif addDel == "all-" then
        dict_white:flush_all()
    end
end


-- whitePerUrlRateLimit
if list_type == "whitePerUrlRateLimit" then
    --判断更新的类型是否为 whitePerUrlRateLimit
    if addDel == "add" then
        --增加记录
        if XFFon then
            --添加单个经过 proxy IP
            local whiteKey = ipPut .. list_type
            dict_white:set(whiteKey, 0, whiteTime)  --增加IP到whitePerUrlRateLimit名单
        else
            local ip, err = ngx.re.gmatch(ipPut, ipRegular)  --添加批量规范IP
            if not ip then
                ngx.log(ngx.ERR, "error: ", err)
                return
            end

            while true do
                local p, err = ip()
                if err then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end
                if not p then
                    --no match found (any more)
                    break
                end
                local matchIp = p[0]
                local whiteKey = matchIp .. list_type
                dict_white:set(whiteKey, 0, whiteTime)  --增加IP到whitePerUrlRateLimit名单
            end
        end
    elseif addDel == "del" then
        --删除IP
        if XFFon then
            local whiteKey = ipPut .. list_type
            dict_white:delete(whiteKey)  --whitePerUrlRateLimit名单中删除该IP
        else
            local ip, err = ngx.re.gmatch(ipPut, ipRegular)  --删除批量规范IP
            if not ip then
                ngx.log(ngx.ERR, "error: ", err)
                return
            end

            while true do
                local p, err = ip()
                if err then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end
                if not p then
                    --no match found (any more)
                    break
                end
                local matchIp = p[0]
                local whiteKey = matchIp .. list_type
                dict_white:delete(whiteKey)  --whitePerUrlRateLimit名单中删除该IP
            end
        end
    elseif addDel == "all-" then
        dict_white:flush_all()
    end
end



-- whiteVerification
if list_type == "whiteVerification" then
    --判断更新的类型是否为 whiteVerification
    local whiteTime = _Conf.dict_system:get("oneKeyOpenVerification_whiteTime")
    if addDel == "add" then
        --增加记录
        if XFFon then
            --添加单个经过 proxy IP
            local whiteKey = ipPut .. list_type
            dict_white:set(whiteKey, 0, whiteTime)  --增加IP到whiteVerification名单
        else
            local ip, err = ngx.re.gmatch(ipPut, ipRegular)  --添加批量规范IP
            if not ip then
                ngx.log(ngx.ERR, "error: ", err)
                return
            end

            while true do
                local p, err = ip()
                if err then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end
                if not p then
                    --no match found (any more)
                    break
                end
                local matchIp = p[0]
                local whiteKey = matchIp .. list_type
                dict_white:set(whiteKey, 0, whiteTime)  --增加IP到whiteVerification名单
            end
        end
    elseif addDel == "del" then
        --删除IP
        if XFFon then
            local whiteKey = ipPut .. list_type
            dict_white:delete(whiteKey)  --whiteVerification名单中删除该IP
        else
            local ip, err = ngx.re.gmatch(ipPut, ipRegular)  --删除批量规范IP
            if not ip then
                ngx.log(ngx.ERR, "error: ", err)
                return
            end

            while true do
                local p, err = ip()
                if err then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end
                if not p then
                    --no match found (any more)
                    break
                end
                local matchIp = p[0]
                local whiteKey = matchIp .. list_type
                dict_white:delete(whiteKey)  --whiteVerification名单中删除该IP
            end
        end
    elseif addDel == "all-" then
        dict_white:flush_all()
    end
end


--Challenge
if list_type == "challenge" then
    if addDel == "del" then
        local challengeKey = ipPut
        dict_challenge:delete(challengeKey)
    elseif addDel == "all-" then
        dict_challenge:flush_all()
    end
end


--rateLimit
if list_type == "rateLimit" then
    --判断更新的类型是否为 rateLimit
    if addDel == "add" then
        --增加IP记录
        if rateXFFon then
            --提交IP为单个的含 , 的经过 proxy IP
            if rateLimitBlockTime == 0 then
                local rateLimitKey = ipPut
                dict_others:set(rateLimitKey, 1)  --增加IP到rateLimit名单, Values 为 1 的表示不过期
            else
                local rateLimitKey = ipPut
                dict_others:set(rateLimitKey, 2, rateLimitBlockTime)  --增加IP到rateLimit名单, Values 为 2 的表示有过期时间
            end
        else
            if rateLimitBlockTime == 0 then
                local ip, err = ngx.re.gmatch(ipPut, ipUrlRegular)
                if not ip then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end

                while true do
                    --批量添加匹配的IP
                    local p, err = ip()
                    if err then
                        ngx.log(ngx.ERR, "error: ", err)
                        return
                    end
                    if not p then
                        --no match found (any more)
                        break
                    end
                    local matchIp = p[0]  --匹配的IP
                    local rateLimitKey = matchIp
                    dict_others:set(rateLimitKey, 1)  --增加IP到rateLimit名单, Values 为 1 的表示不过期
                end
            else
                local ip, err = ngx.re.gmatch(ipPut, ipUrlRegular)
                if not ip then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end

                while true do
                    --批量添加匹配的IP
                    local p, err = ip()
                    if err then
                        ngx.log(ngx.ERR, "error: ", err)
                        return
                    end
                    if not p then
                        --no match found (any more)
                        break
                    end
                    local matchIp = p[0]  --匹配的IP
                    local rateLimitKey = matchIp
                    dict_others:set(rateLimitKey, 2, rateLimitBlockTime)  --增加IP到rateLimit名单, Values 为 2 的表示有过期时间
                end

            end
        end

    elseif addDel == "del" then
        --删除IP记录
        if XFFon then
            local rateLimitKey = ipPut
            dict_others:delete(rateLimitKey)  --rateLimit名单中删除该IP
        else
            local ip, err = ngx.re.gmatch(ipPut, ipUrlRegular)
            if not ip then
                ngx.log(ngx.ERR, "error: ", err)
                return
            end

            while true do
                local p, err = ip()
                if err then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end
                if not p then
                    --no match found (any more)
                    break
                end
                local matchIp = p[0]
                local rateLimitKey = matchIp  --rateLimit名单中删除该IP
                dict_others:delete(rateLimitKey)
            end
        end

    elseif addDel == "all-" then
        --删除所有 rateLimitKey
        otherKey = dict_others:get_keys(0)
        for k, v in pairs(otherKey) do
            local matchKey = string.match(v, "ratelimit")
            if matchKey then
                dict_others:delete(v)
            end
        end
    end
end


-- perUrlRateLimitList名单
if list_type == "perUrlRateLimit" then
    --判断更新的类型是否为 perUrlRateLimit
    if addDel == "del" then
        --删除IP记录
        if XFFon then
            local byWhiteKey = ipPut
            dict_perUrlRateLimit:delete(byWhiteKey)  --perUrlRateLimit名单中删除该IP
        else
            local ip, err = ngx.re.gmatch(ipPut, ipRegular)
            if not ip then
                ngx.log(ngx.ERR, "error: ", err)
                return
            end

            while true do
                local p, err = ip()
                if err then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end
                if not p then
                    --no match found (any more)
                    break
                end
                local matchIp = p[0]
                local byWhiteKey = matchIp .. "Verified"  --perUrlRateLimit名单中删除该IP
                dict_perUrlRateLimit:delete(byWhiteKey)
                dict_perUrlRateLimit:delete(matchIp)
            end
        end
    elseif addDel == "all-" then
        dict_perUrlRateLimit:flush_all()
    end
end


-- needVerify
if list_type == "needVerify" then
    --判断更新的类型是否为 needVerify
    if expire == -1 then
        expire = _Conf.blockTime
    end
    if addDel == "add" then
        --增加IP记录
        if XFFon then
            --提交IP为单个的含 , 的经过 proxy IP
            local ip = ipPut

            dict_needVerify:set(ip, 1, expire)  --增加IP到needVerify名单

        else

            local ip, err = ngx.re.gmatch(ipPut, ipRegular)
            if not ip then
                ngx.log(ngx.ERR, "error: ", err)
                return
            end

            while true do
                --批量添加匹配的IP
                local p, err = ip()
                if err then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end
                if not p then
                    --no match found (any more)
                    break
                end
                local matchIp = p[0]  --匹配的IP
                local ipKey = matchIp
                dict_needVerify:set(ipKey, 1, expire)  --增加IP到needVerify名单
            end

        end

    elseif addDel == "del" then
        --删除IP记录
        if XFFon then
            local byWhiteKey = ipPut
            dict_needVerify:delete(byWhiteKey)  --needVerify名单中删除该IP
        else
            local ip, err = ngx.re.gmatch(ipPut, ipRegular)
            if not ip then
                ngx.log(ngx.ERR, "error: ", err)
                return
            end

            while true do
                local p, err = ip()
                if err then
                    ngx.log(ngx.ERR, "error: ", err)
                    return
                end
                if not p then
                    --no match found (any more)
                    break
                end
                local matchIp = p[0]
                local byWhiteKey = matchIp  --needVerify名单中删除该IP
                dict_needVerify:delete(byWhiteKey)
            end
        end
    elseif addDel == "all-" then
        dict_needVerify:flush_all()
    end
end
