#!/usr/bin/env ruby

#find dependencies among libs in #{sLibRootPath}

t1 = Time.now
puts "Start analysing at #{t1}\n\n"

require 'find'
require 'set'

##################################### user configuration you should specified begin #####################################

# sDerivedDataRootPath = "#{ENV['HOME']}/Library/Developer/Xcode/DerivedData/TBClient-aakzhhsvrphhqnftlaqaxyidliwk"
# sBuildConfig = "Debug-iphoneos"

sDerivedDataRootPath = "#{ENV['HOME']}/Library/Developer/Xcode/DerivedData/BBAComposeDemo-egzjtzfyjlklckgvpxvqtmvfjpyv"
sBuildConfig = "Debug-iphonesimulator"

# two style of analysing: whether show obj and symbol detail; take long time to analyse detail
bDetailed = false
# whether recursively analyse libs under #{sLibRootPath}; may take long time to analyse recursively
bRecursiveDir = true
# whether process binary file in frameworks
bProcessFramework = true

aSpecifiedLibs = []
# if you only want to analyse a few specified libs, specify them in aSpecifiedLibs; or you should just comment it out
# aSpecifiedLibs = Set["IDK", "IDKCore"]

aIgnoredLibs = []
# if you want to ignore some libs, specify them in aIgnoredLibs; or you should just comment it out
aIgnoredLibs = Set["IDP"]

##################################### user configuration you should specified end #####################################


sLibRootPath = "#{sDerivedDataRootPath}/Build/Products/#{sBuildConfig}"

puts "Finding dependencies among libs in #{sDerivedDataRootPath}/Build/Products/#{sBuildConfig}"
puts "#{bDetailed ? "Detailed" : "Simplified"} style"
puts "Search libs #{bRecursiveDir ? "recursively" : "only"} in specified dir\n\n"

unless aSpecifiedLibs.empty?
	puts "Specified libs: #{aSpecifiedLibs.to_a.join(',')} \n\n"
end

unless aIgnoredLibs.empty?
	puts "Ignored libs: #{aIgnoredLibs.to_a.join(',')} \n\n"
end

# hash dic of "obj file name" => [undefined symbols array]
hUndefinedS = {}
# hash dic of "obj file name" => [defined symbols array]
hDefinedS = {}
aLibNames = []

Dir.chdir(sLibRootPath)
Find.find(".") do |path|
	if path == ?.
		next
	end

	basename = File.basename(path)
	ext = File.extname(path)

	if FileTest.directory?(path)
		unless bRecursiveDir
		 	Find.prune
		 	next
		end

		# TODO: identify dynamic or static framework
		if bProcessFramework && ext == ".framework"
			puts "Process framework: " + path
			next
		# omit hidden or other none framework files, or subdirs inside framework.
		elsif basename[0] == ?. || !ext.empty? || path.match(/\.framework/)
	    	Find.prune       # Don't look any further into this directory.
		end

		# omit dirs in aIgnoredLibs
		unless aIgnoredLibs.empty?
			if aIgnoredLibs.include?(basename)
				Find.prune
				next
			end
		end

		# omit dirs not in aSpecifiedLibs
		unless aSpecifiedLibs.empty?
			unless aSpecifiedLibs.include?(basename)
				Find.prune
			 	next
			end
		end

	elsif ext == ".a"
		strippedName = basename.sub(/^lib/,'').sub(/\.a$/,'')

		# omit libs in aIgnoredLibs
		unless aIgnoredLibs.empty?
			if aIgnoredLibs.include?(strippedName)
				next
			end
		end

		# omit libs not in aSpecifiedLibs
		unless aSpecifiedLibs.empty?
			unless aSpecifiedLibs.include?(strippedName)
			 	next
			end
		end

		aLibNames << path.sub(/^\.\//, "")

	elsif bProcessFramework && ext.empty?		#binary inside framewroks
		unless path.match(/\.framework/)
			next
		end

		aLibNames << path.sub(/^\.\//, "")
	end
end

aLibNames.each do |sLibName|
	puts "Analysing lib: " + sLibName

	############### process of defined symbols ###############

	sDefinedS = `nm -defined-only -just-symbol-name -extern-only #{sLibRootPath}/#{sLibName}`.strip
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
					puts "Finding symbols for #{sLibNameU}"

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
			puts "Symbol dependency detail:"
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

t2 = Time.now
puts "\n\nTotal time consumed: #{t2 - t1}"

