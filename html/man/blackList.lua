local hh = "<br>"
local kg1 = "&nbsp;&nbsp;"
local dict_black = ngx.shared.dict_black
local blackKey = dict_black:get_keys(0)
local total = 0
local blackExpire = _Conf.blockTime


--打印黑名单
ngx.say("<html>")
ngx.say("<head>")
ngx.say('<meta http-equiv="Content-Type" content="text/html; charset=utf-8" >')
ngx.say("<title>Black List</title>")
ngx.say("<style>")
ngx.say('  #container { width:100%; height:auto; margin-top:36px; float:left; font-family:"宋体"; font-size:14px; word-wrap:break-word;}')
ngx.say('  #listHead { position:fixed; width:100%; height:auto; top:8px; font-family:"宋体"; font-size:14px; }')
ngx.say("</style>")
ngx.say("</head>")
ngx.say("<body>")
ngx.say('<div  id = "container" >')

for k, v in pairs(blackKey) do
    local val, fla, sta = dict_black:get_stale(v)
    ngx.say(v, kg1, val, hh)
    total = total + 1
end

ngx.say("</div>")
ngx.say('<div id = "listHead">')
ngx.say("  <a href = ../blist > BackList: </a>",hh)
ngx.say("  Keys[ ", total, " ]  ", "Values  ", "Expire(", blackExpire, "s)")
ngx.say("</div>")
ngx.say("</body>")
ngx.say("</html>")
