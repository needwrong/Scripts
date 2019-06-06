#!/usr/bin/env ruby
# encoding=UTF-8

# 根据require或运行时提示安装对应的imgkit等依赖库
# 拉取Jenkins的数据接口，解析出近期打包作业的时间，生成highcharts图表
# 用于监控近期打包时间，超过一定阈值时，发送邮件给相关人作为提醒；需要配合同目录下的buildTimeGraph.html使用

require 'net/http'
require 'json'
require 'net/smtp'
require "Date"
require 'imgkit'

#主分支的job名
mainJobName = "Tieba_IOS_Master"
#可以通过环境变量输入更多的job名
namesToMonitor = [mainJobName] << ENV["BRANCHJOB"]
chartData = []

nowTime = Time.now
refDay = 45
#只参考最近refDay天的数据;原单位s
refTime = nowTime - 3600 * 24 * refDay
#编译时间增长预警值，1分钟
TIME_DIFF_THRESH = 1

sendEmail = false

namesToMonitor.each_index do |i|
	name = namesToMonitor[i]

	unless name
		break;
	end

	dataOneLine = {"name" => name}
	url = "http://ci.xxx.xxx.com/job/" + name + "/api/json?tree=builds[timestamp,displayName,duration,result]";

	resp = Net::HTTP.get_response(URI.parse(url))
	origdata = JSON.parse(resp.body)
	curData = []

	minTime = 1000
	isTodayFirst = 0
	todayFirstBuildTime = 0
	origdata["builds"].each do |build|
		buildAtTime = Time.at(build["timestamp"]/1000)

		if (build["result"] == "SUCCESS") && buildAtTime > refTime
			minutes = build["duration"] / 60000.0
			if minutes < minTime
				minTime = minutes
			end
			curData << {x:build["timestamp"], y:minutes.round(1), ex:build["displayName"]}

			if (buildAtTime.to_date() == nowTime.to_date()) #今天
				isTodayFirst += 1 #fuck ruby does not have increment operator
				todayFirstBuildTime = minutes
			end
		end
	end

	#今天master的第一次build，检查编译时间
	if i == 0 && 1 == isTodayFirst && todayFirstBuildTime - minTime > TIME_DIFF_THRESH
		sendEmail = true
	end 

	dataOneLine["data"] = curData
	chartData << dataOneLine
end


fileName = "buildTimeGraph.html"
contents = File.read(fileName)
newContents = ''
if contents
	dataJson = JSON.generate(chartData)
	dataJson.gsub!(",\"data\"",',dataLabels:{enabled:true,formatter:function(){return this.y;}},"data"')
	newDataText = "var data = " + dataJson + "\n";
	newContents = contents.gsub(/var data = .*\n/, newDataText)

	# 写文件并作图
	File.open(fileName, "w") {|file| file.puts newContents }
	# kit = IMGKit.new(File.new(fileName), :"javascript-delay" => 1000)

	kit = IMGKit.new(newContents, :"javascript-delay" => 1000)

	# p kit.options

	file = kit.to_file('chart.jpg')
	newContents = File.read('chart.jpg')
else
	puts "Unable to open file!"
end

if sendEmail
	encodedcontent = [newContents].pack("m")   # base64
	marker = "AUNIQUEMARKER"
	ContentID = 'chart_id'

part1 =<<EOF
From: Jenkins Auto Test <tb_autotest@xxx.com>
To: A Test User <teddy_nee@xxx.com>
Subject: iOS编译时长警告
MIME-Version: 1.0
Content-Type: multipart/alternative;
 boundary="#{marker}"; charset=UTF-8
Content-Transfer-Encoding: 7bit

--#{marker}
EOF
 
part2 =<<EOF
Content-Type: text/html;
 charset=UTF-8
Content-Transfer-Encoding: 7bit

<h1>#{mainJobName}分支今日首次编译时长超过近#{refDay}日低值#{TIME_DIFF_THRESH}分钟，请处理！</h1></br>
<img src='cid:#{ContentID}'></img>
--#{marker}
EOF
 
part3 =<<EOF
Content-Type: image/jpeg;
 filename=chart.jpg
Content-Transfer-Encoding: base64
Content-Disposition: attachment;
 filename=chart.jpg
Content-ID: <#{ContentID}>

#{encodedcontent}
--#{marker}
EOF
	 
	mailtext = part1 + part2 + part3

	begin
		Net::SMTP.start('hotswap-in.xxx.com') do |smtp|
			smtp.sendmail(mailtext, 'teddy_nee@xxx.com', ['group@xxx.com', 'leader@xxx.com'])
		end
	rescue Exception => e
		p e  
	end
else
	puts "Don't need to send mail~"
end
 
