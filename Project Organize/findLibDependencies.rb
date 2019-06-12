#!/usr/bin/env ruby

#find dependencies among libs in #{sLibRootPath}

require 'find'

sDerivedDataRootPath = "#{ENV['HOME']}/Library/Developer/Xcode/DerivedData/TBClient-aakzhhsvrphhqnftlaqaxyidliwk"
sBuildConfig = "Debug-iphoneos"
sLibRootPath = "#{sDerivedDataRootPath}/Build/Products/#{sBuildConfig}"

# two style of analysing: whether show obj and symbol detail; take long time to analyse detail
bDetailed = false
# whether recursively analyse libs under #{sLibRootPath}; may take long time to analyse recursively
bRecursiveDir = false

puts "Finding dependencies among libs in #{sDerivedDataRootPath}/Build/Products/#{sBuildConfig}"
puts "#{bDetailed ? "Detailed" : "Simplified"} style"
puts "Search libs #{bRecursiveDir ? "recursively" : "only"} in specified dir\n\n"

# hash dic of "obj file name" => [undefined symbols array]
hUndefinedS = {}
# hash dic of "obj file name" => [defined symbols array]
hDefinedS = {}
aLibNames = []

if bRecursiveDir
	Dir.chdir(sLibRootPath)
	Find.find(".") do |path|
		if path == ?.
			next
		end

		ext = File.extname(path)
		if FileTest.directory?(path)
			if File.basename(path)[0] == ?. || !ext.empty?
		    	Find.prune       # Don't look any further into this directory.
			end
		elsif ext == ".a"
			aLibNames << path.sub(/^\.\//, "")
		end
	end
else
	aLibNames = `ls #{sLibRootPath} | grep "\.a$"`.split(/\n/)
end


aLibNames.each do |sLibName|
	puts "analysing lib: " + sLibName

	############### process of defined symbols ###############

	sDefinedS = `nm -defined-only -just-symbol-name #{sLibRootPath}/#{sLibName}`.strip
	aTempDS = sDefinedS.split("\n/")

	aTempDS.each do |t|
		array = t.split("\n")
		file = array.shift.match(/(?<=\().*(?=\))/).to_s

		if bDetailed
			# 1.1 process by libname + objname
			hDefinedS[sLibName + "(" + file + ")"] = array
		else
			# 2.1 process by libname
			unless hDefinedS[sLibName]
				hDefinedS[sLibName] = []
			end
			hDefinedS[sLibName] |= array
		end
	end

	############### process of undefined symbols ###############

	sUndefinedS = `nm -undefined-only #{sLibRootPath}/#{sLibName}`.strip
	aTempUS = sUndefinedS.split("\n/")

	aTempUS.each do |t|
		array = t.split("\n")
		file = array.shift.match(/(?<=\().*(?=\))/).to_s

		# 减去模块内部的符号，undefined symbol array of moduleA

		if bDetailed
			# 1.2 process by libname + objname
			objName = sLibName + "(" + file + ")"
			hUndefinedS[objName] = array - hDefinedS[objName]
		else
			# 2.2 process by libname
			unless hUndefinedS[sLibName]
				hUndefinedS[sLibName] = []
			end
			hUndefinedS[sLibName] |= array - hDefinedS[sLibName]
		end
	end

end

puts "\nhash dic size: #{hDefinedS.count}\n\n"

############### process of finding dependency ###############

hDependencies = {}
hUndefinedS.each do |ku, au|
	sLibNameU = ku.sub(/\(.*\)/, "")

	hDefinedS.each do |kd, ad|
		sLibNameD = kd.sub(/\(.*\)/, "")

		# 跳过模块内部分析
		if sLibNameD == sLibNameU
			next
		end

		aCommon = au & ad
		unless aCommon.empty?
			if bDetailed
				# 1.3 记录库名+obj名
				hDependencies[kd] = aCommon
			else
				# 2.3 只记录库名；数据结构与1完全不同
				unless hDependencies[sLibNameU]
					puts "finding symbols for #{sLibNameU}"

					hDependencies[sLibNameU] = []
				end
				hDependencies[sLibNameU] << sLibNameD
			end
		end
	end

	if bDetailed
		# 1.4 输出依赖的库名（obj名），以及详细列表
		unless hDependencies.empty?
			puts "\n\033[1;31m#{ku} depends on " + hDependencies.keys.join(",") + "\033[0m"

			# more detailed output
			puts "symbol dependency detail:"
			hDependencies.each do |k, a|
				puts k + ":"
				puts a.join(",")
			end
			hDependencies.clear
		end
	end
end

unless bDetailed || hDependencies.empty?
	puts ""

	# 2.4 只输出依赖的库名
	hDependencies.each do |k, v|
		unless v.empty?
			puts "#{k} depends on " + v.uniq.join(",")
		else
			puts "#{k} depends nothing !"
		end
	end

end


