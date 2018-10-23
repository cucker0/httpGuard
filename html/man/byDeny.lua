local hh = "<br>"
local kg1 = "&nbsp;"
local kg2 = "&nbsp;&nbsp;"
local dict_byDenyIp = ngx.shared.dict_byDenyIp
local byDenyKey = dict_byDenyIp:get_keys(0)
local total = 0


--打印byDenyIp List
ngx.say("<html>")
ngx.say("<head>")
ngx.say('<meta http-equiv="Content-Type" content="text/html; charset=utf-8" >')
ngx.say("<title>byDenyIp List</title>")
ngx.say("<style>")
ngx.say('	#container { width:100%; height:auto; margin-top:36px; float:left; font-family:"宋体"; font-size:14px; word-wrap:break-word;}')
ngx.say('	#listHead { position:fixed; width:100%; height:auto; top:8px; font-family:"宋体"; font-size:14px; }')
ngx.say("</style>")
ngx.say("</head>")
ngx.say("<body>")
ngx.say('<div  id = "container" >')

for k,v in pairs(byDenyKey) do
        local val, fla = dict_byDenyIp:get(v)
        if not fla then
                fla = "nil"
        end
        ngx.say(v, kg1, fla, kg1, val, hh)
        total = total + 1
end

ngx.say("</div>")
ngx.say('<div id = "listHead">')
ngx.say("	<a href = ../bydlist > byDenyIpList: </a>",hh)
ngx.say("	Keys[ ", total, " ] ",  kg2, "Flag", kg2, "Val(Comment)")
ngx.say("</div>")
ngx.say("</body>")
ngx.say("</html>")
