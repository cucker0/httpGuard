local hh = "<br>"
local kg1 = "&nbsp;&nbsp;"
local kg2 = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
local dict_needVerify = ngx.shared.dict_needVerify
local needVerifyKey = dict_needVerify:get_keys(0)
local total = 0
local verifyExpire = _Conf.blockTime


--打印perUrlRateLimitVerify名单
ngx.say("<html>")
ngx.say("<head>")
ngx.say('<meta http-equiv="Content-Type" content="text/html; charset=utf-8" >')
ngx.say("<title>needVerify List</title>")
ngx.say("<style>")
ngx.say('  #container { width:100%; height:auto; margin-top:36px; float:left; font-family:"宋体"; font-size:14px; word-wrap:break-word;}')
ngx.say('  #listHead { position:fixed; width:100%; height:auto; top:8px; font-family:"宋体"; font-size:14px; }')
ngx.say("</style>")
ngx.say("</head>")
ngx.say("<body>")
ngx.say('<div  id = "container" >')

for k, v in pairs(needVerifyKey) do
    --local val, fla = dict_needVerify:get(v)
    --ngx.say(v, kg1, val,hh)
    ngx.say(v, hh)
    total = total + 1
end

ngx.say("</div>")
ngx.say('<div id = "listHead">')
ngx.say("  <a href = ../needVerify >needVerify: </a>", hh)
ngx.say("  Keys[ ", total, " ]   ", "Expire(", verifyExpire, "s)")
ngx.say("</div>")
ngx.say("</body>")
ngx.say("</html>")

