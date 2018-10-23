function iframeHeight(pid) {   
	var ifm= document.getElementById(pid);   
	var subWeb = document.frames ? document.frames[pid].document : ifm.contentDocument;   
	if(ifm != null && subWeb != null) {
		ifm.height = subWeb.body.scrollHeight;
	}
}

function num(ob) {
	if (!ob.value.match(/^[\+\-]?\d*?\.?\d*?$/)) {
		ob.value = ob.t_value;
	}
	else {
		ob.t_value = ob.value;
	}
	if (ob.value.match(/^(?:[\+\-]?\d+(?:\.\d+)?)?$/)) {
		ob.o_value = ob.value;
	}
}

$(document).ready(function(){
	$("#goToTop").hide()//隐藏go to top按钮
	$(function(){
		$(window).scroll(function(){
			if($(this).scrollTop()>1){//当window的scrolltop距离大于1时，go to top按钮淡出，反之淡入
				$("#goToTop").show();
			}
			else {
				$("#goToTop").hide();
			}
		});
	});

	// 给go to top按钮一个点击事件
	$("#goToTop span").click(function(){
		$("html,body").animate({scrollTop:0},460);//点击go to top按钮时，以460的速度回到顶部
		return false;
	});

	//URl正则表达选择框
	$("#select1").change(function () {
		var str = jQuery("#select1 option:selected").val();
		if (str == "0") {
			$("#d0").attr("style","display:block;");
			$("#d1,#d12,#d2,#d3,#d4,#d5,#d52,#d6,#d7").attr("style","display:none;");
		}
		else if (str == "1") {
			$("#d1").attr("style","display:block;");
			$("#d0,#d12,#d2,#d3,#d4,#d5,#d52,#d6,#d7").attr("style","display:none;");
		}
		else if (str == "12") {
			$("#d12").attr("style","display:block;");
			$("#d0,#d1,#d2,#d3,#d4,#d5,#d52,#d6,#d7").attr("style","display:none;");
		}
		else if (str == "2") {
			$("#d2").attr("style","display:block;");
			$("#d0,#d1,#d12,#d3,#d4,#d5,#d52,#d6,#d7").attr("style","display:none;");
		}
		else if (str == "3") {
			$("#d3").attr("style","display:block;");
			$("#d0,#d1,#d12,#d2,#d4,#d5,#d52,#d6,#d7").attr("style","display:none;");
		}
		else if (str == "4") {
			$("#d4").attr("style","display:block;");
			$("#d0,#d1,#d12,#d2,#d3,#d5,#d52,#d6,#d7").attr("style","display:none;");
		}
		else if (str == "5") {
			$("#d5").attr("style","display:block;");
			$("#d0,#d1,#d12,#d2,#d3,#d4,#d52,#d6,#d7").attr("style","display:none;");
		}
		else if (str == "52") {
			$("#d52").attr("style","display:block;");
			$("#d0,#d1,#d12,#d2,#d3,#d4,#d5,#d6,#d7").attr("style","display:none;");
		}
		else if (str == "6") {
			$("#d6").attr("style","display:block;");
			$("#d0,#d1,#d12,#d2,#d3,#d4,#d5,#d52,#d7").attr("style","display:none;");
		}
		else if (str == "7") {
                        $("#d7").attr("style","display:block;");
                        $("#d0,#d1,#d12,#d2,#d3,#d4,#d5,#d52,#d6").attr("style","display:none;");
                }
	});

});

$(function(){
	$("#user_logout").on("click", function(e){
		// HTTPAuth Logout code
		e.preventDefault();
		try {
			// This is for Firefox
			$.ajax({
				// This can be any path on your same domain which requires HTTPAuth
				url: "/any/path",
				username: "reset",
				password: "reset",
				// If the return is 401, refresh the page to request new details.
				statusCode: { 401: function() {
						document.location = document.location;
					}
				}
			});
		} catch (exception) {
			// Firefox throws an exception since we didn't handle anything but a 401 above
			// This line works only in IE
			if (!document.execCommand("ClearAuthenticationCache")) {
				// exeCommand returns false if it didn't work (which happens in Chrome) so as a last
				// resort refresh the page providing new, invalid details.
				document.location = "http://reset:reset@" + document.location.hostname + document.location.pathname;
			}
		  }
	});
});

