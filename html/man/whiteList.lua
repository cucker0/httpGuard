local hh = "<br>"
local kg1 = "&nbsp;&nbsp;"
local dict_white = ngx.shared.dict_white
local whiteKey = dict_white:get_keys(0)
local total = 0
--local ip = ''
local whiteExpire = _Conf.whiteTime
local oneKeyOpenVerificationOn = _Conf.dict_system:get("oneKeyOpenVerificationOn")

if oneKeyOpenVerificationOn == 1 then
	local oneKeyOpenVerificationOn_whiteTime = _Conf.dict_system:get("oneKeyOpenVerification_whiteTime")
	whiteExpire = oneKeyOpenVerificationOn_whiteTime
end



--打印白名单
ngx.say("<html>")
ngx.say("<head>")
ngx.say('<meta http-equiv="Content-Type" content="text/html; charset=utf-8" >')
ngx.say("<title>White List</title>")
ngx.say("<style>")
ngx.say('  #container { width:100%; height:auto; margin-top:36px; float:left; font-family:"宋体"; font-size:14px; word-wrap:break-word;}')
ngx.say('  #listHead { position:fixed; width:100%; height:auto; top:8px; font-family:"宋体"; font-size:14px; }')
ngx.say("</style>")
ngx.say("</head>")
ngx.say("<body>")
ngx.say('<div  id = "container" >')

for k,v in pairs(whiteKey) do
        --local val, fla, sta = dict_white:get_stale(v)
        --ip = table.concat({ ip, v, hh })
	ngx.say(v, hh)
        total = total + 1
end

ngx.say("</div>")
ngx.say('<div id = "listHead">')
ngx.say("  <a href = ../wlist >WhiteList: </a>",hh)
ngx.say("  Keys[ ", total, " ]  ", "Expire(", whiteExpire, "s)")
ngx.say("</div>")
ngx.say("</body>")
ngx.say("</html>")
