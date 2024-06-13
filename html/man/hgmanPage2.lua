-- hgmanPage2

local hgmanPage = [[
<!doctype html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" >
<title>HttpGuard Management</title>

<link rel="stylesheet" type="text/css" href="/hg_src/hg.css" >
<script src="/hg_src/jquery.js"></script>
<script src="/hg_src/hg.js"></script>

</head>

<body>
    <div id="container">
        <div id="header">
            <div id=biaoTi>
                <p class="string-1" >HttpGuard Management</p>
            </div>
            <form name="frmPost1" action="/update_list" method="POST" target="hiddenIframe" >
                <span class="put">
                                        
                    <label><input name="addDel" type="radio" value="add" checked="CHECKED" >+</label>
                    <label><input name="addDel" type="radio" value="del">-</label>
                    <label><input name="addDel" type="radio" value="all-">All-</label>
                    <label><input name="addDel" type="radio" value="w+">w+</label>&nbsp;&nbsp;&nbsp;&nbsp;
                    IP：<textarea name="ip_put" id="ip_put" cols="35" rows="5"></textarea>&nbsp;&nbsp;&nbsp;&nbsp;
                    Expire：<input type="text" size="6" name="custom_Time" onKeyUp="num(custom_Time)" onKeyDown="num(custom_Time)" >s &nbsp;&nbsp;&nbsp;&nbsp;
                    名单：
                    <select name="list_type">
                        <option value="byDeny">byDeny</option>
                        <option value="byWhite">byWhite</option>
                        <option value="black" selected="selected">black黑名单</option>
                        <option value="white302">white302跳转</option>
                        <option value="whitejs">whiteJS跳转</option>
                        <option value="whitecookie">whiteCookie</option>
                        <option value="challenge">challenge</option>
                        <option value="rateLimit">rateLimitDeny</option>
                        <option value="whitePerUrlRateLimit">whitePerUrlRateLimit</option>
                        <option value="perUrlRateLimit">perUrlRateLimit</option>
                        <option value="needVerify">needVerify</option>
                    </select> &nbsp;&nbsp;&nbsp;&nbsp;
                    注释：<input type="text" size="12" name="comment" >
                </span>
                <input class="btn1" type="submit" value="确定" >
            </form>
            <iframe style="display:none" name="hiddenIframe" id="hiddenIframe" ></iframe>
        </div>

        <div id="main">
            <div class="rateLimit">
                <iframe src="/rlist" id="rPage" name="rPage" width="100%" onLoad="iframeHeight(id)" frameborder=0 ></iframe>
            </div>
            <div class="list">
                <iframe src="/perUrlRateLimit" id="perUrlRateLimitPage" name="perUrlRateLimitPage" width="100%" onLoad="iframeHeight(id)" frameborder=0 ></iframe>
            </div>
            <div class="list">
                <iframe src="/needVerify" id="needVerifyPage" name="needVerifyPage" width="100%" onLoad="iframeHeight(id)" frameborder=0 ></iframe>
            </div>
        </div>

    </div>
<div id="goToTop"><span>^Top</span></div>
<div id="goToLeft"><span><a href="/hgman"><<-</a></span></div>
]]

ngx.say(hgmanPage)
ngx.say('<div id="Ta"><a href="/hgman">updateList</a>&nbsp;&nbsp;<a href="/hgsystem">updateSystem</a>&nbsp;&nbsp;<a href="#" id="user_logout">Logout</a> &nbsp;&nbsp;&nbsp;Version: ', _Conf.hg_version, '</div>')
ngx.say('</body>')
ngx.say('</html>')
