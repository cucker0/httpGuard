local Guard = {}

--debug日志
function Guard:debug(data,ip,reqUri)
	if _Conf.debugIsOn then
		local date = os.date("%Y-%m-%d")
		local filename = _Conf.logPath.."/debug-"..date..".log"
		local file = io.open(filename,"a+")
		file:write(os.date('%Y-%m-%d %H:%M:%S').." [DEBUG] "..data.." IP "..ip.." GET "..reqUri.."\n")
		file:close()
	end
end

--攻击日志
function Guard:log(data)
	local date = os.date("%Y-%m-%d")
	local filename = _Conf.logPath.."/attack-"..date..".log"
	local file = io.open(filename,"a+")
	file:write(os.date('%Y-%m-%d %H:%M:%S').." [WARNING] "..data.."\n")
	file:close()
end

--获取真实ip
function Guard:getRealIp(remoteIp,headers)
    if _Conf.realIpFromHeaderIsOn then
        realIp = headers[_Conf.realIpFromHeader.header]
        if realIp then
            --self:debug(type(realIp).."[==========>] realIpFromHeader is on.return ip "..realIp,remoteIp,"")
            -- realIp 类型一般为 string
            if type(realIp) == "table" then
                realIp = realIp[1]
            end
            -- X-Forwarded-For:用户IP, 代理服务器1-IP, 代理服务器2-IP, 代理服务器3-IP, ……
            -- 获取用户IP
            local regex = [[\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}]]
            --local regex = "[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}"
            local m = ngx.re.match(realIp, regex, "ijo") or false

            if m then
                realIp = m[0]
            else
                -- get realIp fail, set default ip 0.0.0.7
                realIp = "0.0.0.7"
            end
            --self:debug(realIp.."[==========>] realIpFromHeader is on.return ip "..realIp,remoteIp,"")

            self:debug("[getRealIp] realIpFromHeader is on.return ip "..realIp,remoteIp,"")
            return realIp
        else
            return remoteIp
        end
    else
        return remoteIp
    end
end

--byWhite白名单模块
function Guard:ipInByWhiteList(ip)
	if _Conf.byWhiteIpModulesIsOn then --判断是否开启白名单模块
		-- self:debug("[ipInByWhiteList] byWhiteIpModules is on.",ip,"")
		if _Conf.dict_byWhiteIp:get(ip) then
			self:debug("[ipInByWhiteList] ip "..ip.." in byWhite list",ip,"")
			return true
		else
			return false
		end
	end
	return false
end

--byDeny黑名单模块
function Guard:ipInByDenyList(ip)
	if _Conf.byDenyIpModulesIsOn then --判断是否开启 byDeny 黑名单模块
		-- self:debug("[ipInByDenyList] byDenyIpModules is on.",ip,"")
		if _Conf.dict_byDenyIp:get(ip) then
			self:debug("[ipInByDenyList] ip "..ip.. " in byDeny list ",ip,"")
			return true
		else
			return false
		end
	end
	return false
end

--黑名单模块
function Guard:blackListModules(ip,reqUri,address,userAgent,httpReferer)
	local blackKey = ip.."black"
	if _Conf.dict_black:get(blackKey) then --判断ip是否存在黑名单字典
		self:debug("[blackListModules] ip "..ip.." in blacklist",ip,reqUri)
		self:takeAction(ip,reqUri,address,userAgent,httpReferer) --存在则执行相应动作
	end
end

--限制请求速率模块
function Guard:limitReqModules(ip,reqUri,address,limitModule)
	--self:debug("[limitReqModules] limitReqModules is on.",ip,reqUri)
	if ( _Conf.limitReqModulesIsOn and not (limitModule == "off") ) or (limitModule == "on") then
		if ngx.re.match(address,_Conf.limitUrlProtect,"ijo") then
			self:debug("[limitReqModules] address "..address.." match reg ".._Conf.limitUrlProtect,ip,reqUri)
			--local blackKey = ip.."black"
			local limitReqKey = ip.."limitreqkey" --定义limitreq key
			local reqTimes = _Conf.dict_challenge:get(limitReqKey) --获取此ip请求的次数
			
			--增加一次请求记录
			if reqTimes then
				_Conf.dict_challenge:incr(limitReqKey, 1)
			else
				_Conf.dict_challenge:set(limitReqKey, 1, _Conf.limitReqModules.amongTime)
				reqTimes = 0
			end
			
			local newReqTimes  = reqTimes + 1
			self:debug("[limitReqModules] newReqTimes "..newReqTimes,ip,reqUri)
			
			--判断请求数是否大于阀值,大于则添加黑名单
			if newReqTimes > _Conf.limitReqModules.maxReqs then --判断是否请求数大于阀值
				self:debug("[limitReqModules] ip "..ip.. " request exceed ".._Conf.limitReqModules.maxReqs,ip,reqUri)
				if _Conf.limitReqModules.action == 1 then		--添加此ip到黑名单
					local blackKey = ip.."black"
					_Conf.dict_black:set(blackKey,0,_Conf.blockTime)
					self:log("[limitReqModules] IP "..ip.." request "..newReqTimes.." times, add it to black list")
				elseif _Conf.limitReqModules.action == 2 then		--添加此ip到needVerify列表
					_Conf.dict_needVerify:set(ip,"limitReqModules",_Conf.blockTime)
					self:log("[limitReqModules] IP "..ip.." request "..newReqTimes.." times, add it to needVerify list")
				elseif _Conf.limitReqModules.action == 3 then		--添加此ip到byDenyIp列表
					_Conf.dict_byDenyIp:set(ip,"limitReqModules",_Conf.blockTime)
					self:log("[limitReqModules] IP "..ip.." request "..newReqTimes.." times, add it to byDenyIp list")
				end
			end
			
		end
	end
end

--302转向模块
function Guard:redirectModules(ip,reqUri,address)
	if ngx.re.match(address,_Conf.redirectUrlProtect,"ijo") then
		self:debug("[redirectModules] address "..address.." match reg ".._Conf.redirectUrlProtect,ip,reqUri)
		local whiteKey = ip.."white302"
		local inWhiteList = _Conf.dict_white:get(whiteKey)
		
		if inWhiteList then --如果在白名单
			self:debug("[redirectModules] in white ip list",ip,reqUri)
			return
		else
			--如果不在白名单,再检测是否有cookie凭证
			local now = ngx.time() --当前时间戳
			local challengeTimesKey = table.concat({ip,"challenge302"})
			local challengeTimesValue = _Conf.dict_challenge:get(challengeTimesKey)
			local blackKey = ip.."black"
			local cookie_key = ngx.var["cookie_key302"] --获取cookie密钥
			local cookie_expire = ngx.var["cookie_expire302"] --获取cookie密钥过期时间
			
			if cookie_key and cookie_expire then
				local key_make = ngx.md5(table.concat({ip,_Conf.redirectModules.keySecret,cookie_expire}))
				local key_make = string.sub(key_make,"1","10")
				--判断cookie是否有效
				if tonumber(cookie_expire) > now and cookie_key == key_make then
					self:debug("[redirectModules] cookie key is valid.",ip,reqUri)
					if challengeTimesValue then
						_Conf.dict_challenge:delete(challengeTimesKey) --删除验证失败计数器
					end
					_Conf.dict_white:set(whiteKey,0,_Conf.whiteTime) --添加到白名单
					if _Conf.dict_black:get(blackKey) then --如果黑名单中有该IP, 则删除
						_Conf.dict_black:delete(blackKey)
					end
					return
				else
					self:debug("[redirectModules] cookie key is invalid.",ip,reqUri)
					local expire = now + _Conf.keyExpire
					local key_new = ngx.md5(table.concat({ip,_Conf.redirectModules.keySecret,expire}))
					local key_new = string.sub(key_new,"1","10")
					--定义转向的url
					local newUrl = ''
					local newReqUri = ngx.re.match(reqUri, "(.*?)\\?(.+)")
					if newReqUri then
						local reqUriNoneArgs = newReqUri[1]
						local args = newReqUri[2]
						--删除cckey和keyexpire
						local newArgs = ngx.re.gsub(args, "[&?]?key302=[^&]+&?|expire302=[^&]+&?", "", "i")
						if newArgs == "" then
							newUrl = table.concat({reqUriNoneArgs,"?key302=",key_new,"&expire302=",expire})
						else
							newUrl = table.concat({reqUriNoneArgs,"?",newArgs,"&key302=",key_new,"&expire302=",expire})
						end
					else
						newUrl = table.concat({reqUri,"?key302=",key_new,"&expire302=",expire})
						
					end
					
					--验证失败次数加1
					if challengeTimesValue then
						_Conf.dict_challenge:incr(challengeTimesKey,1)
						if challengeTimesValue + 1> _Conf.redirectModules.verifyMaxFail then
							self:debug("[redirectModules] client "..ip.." challenge cookie failed "..challengeTimesValue.." times,add to blacklist.",ip,reqUri)
							self:log("[redirectModules] client "..ip.." challenge cookie failed "..challengeTimesValue.." times,add to blacklist.")
							_Conf.dict_black:set(blackKey,0,_Conf.blockTime) --添加此ip到黑名单
							self:black2byDeny(ip,reqUri,address)	--判断是否要添加该IP到byDenyIp名单
						end
					else
						_Conf.dict_challenge:set(challengeTimesKey,1,_Conf.redirectModules.amongTime)
					end
					
					--删除cookie
					ngx.header['Set-Cookie'] = {"key302=; path=/", "expire302=; expires=Sat, 01-Jan-2000 00:00:00 GMT; path=/"}
					return ngx.redirect(newUrl, 302) --发送302转向
				end
			else
				--如果没有找到cookie,则检测是否带cckey参数
				local ccKeyValue = ngx.re.match(reqUri, "key302=([^&]+)","i")
				local expire = ngx.re.match(reqUri, "expire302=([^&]+)","i")
				
				if ccKeyValue and expire then --是否有cckey和keyexpire参数
					local ccKeyValue = ccKeyValue[1]
					local expire = expire[1]
					local key_make = ngx.md5(table.concat({ip,_Conf.redirectModules.keySecret,expire}))
					local key_make = string.sub(key_make,"1","10")
					self:debug("[redirectModules] ccKeyValue "..ccKeyValue,ip,reqUri)
					self:debug("[redirectModules] expire "..expire,ip,reqUri)
					self:debug("[redirectModules] key_make "..key_make,ip,reqUri)
					self:debug("[redirectModules] ccKeyValue "..ccKeyValue,ip,reqUri)
					if key_make == ccKeyValue and now < tonumber(expire) then--判断传过来的cckey参数值是否等于字典记录的值,且没有过期
						self:debug("[redirectModules] ip "..ip.." arg key302 "..ccKeyValue.." is valid.add ip to write list.",ip,reqUri)
						
						if challengeTimesValue then
							_Conf.dict_challenge:delete(challengeTimesKey) --删除验证失败计数器
						end
						_Conf.dict_white:set(whiteKey,0,_Conf.whiteTime) --添加到白名单
						if _Conf.dict_black:get(blackKey) then --如果黑名单中有该IP, 则删除
							_Conf.dict_black:delete(blackKey)
						end
						ngx.header['Set-Cookie'] = {"key302="..key_make.."; path=/", "expire302="..expire.."; path=/"} --发送cookie凭证
						return
					else --如果不相等，则再发送302转向
						self:debug("[redirectModules] ip "..ip.." arg key302 is invalid.",ip,reqUri)
						local expire = now + _Conf.keyExpire
						local key_new = ngx.md5(table.concat({ip,_Conf.redirectModules.keySecret,expire}))
						local key_new = string.sub(key_new,"1","10")
						
						--验证失败次数加1
						if challengeTimesValue then
							_Conf.dict_challenge:incr(challengeTimesKey,1)
							if challengeTimesValue + 1 > _Conf.redirectModules.verifyMaxFail then
								self:debug("[redirectModules] client "..ip.." challenge 302key failed "..challengeTimesValue.." times,add to blacklist.",ip,reqUri)
								self:log("[redirectModules] client "..ip.." challenge 302key failed "..challengeTimesValue.." times,add to blacklist.")
								_Conf.dict_black:set(blackKey,0,_Conf.blockTime) --添加此ip到黑名单
								self:black2byDeny(ip,reqUri,address)	--判断是否要添加该IP到byDenyIp名单
							end
						else
							_Conf.dict_challenge:set(challengeTimesKey,1,_Conf.redirectModules.amongTime)
						end
						--定义转向的url
						local newUrl = ''
						local newReqUri = ngx.re.match(reqUri, "(.*?)\\?(.+)")
						if newReqUri then
							local reqUriNoneArgs = newReqUri[1]
							local args = newReqUri[2]
							--删除cckey和keyexpire
							local newArgs = ngx.re.gsub(args, "[&?]?key302=[^&]+&?|expire302=[^&]+&?", "", "i")
							if newArgs == "" then
								newUrl = table.concat({reqUriNoneArgs,"?key302=",key_new,"&expire302=",expire})
							else
								newUrl = table.concat({reqUriNoneArgs,"?",newArgs,"&key302=",key_new,"&expire302=",expire})
							end
						else
							newUrl = table.concat({reqUri,"?key302=",key_new,"&expire302=",expire})
							
						end
						
						return ngx.redirect(newUrl, 302) --发送302转向
					end
				else
					--验证失败次数加1
					if challengeTimesValue then
						_Conf.dict_challenge:incr(challengeTimesKey,1)
						if challengeTimesValue +1 > _Conf.redirectModules.verifyMaxFail then
							self:debug("[redirectModules] client "..ip.." challenge 302key failed "..challengeTimesValue.." times,add to blacklist.",ip,reqUri)
							self:log("[redirectModules] client "..ip.." challenge 302key failed "..challengeTimesValue.." times,add to blacklist.")
							_Conf.dict_black:set(blackKey,0,_Conf.blockTime) --添加此ip到黑名单
							self:black2byDeny(ip,reqUri,address)	--判断是否要添加该IP到byDenyIp名单
						end
					else
						_Conf.dict_challenge:set(challengeTimesKey,1,_Conf.redirectModules.amongTime)
					end
					
					local expire = now + _Conf.keyExpire
					local key_new = ngx.md5(table.concat({ip,_Conf.redirectModules.keySecret,expire}))
					local key_new = string.sub(key_new,"1","10")
					
					--定义转向的url
					local newUrl = ''
					local newReqUri = ngx.re.match(reqUri, "(.*?)\\?(.+)")
					if newReqUri then
						local reqUriNoneArgs = newReqUri[1]
						local args = newReqUri[2]
						--删除cckey和keyexpire
						local newArgs = ngx.re.gsub(args, "[&?]?key302=[^&]+&?|expire302=[^&]+&?", "", "i")
						if newArgs == "" then
							newUrl = table.concat({reqUriNoneArgs,"?key302=",key_new,"&expire302=",expire})
						else
							newUrl = table.concat({reqUriNoneArgs,"?",newArgs,"&key302=",key_new,"&expire302=",expire})
						end
					else
						newUrl = table.concat({reqUri,"?key302=",key_new,"&expire302=",expire})
						
					end
					
					return ngx.redirect(newUrl, 302) --发送302转向
				end
			end
		end
	end
end

--js跳转模块
function Guard:JsJumpModules(ip,reqUri,address)
	if ngx.re.match(address,_Conf.JsJumpUrlProtect,"ijo") then
		self:debug("[JsJumpModules] address "..address.." match reg ".._Conf.JsJumpUrlProtect,ip,reqUri)
		local whiteKey = ip.."whitejs"
		local inWhiteList = _Conf.dict_white:get(whiteKey)
		
		if inWhiteList then --如果在白名单
			self:debug("[JsJumpModules] in white ip list",ip,reqUri)
			return
		else
			--如果不在白名单,检测是否有cookie凭证
			local cookie_key = ngx.var["cookie_keyjs"] --获取cookie密钥
			local cookie_expire = ngx.var["cookie_expirejs"] --获取cookie密钥过期时间
			local now = ngx.time() --当前时间戳
			local challengeTimesKey = table.concat({ip,"challengejs"})
			local challengeTimesValue = _Conf.dict_challenge:get(challengeTimesKey)
			local blackKey = ip.."black"
			local cookie_key = ngx.var["cookie_keyjs"] --获取cookie密钥
			local cookie_expire = ngx.var["cookie_expirejs"] --获取cookie密钥过期时间
			
			if cookie_key and cookie_expire then
				local key_make = ngx.md5(table.concat({ip,_Conf.JsJumpModules.keySecret,cookie_expire}))
				local key_make = string.sub(key_make,"1","10")
				if tonumber(cookie_expire) > now and cookie_key == key_make then
					if challengeTimesValue then
						_Conf.dict_challenge:delete(challengeTimesKey) --删除验证失败计数器
					end
					self:debug("[JsJumpModules] cookie key is valid.",ip,reqUri)
					_Conf.dict_white:set(whiteKey,0,_Conf.whiteTime) --添加ip到白名单
					if _Conf.dict_black:get(blackKey) then --如果黑名单中有该IP, 则删除
						_Conf.dict_black:delete(blackKey)
					end
					return
				else
					--验证失败次数加1
					if challengeTimesValue then
						_Conf.dict_challenge:incr(challengeTimesKey,1)
						if challengeTimesValue +1 > _Conf.JsJumpModules.verifyMaxFail then
							self:debug("[JsJumpModules] client "..ip.." challenge cookie failed "..challengeTimesValue.." times,add to blacklist.",ip,reqUri)
							self:log("[JsJumpModules] client "..ip.." challenge cookie failed "..challengeTimesValue.." times,add to blacklist.")
							_Conf.dict_black:set(blackKey,0,_Conf.blockTime) --添加此ip到黑名单
							self:black2byDeny(ip,reqUri,address)	--判断是否要添加该IP到byDenyIp名单
						end
					else
						_Conf.dict_challenge:set(challengeTimesKey,1,_Conf.JsJumpModules.amongTime)
					end
					
					self:debug("[JsJumpModules] cookie key is invalid.",ip,reqUri)
					local expire = now + _Conf.keyExpire
					local key_new = ngx.md5(table.concat({ip,_Conf.JsJumpModules.keySecret,expire}))
					local key_new = string.sub(key_new,"1","10")
					
					--定义转向的url
					local newUrl = ''
					local newReqUri = ngx.re.match(reqUri, "(.*?)\\?(.+)")
					if newReqUri then
						local reqUriNoneArgs = newReqUri[1]
						local args = newReqUri[2]
						--删除cckey和keyexpire
						local newArgs = ngx.re.gsub(args, "[&?]?keyjs=[^&]+&?|expirejs=[^&]+&?", "", "i")
						if newArgs == "" then
							newUrl = table.concat({reqUriNoneArgs,"?keyjs=",key_new,"&expirejs=",expire})
						else
							newUrl = table.concat({reqUriNoneArgs,"?",newArgs,"&keyjs=",key_new,"&expirejs=",expire})
						end
					else
						newUrl = table.concat({reqUri,"?keyjs=",key_new,"&expirejs=",expire})
						
					end
					
					local jsJumpCode=table.concat({"<script>window.location.href='",newUrl,"';</script>"}) --定义js跳转代码
					ngx.header.content_type = "text/html"
					--删除cookie
					ngx.header['Set-Cookie'] = {"keyjs=; path=/", "expirejs=; expires=Sat, 01-Jan-2000 00:00:00 GMT; path=/"}
					ngx.print(jsJumpCode)
					ngx.exit(200)
				end
			else
				--如果没有cookie凭证,检测url是否带有cckey参数
				local ccKeyValue = ngx.re.match(reqUri, "keyjs=([^&]+)","i")
				local expire = ngx.re.match(reqUri, "expirejs=([^&]+)","i")
				
				if ccKeyValue and expire then
					local ccKeyValue = ccKeyValue[1]
					local expire = expire[1]
					
					local key_make = ngx.md5(table.concat({ip,_Conf.JsJumpModules.keySecret,expire}))
					local key_make = string.sub(key_make,"1","10")
					
					if key_make == ccKeyValue and now < tonumber(expire) then--判断传过来的cckey参数值是否等于字典记录的值,且没有过期
						self:debug("[JsJumpModules] ip "..ip.." arg keyjs "..ccKeyValue.." is valid.add ip to white list.",ip,reqUri)
						if challengeTimesValue then
							_Conf.dict_challenge:delete(challengeTimesKey) --删除验证失败计数器
						end
						_Conf.dict_white:set(whiteKey,0,_Conf.whiteTime) --添加ip到白名单
						if _Conf.dict_black:get(blackKey) then --如果黑名单中有该IP, 则删除
							_Conf.dict_black:delete(blackKey)
						end
						ngx.header['Set-Cookie'] = {"keyjs="..key_make.."; path=/", "expirejs="..expire.."; path=/"} --发送cookie凭证
						return
					else --如果不相等，则再发送302转向
						--验证失败次数加1
						if challengeTimesValue then
							_Conf.dict_challenge:incr(challengeTimesKey,1)
							if challengeTimesValue + 1 > _Conf.JsJumpModules.verifyMaxFail then
								self:debug("[JsJumpModules] client "..ip.." challenge jskey failed "..challengeTimesValue.." times,add to blacklist.",ip,reqUri)
								self:log("[JsJumpModules] client "..ip.." challenge jskey failed "..challengeTimesValue.." times,add to blacklist.")
								_Conf.dict_black:set(blackKey,0,_Conf.blockTime) --添加此ip到黑名单
								self:black2byDeny(ip,reqUri,address)	--判断是否要添加该IP到byDenyIp名单
							end
						else
							_Conf.dict_challenge:set(challengeTimesKey,1,_Conf.JsJumpModules.amongTime)
						end
						
						self:debug("[JsJumpModules] ip "..ip.." arg keyjs is invalid.",ip,reqUri)
						local expire = now + _Conf.keyExpire
						local key_new = ngx.md5(table.concat({ip,_Conf.JsJumpModules.keySecret,expire}))
						local key_new = string.sub(key_new,"1","10")
						--定义转向的url
						local newUrl = ''
						local newReqUri = ngx.re.match(reqUri, "(.*?)\\?(.+)")
						if newReqUri then
							local reqUriNoneArgs = newReqUri[1]
							local args = newReqUri[2]
							--删除cckey和keyexpire
							local newArgs = ngx.re.gsub(args, "[&?]?keyjs=[^&]+&?|expirejs=[^&]+&?", "", "i")
							if newArgs == "" then
								newUrl = table.concat({reqUriNoneArgs,"?keyjs=",key_new,"&expirejs=",expire})
							else
								newUrl = table.concat({reqUriNoneArgs,"?",newArgs,"&keyjs=",key_new,"&expirejs=",expire})
							end
						else
							newUrl = table.concat({reqUri,"?keyjs=",key_new,"&expirejs=",expire})
							
						end
						local jsJumpCode=table.concat({"<script>window.location.href='",newUrl,"';</script>"}) --定义js跳转代码
						ngx.header.content_type = "text/html"
						ngx.print(jsJumpCode)
						ngx.exit(200)
					end
				else
					--验证失败次数加1
					if challengeTimesValue then
						_Conf.dict_challenge:incr(challengeTimesKey,1)
						if challengeTimesValue + 1 > _Conf.JsJumpModules.verifyMaxFail then
							self:debug("[JsJumpModules] client "..ip.." challenge jskey failed "..challengeTimesValue.." times,add to blacklist.",ip,reqUri)
							self:log("[JsJumpModules] client "..ip.." challenge jskey failed "..challengeTimesValue.." times,add to blacklist.")
							_Conf.dict_black:set(blackKey,0,_Conf.blockTime) --添加此ip到黑名单
							self:black2byDeny(ip,reqUri,address)	--判断是否要添加该IP到byDenyIp名单
						end
					else
						_Conf.dict_challenge:set(challengeTimesKey,1,_Conf.JsJumpModules.amongTime)
					end
					
					--定义转向的url
					local expire = now + _Conf.keyExpire
					local key_new = ngx.md5(table.concat({ip,_Conf.JsJumpModules.keySecret,expire}))
					local key_new = string.sub(key_new,"1","10")
					
					--定义转向的url
					local newUrl = ''
					local newReqUri = ngx.re.match(reqUri, "(.*?)\\?(.+)")
					if newReqUri then
						local reqUriNoneArgs = newReqUri[1]
						local args = newReqUri[2]
						--删除cckey和keyexpire
						local newArgs = ngx.re.gsub(args, "[&?]?keyjs=[^&]+&?|expirejs=[^&]+&?", "", "i")
						if newArgs == "" then
							newUrl = table.concat({reqUriNoneArgs,"?keyjs=",key_new,"&expirejs=",expire})
						else
							newUrl = table.concat({reqUriNoneArgs,"?",newArgs,"&keyjs=",key_new,"&expirejs=",expire})
						end
					else
						newUrl = table.concat({reqUri,"?keyjs=",key_new,"&expirejs=",expire})
						
					end
					
					local jsJumpCode=table.concat({"<script>window.location.href='",newUrl,"';</script>"}) --定义js跳转代码
					ngx.header.content_type = "text/html"
					ngx.print(jsJumpCode)
					ngx.exit(200)
				end
			end
		end
	end
end

--cookie验证模块
function Guard:cookieModules(ip,reqUri,address,userAgent,httpReferer)
	if ngx.re.match(address,_Conf.cookieUrlProtect,"ijo") then
		
		self:debug("[cookieModules] address "..address.." match reg ".._Conf.cookieUrlProtect.."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
		local whiteKey = ip.."whitecookie"
		local inWhiteList = _Conf.dict_white:get(whiteKey)
		
		if inWhiteList then --如果在白名单
			self:debug("[cookieModules] in white ip list.".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
			return
		else
			local cookie_key = ngx.var["cookie_keycookie"] --获取cookie密钥
			local cookie_expire = ngx.var["cookie_expirecookie"] --获取cookie密钥过期时间
			local now = ngx.time() --当前时间戳
			local challengeTimesKey = table.concat({ip,"challengecookie"})
			local challengeTimesValue = _Conf.dict_challenge:get(challengeTimesKey)
			local blackKey = ip.."black"
			
			if cookie_key and cookie_expire then --判断是否有收到cookie
				local key_make = ngx.md5(table.concat({ip,_Conf.cookieModules.keySecret,cookie_expire}))
				local key_make = string.sub(key_make,"1","10")
				local cookie_expire_tonumber = tonumber(cookie_expire) or 0
				--if cookie_expire_tonumber == 0 then		--判断cookie_expire转数字是否失（如篡改cookie_expire为boolean值）, 失败则打印 cookie_expire
				--	self:log("[cookieModules] cookie_expire: "..cookie_expire.." tonumber failed ".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
				--end
				if cookie_expire_tonumber > now and cookie_key == key_make then
					if challengeTimesValue then
						_Conf.dict_challenge:delete(challengeTimesKey) --删除验证失败计数器
					end
					self:debug("[cookieModules] cookie key is valid.add to white ip list".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
					_Conf.dict_white:set(whiteKey,0,_Conf.whiteTime) --添加ip到白名单
					if _Conf.dict_black:get(blackKey) then --如果黑名单中有该IP, 则删除
						_Conf.dict_black:delete(blackKey)
					end
					return
				else
					self:debug("[cookieModules] cookie key is invalid".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
					--验证失败次数加1
					if challengeTimesValue then
						_Conf.dict_challenge:incr(challengeTimesKey,1)
						if challengeTimesValue +1 > _Conf.cookieModules.verifyMaxFail then
							self:debug("[cookieModules] client "..ip.." challenge cookie failed "..challengeTimesValue.." times,add to blacklist.".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
							self:log("[cookieModules] client "..ip.." challenge cookie failed "..challengeTimesValue.." times,add to blacklist.")
							_Conf.dict_black:set(blackKey,0,_Conf.blockTime) --添加此ip到黑名单
							self:black2byDeny(ip,reqUri,address)	--判断是否要添加该IP到byDenyIp名单
						end
					else
						_Conf.dict_challenge:set(challengeTimesKey,1,_Conf.cookieModules.amongTime)
					end
					
					ngx.header['Set-Cookie'] = {"keycookie=; path=/", "expirecookie=; expires=Sat, 01-Jan-2000 00:00:00 GMT; path=/"} --删除cookie
				end
			else --找不到cookie
				self:debug("[cookieModules] cookie not found.".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
				--验证失败次数加1
				if challengeTimesValue then
					_Conf.dict_challenge:incr(challengeTimesKey,1)
					if challengeTimesValue +1 > _Conf.cookieModules.verifyMaxFail then
						self:debug("[cookieModules] client "..ip.." challenge cookie failed "..challengeTimesValue.." times,add to blacklist.".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
						self:log("[cookieModules] client "..ip.." challenge cookie failed "..challengeTimesValue.." times,add to blacklist.")
						_Conf.dict_black:set(blackKey,0,_Conf.blockTime) --添加此ip到黑名单
						self:black2byDeny(ip,reqUri,address)	--判断是否要添加该IP到byDenyIp名单
					end
				else
					_Conf.dict_challenge:set(challengeTimesKey,1,_Conf.cookieModules.amongTime)
				end
				
				local expire = now + _Conf.keyExpire
				local key_new = ngx.md5(table.concat({ip,_Conf.cookieModules.keySecret,expire}))
				local key_new = string.sub(key_new,"1","10")
				
				self:debug("[cookieModules] send cookie to client.".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
				ngx.header['Set-Cookie'] = {"keycookie="..key_new.."; path=/", "expirecookie="..expire.."; path=/"} --发送cookie凭证
			end
		end
	end
end

--获取验证码
function Guard:getCaptcha()
	math.randomseed(ngx.now()) --随机种子
	--local random = math.random(1,10000) --生成1-10000之间的随机数
	local random = math.random(_Conf.randomInteger,(_Conf.randomInteger+10000)) --生成一个随机数
	self:debug("[getCaptcha] get random num "..random,"","")
	local captchaValue = _Conf.dict_captcha:get(random) --取得字典中的验证码
	self:debug("[getCaptcha] get captchaValue "..captchaValue,"","")
	local captchaImg = _Conf.dict_captcha:get(captchaValue) --取得验证码对应的图片
	--返回图片
	ngx.status = 298
	ngx.header.content_type = "image/jpeg"
	ngx.header['Set-Cookie'] = table.concat({"captchaNum=",random,"; path=/"})
	ngx.header['Cache-Control'] = "no-cache"
	ngx.print(captchaImg)
	ngx.exit(298)
end

--验证验证码
function Guard:verifyCaptcha(ip,reqUri,address)
	ngx.req.read_body()
	local captchaNum = ngx.var["cookie_captchaNum"] or "NONE" --获取cookie captchaNum值
	local preurl = ngx.var["cookie_preurl"] or "/" --获取上次访问url,如果为空则返回首页(返回首页是为了避免用户禁用了 Cookie 而导致无法获取上次访问的URL)
	self:debug("[verifyCaptcha] get cookie captchaNum "..captchaNum,ip,"")
	local args = ngx.req.get_post_args() --获取post参数
	local postValue = args["response"] or "postValue_NONE" --获取post value参数
	postValue = string.lower(postValue)
	self:debug("[verifyCaptcha] get post arg response "..postValue,ip,"")
	local captchaValue = _Conf.dict_captcha:get(captchaNum) or "captchaValue_NONE" --从字典获取post value对应的验证码值

	--preurl(若上次访问的URL) 中含verify-captcha.do, 则preurl 截到 verify-captcha.do
	if ngx.re.match(preurl,"verify-captcha.do","i") then
		local from, to, err = ngx.re.find(preurl, "verify-captcha.do", "i")
		preurl = string.sub(preurl, 0, from-1)
	end
	--preurl(若上次访问的URL为ico、js、css、图片等则返回preurl为首页)
	if ngx.re.match(preurl,_Conf.preurlVerifyCaptcha_regex,"i") then
		preurl = "/"
	end
	
	if captchaValue == postValue then --比较验证码是否相等
		_Conf.dict_black:delete(ip.."black") --从黑名单删除
		self:debug("[verifyCaptcha] captcha is valid.delete from blacklist",ip,"")
		
		--清除perUrlRateLimit相关记录
		self:perUrlRateLimitVerifyOK(ip,reqUri,address)
		
		local oneKeyOpenVerificationOn = _Conf.dict_system:get("oneKeyOpenVerificationOn")
		if oneKeyOpenVerificationOn == 1 then			--添加IP到白名单并删除challenge列表中验证失败计数器
			local whiteTime = _Conf.dict_system:get("oneKeyOpenVerification_whiteTime")
			_Conf.dict_white:set(ip.."whiteVerification",0,whiteTime)
			return ngx.redirect(preurl)
		else
			if _Conf.redirectModulesIsOn then
				_Conf.dict_white:set(ip.."white302",0,_Conf.whiteTime)		--添加IP到白名单
				local challengeTimesKey = table.concat({ip,"challenge302"})
				local challengeTimesValue = _Conf.dict_challenge:get(challengeTimesKey)
				if challengeTimesValue then
					_Conf.dict_challenge:delete(challengeTimesKey) --删除challenge列表中验证失败计数器
				end
			end
			if  _Conf.JsJumpModulesIsOn then
				_Conf.dict_white:set(ip.."whitejs",0,_Conf.whiteTime)
				local challengeTimesKey = table.concat({ip,"challengejs"})		--添加IP到白名单
				local challengeTimesValue = _Conf.dict_challenge:get(challengeTimesKey)
				if challengeTimesValue then
					_Conf.dict_challenge:delete(challengeTimesKey) --删除challenge列表中验证失败计数器
				end
			end
			if _Conf.cookieModulesIsOn then
				_Conf.dict_white:set(ip.."whitecookie",0,_Conf.whiteTime)
				local challengeTimesKey = table.concat({ip,"challengecookie"})		--添加IP到白名单
				local challengeTimesValue = _Conf.dict_challenge:get(challengeTimesKey)
				if challengeTimesValue then
					_Conf.dict_challenge:delete(challengeTimesKey) --删除challenge列表中验证失败计数器
				end
			end
		end
		
		--local challengeTimesKey = table.concat({ip,"challengecookie"})
		--local challengeTimesValue = _Conf.dict_challenge:get(challengeTimesKey)
		--if challengeTimesValue then
		--	_Conf.dict_challenge:delete(challengeTimesKey) --删除challenge列表中验证失败计数器
		--end
		
		local expire = ngx.time() + _Conf.keyExpire
		local captchaKey = ngx.md5(table.concat({ip,_Conf.captchaKey,expire}))
		local captchaKey = string.sub(captchaKey,"1","10")
		self:debug("[verifyCaptcha] expire "..expire,ip,"")
		self:debug("[verifyCaptcha] captchaKey "..captchaKey,ip,"")
		ngx.header['Set-Cookie'] = {"captchaKey="..captchaKey.."; path=/", "captchaExpire="..expire.."; path=/"}
		return ngx.redirect(preurl) --返回上次访问url
	else
		if _Conf.captcha2clickOn and postValue then		--是否执行captcha2click
			local challengeTimesKey = table.concat({ip,"verifyFail"})
			local challengeTimesValue = _Conf.dict_challenge:get(challengeTimesKey)
			if challengeTimesValue then
				_Conf.dict_challenge:incr(challengeTimesKey,1)
				--重新发送验证码页面
				--self:debug("[verifyCaptcha] captcha invalid",ip,"")
				--ngx.header.content_type = "text/html"
				--ngx.print(_Conf.reCaptchaPage)
				--ngx.exit(298)
				self:reSendCaptch(ip)
			else
				_Conf.dict_challenge:set(challengeTimesKey,1,_Conf.captcha2click.amongTime)
				--重新发送验证码页面
				--self:debug("[verifyCaptcha] captcha invalid",ip,"")
				--ngx.header.content_type = "text/html"
				--ngx.print(_Conf.reCaptchaPage)
				--ngx.exit(298)
				self:reSendCaptch(ip)
			end
		else
			--重新发送验证码页面
			--self:debug("[verifyCaptcha] captcha invalid",ip,"")
			--ngx.header.content_type = "text/html"
			--ngx.print(_Conf.reCaptchaPage)
			--ngx.exit(298)
			self:reSendCaptch(ip)
		end
	end
end

function Guard:reSendCaptch(ip)
	self:debug("[verifyCaptcha] captcha invalid",ip,"")
	ngx.status = 298
	ngx.header.content_type = "text/html"
	ngx.header['Cache-Control'] = "no-cache"
	ngx.print(_Conf.reCaptchaPage)
	ngx.exit(298)
end

--拒绝访问动作
function Guard:forbiddenAction()
	ngx.header.content_type = "text/html"
	ngx.exit(299)
end

--展示验证码页面动作
function Guard:captchaAction(ip,reqUri,address)
	if _Conf.captcha2clickOn then		--是否开启captcha2click,当 captcha验证失败 _Conf.captcha2click.verifyMaxFail 次后改用 click验证
		local challengeTimesKey = table.concat({ip,"verifyFail"})
		local challengeTimesValue = _Conf.dict_challenge:get(challengeTimesKey)
		if challengeTimesValue and (challengeTimesValue > _Conf.captcha2click.verifyMaxFail) then
			self:clickAction(ip,reqUri,address)
		end
	end

	if ngx.re.match(reqUri,"^/get-captcha.do","i") then
		self:getCaptcha()
	elseif ngx.re.match(reqUri,"^/verify-captcha.do","i") then
		self:verifyCaptcha(ip,reqUri,address)
	else
		ngx.status = 298
		ngx.header.content_type = "text/html"
		ngx.header['Set-Cookie'] = table.concat({"preurl=",reqUri,"; path=/"})
		ngx.header['Cache-Control'] = "no-cache"
		ngx.print(_Conf.captchaPage)
		ngx.exit(298)
	end
end

--执行相应动作  (进入Black黑名单且不匹配 byPass 的都要验证)
function Guard:takeAction(ip,reqUri,address,userAgent,httpReferer)
	local oneKeyOpenVerificationOn = _Conf.dict_system:get("oneKeyOpenVerificationOn")
	if oneKeyOpenVerificationOn == 1 then
		self:debug("[takeAction] return captchaAction(oneKeyOpenVerificationOn)".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
		self:captchaAction(ip,reqUri,address)
	elseif _Conf.captchaAction then
		self:debug("[takeAction] return captchaAction".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
		self:captchaAction(ip,reqUri,address)
	elseif _Conf.clickAction then
		self:debug("[takeAction] return clickAction".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
		self:clickAction(ip,reqUri,address)
	elseif _Conf.forbiddenAction then
		self:debug("[takeAction] return forbiddenAction".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
		self:forbiddenAction()
		
	elseif _Conf.iptablesAction then
		ngx.thread.spawn(Guard.addToIptables,Guard,ip)
	end
end

--添加进iptables drop表
function Guard:addToIptables(ip)
	local cmd = "echo ".._Conf.sudoPass.." | sudo -S /sbin/iptables -I INPUT -p tcp -s "..ip.." --dport 80 -j DROP"
	os.execute(cmd)
end

--自动开启或关闭防cc功能
function Guard:autoSwitch()
	if not _Conf.dict_system:get("monitor") then
		_Conf.dict_system:set("monitor",0,_Conf.autoEnable.interval)
		local f=io.popen(_Conf.autoEnable.ssCommand.." -tan state established '( sport = :".._Conf.autoEnable.protectPort.." or dport = :".._Conf.autoEnable.protectPort.." )' | wc -l")
		local result=f:read("*all")
		local connection=tonumber(result)
		Guard:debug("[autoSwitch] current connection for port ".._Conf.autoEnable.protectPort.." is "..connection,"","")
		if _Conf.autoEnable.enableModule == "redirectModules" then
			local redirectOn = _Conf.dict_system:get("redirectOn")
			if redirectOn == 1 then
				_Conf.dict_system:set("exceedCount",0) --超限次数清0
				--如果当前连接在最大连接之下,为正常次数加1
				if connection < _Conf.autoEnable.maxConnection then
					_Conf.dict_system:incr("normalCount",1)
				end
				
				--如果正常次数大于_Conf.autoEnable.normalTimes,关闭redirectModules
				local normalCount = _Conf.dict_system:get("normalCount")
				if normalCount > _Conf.autoEnable.normalTimes then
					Guard:log("[autoSwitch] turn redirectModules off.")
					_Conf.dict_system:set("redirectOn",0)
				end
			else
				_Conf.dict_system:set("normalCount",0) --正常次数清0
				--如果当前连接在最大连接之上,为超限次数加1
				if connection > _Conf.autoEnable.maxConnection then
					_Conf.dict_system:incr("exceedCount",1)
				end
				
				--如果超限次数大于_Conf.autoEnable.exceedTimes,开启redirectModules
				local exceedCount = _Conf.dict_system:get("exceedCount")
				if exceedCount > _Conf.autoEnable.exceedTimes then
					Guard:log("[autoSwitch] turn redirectModules on.")
					_Conf.dict_system:set("redirectOn",1)
				end
			end
			
		elseif  _Conf.autoEnable.enableModule == "JsJumpModules" then
			local jsOn = _Conf.dict_system:get("jsOn")
			if jsOn == 1 then
				_Conf.dict_system:set("exceedCount",0) --超限次数清0
				--如果当前连接在最大连接之下,为正常次数加1
				if connection < _Conf.autoEnable.maxConnection then
					_Conf.dict_system:incr("normalCount",1)
				end
				
				--如果正常次数大于_Conf.autoEnable.normalTimes,关闭JsJumpModules
				local normalCount = _Conf.dict_system:get("normalCount")
				if normalCount > _Conf.autoEnable.normalTimes then
					Guard:log("[autoSwitch] turn JsJumpModules off.")
					_Conf.dict_system:set("jsOn",0)
				end
			else
				_Conf.dict_system:set("normalCount",0) --正常次数清0
				--如果当前连接在最大连接之上,为超限次数加1
				if connection > _Conf.autoEnable.maxConnection then
					_Conf.dict_system:incr("exceedCount",1)
				end
				
				--如果超限次数大于_Conf.autoEnable.exceedTimes,开启JsJumpModules
				local exceedCount = _Conf.dict_system:get("exceedCount")
				if exceedCount > _Conf.autoEnable.exceedTimes then
					Guard:log("[autoSwitch] turn JsJumpModules on.")
					_Conf.dict_system:set("jsOn",1)
				end
			end
			
		elseif  _Conf.autoEnable.enableModule == "cookieModules" then
			local cookieOn = _Conf.dict_system:get("cookieOn")
			if cookieOn == 1 then
				_Conf.dict_system:set("exceedCount",0) --超限次数清0
				--如果当前连接在最大连接之下,为正常次数加1
				if connection < _Conf.autoEnable.maxConnection then
					_Conf.dict_system:incr("normalCount",1)
				end
				
				--如果正常次数大于_Conf.autoEnable.normalTimes,关闭cookieModules
				local normalCount = _Conf.dict_system:get("normalCount")
				if normalCount > _Conf.autoEnable.normalTimes then
					Guard:log("[autoSwitch] turn cookieModules off.")
					_Conf.dict_system:set("cookieOn",0)
				end
			else
				_Conf.dict_system:set("normalCount",0) --正常次数清0
				--如果当前连接在最大连接之上,为超限次数加1
				if connection > _Conf.autoEnable.maxConnection then
					_Conf.dict_system:incr("exceedCount",1)
				end
				
				--如果超限次数大于_Conf.autoEnable.exceedTimes,开启cookieModules
				local exceedCount = _Conf.dict_system:get("exceedCount")
				if exceedCount > _Conf.autoEnable.exceedTimes then
					Guard:log("[autoSwitch] turn cookieModules on.")
					_Conf.dict_system:set("cookieOn",1)
				end
			end
		end
	end
end

--click点击验证
function Guard:clickAction(ip,reqUri,address)
	if _Conf.captcha2clickOn then		--如果开启了captcha2click, 在用户访问captcha验证页面时显示验证码图片
		if ngx.re.match(reqUri,"^/get-captcha.do","i") then
			self:getCaptcha()
		end
	end

	ngx.req.read_body()
	local now = ngx.time() --当前时间戳
	local preurl = ngx.var["cookie_preurl"] or "/" --获取上次访问url,如果为空则返回首页(返回首页是为了避免用户禁用了 Cookie 而导致无法获取上次访问的URL)
	local clickKeyValue = ngx.re.match(reqUri, "keydj=([^&]+)","i")
	local expire = ngx.re.match(reqUri, "expiredj=([^&]+)","i")

	if ngx.re.match(preurl,"verify-captcha.do","i") then
		local from, to, err = ngx.re.find(preurl, "verify-captcha.do", "i")
		preurl = string.sub(preurl, 0, from-1)
	end

	if clickKeyValue and expire then                --Click验证
		local clickKeyValue = clickKeyValue[1]
		local expire = expire[1]
		
		local key_make = ngx.md5(table.concat({ip,_Conf.clickKey,expire}))
		local key_make = string.sub(key_make,"1","10")
		
		if key_make == clickKeyValue and now < tonumber(expire) then
			local dict_black = ngx.shared.dict_black
			local blackKey = ip.."black"
			dict_black:delete(blackKey)		--从黑名单删除该IP
			if _Conf.redirectModulesIsOn then		--添加IP到白名单
				_Conf.dict_white:set(ip.."white302",0,_Conf.whiteTime)
			end
			if  _Conf.JsJumpModulesIsOn then
				_Conf.dict_white:set(ip.."whitejs",0,_Conf.whiteTime)
			end
			if _Conf.cookieModulesIsOn then
				_Conf.dict_white:set(ip.."whitecookie",0,_Conf.whiteTime)
			end
			
			local challengeTimesKey = table.concat({ip,"challengecookie"})
			local challengeTimesValue = _Conf.dict_challenge:get(challengeTimesKey)
			if challengeTimesValue then
				_Conf.dict_challenge:delete(challengeTimesKey) --删除challenge列表中验证失败计数器
			end
			
			return ngx.redirect(preurl) --返回上次访问url
		else		--如果clickKeyValue expire不合法, 返回click验证页面
			local newUrl = ''
			local clickCode = 'Error: Click Verify Page is no return'
			
			local expire = now + _Conf.keyExpire
			local key_new = ngx.md5(table.concat({ip,_Conf.clickKey,expire}))
			local key_new = string.sub(key_new,"1","10")
			local args = ngx.req.get_uri_args() or {}
			
			--[[
			if next(args) == nil then		--判断请求的reqUri是否带参
				if ngx.re.match(reqUri,"\\?$","ijo") then		--判断url是否以?结尾
					newUrl = table.concat({reqUri,"keydj=",key_new,"&expiredj=",expire})
					--ngx.say(reqUri," match 1")
				else
					newUrl = table.concat({reqUri,"?keydj=",key_new,"&expiredj=",expire})
					--ngx.say(reqUri," no match 1")
				end				
			else
				local f, t, err = ngx.re.find(reqUri,"&keydj=|keydj=","ijo")
				if f then
					local uriStrsub = string.sub(reqUri, 0, f - 1)
					if ngx.re.match(uriStrsub,"\\?$","ijo") then
						newUrl = table.concat({uriStrsub,"keydj=",key_new,"&expiredj=",expire})
						--ngx.say(reqUri," match 2")
					else
						newUrl = table.concat({uriStrsub,"&keydj=",key_new,"&expiredj=",expire})
						--ngx.say(reqUri," no match 2")
					end		
				else
					if ngx.re.match(reqUri,"\\?$","ijo") then
						newUrl = table.concat({reqUri,"keydj=",key_new,"&expiredj=",expire})
						--ngx.say(reqUri," match 3")
					else
						newUrl = table.concat({reqUri,"&keydj=",key_new,"&expiredj=",expire})
						--ngx.say(reqUri," no match 3")
					end
				end
			end
			]]
			local f, t, err = ngx.re.find(reqUri,"\\?&keydj|\\?keydj|&keydj=|keydj=","ijo")
			if f then		--url中是否含 &keydj=或keydj=
				reqUri = string.sub(reqUri, 0, f - 1)		--url 截断到&keydj=或keydj=
			end

			if ngx.re.match(reqUri,"\\?$","ijo") then
				newUrl = table.concat({reqUri,"keydj=",key_new,"&expiredj=",expire})
			elseif ngx.re.match(reqUri,"\\?.+","ijo") then
				newUrl = table.concat({reqUri,"&keydj=",key_new,"&expiredj=",expire})
			else
				newUrl = table.concat({reqUri,"?keydj=",key_new,"&expiredj=",expire})
			end
			
			--定义click验证页面代码
			if _Conf.hiddenClick then		--隐藏click验证页面,自动验证
				clickCode = table.concat({ '<meta http-equiv="refresh" content="0; url=', newUrl, '" >' })
				--clickCode = table.concat({ '<script>window.location.href="',newUrl,'";</script>' })
			else		--click验证页面,倒计时9秒后自动打开目标链接
				clickCode = table.concat({ '<!DOCTYPE html><html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" ><title>Click 2 verity</title><style> #content { position:absolute;width:400px;height:200px;left:50%;top:50%;margin-left:-200px;margin-top:-100px;vertical-align:middle;line-height:200px;text-align:center;font-family:"微软雅黑";font-size:16px } </style><script type="text/javascript"> function countDown(secs,tUrl){ var jumpTo = document.getElementById("jumpTo"); jumpTo.innerHTML=secs; if (--secs>0){ setTimeout("countDown("+secs+",', "'", '"+tUrl+"', "'", ')",1000); } else{ window.location.href=tUrl; } } </script></head> <body><div id="content" ><a href="', newUrl, '">点击继续访问</a> &nbsp; <span id="jumpTo">9</span>&Prime; <script type="text/javascript">countDown(9,"', newUrl, '");</script> </div></body></html>' })
			end
	
			ngx.header.content_type = "text/html"
			local challengeTimesKey = table.concat({ip,"verifyFail"})
			local challengeTimesValue = _Conf.dict_challenge:get(challengeTimesKey)
			if not (_Conf.captcha2clickOn and challengeTimesValue) then		--由 captcha2click 过来的请求不再发送 preurl
				ngx.header['Set-Cookie'] = table.concat({"preurl=",reqUri,"; path=/"})	
			end
			ngx.print(clickCode)
			ngx.exit(200)
		end
	
	else            --如果clickKeyValue expire不存在,返回click验证页面
		local newUrl = ''
		local clickCode = 'Error: Click Verify Page is no return'
		local expire = now + _Conf.keyExpire
		local key_new = ngx.md5(table.concat({ip,_Conf.clickKey,expire}))
		local key_new = string.sub(key_new,"1","10")
		local args = ngx.req.get_uri_args() or {}
		--[[
		if next(args) == nil then		--判断请求的reqUri是否带参
			--newUrl = table.concat({reqUri,"?keydj=",key_new,"&expiredj=",expire})
			if ngx.re.match(reqUri,"\\?$","ijo") then		--判断url是否以?结尾
				newUrl = table.concat({reqUri,"keydj=",key_new,"&expiredj=",expire})
				--ngx.say(reqUri," match 11")
			else
				newUrl = table.concat({reqUri,"?keydj=",key_new,"&expiredj=",expire})
				--ngx.say(reqUri," not match 11")
			end
		else
			local f, t, err = ngx.re.find(reqUri,"&keydj=|keydj=","ijo")
			if f then
				local uriStrsub = string.sub(reqUri, 0, f - 1)
				--newUrl = table.concat({uriStrsub,"&keydj=",key_new,"&expiredj=",expire})
				if ngx.re.match(uriStrsub,"\\?$","ijo") then
					newUrl = table.concat({uriStrsub,"keydj=",key_new,"&expiredj=",expire})
					--ngx.say(reqUri," match 22")
				else
					newUrl = table.concat({uriStrsub,"&keydj=",key_new,"&expiredj=",expire})
					--ngx.say(reqUri," not match 22")
				end
			else
				--newUrl = table.concat({reqUri,"&keydj=",key_new,"&expiredj=",expire})
				if ngx.re.match(reqUri,"\\?$","ijo") then
					newUrl = table.concat({reqUri,"keydj=",key_new,"&expiredj=",expire})
					--ngx.say(reqUri," match 33")
				else
					newUrl = table.concat({reqUri,"&keydj=",key_new,"&expiredj=",expire})
					--ngx.say(reqUri," not match 33")
				end
			end
		end
		]]
		local f, t, err = ngx.re.find(reqUri,"\\?&keydj|\\?keydj|&keydj=|keydj=","ijo")
		if f then		--url中是否含 &keydj=或keydj=
			reqUri = string.sub(reqUri, 0, f - 1)		--url 截断到&keydj=或keydj=
		end

		if ngx.re.match(reqUri,"\\?$","ijo") then
			newUrl = table.concat({reqUri,"keydj=",key_new,"&expiredj=",expire})
		elseif ngx.re.match(reqUri,"\\?.+","ijo") then
			newUrl = table.concat({reqUri,"&keydj=",key_new,"&expiredj=",expire})
		else
			newUrl = table.concat({reqUri,"?keydj=",key_new,"&expiredj=",expire})
		end
		--定义click验证页面代码
		if _Conf.hiddenClick then		--隐藏click验证页面,自动验证
			clickCode = table.concat({ '<meta http-equiv="refresh" content="0; url=', newUrl, '" >' })
			--clickCode = table.concat({ '<script>window.location.href="',newUrl,'";</script>' })
		else		--click验证页面,倒计时9秒后自动打开目标链接
			clickCode = table.concat({ '<!DOCTYPE html><html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" ><title>Click 2 verity</title><style> #content { position:absolute;width:400px;height:200px;left:50%;top:50%;margin-left:-200px;margin-top:-100px;vertical-align:middle;line-height:200px;text-align:center;font-family:"微软雅黑";font-size:16px } </style><script type="text/javascript"> function countDown(secs,tUrl){ var jumpTo = document.getElementById("jumpTo"); jumpTo.innerHTML=secs; if (--secs>0){ setTimeout("countDown("+secs+",', "'", '"+tUrl+"', "'", ')",1000); } else{ window.location.href=tUrl; } } </script></head> <body><div id="content" ><a href="', newUrl, '">点击继续访问</a> &nbsp; <span id="jumpTo">9</span>&Prime; <script type="text/javascript">countDown(9,"', newUrl, '");</script> </div></body></html>' })
		end
			
		ngx.header.content_type = "text/html"
		local challengeTimesKey = table.concat({ip,"verifyFail"})
		local challengeTimesValue = _Conf.dict_challenge:get(challengeTimesKey)
		if not (_Conf.captcha2clickOn and challengeTimesValue) then		--由 captcha2click 过来的请求不再发送 preurl
			ngx.header['Set-Cookie'] = table.concat({"preurl=",reqUri,"; path=/"})	
		end
		ngx.print(clickCode)
		ngx.exit(200)
	end
end

--IP在单位时间内(_Conf.byDenyIpModules.amongTime)超过N(_Conf.byDenyIpModules.inBlackMax)次出现在Black黑名单中则把该IP添加到byDenyIp列表
function Guard:black2byDeny(ip,reqUri,address)
	if _Conf.byDenyIpModulesIsOn and _Conf.black2byDenyIsOn then		--判断byDenyIp、black2byDeny模块是否开启
		local challengeTimesKey = table.concat({ip,"inBlack"})
		local challengeTimesValue = _Conf.dict_challenge:get(challengeTimesKey)
		if challengeTimesValue then
			_Conf.dict_challenge:incr(challengeTimesKey,1)
			if challengeTimesValue +1 > _Conf.byDenyIpModules.inBlackMax then
				self:debug("[black2byDeny] client "..ip.." challenge inBlackMax "..challengeTimesValue,ip,reqUri)
				self:log("[black2byDeny] client "..ip.." challenge inBlackMax "..challengeTimesValue.." times,add to blacklist.")
				if _Conf.byDenyIpModules.blockTime == 0 then		--添加此ip到byDenyIp名单
					_Conf.dict_byDenyIp:set(ip,"black2byDeny",0,3)
				else
					_Conf.dict_byDenyIp:set(ip,"black2byDeny",_Conf.byDenyIpModules.blockTime,4)
				end
			end
		else
			_Conf.dict_challenge:set(challengeTimesKey,1,_Conf.byDenyIpModules.amongTime)
		end
	end
end

--USER Agent过滤
function Guard:userAgent(userAgent,httpReferer,ip,reqUri)
	--return: 是否不再做其他过滤
		--true 是
		--fase 否
	if _Conf.userAgentIsOn then
		--userAgent匹配 userAgentAllowProtect 正则的直接拒绝
		if _Conf.userAgentAllowIsOn then
			if ngx.re.match(userAgent,_Conf.userAgentAllowProtect,"ijo") then
				self:debug("[userAgent] userAgent allow. userAgent match userAgentAllowProtect".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
				--ngx.header.content_type = "text/html"
				--ngx.exit(403)
				self:forbiddenAction()
				return true
			end
		end
		
		--userAgent匹配 userAgentDenyProtect 正则的直接拒绝
		if ngx.re.match(userAgent,_Conf.userAgentDenyProtect,"ijo") then
			self:debug("[userAgent] userAgent deny. userAgent match userAgentDenyProtect".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
			--ngx.header.content_type = "text/html"
			--ngx.exit(403)
			self:forbiddenAction()
			return true
		end
	end
	return false
end

--HTTP Referer过滤
function Guard:httpReferer(userAgent,referer,ip,reqUri)
	--return: 是否不再做其他过滤
		--true 是
		--fase 否
	if _Conf.httpRefererIsOn then
		--httpReferer匹配 httpRefererAllowProtect 正则的直接过
		if _Conf.httpRefererAllowIsOn then
			if ngx.re.match(referer,_Conf.httpRefererAllowProtect,"ijo") then
				self:debug("[httpReferer] httpReferer allow. httpReferer match httpRefererAllowProtect".."::"..userAgent.."::"..referer.."::",ip,reqUri)
				return false
			end
		end

		--httpReferer匹配 httpRefererDenyProtect 正则的直接拒绝
		if ngx.re.match(referer,_Conf.httpRefererDenyProtect,"ijo") then
			self:debug("[httpReferer] httpReferer deny. httpReferer match httpRefererDenyProtect".."::"..userAgent.."::"..referer.."::",ip,reqUri)
			--ngx.header.content_type = "text/html"
			--ngx.exit(403)
			self:forbiddenAction()
			return true	
		end
	end
	return false
end

--URL过滤(仅allow)
function Guard:urlFilterAllow(userAgent,httpReferer,ip,reqUri,address)
	--return: 是否不再做其他过滤
		--true 是
		--fase 否
	if _Conf.urlFilterModulesIsOn then
		if _Conf.urlAllowIsOn then	
			if ngx.re.match(reqUri,_Conf.urlAllowProtect,"ijo") then
				self:debug("[urlFilter] url allow. URL match urlAllowProtect".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
				return true
			end
		end
	end
	return false
end

--URL过滤
function Guard:urlFilter(userAgent,httpReferer,ip,reqUri,address)
	--return: 是否不再做其他过滤
		--true 是
		--fase 否
	if _Conf.urlFilterModulesIsOn then
		--URL匹配 urlAllowProtect 正则的直接过
		if _Conf.urlAllowIsOn then	
			if ngx.re.match(reqUri,_Conf.urlAllowProtect,"ijo") then
				self:debug("[urlFilter] url allow. URL match urlAllowProtect".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
				return true
			end
		end
		
		--URL匹配 urlDenyProtect 正则的直接拒绝
		if _Conf.urlDenyIsOn then
			for _, rule in pairs(_Conf.urlDenyProtect) do
				if ngx.re.match(address,rule,"ijo") then
					self:debug("[urlFilter] URL deny. URL match urlDenyProtect".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
					--ngx.header.content_type = "text/html"
					--ngx.exit(403)
					self:forbiddenAction()
					return true
				end
			end
		end
	end
	return false
end

--POST Args过滤
function Guard:postFilter(ip,reqUri)
	--return: 是否不再做其他过滤
		--true 是
		--fase 否	
	if _Conf.postArgsFilterIsOn then
		local get_method = ngx.req.get_method()
		if get_method == "POST" then	
			ngx.req.read_body()
			local args, err = ngx.req.get_post_args(1009)	--获取post参数
			if args then
				for k, v in pairs(args) do
					if type(v) == "table" then
						v = table.concat(v, ", ")
					end
					if v and not (type(v) == "boolean") then
						for _,rule in pairs(_Conf.postArgsDenyProtect) do
							local m, err = ngx.re.match(v,rule,"ijo" )
							if m then		--post args 匹配 postArgsDenyProtect 的直接拒绝
								self:debug("[postFilter] POST arg:"..m[0].." is deny ",ip,reqUri)
								--ngx.header.content_type = "text/html"
								--ngx.exit(403)
								self:forbiddenAction()
								return true
							end
						end
					end
				end
			end
		end
	end
	return false
end

--GET Args过滤
function Guard:getArgsFilter(ip,reqUri)
	--return: 是否不再做其他过滤
		--true 是
		--fase 否
	if _Conf.getArgsFilterIsOn then
		local args = ngx.req.get_uri_args(1009)		--获取request URL请求的参数
		if args then
			for k, v in pairs(args) do
				if type(v) == "table" then
					v = table.concat(v, " ")
				end
				if v and not (type(v) == "boolean") then
					for _, rule in pairs(_Conf.getArgsDenyProtect) do	
						local f, t, err = ngx.re.find(v,rule,"ijo")
						if f then
							self:debug("[getArgsFilter] GET arg:"..string.sub(v, f, t).." is deny ",ip,reqUri)
							--ngx.header.content_type = "text/html"
							--ngx.exit(403)
							self:forbiddenAction()
							return true
						end
					end
				end
			end
		end
	end
	return false
end

--COOKIE Args过滤
function Guard:cookieArgsFilter(ip,reqUri)
	--return: 是否不再做其他过滤
		--true 是
		--fase 否
	if _Conf.cookieArgsFilterIsOn then
		local args = ngx.var.http_cookie		--获取cookie参数
		if args and not (type(args) == "boolean") then
			for _, rule in pairs(_Conf.cookieArgsDenyProtect) do
				local f, t, err = ngx.re.find(args,rule,"ijo")
				if f then
					self:debug("[cookieArgsFilter] Cookie arg:"..string.sub(args, f, t).." is deny ",ip,reqUri)
					--ngx.header.content_type = "text/html"
					--ngx.exit(403)
					self:forbiddenAction()
					return true
				end
			end
		end
	end
	return false
end

--rateLimit访问频率限制
--符合条件的请求直接丢弃
function Guard:rateLimit(ip,reqUri,address,userAgent,httpReferer)
	if _Conf.rateLimitIsOn then
		local urlTab = _Conf.rateLimitUrlProtect
		for k, v in pairs(urlTab) do
			local f, t, err = ngx.re.find(address,v[1],"ijo")
			if f then
				local rateLimitKey = ip.."ratelimit"..k
				local rateLimitKeyBig = ip.."ratelimitBig"..k
				local inRateLimitList = _Conf.dict_others:get(rateLimitKey)
				local challengeTimesValueBig = _Conf.dict_challenge:get(rateLimitKeyBig) or 0

				local rateIncr, rateIncrErr = _Conf.dict_challenge:incr(rateLimitKeyBig,1)	--rateLimitKeyBig challenge 加1
				if rateIncrErr then
					_Conf.dict_challenge:set(rateLimitKeyBig,1,_Conf.rateLimit.bigAmongTime)
				end
				if _Conf.rate2byDenyStateIsOn and (challengeTimesValueBig + 1 > v[3]) then
					_Conf.dict_byDenyIp:set(ip,"rate2byDeny",_Conf.rateLimit.bigBlockTime,6)                --添加IP到byDeny列表
					self:log("[rateLimit] bigRate exceed "..v[3].." within ".._Conf.rateLimit.bigAmongTime.." add this ip to byDeny list: "..ip)
					local blackKey = ip.."black"
					if _Conf.dict_black:get(blackKey) then --如果黑名单中有该IP, 则删除
						_Conf.dict_black:delete(blackKey)
					end
				end				
				
				--在rateLimit列表的直接拒绝,返回提示页面
				if inRateLimitList then
					self:toHomePage()
					self:debug("[rateLimit] "..rateLimitKey.. " in rateLimitDenyList ",ip,reqUri)
					return true
				--若不在rateLimi列表的,则在challenge列表记录其访问频率
				else
					--小频率访问challenge情况
					if _Conf.rateStateIsOn then
						local challengeTimesValue = _Conf.dict_challenge:get(rateLimitKey)
						if challengeTimesValue then
							_Conf.dict_challenge:incr(rateLimitKey,1)
							if challengeTimesValue + 1 > v[2] then
								_Conf.dict_others:set(rateLimitKey,6,_Conf.rateLimit.blockTime)
								self:debug("[rateLimit] "..rateLimitKey.. " request exceed "..v[2]..", added to rateLimitDenyList",ip,reqUri)
							end
						else
							_Conf.dict_challenge:set(rateLimitKey,1,_Conf.rateLimit.amongTime)
						end
					end
					
					--大频率访问challenge情况
					if _Conf.bigRateStateIsOn then
						--local challengeTimesValueBig = _Conf.dict_challenge:get(rateLimitKeyBig) or 0
						if challengeTimesValueBig + 1 > v[3] then
							_Conf.dict_others:set(rateLimitKey,4,_Conf.rateLimit.bigBlockTime)
							self:debug("[rateLimit] "..rateLimitKeyBig.. " request exceed "..v[3]..", added to rateLimitDenyList",ip,reqUri)
						end
					end
				end
				return false
			end
		end
	end
	return false
end

--返回首页
function Guard:toHomePage()
	homePage = [[
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" >
<title>提示</title>
<style type="text/css">
	#content { position:absolute;width:400px;height:200px;left:50%;top:50%;margin-left:-200px;margin-top:-100px;vertical-align:middle;line-height:200px;text-align:center;font-family:"微软雅黑";font-size:16px } 
	a:link, a:visited, a:hover, a:active { text-decoration:none;color:000; }
</style>
<script type="text/javascript">
	function countDown(secs,tUrl){ var jumpTo = document.getElementById("jumpTo"); jumpTo.innerHTML=secs; if (--secs>0){ setTimeout("countDown("+secs+",'"+tUrl+"')",1000); } else{ window.location.href=tUrl; } }
</script>
</head>
<body>
	<div id="content" ><a href="/">您的访问过于频率，累了歇会吧&nbsp;...&nbsp;（返回首页）</a> &nbsp; <span id="jumpTo">6</span>&Prime; <script type="text/javascript">countDown(6,"/");</script> </div>
</body>
</html>
]]
	ngx.header.content_type = "text/html"
	ngx.print(homePage)
	ngx.exit(200)
	
end

--杂项访问控制
function Guard:others(userAgent,httpReferer,ip,reqUri,address)
	if _Conf.othersIsOn then
		-- 显示 _Conf.showPostArgAndCookieArgPages URL中的PostArg、CookieArg值
		if _Conf.showPostArgAndCookieArgStateOn then
			local f, t, err = ngx.re.find(address,_Conf.showPostArgAndCookieArgPages,"ijo")
			if f then
				local cookieArgs = ngx.var.http_cookie		--获取cookie参数
				if cookieArgs and not (type(cookieArgs) == "boolean") then
					self:debug("[others] Cookie arg:"..cookieArgs,ip,reqUri)		--输出Cookie Args到debug日志
				end
				
				local get_method = ngx.req.get_method()
				if get_method == "POST" then
					ngx.req.read_body()
					local postArgs, err = ngx.req.get_post_args(1009)	--获取post参数
					if postArgs then
						local getPostArgs = ''
						for k, v in pairs(postArgs) do 
							if type(v) == "table" then
								v = table.concat(v, ", ")
							end
							if v and not (type(v) == "boolean") then
								getPostArgs = table.concat({ getPostArgs, k, "=", v, "&" })
							end
						end
						if getPostArgs then
							self:debug("[others] POST Args: "..getPostArgs,ip,reqUri)		--输出Post Args到debug日志
								
						end
					end
				end
			
			end
		end
		
		-- 访问 _Conf.noneRefererPages 中指定的URL且Referer 为空, 则直接拒绝, 并添加该IP到黑名单
		if ngx.re.match(address,_Conf.noneRefererPages,"ijo") and (httpReferer == "http_refere_NONE") then
			local blackKey = ip.."black"
			_Conf.dict_black:set(blackKey,6,_Conf.blockTime) --添加此ip到黑名单
			self:debug("[others] "..address.." match noneRefererPages,referer is none ::"..userAgent,ip,reqUri)
			ngx.header.content_type = "text/html"
			ngx.exit(200)
			return true
		end
		
	end
	return false
end

--一键开启验证
function Guard:oneKeyOpenVerification(ip,reqUri,address,userAgent,httpReferer)
	local whiteKey = ip.."whiteVerification"
	local inWhiteList = _Conf.dict_white:get(whiteKey)

	if inWhiteList then --如果在白名单
		self:debug("[oneKeyOpenVerification] in white ip list.".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
		return
	else
		local blackKey = ip.."black"
		_Conf.dict_black:set(blackKey,0,_Conf.blockTime) --添加此ip到黑名单
	end	
end

--perUrlRateLimit访问频率限制
--符合条件的请求需要验证验证码
function Guard:perUrlRateLimit(ip,reqUri,address,userAgent,httpReferer)
	--return: 是否不再做其他过滤
		--true 是
		--fase 否
	--判断用户IP是否在WhiteList中, 在则直接通过
	if _Conf.perUrlRateLimitIsOn then
		local f, t, err = ngx.re.find(address, _Conf.perUrlRateLimitUrlProtect, "ijo")
		if f then
			local whiteKey = ip.."whitePerUrlRateLimit"
			local inWhiteList = _Conf.dict_white:get(whiteKey)
			if inWhiteList then		-- 在byWhite名单时直接通过
				return true
			end
				
			--address建议取decode的uri
			if _Conf.urlIgnoreCaseIsOn then		-- url转成小写
				address = string.lower(address)
			end
			local ipUrl = ip..address
				
			if _Conf.perUrlRateLimit.direct2byDeny ~= 0 then	-- 直接黑名单模式
				self:perUrlRateLimitDirect2byDeny(ip,reqUri,address,userAgent,httpReferer,ipUrl)
			else		-- 验证模式
				-- 是否在perUrlRateLimitVerity验证列表中
				--local inNeedVerify = _Conf.dict_needVerify:get(ip)
				--if inNeedVerify then		--在needVerify验证列表中，执行验证码验证
				--	self:captchaAction(ip,reqUri,address)
				--	return true
				--else		--不在PerUrlRateLimitList验证列表中，执行PerUrlRateLimit过滤			
					--if ngx.re.match(address,_Conf.perUrlRateLimitUrlProtect,"ijo") then
					--应用模式
					if _Conf.perUrlRateLimit.model ~= 0 then
						if _Conf.perUrlRateLimit.model == 1 then		--应用white临时白名单模式
							if _Conf.cookieModulesIsOn then
								local whiteKey = ip.."whitecookie"
								local inWhiteList = _Conf.dict_white:get(whiteKey)	
								if inWhiteList then
									self:debug("[cookieModules] in white ip list.".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
									return true
								end
							end
							if _Conf.redirectModulesIsOn then
								local whiteKey = ip.."white302"
								local inWhiteList = _Conf.dict_white:get(whiteKey)		
								if inWhiteList then
									self:debug("[redirectModules] in white ip list",ip,reqUri)
									return true
								end
							end
							if  _Conf.JsJumpModulesIsOn then
								local whiteKey = ip.."whitejs"
								local inWhiteList = _Conf.dict_white:get(whiteKey)		
								if inWhiteList then
									self:debug("[JsJumpModules] in white ip list",ip,reqUri)
									return true
								end
							end
							
						elseif _Conf.perUrlRateLimit.model == 2 then		--request中是否含cookie模式
							local cookie_key = ngx.var["cookie_keycookie"] --获取cookie密钥
							local cookie_expire = ngx.var["cookie_expirecookie"] --获取cookie密钥过期时间
							if cookie_key and cookie_expire then 
								return true
							else
								local now = ngx.time()
								local expire = now + _Conf.keyExpire
								local key_new = ngx.md5(table.concat({ip,_Conf.cookieModules.keySecret,expire}))
								local key_new = string.sub(key_new,"1","10")
								
								self:debug("[perUrlRateLimit] send cookie to client.".."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
								ngx.header['Set-Cookie'] = {"keycookie="..key_new.."; path=/", "expirecookie="..expire.."; path=/"} --发送cookie凭证
							end
						end
					end
					
					local challengeTimesValue = _Conf.dict_challenge:get(ipUrl)
					--local maxReqs = _Conf.dict_system:get(address) or _Conf.perUrlRateLimit.defaultMaxReqs
					if challengeTimesValue then
						_Conf.dict_challenge:incr(ipUrl,1)
						local maxReqs = _Conf.dict_system:get(address) or _Conf.perUrlRateLimit.defaultMaxReqs
						if challengeTimesValue +1 > maxReqs then	--超过了perUrlRateLimit最大请求数
							self:debug("[perUrlRateLimit] .".."challengeTimesValue:"..challengeTimesValue.." maxReqs:"..maxReqs.."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
							local inPerUrlRateLimitTimes = _Conf.dict_perUrlRateLimit:get(ip)
							if inPerUrlRateLimitTimes then
								_Conf.dict_perUrlRateLimit:incr(ip, 1)
							else
								_Conf.dict_perUrlRateLimit:set(ip, 1, _Conf.perUrlRateLimit.inPerUrlRateLimitAmongTime)
							end
							_Conf.dict_challenge:set(ipUrl, 0, _Conf.perUrlRateLimit.amongTime)		--challenge计数器重置为0
							self:log("[perUrlRateLimit] "..ipUrl.." request "..challengeTimesValue.." exceed "..maxReqs.."'/".._Conf.perUrlRateLimit.amongTime.."s")
						end
					else
						_Conf.dict_challenge:set(ipUrl, 1, _Conf.perUrlRateLimit.amongTime)
					end
					
					--进入urlRateLimit次数是否超了限制次数
					local inUrlRateLimitTimes = _Conf.dict_perUrlRateLimit:get(ip) or 0
					--进入urlRateLimit次数超过了限制次数则把该IP添加到perUrlRateLimitVerity验证列表中
					if inUrlRateLimitTimes >= _Conf.perUrlRateLimit.inPerUrlRateLimitMaxTimes then
						_Conf.dict_needVerify:set(ip, 1, _Conf.perUrlRateLimit.verifyBlockTime)						
						self:log("[perUrlRateLimit] within ".._Conf.perUrlRateLimit.inPerUrlRateLimitAmongTime.." exceed "..inUrlRateLimitTimes.." block in inUrlRateLimit")
					end
					return false
					--end
				--end
			end
		end
		
	end
	return false
end

--perUrlRateLimitVerify验证验证成功后， challenge列表、urlRateLimit列表、urlRateLimitVerify验证列表 清除相关记录
function Guard:perUrlRateLimitVerifyOK(ip,reqUri,address)
	if _Conf.perUrlRateLimitIsOn then
		local ipUrl = ip..address
		local whiteKey = ip.."whitePerUrlRateLimit"
		--添加WhiteList白名单
		_Conf.dict_white:set(whiteKey,0,_Conf.perUrlRateLimit.verifyOkTime)
		
		--删除在challenge中的记录
		_Conf.dict_challenge:delete(ipUrl)
		
		--删除在urlRateLimit中的记录
		_Conf.dict_perUrlRateLimit:delete(ip)
		
		--删除在urlRateLimitVerify中的记录
		_Conf.dict_needVerify:delete(ip)
		
		--记录perUrlRateLimitVerify验证验证成功次数，记录在dict_perUrlRateLimit字典中
		local perUrlRateLimitVerifySuccessKey = ip.."Verified"
		local perUrlRateLimitVerifyTimes = _Conf.dict_perUrlRateLimit:get(perUrlRateLimitVerifySuccessKey)
		if perUrlRateLimitVerifyTimes then
			_Conf.dict_perUrlRateLimit:incr(perUrlRateLimitVerifySuccessKey, 1)
			--判断是否要加入到byDeny名单
			if _Conf.perUrlRateLimit2ByDenyIsOn then
				perUrlRateLimitVerifyTimes = perUrlRateLimitVerifyTimes + 1
				if perUrlRateLimitVerifyTimes >= _Conf.perUrlRateLimit.perUrlRateLimitVerifySuccessMax then
					_Conf.dict_byDenyIp:set(ip, "perUrlRateLimit2ByDeny", _Conf.perUrlRateLimit.inByDenyTime, 8)
					--local perUrlRateLimitVerifyTimesVal = perUrlRateLimitVerifyTimes + 1
					self:log("[perUrlRateLimitVerifyOK] IP "..ip.." perUrlRateLimitVerify "..perUrlRateLimitVerifyTimes.." times,add the ip to byDeny list.")
				end
			end
				
		else
			_Conf.dict_perUrlRateLimit:set(perUrlRateLimitVerifySuccessKey, 1, _Conf.perUrlRateLimit.toByDenyAmongTime)
		end
		
	end
	return 0
end

--perUrlRateLimit直接黑名单模式
function Guard:perUrlRateLimitDirect2byDeny(ip,reqUri,address,userAgent,httpReferer,ipUrl)
	local challengeTimesValue = _Conf.dict_challenge:get(ipUrl)
	--local maxReqs = _Conf.dict_system:get(address) or _Conf.perUrlRateLimit.defaultMaxReqs
	if challengeTimesValue then
		_Conf.dict_challenge:incr(ipUrl,1)
		local maxReqs = _Conf.dict_system:get(address) or _Conf.perUrlRateLimit.defaultMaxReqs
		local newReqTimes = challengeTimesValue +1
		if newReqTimes > maxReqs then	--超过了perUrlRateLimit最大请求数
			self:debug("[perUrlRateLimitDirect2byDeny] .".."challengeTimesValue:"..challengeTimesValue.." maxReqs:"..maxReqs.."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)

			if _Conf.perUrlRateLimit.direct2byDeny == 1 then
				local blackKey = ip.."black"
				if not _Conf.dict_black:get(blackKey) then
					_Conf.dict_black:set(blackKey,8,_Conf.blockTime) --添加此ip到black黑名单	
					self:log("[perUrlRateLimitDirect2byDeny] IP "..ip.." request "..newReqTimes.." times,add the ip to black list.")
				end
			elseif _Conf.perUrlRateLimit.direct2byDeny == 2 then
				if not _Conf.dict_byDenyIp:get(ip) then	
					_Conf.dict_byDenyIp:set(ip,"perUrlRateLimitDirect2byDeny",_Conf.perUrlRateLimit.inByDenyTime,8)	--添加此ip到byDeny黑名单
					self:log("[perUrlRateLimitDirect2byDeny] IP "..ip.." request "..newReqTimes.." times,add the ip to byDeny list.")
				end
			end
			
		end
	else
		_Conf.dict_challenge:set(ipUrl, 1, _Conf.perUrlRateLimit.amongTime)
	end
	
end

--在needVerify验证列表中的IP，执行验证码验证
function Guard:needVerify(ip,reqUri,address)
	local inNeedVerify = _Conf.dict_needVerify:get(ip)
	if inNeedVerify then		--在needVerify验证列表中，执行验证码验证
		self:captchaAction(ip,reqUri,address)
		return true
	end
	return false
end

--随机延时处理URL
function Guard:randomDelayProcessing(ip,reqUri,address,userAgent,httpReferer)
	--return: 是否不再做其他过滤
		--true 是
		--fase 否
	if _Conf.randomDelayProcessingIsOn then
		local f, t, err = ngx.re.find(address, _Conf.randomDelayProcessingUrlProtect, "ijo")
		if f then
			local rmdTime = _Conf.randomTime()		--生产随机时间差
			self:debug("[randomDelayProcessing] ".."start timestamp:"..ngx.time().." randomTime:"..rmdTime.."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
			ngx.sleep(rmdTime)		--睡眠处理
			self:debug("[randomDelayProcessing] ".."end timestamp:"..ngx.time().." randomTime:"..rmdTime.."::"..userAgent.."::"..httpReferer.."::",ip,reqUri)
		end
	end
	return false
end

return Guard














