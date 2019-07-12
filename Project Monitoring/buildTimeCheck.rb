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

urlPrefix = "http://ci.xxx.xxx.com/job/"
#主分支的job名
mainJobName = "Tieba_IOS_xxx"
namesToMonitor = []
if ENV["JOB_NAME"]
	namesToMonitor << ENV["JOB_NAME"]
else
	namesToMonitor << mainJobName
end

chartData = []

nowTime = Time.now
refDay = 30
# 只参考最近refDay天的数据;原单位s
refTime = nowTime - 3600 * 24 * refDay
# 打包时间激增预警值，TIME_DIFF_THRESH分钟
TIME_DIFF_THRESH = 1
# 参考最近REF_BUILDS_COUNT次打包
REF_BUILDS_COUNT = 3

sendEmail = false
timeDiff = 0
buildId = ''
#最新一次build时间
latestBuildTime = -1

namesToMonitor.each_index do |i|
	name = namesToMonitor[i]

	unless name
		break;
	end

	dataOneLine = {"name" => name}
	url = urlPrefix + name + "/api/json?tree=builds[id,timestamp,displayName,duration,result]";

	resp = Net::HTTP.get_response(URI.parse(url))
	origdata = JSON.parse(resp.body)
	curData = []

	minTime = 1000
	refCount = 0
	origdata["builds"].each do |build|
		buildAtTime = Time.at(build["timestamp"]/1000)

		if (build["result"] == "SUCCESS") && buildAtTime > refTime
			minutes = build["duration"] / 60000.0
			if minutes < minTime
				minTime = minutes
			end
			curData << {x:build["timestamp"], y:minutes.round(1), ex:build["displayName"]}

			# if (buildAtTime.to_date() == nowTime.to_date()) #今天
			# 	isTodayFirst += 1 #fuck ruby does not have increment operator
			# 	todayFirstBuildTime = minutes
			# end

			if latestBuildTime == -1
				latestBuildTime = minutes
				buildId = build["id"]
			end

			refCount += 1
			# 对比前三次
			if refCount == REF_BUILDS_COUNT && latestBuildTime - minTime > TIME_DIFF_THRESH
				sendEmail = true
				timeDiff = latestBuildTime - minTime
			end
		end
	end

	# 今天master的第一次build，检查编译时间
	# if i == 0 && 1 == isTodayFirst && todayFirstBuildTime - minTime > TIME_DIFF_THRESH
	# 	sendEmail = true
	# 	timeDiff = todayFirstBuildTime - minTime
	# end 

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

	# 写文件
	File.open(fileName, "w") {|file| file.puts newContents }
else
	puts "Unable to open file!"
end

if sendEmail && !newContents.empty?

	timeDiff = timeDiff.round(2)
	# 作图
	# kit = IMGKit.new(File.new(fileName), :"javascript-delay" => 1000)
	kit = IMGKit.new(newContents, :"javascript-delay" => 1000)

	# write file and read
	# file = kit.to_file('chart.jpg').read
	
	# directly to image string
	newContents = kit.to_img

	encodedcontent = [newContents].pack("m")   # base64
	marker = "ANUNIQUEMARKER"
	ContentID = 'chart_id'

part1 =<<EOF
From: Angry Script <tb_autotest@xxx.com>
To: <xxx@xxx.com>
Cc: <xxx@xxx.com>, <tb_iosqa@xxx.com>, <ala_rd@xxx.com>, <tb_framework@xxx.com>
Subject: [警报]iOS打包时间异常
MIME-Version: 1.0
Content-Type: multipart/mixed;
 boundary="#{marker}"; 

--#{marker}
EOF
 
part2 =<<EOF
Content-Type: text/html;
 charset=UTF-8
Content-Transfer-Encoding: 8bit

<h1>#{namesToMonitor[0]}分支打包时间激增，请处理！</h1></br>
<h3>打包时间从#{(latestBuildTime - timeDiff).round(2)}分增加到#{latestBuildTime.round(2)}分，激增#{timeDiff}分钟</h3>
对应build详情链接：</br>
<a class="task-link" href="#{urlPrefix}#{namesToMonitor[0]}/#{buildId}/">#{urlPrefix}#{namesToMonitor[0]}/#{buildId}</a></br></br>

近期打包时间变化曲线图详见：</br>
<a class="task-link" href="#{urlPrefix}#{namesToMonitor[0]}/BUILD_TIME_Report">#{urlPrefix}#{namesToMonitor[0]}/BUILD_TIME_Report</a>

<br></br>
<br></br>

概览图：</br>
<img src='cid:#{ContentID}'></img>

<br></br>
<br></br>
<br></br>
<br></br>

attachments
--#{marker}
EOF
 
part3 =<<EOF
Content-Type: image/jpeg;
 name="chart.jpg"
Content-Transfer-Encoding: base64
Content-Disposition: attachment;
 filename="chart.jpg"
Content-ID: <#{ContentID}>

#{encodedcontent}
EOF

	mailtext = part1 + part2 + part3

	begin
		Net::SMTP.start('mail2-in.xxx.com') do |smtp|
			smtp.sendmail(mailtext, 'tb_autotest@xxx.com', ['tb_upapp_ios@xxx.com'])
			puts "Do sent a mail~"
		end
	rescue Exception => e
		p e  
	end
else
	puts "Don't need to send mail~"
end
 
