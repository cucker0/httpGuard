local hh = "<br>"
local kg1 = "&nbsp;&nbsp;"
local kg2 = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
local dict_challenge = ngx.shared.dict_challenge
local challengeKey = dict_challenge:get_keys(0)
local total = 0
local ip = ''
local challengeExpire = 0
if _Conf.redirectModulesIsOn then		
	challengeExpire = _Conf.redirectModules.amongTime
elseif  _Conf.JsJumpModulesIsOn then
	challengeExpire = _Conf.JsJumpModules.amongTime
elseif _Conf.cookieModulesIsOn then
	challengeExpire = _Conf.cookieModules.amongTime
end


--打印攻击名单
ngx.say("<html>")
ngx.say("<head>")
ngx.say('<meta http-equiv="Content-Type" content="text/html; charset=utf-8" >')
ngx.say("<title>Challenge List</title>")
ngx.say("<style>")
ngx.say('  #container { width:100%; height:auto; margin-top:36px; float:left; font-family:"宋体"; font-size:14px; word-wrap:break-word;}')
ngx.say('  #listHead { position:fixed; width:100%; height:auto; top:8px; font-family:"宋体"; font-size:14px; }')
ngx.say("</style>")
ngx.say("</head>")
ngx.say("<body>")
ngx.say('<div  id = "container" >')


for k,v in pairs(challengeKey) do
        local val, fla = dict_challenge:get(v)
	ngx.say(v, kg1, val,hh)
        total = total + 1
end

ngx.say("</div>")
ngx.say('<div id = "listHead">')
ngx.say("  <a href = ../clist >ChallengeList: </a>", hh)
ngx.say("  Keys[ ", total, " ]   ", "Values  ", "Expire(", challengeExpire, "s)")
ngx.say("</div>")
ngx.say("</body>")
ngx.say("</html>")
