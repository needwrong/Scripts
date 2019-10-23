#!/bin/sh

# 检验参数
schemeName=$1
workspaceName=$2
outputDir=$3

if [ -z $schemeName ];then
    echo "参数1，要打包的scheme name 没有填写"
    exit 1
fi

if [ -z $workspaceName ];then
    workspaceName="TBClient"
    echo "默认workspace name: ${workspaceName}"
else
    echo "workspace name: ${workspaceName}"
fi

outputPath=~/Desktop/tmp
if [ -z $outputDir ];then
    echo "默认输出路径: ${outputPath}"
else
    outputPath=${outputDir}
fi

#rm -rdf "${outputPath}"
if [ ! -d ${outputPath} ];then
    mkdir -p "${outputPath}"
fi
echo "******* tmp output directory ${outputPath} ******"

function printAndRunCmd () {
    cmd=$1
    echo '\nrun command:'
    echo "$cmd"

    eval $cmd
}

# xcode-select -switch /Applications/Xcode.app/Contents/Developer/

echo "\n******* xcodebuild *******"

buildCommand="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -workspace ${workspaceName}.xcworkspace -scheme ${schemeName} ENABLE_BITCODE=NO -configuration Release -quiet"
iphoneBuildParams='-sdk iphoneos ARCHS="arm64"'
simulatorBuildParams='-sdk iphonesimulator ARCHS="x86_64"'

buildDir=`${buildCommand} ${iphoneBuildParams} -showBuildSettings | grep '\bTARGET_BUILD_DIR.*$' | awk '{print $3}'`
iphoneLibPath=${buildDir}/lib${schemeName}.a

printAndRunCmd "${buildCommand} ${iphoneBuildParams}"

if [ $? -eq 0 ]; then
    echo "iphoneos lib path: ${iphoneLibPath}"
else
    echo "build for iphoneos failed !"
    exit 2
fi


buildDir=`${buildCommand} ${simulatorBuildParams} -showBuildSettings | grep '\bTARGET_BUILD_DIR.*$' | awk '{print $3}'`
simulatorLibPath=${buildDir}/lib${schemeName}.a

printAndRunCmd "${buildCommand} ${simulatorBuildParams}"

if [ $? -eq 0 ]; then
    echo "simulator lib path: ${simulatorLibPath}"
else
    echo "build for simulator failed !"
    exit 2
fi


echo "\n******* create universal library *******"

allArchLibPath="${outputPath}/lib${schemeName}.a"

printAndRunCmd "lipo -create ${iphoneLibPath} ${simulatorLibPath} -output ${allArchLibPath}"

echo "\n**** output lib dir = $allArchLibPath ******"
lipo -info "${allArchLibPath}"
