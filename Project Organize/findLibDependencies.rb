#!/usr/bin/env ruby

# find dependencies among libs in #{sLibRootPath}
# use arg 0 to specific the lib root path

t1 = Time.now
puts "Start analysing at #{t1}\n\n"

require 'find'
require 'set'
require 'json'

##################################### user configuration you should specified begin #####################################

sDerivedDataRootPath = "#{ENV['HOME']}/Library/Developer/Xcode/DerivedData/TBClient-hckenbkakhzdfechrkslltstgvbv"
sBuildConfig = "Debug-iphoneos"

# the final dir in which to find lib dependencies
sLibRootPath = "#{sDerivedDataRootPath}/Build/Products/#{sBuildConfig}"

# two style of analysing: whether show obj and symbol detail; take long time to analyse detail
bDetailed = true

# whether recursively analyse libs under #{sLibRootPath}; may take long time to analyse recursively
bRecursiveDir = true

# whether process binary file in frameworks
bProcessFramework = true

# whether strip long file path of libs
bStripFilePath = true

aSpecifiedLibs = []
# if you only want to analyse a few specified libs, specify them in aSpecifiedLibs; or you should just comment it out
# aSpecifiedLibs = Set["IDK", "IDKCore"]

aIgnoredLibs = []
# if you want to ignore some libs, specify them in aIgnoredLibs; or you should just comment it out
aIgnoredLibs = Set["IDP", "IDK", "IDKCore"]

# beta function: directly process object files
bProcessObject = true

##################################### user configuration you should specified end #####################################


##################################### take configuration from args begin #####################################

class String
	def to_b
    	return true if self == "true" || self == "YES"
    	return false if self == "false" || self == "NO"
	end
end

iArgCount = ARGV.count

bStripFilePath = ARGV[4].to_b if iArgCount > 4
bProcessFramework = ARGV[3].to_b if iArgCount > 3
bRecursiveDir = ARGV[2].to_b if iArgCount > 2
bDetailed = ARGV[1].to_b if iArgCount > 1
sLibRootPath = ARGV[0] if iArgCount > 0

##################################### take configuration from args end #####################################


puts "Finding dependencies among libs in #{sLibRootPath}"
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

Dir.chdir(sLibRootPath) do
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
			# omit hidden, or subdirs inside framework, or some other dir except some special ones
			elsif basename[0] == ?. || path.match(/\.framework/) || (!ext.empty? && ext != '.default' && !ext.match(/\.\d/) && ext != '.build')
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
		elsif bProcessObject && ext == ".o"

			aLibNames << path.sub(/^\.\//, "")
		elsif bProcessFramework && ext.empty?		#binary inside framewroks, without f*cking .DS_Store file
			unless path.match(/\.framework/) && !path.end_with?(".DS_Store")
				next
			end

			aLibNames << path.sub(/^\.\//, "")
		end
	end
end

# node info used for charts
aNodes = []
aEdges = []

aLibNames.each do |sLibName|
	sSimpleLibName = sLibName
	sSimpleLibName = File.basename(sLibName) if bStripFilePath
	puts "Analysing lib: " + sLibName

	aNodes << {"id" => sSimpleLibName, "label" => sSimpleLibName, "value" => 1}

	############### process of defined symbols ###############

	sDefinedS = `nm -defined-only -just-symbol-name #{sLibRootPath}/#{sLibName}`.strip
	aTempDS = sDefinedS.split("\n/")

	aTempDS.each do |t|
		array = t.split("\n")
		file = array.shift.match(/(?<=\().*(?=\))/).to_s

		if bDetailed && !bProcessObject
			# 1.1 process by libname + objname
			hDefinedS[sSimpleLibName + "(" + file + ")"] = array
		else
			# 2.1 process by libname
			unless hDefinedS[sSimpleLibName]
				hDefinedS[sSimpleLibName] = []
			end
			hDefinedS[sSimpleLibName] |= array
		end
	end

	############### process of undefined symbols ###############

	sUndefinedS = `nm -undefined-only -j #{sLibRootPath}/#{sLibName}`.strip
	aTempUS = sUndefinedS.split("\n/")

	aTempUS.each do |t|
		array = t.split("\n")
		file = array.shift.match(/(?<=\().*(?=\))/).to_s

		# 减去模块内部的符号，undefined symbol array of moduleA

		if bDetailed && !bProcessObject
			# 1.2 process by libname + objname
			objName = sSimpleLibName + "(" + file + ")"
			hUndefinedS[objName] = array - hDefinedS[objName]
		else
			# 2.2 process by libname
			unless hUndefinedS[sSimpleLibName]
				hUndefinedS[sSimpleLibName] = []
			end

			hUndefinedS[sSimpleLibName] |= array - hDefinedS[sSimpleLibName]
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
				unless a.empty?
					puts k + ":"
					puts a.join(",")
				end

				aEdges << {"from" => ku, "to" => k}
				node = aNodes.find {|x| x["id"] == k}
				node["value"] += 1
			end
			hDependencies.clear
		end
	end
end

# chartData = []
unless bDetailed || hDependencies.empty?
	puts ""

	# 2.4 只输出依赖的库名
	hDependencies.each do |k, v|
		unless v.empty?
			puts "#{k} depends on " + v.uniq.join(",")

			v.each do |vl|
				# chartData << [k, vl]

				aEdges << {"from" => k, "to" => vl}
				node = aNodes.find {|x| x["id"] == vl}
				node["value"] += 1
			end
		else
			puts "#{k} depends nothing !"
		end
	end

end

t2 = Time.now
puts "\n\nTotal time consumed: #{t2 - t1}"


sFileName = "VisRelationsChart.html"
contents = File.read(sFileName)

# hDependencies.each do |k, v|
# 	unless v.empty?
# 		v.each do |vl|
# 			aEdges << {"from" => k, "to" => vl}
# 			node = aNodes.find {|x| x["id"] == vl}
# 			node["value"] += 1
# 		end
# 	end
# end

newContents = ''
if contents
	nodesJson = JSON.generate(aNodes)
	edgesJson = JSON.generate(aEdges)

	newDataText = "var nodes = " + nodesJson + "\n";
	newContents = contents.gsub(/var nodes = .*\n/, newDataText)

	newDataText = "var edges = " + edgesJson + "\n";
	newContents = newContents.gsub(/var edges = .*\n/, newDataText)

	# 写文件
	File.open(sFileName, "w") {|file| file.puts newContents }
end
