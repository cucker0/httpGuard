--update system
--解析用户操作 hgSystem.lua 页面的动作并执行

--if string.lower(_Conf.hgModules.manType) == "dynamic" then
ngx.say('<script language=JavaScript> self.opener.location.reload(); </script>')	--刷新 /hgsystem 父窗口

ngx.req.read_body()
local hh = "<br>"
local kg = "&nbsp;&nbsp;"
local dict_system = ngx.shared.dict_system
local dict_byDenyIp = ngx.shared.dict_byDenyIp
local dict_byWhiteIp = ngx.shared.dict_byWhiteIp
local dict_black = ngx.shared.dict_black
local dict_white = ngx.shared.dict_white
local dict_challenge = ngx.shared.dict_challenge
local args = ngx.req.get_post_args() --获取post参数
local item = args["item"] 	--获取 item post 值
local state = args["state"]		--获取State值
local get_blockTime = args["blockTime"]		--获取黑名单时间
local get_whiteTime = args["whiteTime"]		--获取白名单时间
local blockAction = args["block"]		--获取限制动作类型
local get_cookieVerifyMaxFail = args["cookieVerifyMaxFail"]		--获取 cookieVerifyMaxFail 值
local get_cookieAmongTime = args["cookieAmongTime"]		--获取cookieAmongTime值
local get_c2cVerifyMaxFail = args["c2cVerifyMaxFail"]		--获取captcha2click VerifyMaxFail值
local get_c2cAmongTime = args["c2cAmongTime"]		--获取captcha2click AmongTime值
local get_limitReq = args["limitReq"]		--获取 limitReq 值
local get_limitAmongTime = args["limitAmongTime"]		--获取 limitAmongTime 值
local get_redirectVerifyMaxFail = args["redirectVerifyMaxFail"]		--获取 redirectVerifyMaxFail 值
local get_redirectAmongTime = args["redirectAmongTime"]		--获取 redirectAmongTime 值
local get_jsVerifyMaxFail = args["jsVerifyMaxFail"]		--获取 jsVerifyMaxFail 值
local get_jsAmongTime = args["jsAmongTime"]		--获取 jsAmongTime 值
local get_inBlackMax = args["inBlackMax"]		--获取 inBlackMax 值
local get_b2byDenyAmongTime = args["b2byDenyAmongTime"]		--获取 b2byDenyAmongTime 值
local get_inByDenyBlockTime = args["inByDenyBlockTime"]		--获取 inByDenyBlockTime 值
local parseRule = args["parseRule"]		--获取 parseRule 值
local get_oneKeyOpenVerification_whiteTime = args["oneKeyOpenVerification_whiteTime"]         --获取黑名单时间

--获取正运行的blockAction动作
function blockActionType()
	local captchaAction = dict_system:get("captchaAction")
	local clickAction = dict_system:get("clickAction")
	local forbiddenAction = dict_system:get("forbiddenAction")
	local iptablesAction = dict_system:get("iptablesAction")
	local hiddenClick = dict_system:get("hiddenClick")
	if captchaAction then
		return "captchaAction"
	elseif clickAction then
		if hiddenClick then
			return "hiddenClickAction"
		else
			return "displayClickAction"
		end
	elseif forbiddenAction then
		return "forbiddenAction"
	elseif iptablesAction then
		return "iptablesAction"
	end
end

--解析要更新的blockAction动作并执行开启
function parseBlockAction1(act)
	local clickAction = dict_system:get("clickAction")
	local hiddenClick = dict_system:get("hiddenClick")
	if act == "captchaAction" then
		dict_system:set("captchaAction",true)
	elseif act == "hiddenClickAction" then
		if not clickAction then
			dict_system:set("clickAction",true)
		end
		if not hiddenClick then
			dict_system:set("hiddenClick",true)
		end
	elseif act == "displayClickAction" then
		if not clickAction then
			dict_system:set("clickAction",true)
		end
		if hiddenClick then
			dict_system:set("hiddenClick",false)
		end
	elseif act == "forbiddenAction" then
		dict_system:set("forbiddenAction",true)
	elseif act == "iptablesAction" then
		dict_system:set("iptablesAction",true)
	end
end

--解析正运行的blockAction动作并执行关闭
function parseBlockAction2(act,updateAct) 
	if act == "captchaAction" then
		dict_system:set("captchaAction",false)
	elseif act == "hiddenClickAction" and not (updateAct == "displayClickAction") then
		dict_system:set("clickAction",false)
	elseif act == "displayClickAction" and not (updateAct == "hiddenClickAction") then
		dict_system:set("clickAction",false)
	elseif act == "forbiddenAction" then
		dict_system:set("forbiddenAction",false)
	elseif act == "iptablesAction" then
		dict_system:set("iptablesAction",false)
	end
end

--提取数字
function number(n)
	local n1 = ngx.re.match(n, "[0-9]+")
	local n2 = n1[0]
	local n3 = tonumber(n2)
	if n3 then
		return n3
	else
		return false
	end
end

--把值为 "1", 1 / "0", 0 转换为 "On" / "Off"
function onOff1(s)
	if (s == "1") or (s == 1) then
		return "On"
	elseif (s == "0") or (s == 0) then
		return "Off"
	else
		return false
	end
end

--把 true / false 转换为 "On" / "Off"
function onOff2(s)
        if s then
                return "On"
        else
                return "Off"
        end
end

state = onOff1(state)

local blockTime = false
if get_blockTime and not (get_blockTime == '') then
	blockTime = number(get_blockTime)
end

local whiteTime = false
if get_whiteTime and not (get_whiteTime == '')then
	whiteTime = number(get_whiteTime)
end

local cookieVerifyMaxFail = false
if get_cookieVerifyMaxFail and not (get_cookieVerifyMaxFail == '') then
	cookieVerifyMaxFail = number(get_cookieVerifyMaxFail)
end

local cookieAmongTime = false
if get_cookieAmongTime and not (get_cookieAmongTime == '') then
	cookieAmongTime = number(get_cookieAmongTime)
end

local c2cVerifyMaxFail = false
if get_c2cVerifyMaxFail and not (get_c2cVerifyMaxFail == '') then
	c2cVerifyMaxFail = number(get_c2cVerifyMaxFail)
end

local c2cAmongTime = false
if get_c2cAmongTime and not (get_c2cAmongTime == '') then
	c2cAmongTime = number(get_c2cAmongTime)
end

local limitReq = false
if get_limitReq and not(get_limitReq == '') then
	limitReq = number(get_limitReq)
end

local limitAmongTime = false
if get_limitAmongTime and not (get_limitAmongTime == '') then
	limitAmongTime = number(get_limitAmongTime)
end

local redirectVerifyMaxFail = false
if get_redirectVerifyMaxFail and not (get_redirectVerifyMaxFail == '') then
	redirectVerifyMaxFail = number(get_redirectVerifyMaxFail)
end

local redirectAmongTime =false
if get_redirectAmongTime and not (get_redirectAmongTime == '') then
	redirectAmongTime = number(get_redirectAmongTime)
end

local jsVerifyMaxFail = false
if get_jsVerifyMaxFail and not (get_jsVerifyMaxFail == '') then
	jsVerifyMaxFail = number(get_jsVerifyMaxFail)
end

local jsAmongTime = false
if get_jsAmongTime and not (get_jsAmongTime == '') then
	jsAmongTime = number(get_jsAmongTime)
end

local inBlackMax = false
if get_inBlackMax and not (get_inBlackMax == '') then
	inBlackMax = number(get_inBlackMax)
end

local b2byDenyAmongTime = false
if get_b2byDenyAmongTime and not (get_b2byDenyAmongTime == '') then
	b2byDenyAmongTime = number(get_b2byDenyAmongTime)
end

local inByDenyBlockTime = false
if get_inByDenyBlockTime and not (get_inByDenyBlockTime == '') then
	inByDenyBlockTime = number(get_inByDenyBlockTime)
end

local oneKeyOpenVerification_whiteTime = false
if get_oneKeyOpenVerification_whiteTime and not (get_oneKeyOpenVerification_whiteTime == '')then
	oneKeyOpenVerification_whiteTime = number(get_oneKeyOpenVerification_whiteTime)
end


-- 更新操作
if string.lower(_Conf.hgModules.manType) == "dynamic" then

--[[
if item == "hgModules" and state then
	local hgOn = dict_system:get("hgModules_state")
	hgOn = onOff2(hgOn)
	--更新_Conf.hgModulesIsOn
	if not (state == hgOn) then
		if hgOn == "On" then
			dict_system:set("hgModules_state",false)
		elseif hgOn == "Off" then
			dict_system:set("hgModules_state",true)
		end
	end
]]

--elseif item == "debug" and state then
if item == "debug" and state then
	local debugIsOn = dict_system:get("debug_state")
	debugIsOn = onOff2(debugIsOn)
	--更新_Conf.debugIsOn
	if not (state == debugIsOn) then
		if debugIsOn == "On" then
			dict_system:set("debug_state",false)
		elseif debugIsOn == "Off" then
			dict_system:set("debug_state",true)
		end
	end

elseif item == "byWhiteIpModules" and state then
	local byWhiteIpModulesIsOn = dict_system:get("byWhiteIpModules_state")
	byWhiteIpModulesIsOn = onOff2(byWhiteIpModulesIsOn)
	if not (state == byWhiteIpModulesIsOn) then
		if byWhiteIpModulesIsOn == "On" then
			dict_system:set("byWhiteIpModules_state",false)
		elseif byWhiteIpModulesIsOn == "Off" then
			dict_system:set("byWhiteIpModules_state",true)
		end
	end

elseif item == "byDenyIpModules" and state then
	local byDenyIpModulesIsOn = dict_system:get("byDenyIpModules_state")
	byDenyIpModulesIsOn = onOff2(byDenyIpModulesIsOn)
	if not (state == byDenyIpModulesIsOn) then
		if byDenyIpModulesIsOn == "On" then
			dict_system:set("byDenyIpModules_state",false)
		elseif byDenyIpModulesIsOn == "Off" then
			dict_system:set("byDenyIpModules_state",true)
		end
	end

elseif item == "black2byDeny" then
	local black2byDenyIsOn = dict_system:get("byDenyIpModules_black2byDenyState")
	local byDenyIpModules_inBlackMax = dict_system:get("byDenyIpModules_inBlackMax")
	local byDenyIpModules_blockTime = dict_system:get("byDenyIpModules_blockTime")
	local byDenyIpModules_amongTime = dict_system:get("byDenyIpModules_amongTime")
	black2byDenyIsOn = onOff2(black2byDenyIsOn)
	if state and not (state == black2byDenyIsOn) then
		if black2byDenyIsOn == "On" then
			dict_system:set("byDenyIpModules_black2byDenyState",false)
		elseif black2byDenyIsOn == "Off" then
			dict_system:set("byDenyIpModules_black2byDenyState",true)
		end
	end
	if inBlackMax and not (inBlackMax == byDenyIpModules_inBlackMax) then
		dict_system:set("byDenyIpModules_inBlackMax",inBlackMax)
	end
	if b2byDenyAmongTime and not (b2byDenyAmongTime == byDenyIpModules_amongTime) then
		dict_system:set("byDenyIpModules_amongTime",b2byDenyAmongTime)
	end
	if inByDenyBlockTime and not (inByDenyBlockTime == byDenyIpModules_blockTime) then
		dict_system:set("byDenyIpModules_blockTime",inByDenyBlockTime)
	end


elseif item == "captcha2click" then
	local captcha2clickOn = dict_system:get("captcha2click_state")
	local captcha2click_verifyMaxFail = dict_system:get("captcha2click_verifyMaxFail")
	local captcha2click_amongTime = dict_system:get("captcha2click_amongTime")
	captcha2clickOn	= onOff2(captcha2clickOn)
	--更新_Conf.captcha2clickOn
	if state and not (state == captcha2clickOn) then
		if captcha2clickOn == "On" then
			dict_system:set("captcha2click_state",false)
		elseif captcha2clickOn == "Off" then
			dict_system:set("captcha2click_state",true)
		end
	end
	--更新_Conf.captcha2click.verifyMaxFail
	if c2cVerifyMaxFail and not (c2cVerifyMaxFail == captcha2click_verifyMaxFail) then
		dict_system:set("captcha2click_verifyMaxFail",c2cVerifyMaxFail)
	end
	--更新_Conf.captcha2click.amongTime
	if c2cAmongTime and not (c2cAmongTime == captcha2click_amongTime) then
		dict_system:set("captcha2click_amongTime",c2cAmongTime)
	end

elseif item == "limitReqModules" then
	local limitReqModulesIsOn = dict_system:get("limitReqModules_state")
	local limitReqModules_maxReqs = dict_system:get("limitReqModules_maxReqs")
	local limitReqModules_amongTime = dict_system:get("limitReqModules_amongTime")
	limitReqModulesIsOn = onOff2(limitReqModulesIsOn)
	--更新_Conf.limitReqModulesIsOn
	if state and not (state == limitReqModulesIsOn) then
		if limitReqModulesIsOn == "On" then
			dict_system:set("limitReqModules_state",false)
		elseif limitReqModulesIsOn == "Off" then
			dict_system:set("limitReqModules_state",true)
		end
	end
	--更新_Conf.limitReqModules.maxReqs
	if limitReq and not (limitReq == limitReqModules_maxReqs) then
		dict_system:set("limitReqModules_maxReqs",limitReq)
	end
	--更新_Conf.limitReqModules.amongTime
	if limitAmongTime and not (limitAmongTime == limitReqModules_amongTime) then
		dict_system:set("limitReqModules_amongTime",limitAmongTime)
	end

elseif item == "redirectModules" then
	local redirectModulesIsOn = dict_system:get("redirectOn")
	local redirectModules_verifyMaxFail = dict_system:get("redirectModules_verifyMaxFail")
	local redirectModules_amongTime = dict_system:get("redirectModules_amongTime")
	redirectModulesIsOn = onOff1(redirectModulesIsOn)
	--更新redirectModulesIsOn
	if state and not (state == redirectModulesIsOn ) then
		if redirectModulesIsOn == "On" then
			dict_system:set("redirectOn",0)
		elseif redirectModulesIsOn == "Off" then
			dict_system:set("redirectOn",1)
		end
	end
	--更新_Conf.redirectModules.verifyMaxFail
	if redirectVerifyMaxFail and not (redirectVerifyMaxFail == redirectModules_verifyMaxFail) then
		dict_system:set("redirectModules_verifyMaxFail",redirectVerifyMaxFail)
	end
	--更新_Conf.redirectModules.amongTime
	if redirectAmongTime and not (redirectAmongTime == redirectModules_amongTime) then
		dict_system:set("redirectModules_amongTime",redirectAmongTime)
	end

elseif item == "JsJumpModules" then
	local JsJumpModulesIsOn = dict_system:get("jsOn")
	local JsJumpModules_verifyMaxFail = dict_system:get("JsJumpModules_verifyMaxFail")
	local JsJumpModules_amongTime = dict_system:get("JsJumpModules_amongTime")
	JsJumpModulesIsOn = onOff1(JsJumpModulesIsOn)
	--更新JsJumpModulesIsOn
	if state and not (state == JsJumpModulesIsOn) then
		if JsJumpModulesIsOn == "On" then
			dict_system:set("jsOn",0)
		elseif JsJumpModulesIsOn == "Off" then
			dict_system:set("jsOn",1)
		end
	end
	--更新_Conf.JsJumpModules.verifyMaxFail
	if jsVerifyMaxFail and not (jsVerifyMaxFail == JsJumpModules_verifyMaxFail) then
		dict_system:set("JsJumpModules_verifyMaxFail",jsVerifyMaxFail)
	end
	--更新_Conf.JsJumpModules.amongTime
	if jsAmongTime and not (jsAmongTime == JsJumpModules_amongTime) then
		dict_system:set("JsJumpModules_amongTime",jsAmongTime)
	end
	
elseif item == "cookieModules" then
	local cookieModulesIsOn = dict_system:get("cookieOn")
	local cookieModules_verifyMaxFail = dict_system:get("cookieModules_verifyMaxFail")
	local cookieModules_amongTime = dict_system:get("cookieModules_amongTime")
	cookieModulesIsOn = onOff1(cookieModulesIsOn)
	--更新cookieModulesIsOn
	if state and not (state == cookieModulesIsOn) then
		if cookieModulesIsOn == "On" then
			dict_system:set("cookieOn",0)
		elseif cookieModulesIsOn == "Off" then
			dict_system:set("cookieOn",1)
		end
	end
	--更新_Conf.cookieModules.verifyMaxFail
	if cookieVerifyMaxFail and not (cookieVerifyMaxFail == cookieModules_verifyMaxFail) then
		dict_system:set("cookieModules_verifyMaxFail",cookieVerifyMaxFail)
	end
	--更新_Conf.cookieModules.amongTime
	if cookieAmongTime and not (cookieAmongTime == cookieModules_amongTime) then
		dict_system:set("cookieModules_amongTime",cookieAmongTime)
	end

elseif item == "blockTime" then
	--更新_Conf.blockTime
	local globalBlockTime = dict_system:get("blockTime")
	if blockTime and not (blockTime == globalBlockTime) then
		dict_system:set("blockTime",blockTime)
	end

elseif item == "whiteTime" then
	--更新_Conf.whiteTime
	local globalWhiteTime = dict_system:get("whiteTime")
	if whiteTime and not (whiteTime == globalWhiteTime) then
		dict_system:set("whiteTime",whiteTime)
	end

elseif item == "blockAction" and not (blockAction == '') then
	local blockActionRun = blockActionType()
	--更新blockAction
	if not (blockAction == "none") and not (blockAction == blockActionRun) then
		parseBlockAction1(blockAction)
		parseBlockAction2(blockActionRun,blockAction)
	end

--更新_Conf.urlAllowProtect
elseif item == "urlAllow" then
	local urlAllowProtect = dict_system:get("urlAllowProtect")
	if parseRule and not (parseRule == "") and not (parseRule == urlAllowProtect) then
		dict_system:set("urlAllowProtect",parseRule)
	end

--更新_Conf.limitUrlProtect
elseif item == "limitUrl" then
	local limitUrlProtect = dict_system:get("limitUrlProtect")
	if parseRule and not (parseRule == "") and not (parseRule == limitUrlProtect) then
		dict_system:set("limitUrlProtect",parseRule)
	end

--更新_Conf.redirectUrlProtect
elseif item == "redirectUrl" then
	local redirectUrlProtect = dict_system:get("redirectUrlProtect")
	if parseRule and not (parseRule == "") and not (parseRule == redirectUrlProtect) then
		dict_system:set("redirectUrlProtect",parseRule)
	end

--更新_Conf.JsJumpUrlProtect
elseif item == "JsJumpUrl" then
	local JsJumpUrlProtect = dict_system:get("JsJumpUrlProtect")
	if parseRule and not (parseRule == "") and not (parseRule == JsJumpUrlProtect) then
		dict_system:set("JsJumpUrlProtect",parseRule)
	end

--更新_Conf.cookieUrlProtect
elseif item == "cookieUrl" then
	local cookieUrlProtect = dict_system:get("cookieUrlProtect")
	if parseRule and not (parseRule == "") and not (parseRule == cookieUrlProtect) then
		dict_system:set("cookieUrlProtect",parseRule)
	end

--更新 oneKeyOpenVerification
elseif item == "oneKeyOpenVerification" then
	local oneKeyOpenVerificationIsOn = dict_system:get("oneKeyOpenVerificationOn")
	oneKeyOpenVerificationIsOn = onOff1(oneKeyOpenVerificationIsOn)
	if state and not (state == oneKeyOpenVerificationIsOn) then
		if oneKeyOpenVerificationIsOn == "On" then
			dict_system:set("oneKeyOpenVerificationOn",0)
		elseif oneKeyOpenVerificationIsOn == "Off" then
			dict_system:set("oneKeyOpenVerificationOn",1)
		end
                --更新oneKeyOpenVerification_whiteTime
                local oneKeyOpenVerification_whiteTime_sys = dict_system:get("oneKeyOpenVerification_whiteTime")
                if oneKeyOpenVerification_whiteTime and not (oneKeyOpenVerification_whiteTime == oneKeyOpenVerification_whiteTime_sys) then
                        dict_system:set("oneKeyOpenVerification_whiteTime",oneKeyOpenVerification_whiteTime)
                end 
	end

end


-- Static模式
else	
        --更新 oneKeyOpenVerification
	if item == "oneKeyOpenVerification" then
        	local oneKeyOpenVerificationIsOn = dict_system:get("oneKeyOpenVerificationOn")
        	oneKeyOpenVerificationIsOn = onOff1(oneKeyOpenVerificationIsOn)
        	if state and not (state == oneKeyOpenVerificationIsOn) then
        	        if oneKeyOpenVerificationIsOn == "On" then
        	                dict_system:set("oneKeyOpenVerificationOn",0)
        	        elseif oneKeyOpenVerificationIsOn == "Off" then
        	                dict_system:set("oneKeyOpenVerificationOn",1)
        	        end
       		end
		--更新oneKeyOpenVerification_whiteTime
        	local oneKeyOpenVerification_whiteTime_sys = dict_system:get("oneKeyOpenVerification_whiteTime")
        	if oneKeyOpenVerification_whiteTime and not (oneKeyOpenVerification_whiteTime == oneKeyOpenVerification_whiteTime_sys) then
                	dict_system:set("oneKeyOpenVerification_whiteTime",oneKeyOpenVerification_whiteTime)
        	end  
	end
	
end
