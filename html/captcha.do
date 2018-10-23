<!DOCTYPE HTML>
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
	<title>输入验证码</title>

    <script>
        function getYear(){
            var date=new Date;
            var year=date.getFullYear();
            return year;
        }
    </script>
    <style type="text/css">
        body{background:#fff;}
        .foot{padding: 45px;text-align: center;color: #000;font-size: 12px;background:#f8f8f8;font-family: "微软雅黑",Arial, Helvetica,sans-serif,"宋体";border-top:1px solid #e6e6e6;}
        *{margin:0;padding:0;}
        .myhead{width:100%;height:99px;border-bottom:1px solid #e7e7e7;opacity:0.5;}
        #contain{width:972px;position:relative;margin:0 auto;height:432px;padding-top:205px;}
        .logo{background:url("//image.tuandai.com/httpGuardImg/logo.jpg") no-repeat center;width:376px;height:71px;position:absolute;left:0;top:-90px;}
        .left-box{background:url("//image.tuandai.com/httpGuardImg/2.jpg") no-repeat center;width:203px;height:198px;float:left;margin-top: 25px;margin-right:48px;margin-left:160px;}
        .right-box{float:left;}
        .circle1{float:left;margin-left:0px; margin-top: 5px;width:40px; height:40px; background-color:#F00; border-radius:25px;}
        .circle2{height:40px; line-height:40px; display:block; color:#FFF; text-align:center; font-size:34px}
        .note{font-family: "微软雅黑",Arial, Helvetica,sans-serif,"宋体";font-size:34px;color:#ffc603;}
        .right-box .up p{font-size:20px;color:#767676;font-family: "微软雅黑",Arial, Helvetica,sans-serif,"宋体";margin-top:27px;margin-bottom:28px;}
        .right-box .down .num{width:160px;height:40px;float:left;margin-right:18px;}

        .right-box .down .word{width:245px;height:38px;float:left;border:1px solid #dcdcdc;}
        .right-box .down .btn{width:70px;height:38px;background-color:#56c458;float:left;text-align:center;font-size:16px;color:#fff;font-weight:bold;line-height:32px;margin-left:16px;margin-top:2px;cursor:pointer;}
        a{text-decoration:none;color:#000;}
    </style>

</head>
<body>
<div class="myhead">

</div>
<div id="contain">
    <div class="logo"></div>
    <div class="left-box">
    </div>
    <div class="right-box">
        <div class="up">
            <div class="circle1">
                <span class="circle2">!</span>
            </div>
            <span class="note">&nbsp;很抱歉...</span>
            <p>您的请求过于频繁，请输入验证码</p>
            <p>&nbsp;</p>
        </div>
        <div class="down">
            <form action="/verify-captcha.do" method="POST">
                <div class="num"><img src="/get-captcha.do" alt="Captcha image" onclick="window.location.reload()"></div>
                <input class="word" type="text" name="response">
                <input class="btn" type="submit" value="确定" >
            </form>
        </div>
    </div>
</div>
<div class="foot">
    &copy;2010-<script>document.write(getYear());</script> Tuandai.com 版权所有
    <a href="http://www.miitbeian.gov.cn" target="_blank" rel="noflow">粤ICP备12043601号-1</a>
    <a rel="external nofollow" href="http://www.beian.gov.cn/portal/registerSystemInfo?recordcode=44190002000538" target="_blank">粤公网安备44190002000538号</a>
    &nbsp;&nbsp;东莞团贷网互联网科技服务有限公司 地址：东莞市南城街道莞太路111号众创金融大厦1号楼28楼
</div>
</body>

</html>
