#!/usr/bin/env ruby

# 在xcodeproj所在目录执行；批量设置其同名target中，文件的compiler flag

require 'xcodeproj'

projName='TiebaMNP'
theFlag='-w'

refProjectPath = projName + ".xcodeproj"
puts "处理的工程为：" + refProjectPath


if File::exist?(refProjectPath)
	proj = Xcodeproj::Project.open(refProjectPath)
	target = nil
	proj.targets.each do |t|
		if t.display_name == projName
			target = t;
			break;
		end
	end

	unless target
	 	puts '未找到' + projName + ' target，即将退出'
	 	exit
	end

	bf = target.source_build_phase

	bf.files.each do |f|
		if nil == f.settings
			f.settings = {"COMPILER_FLAGS" => theFlag}
		elsif !f.settings["COMPILER_FLAGS"].include?(theFlag)
			f.settings["COMPILER_FLAGS"] += (" " +theFlag)
		end
	end

	proj.save
	puts "完成设置"
else
	puts "当前目录未找到#{refProjectPath}工程"
end






