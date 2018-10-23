local hh = "<br>"
local kg1 = "&nbsp;&nbsp;"
local kg2 = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
local dict_perUrlRateLimit = ngx.shared.dict_perUrlRateLimit
local perUrlRateLimitKey = dict_perUrlRateLimit:get_keys(0)
local total = 0
local perUrlRateLimitExpire = _Conf.perUrlRateLimit.toByDenyAmongTime


--打印perUrlRateLimit名单
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


for k,v in pairs(perUrlRateLimitKey) do
        local val, fla = dict_perUrlRateLimit:get(v)
	ngx.say(v, kg1, val,hh)
        total = total + 1
end

ngx.say("</div>")
ngx.say('<div id = "listHead">')
ngx.say("  <a href = ../perUrlRateLimit >perUrlRateLimitList: </a>", hh)
ngx.say("  Keys[ ", total, " ]   ", "Values  ", "Expire(", perUrlRateLimitExpire, "s)")
ngx.say("</div>")
ngx.say("</body>")
ngx.say("</html>")
