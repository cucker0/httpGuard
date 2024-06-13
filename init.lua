local Config = require("config")
local requireGuard = ''
if string.lower(Config.hgModules.manType) == "dynamic" then
    requireGuard = require "guard_dynamic"
else
    requireGuard = require "guard_static"
end

local version = "v3.7.6.3"        --HttpGuard 版本号

--开关转换为true或false函数
local function optionIsOn(options)
    local options = string.lower(options)
    if options == "on" then
        return true
    else
        return false
    end
end

--生成密码
local function makePassword()
    local string = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    math.randomseed(os.time()) --随机种子
    local r1 = math.random(1, 62)  --生成1-62之间的随机数
    local r2 = math.random(1, 62)  --生成1-62之间的随机数
    local r3 = math.random(1, 62)  --生成1-62之间的随机数
    local r4 = math.random(1, 62)  --生成1-62之间的随机数
    local r5 = math.random(1, 62)  --生成1-62之间的随机数
    local r6 = math.random(1, 62)  --生成1-62之间的随机数
    local r7 = math.random(1, 62)  --生成1-62之间的随机数
    local r8 = math.random(1, 62)  --生成1-62之间的随机数

    local s1 = string.sub(string, r1, r1)
    local s2 = string.sub(string, r2, r2)
    local s3 = string.sub(string, r3, r3)
    local s4 = string.sub(string, r4, r4)
    local s5 = string.sub(string, r5, r5)
    local s6 = string.sub(string, r6, r6)
    local s7 = string.sub(string, r7, r7)
    local s8 = string.sub(string, r8, r8)

    return s1 .. s2 .. s3 .. s4 .. s5 .. s6 .. s7 .. s8
end

local function stringLower(s)
    -- url是否转小写
    if string.lower(Config.hgModules.urlIgnoreCase) == "on" then
        s = string.lower(s)
    end
    return s
end

--解析文件到正则字符串函数
local function parseRuleFile(filePath)
    local list = ''
    local rfile = assert(io.open(filePath, 'r'))
    for line in rfile:lines() do
        --忽略 只含空格的行、--开头的行、空行
        if not (string.match(line, "^ *$")) and not (string.match(line, "^([%s]*%-%-)")) and not (line == '') then
            list = list .. "|" .. line
        end
    end
    list = string.gsub(list, "^%|", '')
    --list = stringLower(list)
    rfile:close()
    --如果 list 为空, 则 list 赋值 "^HttpGuard match nil!$"
    if list == '' then
        list = "^HttpGuard match nil!$"
    end
    return list
end

--解析文件到正则字符串到 Table
local function parseRuleFile2Table(filePath)
    rfile = assert(io.open(filePath, 'r'))
    local t = {}
    for line in rfile:lines() do
        --忽略 只含空格的行、--开头的行、空行
        if not (string.match(line, "^ *$")) and not (string.match(line, "^([%s]*%-%-)")) and not (line == '') then
            line = string.gsub(line, "^%|", '')
            --line = stringLower(line)
            table.insert(t, line)
        end
    end
    rfile:close()
    --如果 t 表为空, 则插入一个 key
    if not t[1] then
        table.insert(t, "^HttpGuard match nil!$")
    end
    return t
end

--解析文件到正则字符串函数（URL中含其他选项），返回组合的正则
local function parseRuleFile2(filePath)
    local list = ''
    local rfile = assert(io.open(filePath, 'r'))
    for line in rfile:lines() do
        --忽略 只含空格的行、--开头的行、空行
        if not (string.match(line, "^ *$")) and not (string.match(line, "^([%s]*%-%-)")) and not (line == '') then
            for v1, v2 in string.gmatch(line, "(.*)#maxReqs=([0-9]+)") do
                list = list .. "|" .. v1
                --if v2 ~= nil then
                --	v2 = tonumber(v2)
                --	dict:set(v1, v2)
                --end
            end

        end
    end
    list = string.gsub(list, "^%|", '')
    --list = stringLower(list)
    rfile:close()
    --如果 list 为空, 则 list 赋值 "^HttpGuard match nil!$"
    if list == '' then
        list = "^HttpGuard match nil!$"
    end
    return list

end


--解析动作
local function actionIsOn1(action)
    if string.lower(action) == "captcha" then
        return true
    else
        return false
    end
end

local function actionIsOn2(action)
    if string.lower(action) == "forbidden" then
        return true
    else
        return false
    end
end

local function actionIsOn3(action)
    if string.lower(action) == "iptables" then
        return true
    else
        return false
    end
end

local function actionIsOn4(action)
    if string.lower(action) == "click" then
        return true
    else
        return false
    end
end

--解析uri匹配模式
local function urlMode1(mode)
    if string.lower(mode) == "uri" then
        return true
    else
        return false
    end
end

local function urlMode2(mode)
    if string.lower(mode) == "requesturi" then
        return true
    else
        return false
    end
end


--读取文件到内存
local function readFile2Mem(file)
    local fp = io.open(file, "r")
    if fp then
        return fp:read("*all")
    end
end

--读取验证码到字典
local function readCaptcha2Dict(dir, dict)
    local i = _Conf.randomInteger        --随机整数
    --local i = 0
    local count = i + 10000
    for path in io.popen('ls -a ' .. dir .. '*.png'):lines() do
        if i < count then
            i = i + 1
            local fp = io.open(path, "rb")
            local img = fp:read("*all")
            local captcha = string.gsub(path, ".*/(.*)%.png", "%1")
            captcha = string.lower(captcha)
            dict:set(i, captcha)
            dict:set(captcha, img)
        else
            break
        end
    end
end

--读取IP到字典
local function readIp2Dict(filePath, dict)
    local rfile = assert(io.open(filePath, 'r'))
    for line in rfile:lines() do
        if not (string.match(line, "^ *$")) and not (string.match(line, "^([%s]*%-%-)")) and not (line == '') then
            local t = {}
            local i = 0
            for k in string.gmatch(line, "[^#]+") do
                t[i] = k
                i = i + 1
            end
            local ip = t[0]
            local comment = t[1] or 0
            dict:set(ip, comment)
        end
    end
    rfile:close()
end

--读取设置到字典
local function readConfig2Dict(item, conf, dict)
    if type(conf) == "table" then
        for k, v in pairs(conf) do
            if string.lower(v) == "on" then
                v = true
            elseif string.lower(v) == "off" then
                v = false
            end
            dict:set(item .. "_" .. k, v)
        end
    else
        if type(conf) == "string" then
            local isOn = ""
            if (string.lower(conf) == "on") then
                isOn = true
                dict:set(item, isOn)
            elseif (string.lower(conf) == "off") then
                isOn = false
                dict:set(item, isOn)
            else
                dict:set(item, conf)
            end
        else
            dict:set(item, conf)
        end
    end
end

--读取rateLimit配置到Table
local function rateLimitFile2Table(filePath)
    local rfile = assert(io.open(filePath, 'r'))
    local t = {}
    local i = 1
    for line in rfile:lines() do
        if not (string.match(line, "^ *$")) and not (string.match(line, "^([%s]*%-%-)")) and not (line == '') then
            t[i] = {}
            for v1, v2, v3 in string.gmatch(line, "(.*)#maxReqs=([0-9]+)#bigMaxReqs=([0-9]+)") do
                t[i][1] = v1
                t[i][2] = tonumber(v2)
                t[i][3] = tonumber(v3)
            end
            i = i + 1
        end
    end
    rfile:close()
    return t
end

--读取 perUrlRateLimit的url、最大请求数据到字典 dict:set(url, MaxReq)到字典
local function readPerUrlRateLimit2Dict(filePath, dict)
    local rfile = assert(io.open(filePath, 'r'))
    for line in rfile:lines() do
        --忽略 只含空格的行、--开头的行、空行
        if not (string.match(line, "^ *$")) and not (string.match(line, "^([%s]*%-%-)")) and not (line == '') then
            for v1, v2 in string.gmatch(line, "(.*)#maxReqs=([0-9]+)") do
                --list = list.."|"..v1
                if v2 ~= nil then
                    v2 = tonumber(v2)
                    dict:set(v1, v2)
                end
            end

        end
    end
    rfile:close()
end

--生成随机时间差
math.randomseed(os.time())
local function genRandomTime()
    local randm = (math.random(Config.randomDelayProcessing.timeRange.s, Config.randomDelayProcessing.timeRange.e))
    local offset = randm / 1000
    return offset
end

_Conf = {

    --引入原始设置
    hgModules = Config.hgModules,
    limitReqModules = Config.limitReqModules,
    redirectModules = Config.redirectModules,
    --byPassModules = Config.byPassModules,
    JsJumpModules = Config.JsJumpModules,
    cookieModules = Config.cookieModules,
    byWhiteIpModules = Config.byWhiteIpModules,
    byDenyIpModules = Config.byDenyIpModules,
    realIpFromHeader = Config.realIpFromHeader,
    autoEnable = Config.autoEnable,
    logPath = Config.debug.logPath,
    blockTime = Config.blockTime,
    keyExpire = Config.keyExpire,
    sudoPass = Config.sudoPass,
    whiteTime = Config.whiteTime,
    captchaKey = Config.captchaKey,
    clickKey = Config.clickKey,
    captcha2click = Config.captcha2click,
    rateLimit = Config.rateLimit,
    others = Config.others,
    oneKeyOpenVerification = Config.oneKeyOpenVerification,
    perUrlRateLimit = Config.perUrlRateLimit,
    randomDelayProcessing = Config.randomDelayProcessing,

    --解析开关设置
    hgModulesIsOn = optionIsOn(Config.hgModules.state),
    limitReqModulesIsOn = optionIsOn(Config.limitReqModules.state),
    byWhiteIpModulesIsOn = optionIsOn(Config.byWhiteIpModules.state),
    byDenyIpModulesIsOn = optionIsOn(Config.byDenyIpModules.state),
    black2byDenyIsOn = optionIsOn(Config.byDenyIpModules.black2byDenyState),
    realIpFromHeaderIsOn = optionIsOn(Config.realIpFromHeader.state),
    autoEnableIsOn = optionIsOn(Config.autoEnable.state),
    redirectModulesIsOn = optionIsOn(Config.redirectModules.state),
    urlFilterModulesIsOn = optionIsOn(Config.urlFilterModules.state),
    urlDenyIsOn = optionIsOn(Config.urlFilterModules.denyState),
    urlAllowIsOn = optionIsOn(Config.urlFilterModules.allowState),
    JsJumpModulesIsOn = optionIsOn(Config.JsJumpModules.state),
    cookieModulesIsOn = optionIsOn(Config.cookieModules.state),
    captcha2clickOn = optionIsOn(Config.captcha2click.state),
    debugIsOn = optionIsOn(Config.debug.state),
    userAgentIsOn = optionIsOn(Config.userAgent.state),
    userAgentAllowIsOn = optionIsOn(Config.userAgent.allowState),
    httpRefererIsOn = optionIsOn(Config.httpReferer.state),
    httpRefererAllowIsOn = optionIsOn(Config.httpReferer.allowState),
    postArgsFilterIsOn = optionIsOn(Config.postArgsFilter.state),
    getArgsFilterIsOn = optionIsOn(Config.getArgsFilter.state),
    cookieArgsFilterIsOn = optionIsOn(Config.cookieArgsFilter.state),
    rateLimitIsOn = optionIsOn(Config.rateLimit.state),
    rateStateIsOn = optionIsOn(Config.rateLimit.rateState),
    bigRateStateIsOn = optionIsOn(Config.rateLimit.bigRateState),
    rate2byDenyStateIsOn = optionIsOn(Config.rateLimit.rate2byDenyState),
    othersIsOn = optionIsOn(Config.others.state),
    showPostArgAndCookieArgStateOn = optionIsOn(Config.others.showPostArgAndCookieArgState),
    oneKeyOpenVerificationIsOn = optionIsOn(Config.oneKeyOpenVerification.state),
    perUrlRateLimitIsOn = optionIsOn(Config.perUrlRateLimit.state),
    perUrlRateLimit2ByDenyIsOn = optionIsOn(Config.perUrlRateLimit.perUrlRateLimit2ByDenyState),
    randomDelayProcessingIsOn = optionIsOn(Config.randomDelayProcessing.state),
    urlIgnoreCaseIsOn = optionIsOn(Config.hgModules.urlIgnoreCase),

    --解析文件到正则
    redirectUrlProtect = parseRuleFile(Config.redirectModules.urlProtect),
    urlAllowProtect = parseRuleFile(Config.urlFilterModules.urlAllowProtect),
    urlDenyProtect = parseRuleFile2Table(Config.urlFilterModules.urlDenyProtect),
    JsJumpUrlProtect = parseRuleFile(Config.JsJumpModules.urlProtect),
    limitUrlProtect = parseRuleFile(Config.limitReqModules.urlProtect),
    cookieUrlProtect = parseRuleFile(Config.cookieModules.urlProtect),
    userAgentAllowProtect = parseRuleFile(Config.userAgent.userAgentAllow),
    userAgentDenyProtect = parseRuleFile(Config.userAgent.userAgentDeny),
    httpRefererAllowProtect = parseRuleFile(Config.httpReferer.httpRefererAllow),
    httpRefererDenyProtect = parseRuleFile(Config.httpReferer.httpRefererDeny),
    postArgsDenyProtect = parseRuleFile2Table(Config.postArgsFilter.postArgsDeny),
    getArgsDenyProtect = parseRuleFile2Table(Config.getArgsFilter.getArgsDeny),
    cookieArgsDenyProtect = parseRuleFile2Table(Config.cookieArgsFilter.cookieArgsDeny),
    rateLimitUrlProtect = rateLimitFile2Table(Config.rateLimit.urlProtect),
    noneRefererPages = parseRuleFile(Config.others.noneRefererPages),
    showPostArgAndCookieArgPages = parseRuleFile(Config.others.showPostArgAndCookieArgPages),
    preurlVerifyCaptcha_regex = parseRuleFile(Config.preurlVerifyCaptcha_regex),
    perUrlRateLimitUrlProtect = parseRuleFile2(Config.perUrlRateLimit.urlProtect),
    randomDelayProcessingUrlProtect = parseRuleFile(Config.randomDelayProcessing.urlProtect),

    --读取文件到内存
    captchaPage = readFile2Mem(Config.captchaPage),
    reCaptchaPage = readFile2Mem(Config.reCaptchaPage),

    --新建字典(用于记录系统设置)
    dict_system = ngx.shared.dict_system,

    --新建字典(用于记录ip访问次数及黑名单)
    dict_black = ngx.shared.dict_black,

    --新建字典(用于记录白名单ip)
    dict_white = ngx.shared.dict_white,

    --新建字典（用户记录byDeny直接黑名单IP）
    dict_byDenyIp = ngx.shared.dict_byDenyIp,

    --新建字典（用于记录byWhite直接白名单IP）
    dict_byWhiteIp = ngx.shared.dict_byWhiteIp,

    --新建字典(用于记录challenge ip及次数)
    dict_challenge = ngx.shared.dict_challenge,

    --新建字典(只用于记录验证码,防止丢失)
    dict_captcha = ngx.shared.dict_captcha,

    --新建杂项字典(记录rateLimte等)
    dict_others = ngx.shared.dict_others,

    --新建字典(记录进入perUrlRateLimit列表次数)
    dict_perUrlRateLimit = ngx.shared.dict_perUrlRateLimit,

    --新建字典(记录需要验证验证码的IP)
    dict_needVerify = ngx.shared.dict_needVerify,

    --验证码图片路径
    captchaDir = Config.captchaDir,

    --byWhite IP 路径
    byWhiteIpPath = Config.byWhiteIpModules.ipList,

    --byDeny IP 路径
    byDenyIpPath = Config.byDenyIpModules.ipList,

    captchaAction = actionIsOn1(Config.blockAction.type),
    forbiddenAction = actionIsOn2(Config.blockAction.type),
    iptablesAction = actionIsOn3(Config.blockAction.type),
    clickAction = actionIsOn4(Config.blockAction.type),
    hiddenClick = optionIsOn(Config.blockAction.hiddenClickState),

    --解析url匹配模式
    uriMode = urlMode1(Config.urlMatchMode),
    requestUriMode = urlMode2(Config.urlMatchMode),

    normalCount = 0,
    exceedCount = 0,

    --版本号
    hg_version = version,

    Guard = requireGuard,

    --获取1-10000之间的一个随机数
    randomInteger = math.random(1, 10000),

    randomTime = genRandomTime,

}

--读取验证码到字典
readCaptcha2Dict(_Conf.captchaDir, _Conf.dict_captcha)

--读取byWhite列表IP到字典
readIp2Dict(_Conf.byWhiteIpPath, _Conf.dict_byWhiteIp)

--读取byDeny列表IP到字典
readIp2Dict(_Conf.byDenyIpPath, _Conf.dict_byDenyIp)

--读取perUrlRateLimit url MaxReq到字典
readPerUrlRateLimit2Dict(_Conf.perUrlRateLimit.urlProtect, _Conf.dict_system)

--判断redirectModules是否开启
if _Conf.redirectModulesIsOn then
    _Conf.dict_system:set("redirectOn", 1)
else
    _Conf.dict_system:set("redirectOn", 0)
end

--判断JsJumpModules是否开启
if _Conf.JsJumpModulesIsOn then
    _Conf.dict_system:set("jsOn", 1)
else
    _Conf.dict_system:set("jsOn", 0)
end

--判断cookieModules是否开启
if _Conf.cookieModulesIsOn then
    _Conf.dict_system:set("cookieOn", 1)
else
    _Conf.dict_system:set("cookieOn", 0)
end

--设置自动开启防cc相关变量
_Conf.dict_system:set("normalCount", 0)
_Conf.dict_system:set("exceedCount", 0)

--判断oneKeyOpenVerification是否开启
if _Conf.oneKeyOpenVerificationIsOn then
    _Conf.dict_system:set("oneKeyOpenVerificationOn", 1)
else
    _Conf.dict_system:set("oneKeyOpenVerificationOn", 0)
end

--初始化oneKeyOpenVerification whiteTime
_Conf.dict_system:set("oneKeyOpenVerification_whiteTime", Config.oneKeyOpenVerification.whiteTime)

--判断是否key是动态生成
if string.lower(Config.keyDefine) == "dynamic" then
    _Conf.redirectModules.keySecret = makePassword()
    _Conf.JsJumpModules.keySecret = makePassword()
    _Conf.cookieModules.keySecret = makePassword()
    _Conf.captchaKey = makePassword()
    _Conf.clickKey = makePassword()
end


--读取动态管理参数到字典
if string.lower(Config.hgModules.manType) == "dynamic" then
    local dict = _Conf.dict_system
    --readConfig2Dict("hgModules",Config.hgModules,dict)
    readConfig2Dict("limitReqModules", Config.limitReqModules, dict)
    readConfig2Dict("redirectModules", Config.redirectModules, dict)
    readConfig2Dict("JsJumpModules", Config.JsJumpModules, dict)
    readConfig2Dict("cookieModules", Config.cookieModules, dict)
    readConfig2Dict("autoEnable", Config.autoEnable, dict)
    readConfig2Dict("blockAction", Config.blockAction, dict)
    readConfig2Dict("blockTime", Config.blockTime, dict)
    readConfig2Dict("whiteTime", Config.whiteTime, dict)
    readConfig2Dict("keyExpire", Config.keyExpire, dict)
    readConfig2Dict("byWhiteIpModules", Config.byWhiteIpModules, dict)
    readConfig2Dict("byDenyIpModules", Config.byDenyIpModules, dict)
    readConfig2Dict("debug", Config.debug, dict)
    readConfig2Dict("captcha2click", Config.captcha2click, dict)
    readConfig2Dict("userAgent", Config.userAgent, dict)
    readConfig2Dict("httpReferer", Config.httpReferer, dict)
    readConfig2Dict("urlFilterModules", Config.urlFilterModules, dict)
    readConfig2Dict("postArgsFilter", Config.postArgsFilter, dict)
    readConfig2Dict("getArgsFilter", Config.getArgsFilter, dict)
    readConfig2Dict("cookieArgsFilter", Config.cookieArgsFilter, dict)

    readConfig2Dict("captchaAction", _Conf.captchaAction, dict)
    readConfig2Dict("forbiddenAction", _Conf.forbiddenAction, dict)
    readConfig2Dict("iptablesAction", _Conf.iptablesAction, dict)
    readConfig2Dict("clickAction", _Conf.clickAction, dict)
    readConfig2Dict("hiddenClick", _Conf.hiddenClick, dict)
    readConfig2Dict("redirectUrlProtect", _Conf.redirectUrlProtect, dict)
    readConfig2Dict("urlAllowProtect", _Conf.urlAllowProtect, dict)
    readConfig2Dict("urlDenyProtect", _Conf.urlDenyProtect, dict)
    readConfig2Dict("JsJumpUrlProtect", _Conf.JsJumpUrlProtect, dict)
    readConfig2Dict("limitUrlProtect", _Conf.limitUrlProtect, dict)
    readConfig2Dict("cookieUrlProtect", _Conf.cookieUrlProtect, dict)
    readConfig2Dict("userAgentAllowProtect", _Conf.userAgentAllowProtect, dict)
    readConfig2Dict("userAgentDenyProtect", _Conf.userAgentDenyProtect, dict)
    readConfig2Dict("httpRefererAllowProtect", _Conf.httpRefererAllowProtect, dict)
    readConfig2Dict("httpRefererDenyProtect", _Conf.httpRefererDenyProtect, dict)
    readConfig2Dict("postArgsDenyProtect", _Conf.postArgsDenyProtect, dict)
    readConfig2Dict("getArgsDenyProtect", _Conf.getArgsDenyProtect, dict)
    readConfig2Dict("cookieArgsDenyProtect", _Conf.cookieArgsDenyProtect, dict)

end
