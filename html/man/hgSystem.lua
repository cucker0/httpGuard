-- updateSystemPage

if string.lower(_Conf.hgModules.manType) == "static" then
local hh = "<br>"
local kg1 = "&nbsp;&nbsp;"
local hgOn = _Conf.hgModulesIsOn
local hgModules_manType = _Conf.hgModules.manType
local debugOn = _Conf.debugIsOn
local limitReqModulesIsOn = _Conf.limitReqModulesIsOn
local redirectModulesIsOn = _Conf.dict_system:get("redirectOn")
local JsJumpModulesIsOn = _Conf.dict_system:get("jsOn")
local cookieModulesIsOn = _Conf.dict_system:get("cookieOn")
local blockTime = _Conf.blockTime
local whiteTime = _Conf.whiteTime
local captcha2clickOn = _Conf.captcha2clickOn
local byWhiteIpModulesIsOn = _Conf.byWhiteIpModulesIsOn
local byDenyIpModulesIsOn = _Conf.byDenyIpModulesIsOn
local black2byDenyIsOn = _Conf.black2byDenyIsOn
local urlAllowProtect = _Conf.urlAllowProtect
local get_urlDenyProtect = _Conf.urlDenyProtect		-- type is table
local limitUrlProtect = _Conf.limitUrlProtect
local redirectUrlProtect = _Conf.redirectUrlProtect
local JsJumpUrlProtect = _Conf.JsJumpUrlProtect
local cookieUrlProtect = _Conf.cookieUrlProtect
local get_postArgsDenyProtect = _Conf.postArgsDenyProtect		-- type is table
local get_rateLimitUrlProtect = _Conf.rateLimitUrlProtect		-- array table
local oneKeyOpenVerificationIsOn = _Conf.dict_system:get("oneKeyOpenVerificationOn")
local oneKeyOpenVerification_whiteTime = _Conf.dict_system:get("oneKeyOpenVerification_whiteTime")

--打印table
function sayTab(t)
	if type(t) == "table" then
		local tab = ''
		for  k,v in pairs(t) do
			tab = table.concat({ tab, k, "  ", v, "&#13;&#10;" })
		end
		return tab
	else
		return "Not a table"
	end
end

--打印数组table
function sayArrayTab(t)
	if type(t) then
		local tab = ''
		for k, v in pairs(t) do
			tab = table.concat({ tab, k, "  ", v[1], "  小频率MaxReq:", v[2], "  大频率MaxReq:", v[3], "&#13;&#10;" })
		end
		return tab
	else
		return "Not a table"
	end
end

--解析开关
function onOff1(s)
	if s == 1 then
		return "true"
	elseif s == 0 then
		return "false"
	end
end

--获取正运行的 blockAction 值
function blockActionType()
	if _Conf.captchaAction then
		return "captcha验证"
	elseif _Conf.clickAction then
		if _Conf.hiddenClick then
			return "click隐式验证"
		else
			return "click显式验证"
		end
	elseif _Conf.forbiddenAction then
		return "forbidden拒绝"
	elseif _Conf.iptablesAction then
		return "iptables"
	end
end

--获取perUrlRateLimit URL列表信息
function perUrlRateLimitURLProtect(filepath)
	local ProtectUrl = ''
	local rfile = assert(io.open(filepath,'r'))
	for line in rfile:lines() do
		--忽略 只含空格的行、--开头的行、空行
		if not (string.match(line,"^ *$")) and not (string.match(line,"^([%s]*%-%-)")) and not (line == '') then
			for v1, v2 in string.gmatch(line,"(.*)#maxReqs=([0-9]+)") do
				--list = list.."|"..v1
				if v2 == nil then
					v2 = _Conf.perUrlRateLimit.defaultMaxReqs
				end
				ProtectUrl = table.concat({ ProtectUrl, v1, "  频率MaxReq:", v2, "&#13;&#10;" })
			end
		end
	end
	rfile:close()
	return ProtectUrl
end


perUrlRateLimitURLProtect = perUrlRateLimitURLProtect(_Conf.perUrlRateLimit.urlProtect)

redirectModulesIsOn = onOff1(redirectModulesIsOn)
JsJumpModulesIsOn = onOff1(JsJumpModulesIsOn)
cookieModulesIsOn = onOff1(cookieModulesIsOn)
local blockAction = blockActionType()
urlDenyProtect = sayTab(get_urlDenyProtect)
postArgsDenyProtect = sayTab(get_postArgsDenyProtect)
rateLimitUrlProtect = sayArrayTab(get_rateLimitUrlProtect)
oneKeyOpenVerificationIsOn = onOff1(oneKeyOpenVerificationIsOn)


ngx.say('<!doctype html>')
ngx.say('<html>')
ngx.say('<head>')
ngx.say('<meta http-equiv="Content-Type" content="text/html; charset=utf-8" >')
ngx.say('<title>HttpGuard Update System</title>')

ngx.say('<link rel="stylesheet" type="text/css" href="/hg_src/hg.css" >')
ngx.say('<script src="/hg_src/jquery.js"></script>')
ngx.say('<script src="/hg_src/hg.js"></script>')

ngx.say('</head>')

ngx.say('<body>')
ngx.say('<div id="container">')
ngx.say('  <div id="header">')
ngx.say('	<div id=biaoTi>')
ngx.say('		<p class = string-1 >HttpGuard Management(Static) </p>')
ngx.say('	</div>')
ngx.say('  </div>')

ngx.say('  <div id="main">')

ngx.say('    <table class="tab" border="0" cellpadding="0" cellspacing="0">')
ngx.say('      <tbody>')
ngx.say('	<tr>')
ngx.say('		<td class="td1"><b>Item</b></td>')
ngx.say('		<td class="td2"><b>Option</b></td>')
ngx.say('	</tr>')
ngx.say('	<tr>')
ngx.say('		<td class="td1">HttpGuard: ', hgOn, kg1, "|", kg1, "HttpGuard manType: ", hgModules_manType, '</td>')
ngx.say('		<td class="td2">')
--ngx.say('			<form  action="/update_system" method="POST" target="hiddenIframe" >')
--ngx.say('				<input name="item" value="hgModules" type="hidden">')
--ngx.say('				<label><input name="state" type="radio" value="1">True</label>')
--ngx.say('				<label><input name="state" type="radio" value="0">False</label>')
--ngx.say('				<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
--ngx.say('			</form>')
ngx.say('		</td>')
ngx.say('	</tr>')

ngx.say('       <tr>')
ngx.say('               <td class="td1">一键开启验证: ', oneKeyOpenVerificationIsOn, '</td>')
ngx.say('               <td class="td2">')
ngx.say('                       <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('                               <input name="item" value="oneKeyOpenVerification" type="hidden">')
ngx.say('                               <label><input name="state" type="radio" value="1">True</label>')
ngx.say('                               <label><input name="state" type="radio" value="0">False</label>&nbsp;&nbsp;oneKeyOpenVerification_whiteTime: ')
ngx.say('               		<input type="text" size="6" name="oneKeyOpenVerification_whiteTime" onKeyUp="num(oneKeyOpenVerification_whiteTime)" onKeyDown="num(oneKeyOpenVerification_whiteTime)"  ')
ngx.say('                 		  value="', oneKeyOpenVerification_whiteTime, '"')
ngx.say('                 		  onfocus=', "'", 'if(value=="', oneKeyOpenVerification_whiteTime, '"){value=""}', "'")
ngx.say('                 		  onblur=', "'", 'if(value==""){value="', oneKeyOpenVerification_whiteTime, '"}', "'", ' >s')
ngx.say('               		<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('                       </form>')
ngx.say('               </td>')
ngx.say('       </tr>')

ngx.say('	<tr>')
ngx.say('		<td class="td1">debug: ', debugOn, '</td>')
ngx.say('		<td class="td2">')
ngx.say('			<form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('				<input name="item" value="debug" type="hidden">')
ngx.say('				<label><input name="state" type="radio" value="1">True</label>')
ngx.say('				<label><input name="state" type="radio" value="0">False</label>')
ngx.say('				<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('			</form>')
ngx.say('		</td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('		<td class="td1">byWhiteIpModule: ', byWhiteIpModulesIsOn, '</td>')
ngx.say('		<td class="td2">')
ngx.say('			<form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('				<input name="item" value="byWhiteIpModules" type="hidden">')
ngx.say('				<label><input name="state" type="radio" value="1">True</label>')
ngx.say('				<label><input name="state" type="radio" value="0">False</label>')
ngx.say('				<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('			</form>')
ngx.say('		</td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('		<td class="td1">byDenyIpModule: ', byDenyIpModulesIsOn, '</td>')
ngx.say('		<td class="td2">')
ngx.say('			<form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('				<input name="item" value="byDenyIpModules" type="hidden">')
ngx.say('				<label><input name="state" type="radio" value="1">True</label>')
ngx.say('				<label><input name="state" type="radio" value="0">False</label>')
ngx.say('				<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('			</form>')
ngx.say('		</td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td1">black2byDeny: ', black2byDenyIsOn, '</td>')
ngx.say('	  <td class="td2">')
ngx.say('	    <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('		<input name="item" value="black2byDeny" type="hidden">')
ngx.say('		<label><input name="state" type="radio" value="1">True</label>')
ngx.say('		<label><input name="state" type="radio" value="0">False</label>&nbsp;&nbsp;inBlackMax: ')
ngx.say('		<input type="text" size="6" name="inBlackMax" onKeyUp="num(inBlackMax)" onKeyDown="num(inBlackMax)" ')
ngx.say('		  value="', _Conf.byDenyIpModules.inBlackMax, '"')
ngx.say('		  onfocus=', "'", 'if(value=="',  _Conf.byDenyIpModules.inBlackMax, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', _Conf.byDenyIpModules.inBlackMax, '"}', "'", ' >次 &nbsp;&nbsp;amongTime:')
ngx.say('		<input type="text" size="6" name="b2byDenyAmongTime" onKeyUp="num(b2byDenyAmongTime)" onKeyDown="num(b2byDenyAmongTime)" ')
ngx.say('		  value="', _Conf.byDenyIpModules.amongTime, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', _Conf.byDenyIpModules.amongTime, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', _Conf.byDenyIpModules.amongTime, '"}', "'", ' >s &nbsp;&nbsp;inByDenyBlockTime:')
ngx.say('		<input type="text" size="6" name="inByDenyBlockTime" onKeyUp="num(inByDenyBlockTime)" onKeyDown="num(inByDenyBlockTime)" ')
ngx.say('		  value="', _Conf.byDenyIpModules.blockTime, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', _Conf.byDenyIpModules.blockTime, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', _Conf.byDenyIpModules.blockTime, '"}', "'", ' >s')
ngx.say('		<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('	    </form>')
ngx.say('	  </td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td1">captcha2click: ', captcha2clickOn, '</td>')
ngx.say('	  <td class="td2">')
ngx.say('	    <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('		<input name="item" value="captcha2click" type="hidden">')
ngx.say('		<label><input name="state" type="radio" value="1">True</label>')
ngx.say('		<label><input name="state" type="radio" value="0">False</label> &nbsp;&nbsp;verifyMaxFail:')
ngx.say('		<input type="text" size="6" name="c2cVerifyMaxFail" onKeyUp="num(c2cVerifyMaxFail)" onKeyDown="num(c2cVerifyMaxFail)" ')
ngx.say('		  value="', _Conf.captcha2click.verifyMaxFail, '"')
ngx.say('		  onfocus=', "'", 'if(value=="',  _Conf.captcha2click.verifyMaxFail, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', _Conf.captcha2click.verifyMaxFail, '"}', "'", ' >次 &nbsp;&nbsp;amongTime:')
ngx.say('		<input type="text" size="6" name="c2cAmongTime" onKeyUp="num(c2cAmongTime)" onKeyDown="num(c2cAmongTime)" ')
ngx.say('		  value="', _Conf.captcha2click.amongTime, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', _Conf.captcha2click.amongTime,  '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', _Conf.captcha2click.amongTime, '"}', "'", ' >s')
ngx.say('		<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('	    </form>')
ngx.say('	  </td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td1">limitReqModule(限制请求速率): ', limitReqModulesIsOn, '</td>')
ngx.say('	  <td class="td2">')
ngx.say('	    <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('		<input name="item" value="limitReqModules" type="hidden">')
ngx.say('		<label><input name="state" type="radio" value="1">True</label>')
ngx.say('		<label><input name="state" type="radio" value="0">False</label> &nbsp;&nbsp;maxRequest:&nbsp;')
ngx.say('		<input type="text" size="6" name="limitReq" onKeyUp="num(limitReq)" onKeyDown="num(limitReq)" ')
ngx.say('		  value="', _Conf.limitReqModules.maxReqs, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', _Conf.limitReqModules.maxReqs, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', _Conf.limitReqModules.maxReqs, '"}', "'", ' >次 &nbsp;&nbsp;amongTime:')
ngx.say('		<input type="text" size="6" name="limitAmongTime" onKeyUp="num(limitAmongTime)" onKeyDown="num(limitAmongTime)" ')
ngx.say('		  value="', _Conf.limitReqModules.amongTime, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', _Conf.limitReqModules.amongTime, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', _Conf.limitReqModules.amongTime, '"}', "'", ' >s')
ngx.say('		<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('	    </form>')
ngx.say('	  </td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td1">redirectModule(302跳转): ', redirectModulesIsOn, '</td>')
ngx.say('	  <td class="td2">')
ngx.say('	    <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('		<input name="item" value="redirectModules" type="hidden">')
ngx.say('		<label><input name="state" type="radio" value="1">True</label>')
ngx.say('		<label><input name="state" type="radio" value="0">False</label> &nbsp;&nbsp;verifyMaxFail:')
ngx.say('		<input type="text" size="6" name="redirectVerifyMaxFail" onKeyUp="num(redirectVerifyMaxFail)" onKeyDown="num(redirectVerifyMaxFail)" ')
ngx.say('		  value="', _Conf.redirectModules.verifyMaxFail, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', _Conf.redirectModules.verifyMaxFail, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', _Conf.redirectModules.verifyMaxFail, '"}', "'", ' >次 &nbsp;&nbsp;amongTime:')
ngx.say('		<input type="text" size="6" name="redirectAmongTime" onKeyUp="num(redirectAmongTime)" onKeyDown="num(redirectAmongTime)" ')
ngx.say('		  value="', _Conf.redirectModules.amongTime, '"') 
ngx.say('		  onfocus=', "'", 'if(value=="', _Conf.redirectModules.amongTime, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', _Conf.redirectModules.amongTime, '"}', "'", ' >s')
ngx.say('		<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('	    </form>')
ngx.say('	  </td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td1">JsJumpModule(JS跳转): ', JsJumpModulesIsOn, '</td>')
ngx.say('	  <td class="td2">')
ngx.say('	    <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('		<input name="item" value="JsJumpModules" type="hidden">')
ngx.say('		<label><input name="state" type="radio" value="1">True</label>')
ngx.say('		<label><input name="state" type="radio" value="0">False</label> &nbsp;&nbsp;verifyMaxFail:')
ngx.say('		<input type="text" size="6" name="jsVerifyMaxFail" onKeyUp="num(jsVerifyMaxFail)" onKeyDown="num(jsVerifyMaxFail)" ')
ngx.say('		  value="', _Conf.JsJumpModules.verifyMaxFail, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', _Conf.JsJumpModules.verifyMaxFail, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', _Conf.JsJumpModules.verifyMaxFail, '"}', "'", ' >次 &nbsp;&nbsp;amongTime:')
ngx.say('		<input type="text" size="6" name="jsAmongTime" onKeyUp="num(jsAmongTime)" onKeyDown="num(jsAmongTime)" ')
ngx.say('		  value="', _Conf.JsJumpModules.amongTime, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', _Conf.JsJumpModules.amongTime, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', _Conf.JsJumpModules.amongTime, '"}', "'", ' >s')
ngx.say('		<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('	    </form>')
ngx.say('	  </td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td1">cookieModule(Cookie验证): ', cookieModulesIsOn, '</td>')
ngx.say('	  <td class="td2">')
ngx.say('	    <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('		<input name="item" value="cookieModules" type="hidden">')
ngx.say('		<label><input name="state" type="radio" value="1">True</label>')
ngx.say('		<label><input name="state" type="radio" value="0">False</label> &nbsp;&nbsp;verifyMaxFail:')
ngx.say('		<input type="text" size="6" name="cookieVerifyMaxFail" onKeyUp="num(cookieVerifyMaxFail)" onKeyDown="num(cookieVerifyMaxFail)" ')
ngx.say('		  value="', _Conf.cookieModules.verifyMaxFail, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', _Conf.cookieModules.verifyMaxFail, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', _Conf.cookieModules.verifyMaxFail, '"}', "'", ' >次 &nbsp;&nbsp;amongTime:')
ngx.say('		<input type="text" size="6" name="cookieAmongTime" onKeyUp="num(cookieAmongTime)" onKeyDown="num(cookieAmongTime)" ')
ngx.say('		  value="', _Conf.cookieModules.amongTime, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', _Conf.cookieModules.amongTime, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', _Conf.cookieModules.amongTime, '"}', "'", ' >s')
ngx.say('		<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('	    </form>')
ngx.say('	  </td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td1">blockTime(黑名单时间): ', blockTime, '</td>')
ngx.say('	  <td class="td2">')
ngx.say('	    <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('		<input name="item" value="blockTime" type="hidden">')
ngx.say('		<input type="text" size="6" name="blockTime" onKeyUp="num(blockTime)" onKeyDown="num(blockTime)" ')
ngx.say('		  value="', blockTime, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', blockTime, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', blockTime, '"}', "'", ' >s')
ngx.say('		<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('	    </form>')
ngx.say('	  </td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td1">whiteTime(白名单时间): ', whiteTime, '</td>')
ngx.say('	  <td class="td2">')
ngx.say('	    <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('		<input name="item" value="whiteTime" type="hidden">')
ngx.say('		<input type="text" size="6" name="whiteTime" onKeyUp="num(whiteTime)" onKeyDown="num(whiteTime)"  ')
ngx.say('		  value="', whiteTime, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', whiteTime, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', whiteTime, '"}', "'", ' >s')
ngx.say('		<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('	    </form>')
ngx.say('	  </td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td1">blockAction(限制动作): ', blockAction, '</td>')
ngx.say('	  <td class="td2">')
ngx.say('	    <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('		<input name="item" value="blockAction" type="hidden">')
ngx.say('		<select name="block">')
ngx.say('			<option value="none">None</option>')
ngx.say('			<option value="captchaAction">captcha验证</option>')
ngx.say('			<option value="hiddenClickAction">click隐式验证</option>')
ngx.say('			<option value="displayClickAction">click显式验证</option>')
ngx.say('			<option value="forbiddenAction">forbidden拒绝</option>')
ngx.say('			<option value="iptablesAction">iptables</option>')
ngx.say('		</select>')
ngx.say('		<input class="btn2" type="submit" value="确定" onclick="window.location.reload();" >')
ngx.say('	    </form>')
ngx.say('	  </td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td3">类型:')
ngx.say('		<select id="select1">')
ngx.say('			<option value="0" selected="selected">None</option>')
ngx.say('			<option value="1">urlAllow正则</option>')
ngx.say('			<option value="12">urlDeny正则</option>')
ngx.say('			<option value="2">limitUrl正则</option>')
ngx.say('			<option value="3">302redirectUrl正则</option>')
ngx.say('			<option value="4">JsJumpUrl正则</option>')
ngx.say('			<option value="5">cookieUrl正则</option>')
ngx.say('			<option value="52">postArgsDeny正则</option>')
ngx.say('			<option value="6">rateLimitDeny正则</option>')
ngx.say('			<option value="7">perUrlRateLimit正则</option>')
ngx.say('		</select>') 
ngx.say('	  </td>')
ngx.say('	  <td class="td4">')
ngx.say('	    <div id="d0" >')
ngx.say('		<form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('			<input name="item" value="None" type="hidden">')
ngx.say('			<textarea name="parseRule" class="text1" style="color:#666;">None</textarea>')
ngx.say('			<input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()">')
ngx.say('		</form>')
ngx.say('	    </div>')
ngx.say('	    <div id="d1" style="display:none">')
ngx.say('		<form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('			<input name="item" value="urlAllow" type="hidden">')
ngx.say('			<textarea name="parseRule" class="text1">', urlAllowProtect, '</textarea>')
ngx.say('			<input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()">')
ngx.say('		</form>')
ngx.say('	    </div>')
ngx.say('	    <div id="d12" style="display:none">')
ngx.say('		<form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('			<input name="item" value="urlDeny" type="hidden">')
ngx.say('			<textarea name="parseRule" class="text1" disabled="disabled">', urlDenyProtect, '</textarea>')
ngx.say('			<input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()" disabled="disabled">')
ngx.say('		</form>')
ngx.say('	    </div>')
ngx.say('	    <div id="d2" style="display:none">')
ngx.say('		<form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('			<input name="item" value="limitUrl" type="hidden">')
ngx.say('			<textarea name="parseRule" class="text1">', limitUrlProtect, '</textarea>')
ngx.say('			<input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()">')
ngx.say('		</form>')
ngx.say('	    </div>')
ngx.say('	    <div id="d3" style="display:none">')
ngx.say('		<form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('			<input name="item" value="redirectUrl" type="hidden">')
ngx.say('			<textarea name="parseRule" class="text1">', redirectUrlProtect, '</textarea>')
ngx.say('			<input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()">')
ngx.say('		</form>')
ngx.say('	    </div>')
ngx.say('	    <div id="d4" style="display:none">')
ngx.say('		<form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('			<input name="item" value="JsJumpUrl" type="hidden">')
ngx.say('			<textarea name="parseRule" class="text1">', JsJumpUrlProtect, '</textarea>')
ngx.say('			<input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()">')
ngx.say('		</form>')
ngx.say('	    </div>')
ngx.say('	    <div id="d5" style="display:none">')
ngx.say('		<form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('			<input name="item" value="cookieUrl" type="hidden">')
ngx.say('			<textarea name="parseRule" class="text1">', cookieUrlProtect, '</textarea>')
ngx.say('			<input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()">')
ngx.say('		</form>')
ngx.say('	    </div>')											
ngx.say('	    <div id="d52" style="display:none">')
ngx.say('		<form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('			<input name="item" value="postArgsDeny" type="hidden">')
ngx.say('			<textarea name="parseRule" class="text1" disabled="disabled">', postArgsDenyProtect, '</textarea>')
ngx.say('			<input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()" disabled="disabled">')
ngx.say('		</form>')
ngx.say('	    </div>')

ngx.say('	    <div id="d6" style="display:none">')
ngx.say('		<form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('			<input name="item" value="rateLimit" type="hidden">')
ngx.say('			<textarea name="parseRule" class="text1" disabled="disabled">', rateLimitUrlProtect, '</textarea>')
ngx.say('			<input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()" disabled="disabled">')
ngx.say('		</form>')
ngx.say('	    </div>')

ngx.say('           <div id="d7" style="display:none">')
ngx.say('               <form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('                       <input name="item" value="rateLimit" type="hidden">')
ngx.say('                       <textarea name="parseRule" class="text1" disabled="disabled">', perUrlRateLimitURLProtect, '</textarea>')
ngx.say('                       <input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()" disabled="disabled">')
ngx.say('               </form>')
ngx.say('           </div>')


ngx.say('	  </td>')
ngx.say('	</tr>')
ngx.say('      </tbody>')

ngx.say('    </table>')
ngx.say('<iframe style="display:none" name="hiddenIframe" id="hiddenIframe" ></iframe>')
ngx.say('  </div>')

ngx.say('</div>')

ngx.say('<div id="Ta"> <a href="/hgman">updateList</a>&nbsp;&nbsp;<a href="/hgsystem">updateSystem</a>&nbsp;&nbsp;<a href="#" id="user_logout">Logout</a> &nbsp;&nbsp;&nbsp;Version: ', _Conf.hg_version, '</div>')
ngx.say('<div id="goToTop"><span>^Top</span></div>')
ngx.say('</body>')
ngx.say('</html>')

--Dynamic
elseif string.lower(_Conf.hgModules.manType) == "dynamic" then
local dict = _Conf.dict_system
local hh = "<br>"
local kg1 = "&nbsp;&nbsp;"
local hgOn = _Conf.hgModulesIsOn
local hgModules_manType = _Conf.hgModules.manType
local debugOn = dict:get("debug_state")
local limitReqModulesIsOn = dict:get("limitReqModules_state")
local redirectModulesIsOn = dict:get("redirectOn")
local JsJumpModulesIsOn = dict:get("jsOn")
local cookieModulesIsOn = dict:get("cookieOn")
local blockTime = dict:get("blockTime")
local whiteTime = dict:get("whiteTime")
local captcha2clickOn = dict:get("captcha2click_state")
local byWhiteIpModulesIsOn = dict:get("byWhiteIpModules_state")
local byDenyIpModulesIsOn = dict:get("byDenyIpModules_state")
local black2byDenyIsOn = dict:get("byDenyIpModules_black2byDenyState")
local urlAllowProtect = dict:get("urlAllowProtect")
local get_urlDenyProtect = _Conf.urlDenyProtect		-- type is table
local limitUrlProtect = dict:get("limitUrlProtect")
local redirectUrlProtect = dict:get("redirectUrlProtect")
local JsJumpUrlProtect = dict:get("JsJumpUrlProtect")
local cookieUrlProtect = dict:get("cookieUrlProtect")
local get_postArgsDenyProtect = _Conf.postArgsDenyProtect		-- type is table
local black2byDeny_inBlackMax = dict:get("byDenyIpModules_inBlackMax")
local black2byDeny_amongTime = dict:get("byDenyIpModules_amongTime")
local black2byDeny_blockTime = dict:get("byDenyIpModules_blockTime")
local captcha2click_verifyMaxFail = dict:get("captcha2click_verifyMaxFail")
local captcha2click_amongTime = dict:get("captcha2click_amongTime")
local limitReqModules_maxReqs = dict:get("limitReqModules_maxReqs")
local limitReqModules_amongTime = dict:get("limitReqModules_amongTime")
local redirectModules_verifyMaxFail = dict:get("redirectModules_verifyMaxFail")
local redirectModules_amongTime = dict:get("redirectModules_amongTime")
local JsJumpModules_verifyMaxFail = dict:get("JsJumpModules_verifyMaxFail")
local JsJumpModules_amongTime = dict:get("JsJumpModules_amongTime")
local cookieModules_verifyMaxFail = dict:get("cookieModules_verifyMaxFail")
local cookieModules_amongTime = dict:get("cookieModules_amongTime")
local get_rateLimitUrlProtect = _Conf.rateLimitUrlProtect		-- array table
local oneKeyOpenVerificationIsOn = _Conf.dict_system:get("oneKeyOpenVerificationOn")
local oneKeyOpenVerification_whiteTime = _Conf.dict_system:get("oneKeyOpenVerification_whiteTime")


--打印table
function sayTab(t)
	if type(t) == "table" then
		local tab = ''
		for  k,v in pairs(t) do
			tab = table.concat({ tab, k, "  ", v, "&#13;&#10;" })
		end
		return tab
	else
		return "Not a table"
	end
end

--打印数组table
function sayArrayTab(t)
	if type(t) then
		local tab = ''
		for k, v in pairs(t) do
			tab = table.concat({ tab, k, "  ", v[1], "  小频率MaxReq:", v[2], "&#13;&#10;" })
		end
		return tab
	else
		return "Not a table"
	end
end

--解析开关
function onOff1(s)
	if s == 1 then
		return "true"
	elseif s == 0 then
		return "false"
	end
end

--获取正运行的 blockAction 值
function blockActionType()
	local captchaAction = _Conf.dict_system:get("captchaAction")
	local clickAction = _Conf.dict_system:get("clickAction")
	local forbiddenAction = _Conf.dict_system:get("forbiddenAction")
	local iptablesAction = _Conf.dict_system:get("iptablesAction")
	local hiddenClick = _Conf.dict_system:get("hiddenClick")
	if captchaAction then
		return "captcha验证"
	elseif clickAction then
		if hiddenClick then
			return "click隐式验证"
		else
			return "click显式验证"
		end
	elseif forbiddenAction then
		return "forbidden拒绝"
	elseif iptablesAction then
		return "iptables"
	end
end

redirectModulesIsOn = onOff1(redirectModulesIsOn)
JsJumpModulesIsOn = onOff1(JsJumpModulesIsOn)
cookieModulesIsOn = onOff1(cookieModulesIsOn)
local blockAction = blockActionType()
urlDenyProtect = sayTab(get_urlDenyProtect)
postArgsDenyProtect = sayTab(get_postArgsDenyProtect)
rateLimitUrlProtect = sayArrayTab(get_rateLimitUrlProtect)
oneKeyOpenVerificationIsOn = onOff1(oneKeyOpenVerificationIsOn)


ngx.say('<!doctype html>')
ngx.say('<html>')
ngx.say('<head>')
ngx.say('<meta http-equiv="Content-Type" content="text/html; charset=utf-8" >')
ngx.say('<title>HttpGuard Update System</title>')

ngx.say('<link rel="stylesheet" type="text/css" href="/hg_src/hg.css" >')
ngx.say('<script src="/hg_src/jquery.js"></script>')
ngx.say('<script src="/hg_src/hg.js"></script>')

ngx.say('</head>')

ngx.say('<body>')
ngx.say('<div id="container">')
ngx.say('  <div id="header">')
ngx.say('	<div id=biaoTi>')
ngx.say('		<p class = string-1 >HttpGuard Management(Dynamic) </p>')
ngx.say('	</div>')
ngx.say('  </div>')

ngx.say('  <div id="main">')

ngx.say('    <table class="tab" border="0" cellpadding="0" cellspacing="0">')
ngx.say('      <tbody>')
ngx.say('	<tr>')
ngx.say('		<td class="td1"><b>Item</b></td>')
ngx.say('		<td class="td2"><b>Option</b></td>')
ngx.say('	</tr>')
ngx.say('	<tr>')
ngx.say('		<td class="td1">HttpGuard: ', hgOn, kg1, "|", kg1, "HttpGuard manType: ", hgModules_manType, '</td>')
ngx.say('		<td class="td2">')
--ngx.say('			<form  action="/update_system" method="POST" target="hiddenIframe" >')
--ngx.say('				<input name="item" value="hgModules" type="hidden">')
--ngx.say('				<label><input name="state" type="radio" value="1">True</label>')
--ngx.say('				<label><input name="state" type="radio" value="0">False</label>')
--ngx.say('				<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
--ngx.say('			</form>')
ngx.say('		</td>')
ngx.say('	</tr>')

ngx.say('       <tr>')
ngx.say('               <td class="td1">一键开启验证: ', oneKeyOpenVerificationIsOn, '</td>')
ngx.say('               <td class="td2">')
ngx.say('                       <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('                               <input name="item" value="oneKeyOpenVerification" type="hidden">')
ngx.say('                               <label><input name="state" type="radio" value="1">True</label>')
ngx.say('                               <label><input name="state" type="radio" value="0">False</label>&nbsp;&nbsp;oneKeyOpenVerification_whiteTime: ')
ngx.say('                               <input type="text" size="6" name="oneKeyOpenVerification_whiteTime" onKeyUp="num(oneKeyOpenVerification_whiteTime)" onKeyDown="num(oneKeyOpenVerification_whiteTime)"  ')
ngx.say('                                 value="', oneKeyOpenVerification_whiteTime, '"')
ngx.say('                                 onfocus=', "'", 'if(value=="', oneKeyOpenVerification_whiteTime, '"){value=""}', "'")
ngx.say('                                 onblur=', "'", 'if(value==""){value="', oneKeyOpenVerification_whiteTime, '"}', "'", ' >s')
ngx.say('                               <input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('                       </form>')
ngx.say('               </td>')
ngx.say('       </tr>')

ngx.say('	<tr>')
ngx.say('		<td class="td1">debug: ', debugOn, '</td>')
ngx.say('		<td class="td2">')
ngx.say('			<form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('				<input name="item" value="debug" type="hidden">')
ngx.say('				<label><input name="state" type="radio" value="1">True</label>')
ngx.say('				<label><input name="state" type="radio" value="0">False</label>')
ngx.say('				<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('			</form>')
ngx.say('		</td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('		<td class="td1">byWhiteIpModule: ', byWhiteIpModulesIsOn, '</td>')
ngx.say('		<td class="td2">')
ngx.say('			<form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('				<input name="item" value="byWhiteIpModules" type="hidden">')
ngx.say('				<label><input name="state" type="radio" value="1">True</label>')
ngx.say('				<label><input name="state" type="radio" value="0">False</label>')
ngx.say('				<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('			</form>')
ngx.say('		</td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('		<td class="td1">byDenyIpModule: ', byDenyIpModulesIsOn, '</td>')
ngx.say('		<td class="td2">')
ngx.say('			<form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('				<input name="item" value="byDenyIpModules" type="hidden">')
ngx.say('				<label><input name="state" type="radio" value="1">True</label>')
ngx.say('				<label><input name="state" type="radio" value="0">False</label>')
ngx.say('				<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('			</form>')
ngx.say('		</td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td1">black2byDeny: ', black2byDenyIsOn, '</td>')
ngx.say('	  <td class="td2">')
ngx.say('	    <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('		<input name="item" value="black2byDeny" type="hidden">')
ngx.say('		<label><input name="state" type="radio" value="1">True</label>')
ngx.say('		<label><input name="state" type="radio" value="0">False</label>&nbsp;&nbsp;inBlackMax: ')
ngx.say('		<input type="text" size="6" name="inBlackMax" onKeyUp="num(inBlackMax)" onKeyDown="num(inBlackMax)" ')
ngx.say('		  value="', black2byDeny_inBlackMax, '"')
ngx.say('		  onfocus=', "'", 'if(value=="',  black2byDeny_inBlackMax, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', black2byDeny_inBlackMax, '"}', "'", ' >次 &nbsp;&nbsp;amongTime:')
ngx.say('		<input type="text" size="6" name="b2byDenyAmongTime" onKeyUp="num(b2byDenyAmongTime)" onKeyDown="num(b2byDenyAmongTime)" ')
ngx.say('		  value="', black2byDeny_amongTime, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', black2byDeny_amongTime, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', black2byDeny_amongTime, '"}', "'", ' >s &nbsp;&nbsp;inByDenyBlockTime:')
ngx.say('		<input type="text" size="6" name="inByDenyBlockTime" onKeyUp="num(inByDenyBlockTime)" onKeyDown="num(inByDenyBlockTime)" ')
ngx.say('		  value="', black2byDeny_blockTime, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', black2byDeny_blockTime, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', black2byDeny_blockTime, '"}', "'", ' >s')
ngx.say('		<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('	    </form>')
ngx.say('	  </td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td1">captcha2click: ', captcha2clickOn, '</td>')
ngx.say('	  <td class="td2">')
ngx.say('	    <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('		<input name="item" value="captcha2click" type="hidden">')
ngx.say('		<label><input name="state" type="radio" value="1">True</label>')
ngx.say('		<label><input name="state" type="radio" value="0">False</label> &nbsp;&nbsp;verifyMaxFail:')
ngx.say('		<input type="text" size="6" name="c2cVerifyMaxFail" onKeyUp="num(c2cVerifyMaxFail)" onKeyDown="num(c2cVerifyMaxFail)" ')
ngx.say('		  value="', captcha2click_verifyMaxFail, '"')
ngx.say('		  onfocus=', "'", 'if(value=="',  captcha2click_verifyMaxFail, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', captcha2click_verifyMaxFail, '"}', "'", ' >次 &nbsp;&nbsp;amongTime:')
ngx.say('		<input type="text" size="6" name="c2cAmongTime" onKeyUp="num(c2cAmongTime)" onKeyDown="num(c2cAmongTime)" ')
ngx.say('		  value="', captcha2click_amongTime, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', captcha2click_amongTime,  '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', captcha2click_amongTime, '"}', "'", ' >s')
ngx.say('		<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('	    </form>')
ngx.say('	  </td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td1">limitReqModule(限制请求速率): ', limitReqModulesIsOn, '</td>')
ngx.say('	  <td class="td2">')
ngx.say('	    <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('		<input name="item" value="limitReqModules" type="hidden">')
ngx.say('		<label><input name="state" type="radio" value="1">True</label>')
ngx.say('		<label><input name="state" type="radio" value="0">False</label> &nbsp;&nbsp;maxRequest:&nbsp;')
ngx.say('		<input type="text" size="6" name="limitReq" onKeyUp="num(limitReq)" onKeyDown="num(limitReq)" ')
ngx.say('		  value="', limitReqModules_maxReqs, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', limitReqModules_maxReqs, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', limitReqModules_maxReqs, '"}', "'", ' >次 &nbsp;&nbsp;amongTime:')
ngx.say('		<input type="text" size="6" name="limitAmongTime" onKeyUp="num(limitAmongTime)" onKeyDown="num(limitAmongTime)" ')
ngx.say('		  value="', limitReqModules_amongTime, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', limitReqModules_amongTime, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', limitReqModules_amongTime, '"}', "'", ' >s')
ngx.say('		<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('	    </form>')
ngx.say('	  </td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td1">redirectModule(302跳转): ', redirectModulesIsOn, '</td>')
ngx.say('	  <td class="td2">')
ngx.say('	    <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('		<input name="item" value="redirectModules" type="hidden">')
ngx.say('		<label><input name="state" type="radio" value="1">True</label>')
ngx.say('		<label><input name="state" type="radio" value="0">False</label> &nbsp;&nbsp;verifyMaxFail:')
ngx.say('		<input type="text" size="6" name="redirectVerifyMaxFail" onKeyUp="num(redirectVerifyMaxFail)" onKeyDown="num(redirectVerifyMaxFail)" ')
ngx.say('		  value="', redirectModules_verifyMaxFail, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', redirectModules_verifyMaxFail, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', redirectModules_verifyMaxFail, '"}', "'", ' >次 &nbsp;&nbsp;amongTime:')
ngx.say('		<input type="text" size="6" name="redirectAmongTime" onKeyUp="num(redirectAmongTime)" onKeyDown="num(redirectAmongTime)" ')
ngx.say('		  value="', redirectModules_amongTime, '"') 
ngx.say('		  onfocus=', "'", 'if(value=="', redirectModules_amongTime, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', redirectModules_amongTime, '"}', "'", ' >s')
ngx.say('		<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('	    </form>')
ngx.say('	  </td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td1">JsJumpModule(JS跳转): ', JsJumpModulesIsOn, '</td>')
ngx.say('	  <td class="td2">')
ngx.say('	    <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('		<input name="item" value="JsJumpModules" type="hidden">')
ngx.say('		<label><input name="state" type="radio" value="1">True</label>')
ngx.say('		<label><input name="state" type="radio" value="0">False</label> &nbsp;&nbsp;verifyMaxFail:')
ngx.say('		<input type="text" size="6" name="jsVerifyMaxFail" onKeyUp="num(jsVerifyMaxFail)" onKeyDown="num(jsVerifyMaxFail)" ')
ngx.say('		  value="', JsJumpModules_verifyMaxFail, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', JsJumpModules_verifyMaxFail, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', JsJumpModules_verifyMaxFail, '"}', "'", ' >次 &nbsp;&nbsp;amongTime:')
ngx.say('		<input type="text" size="6" name="jsAmongTime" onKeyUp="num(jsAmongTime)" onKeyDown="num(jsAmongTime)" ')
ngx.say('		  value="', JsJumpModules_amongTime, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', JsJumpModules_amongTime, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', JsJumpModules_amongTime, '"}', "'", ' >s')
ngx.say('		<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('	    </form>')
ngx.say('	  </td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td1">cookieModule(Cookie验证): ', cookieModulesIsOn, '</td>')
ngx.say('	  <td class="td2">')
ngx.say('	    <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('		<input name="item" value="cookieModules" type="hidden">')
ngx.say('		<label><input name="state" type="radio" value="1">True</label>')
ngx.say('		<label><input name="state" type="radio" value="0">False</label> &nbsp;&nbsp;verifyMaxFail:')
ngx.say('		<input type="text" size="6" name="cookieVerifyMaxFail" onKeyUp="num(cookieVerifyMaxFail)" onKeyDown="num(cookieVerifyMaxFail)" ')
ngx.say('		  value="', cookieModules_verifyMaxFail, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', cookieModules_verifyMaxFail, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', cookieModules_verifyMaxFail, '"}', "'", ' >次 &nbsp;&nbsp;amongTime:')
ngx.say('		<input type="text" size="6" name="cookieAmongTime" onKeyUp="num(cookieAmongTime)" onKeyDown="num(cookieAmongTime)" ')
ngx.say('		  value="', cookieModules_amongTime, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', cookieModules_amongTime, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', cookieModules_amongTime, '"}', "'", ' >s')
ngx.say('		<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('	    </form>')
ngx.say('	  </td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td1">blockTime(黑名单时间): ', blockTime, '</td>')
ngx.say('	  <td class="td2">')
ngx.say('	    <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('		<input name="item" value="blockTime" type="hidden">')
ngx.say('		<input type="text" size="6" name="blockTime" onKeyUp="num(blockTime)" onKeyDown="num(blockTime)" ')
ngx.say('		  value="', blockTime, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', blockTime, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', blockTime, '"}', "'", ' >s')
ngx.say('		<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('	    </form>')
ngx.say('	  </td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td1">whiteTime(白名单时间): ', whiteTime, '</td>')
ngx.say('	  <td class="td2">')
ngx.say('	    <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('		<input name="item" value="whiteTime" type="hidden">')
ngx.say('		<input type="text" size="6" name="whiteTime" onKeyUp="num(whiteTime)" onKeyDown="num(whiteTime)"  ')
ngx.say('		  value="', whiteTime, '"')
ngx.say('		  onfocus=', "'", 'if(value=="', whiteTime, '"){value=""}', "'")
ngx.say('		  onblur=', "'", 'if(value==""){value="', whiteTime, '"}', "'", ' >s')
ngx.say('		<input class="btn2" type="submit" value="确定" onclick="window.location.reload()" >')
ngx.say('	    </form>')
ngx.say('	  </td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td1">blockAction(限制动作): ', blockAction, '</td>')
ngx.say('	  <td class="td2">')
ngx.say('	    <form  action="/update_system" method="POST" target="hiddenIframe" >')
ngx.say('		<input name="item" value="blockAction" type="hidden">')
ngx.say('		<select name="block">')
ngx.say('			<option value="none">None</option>')
ngx.say('			<option value="captchaAction">captcha验证</option>')
ngx.say('			<option value="hiddenClickAction">click隐式验证</option>')
ngx.say('			<option value="displayClickAction">click显式验证</option>')
ngx.say('			<option value="forbiddenAction">forbidden拒绝</option>')
ngx.say('			<option value="iptablesAction">iptables</option>')
ngx.say('		</select>')
ngx.say('		<input class="btn2" type="submit" value="确定" onclick="window.location.reload();" >')
ngx.say('	    </form>')
ngx.say('	  </td>')
ngx.say('	</tr>')

ngx.say('	<tr>')
ngx.say('	  <td class="td3">类型:')
ngx.say('		<select id="select1">')
ngx.say('			<option value="0" selected="selected">None</option>')
ngx.say('			<option value="1">urlAllow正则</option>')
ngx.say('			<option value="12">urlDeny正则</option>')
ngx.say('			<option value="2">limitUrl正则</option>')
ngx.say('			<option value="3">302redirectUrl正则</option>')
ngx.say('			<option value="4">JsJumpUrl正则</option>')
ngx.say('			<option value="5">cookieUrl正则</option>')
ngx.say('			<option value="52">postArgsDeny正则</option>')
ngx.say('			<option value="6">rateLimitDeny正则</option>')
ngx.say('			<option value="7">perUrlRateLimit正则</option>')
ngx.say('		</select>') 
ngx.say('	  </td>')
ngx.say('	  <td class="td4">')
ngx.say('	    <div id="d0" >')
ngx.say('		<form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('			<input name="item" value="None" type="hidden">')
ngx.say('			<textarea name="parseRule" class="text1" style="color:#666;">None</textarea>')
ngx.say('			<input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()">')
ngx.say('		</form>')
ngx.say('	    </div>')
ngx.say('	    <div id="d1" style="display:none">')
ngx.say('		<form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('			<input name="item" value="urlAllow" type="hidden">')
ngx.say('			<textarea name="parseRule" class="text1">', urlAllowProtect, '</textarea>')
ngx.say('			<input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()">')
ngx.say('		</form>')
ngx.say('	    </div>')
ngx.say('	    <div id="d12" style="display:none">')
ngx.say('		<form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('			<input name="item" value="urlDeny" type="hidden">')
ngx.say('			<textarea name="parseRule" class="text1" disabled="disabled">', urlDenyProtect, '</textarea>')
ngx.say('			<input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()" disabled="disabled">')
ngx.say('		</form>')
ngx.say('	    </div>')
ngx.say('	    <div id="d2" style="display:none">')
ngx.say('		<form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('			<input name="item" value="limitUrl" type="hidden">')
ngx.say('			<textarea name="parseRule" class="text1">', limitUrlProtect, '</textarea>')
ngx.say('			<input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()">')
ngx.say('		</form>')
ngx.say('	    </div>')
ngx.say('	    <div id="d3" style="display:none">')
ngx.say('		<form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('			<input name="item" value="redirectUrl" type="hidden">')
ngx.say('			<textarea name="parseRule" class="text1">', redirectUrlProtect, '</textarea>')
ngx.say('			<input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()">')
ngx.say('		</form>')
ngx.say('	    </div>')
ngx.say('	    <div id="d4" style="display:none">')
ngx.say('		<form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('			<input name="item" value="JsJumpUrl" type="hidden">')
ngx.say('			<textarea name="parseRule" class="text1">', JsJumpUrlProtect, '</textarea>')
ngx.say('			<input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()">')
ngx.say('		</form>')
ngx.say('	    </div>')
ngx.say('	    <div id="d5" style="display:none">')
ngx.say('		<form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('			<input name="item" value="cookieUrl" type="hidden">')
ngx.say('			<textarea name="parseRule" class="text1">', cookieUrlProtect, '</textarea>')
ngx.say('			<input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()">')
ngx.say('		</form>')
ngx.say('	    </div>')											
ngx.say('	    <div id="d52" style="display:none">')
ngx.say('		<form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('			<input name="item" value="postArgsDeny" type="hidden">')
ngx.say('			<textarea name="parseRule" class="text1" disabled="disabled">', postArgsDenyProtect, '</textarea>')
ngx.say('			<input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()" disabled="disabled">')
ngx.say('		</form>')
ngx.say('	    </div>')

ngx.say('	    <div id="d6" style="display:none">')
ngx.say('		<form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('			<input name="item" value="rateLimit" type="hidden">')
ngx.say('			<textarea name="parseRule" class="text1" disabled="disabled">', rateLimitUrlProtect, '</textarea>')
ngx.say('			<input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()" disabled="disabled">')
ngx.say('		</form>')
ngx.say('	    </div>')

ngx.say('	    <div id="d7" style="display:none">')
ngx.say('		<form action="/update_system" method="POST" target="hiddenIframe">')
ngx.say('			<input name="item" value="rateLimit" type="hidden">')
ngx.say('			<textarea name="parseRule" class="text1" disabled="disabled">', perUrlRateLimitURLProtect, '</textarea>')
ngx.say('			<input class="btn2" style="margin-top: 55px" type="submit" value="确定" onClick="window.location.reload()" disabled="disabled">')
ngx.say('		</form>')
ngx.say('	    </div>')


ngx.say('	  </td>')
ngx.say('	</tr>')
ngx.say('      </tbody>')

ngx.say('    </table>')
ngx.say('<iframe style="display:none" name="hiddenIframe" id="hiddenIframe" ></iframe>')
ngx.say('  </div>')

ngx.say('</div>')

ngx.say('<div id="Ta"> <a href="/hgman">updateList</a>&nbsp;&nbsp;<a href="/hgsystem">updateSystem</a>&nbsp;&nbsp;<a href="#" id="user_logout">Logout</a> &nbsp;&nbsp;&nbsp;Version: ', _Conf.hg_version, '</div>')
ngx.say('<div id="goToTop"><span>^Top</span></div>')
ngx.say('</body>')
ngx.say('</html>')

end


