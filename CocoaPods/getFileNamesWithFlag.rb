#!/usr/bin/env ruby

# 在Pods工程根目录执行；可根据需要输出target中的文件总个数、ARC/非ARC文件的个数、名字等信息

require 'xcodeproj'

targetName='IDK'

refProjectPath = `pwd`.chomp + "/Pods/Pods.xcodeproj"
puts "处理的Pods工程为：" + refProjectPath
puts targetName
nonarcNames = ""
arcNames = ""

if File::exist?(refProjectPath)
	proj = Xcodeproj::Project.open(refProjectPath)
	target = nil
	proj.targets.each do |t|
		if t.display_name == targetName
			target = t;
			break;
		end
	end

	unless target
	 	puts '未找到' + targetName + ' target，即将退出'
	 	exit
	end

	bf = target.source_build_phase

	totalCnt = 0
	nonarcCnt = 0
	arcCnt = 0

	bf.files.each do |f|
		totalCnt += 1
		if f.settings && f.settings["COMPILER_FLAGS"].match(/-fno-objc-arc/)
			nonarcCnt += 1

			nonarcNames += f.display_name + ","

			# 输出相对某目录（如../xxx/xxx/IDK）的全路径，可用于podspec配置
			# nonarcNames += f.file_ref.full_path.relative_path_from(Pathname.new('../xxx/xxx/IDK')).to_path.chomp('.mm').chomp('.m') + ","
		else
			arcNames += f.display_name + ","
			arcCnt += 1
		end
	end

	puts "文件总数：" + totalCnt.to_s
	# puts "arc的文件数：" + arcCnt.to_s
	# puts "文件列表：" + arcNames.chop

	puts "非arc的文件数：" + nonarcCnt.to_s
	puts "文件列表：" + nonarcNames.chop
else
	puts "未找到Pods工程"
end






