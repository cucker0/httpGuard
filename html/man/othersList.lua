local hh = "<br>"
local kg1 = "&nbsp;&nbsp;"
local kg2 = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
local dict_others = ngx.shared.dict_others
local othersKey = dict_others:get_keys(0)
local total = 0
--local ip = ''

--从字典检出key
local function checkKey(keyType)
    --local total = 0
    --local key = ''
    for k, v in pairs(othersKey) do
        local matchKey = string.match(v, keyType)
        if matchKey then
            local val, fla = dict_others:get(v)
            --key = table.concat({ key, v, kg1, val,hh })
            ngx.say(v, kg1, val, hh)
            total = total + 1
        end
    end
    --return key, total
end

--local rateLimitDenyKey, rateLimitDenyTotal = checkKey("ratelimit")



--打印攻击名单
ngx.say("<html>")
ngx.say("<head>")
ngx.say('<meta http-equiv="Content-Type" content="text/html; charset=utf-8" >')
ngx.say("<title>RateLimitDeny List</title>")
ngx.say("<style>")
ngx.say('  #container { width:100%; height:auto; margin-top:36px; float:left; font-family:"宋体"; font-size:14px; word-wrap:break-word;}')
ngx.say('  #listHead { position:fixed; width:100%; height:auto; top:8px; font-family:"宋体"; font-size:14px; }')
ngx.say("</style>")
ngx.say("</head>")
ngx.say("<body>")
ngx.say('<div  id = "container" >')

checkKey("ratelimit")

ngx.say("</div>")
ngx.say('<div id = "listHead">')
ngx.say("  <a href = ../rlist >RateLimitDenyList: </a>",hh)
ngx.say("  Keys[ ", total, " ] ", kg2, "Values")
ngx.say("</div>")
ngx.say("</body>")
ngx.say("</html>")
