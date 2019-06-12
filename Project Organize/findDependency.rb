#!/usr/bin/env ruby

#first version of finding dependency

sModuleNameA = "IDKCore"
sModuleNameB = "IDK"

sDerivedDataRootPath = "/Users/nidong/Library/Developer/Xcode/DerivedData/TBClient-aakzhhsvrphhqnftlaqaxyidliwk"
sBuildConfig="Debug-iphoneos"


############### process of module A ###############

# hash dic of "obj file name" => [undefined symbols array]
hUndefinedSA = {}

sDefinedSA = `nm -defined-only -just-symbol-name #{sDerivedDataRootPath}/Build/Products/#{sBuildConfig}/#{sModuleNameA}/lib#{sModuleNameA}.a`.strip
aDefinedA = sDefinedSA.split("\n").uniq

sUndefinedSA = `nm -undefined-only #{sDerivedDataRootPath}/Build/Products/#{sBuildConfig}/#{sModuleNameA}/lib#{sModuleNameA}.a`.strip
# aUndefinedA = sUndefinedSA.split("\n/").uniq
aTempA = sUndefinedSA.split("\n/")

aTempA.each do |t|
	array = t.split("\n")
	file = array.shift.match(/(?<=\().*(?=\))/).to_s

	#减去模块内部的符号，undefined symbol array of moduleA
	hUndefinedSA[file] = array - aDefinedA
end


############### process of module B ###############

# hash dic of "obj file name" => [defined symbols array]
hDefinedSB = {}

sDefinedSB = `nm -defined-only -just-symbol-name #{sDerivedDataRootPath}/Build/Products/#{sBuildConfig}/#{sModuleNameB}/lib#{sModuleNameB}.a`.strip
aTempB = sDefinedSB.split("\n/")

aTempB.each do |t|
	array = t.split("\n")
	file = array.shift.match(/(?<=\().*(?=\))/).to_s

	hDefinedSB[file] = array
end


############### process of finding dependency ###############

hUndefinedSA.each do |ka, aa|
	# puts "-------------------- #{ka} ---------------------"
	hDependencies = {}

	hDefinedSB.each do |kb, ab|
		common = aa & ab

		unless common.empty?
			hDependencies[kb] = common
		end
	end

	unless hDependencies.empty?
		puts "\033[1;31m#{ka} depends on " + hDependencies.keys.join(",") + "\033[0m"

		#detailed output
		hDependencies.each do |kr, ar|
			puts kr + ":"
			puts ar.join(",")
		end
	end
end


