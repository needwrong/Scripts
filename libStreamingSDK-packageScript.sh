#!/bin/sh

#  Created by east 16-03-22.
#  Copyright (c) 2016年 NearEast. All rights reserved.

version=$1
noDoc=$2
noPackage=$3
# 检验参数
if [ -z $version ];then
echo "版本号没有填写"
exit 1
fi

dateToday=`date +%Y%m%d`
buildDir="./PackageDir"
libName="libStreamingSDK"
outputDirName="lecloud_ios_mobile_live_push_SDK_${dateToday}_v${version}_stable"

echo "******* create Build Directory ******"
rm -rdf "${buildDir}"
mkdir "${buildDir}"

echo "************* 设置版本号 ************"
NE_BUILDID=${dateToday}.`git rev-list HEAD | wc -l | awk '{print $1}'`
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NE_BUILDID}" LeCloudStreamingUI/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NE_BUILDID}" ../PushStreamDemo/PushStreamDemo/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${version}" LeCloudStreamingUI/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${version}" ../PushStreamDemo/PushStreamDemo/Info.plist

#xcode use number only
#NE_OPTION_MACRO="$GCC_PREPROCESSOR_DEFINITIONS NE_BUILDID=${NE_BUILDID} NE_VERSIONID=${version}"
#test: cat LeCloudStreaming/utils/LeCApplicationContext.m | sed -n -e s/"\(#define NE_BUILDID @\"\).*$"/"\12.0.1\""/gp
sed -i "" s/"\(#define NE_BUILDID @\"\).*$"/"\1${NE_BUILDID}\""/g LeCloudStreaming/utils/LeCApplicationContext.m
sed -i "" s/"\(#define NE_VERSIONID @\"\).*$"/"\1${version}\""/g LeCloudStreaming/utils/LeCApplicationContext.m


echo "******* 切换到xcode7.3，SDK9.3环境下编译 ******"
#xcodebuild -showsdks
#sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer/

echo "*************************************"
echo ">>>>>> 真机架构构建 "
xcodebuild -scheme LeCloudStreaming -configuration Release clean build ARCHS='armv7 armv7s arm64' -sdk iphoneos9.3 GCC_PREPROCESSOR_DEFINITIONS="${NE_OPTION_MACRO}"
iphoneLibPath="${buildDir}/${libName}_armv7_${version}.a"
cp ./DerivedData/LeCloudStreamingUI/Build/Products/Release-iphoneos/libLeCloudStreaming.a "${iphoneLibPath}"
echo "****LibDir=$iphoneLibPath ******"
lipo -info "${iphoneLibPath}"

echo "*************************************"
echo ">>>>>> 模拟器架构构建 "
xcodebuild -scheme LeCloudStreaming -configuration Release clean build ARCHS='x86_64 i386' -sdk iphonesimulator9.3 PLATFORM_NAME=iphonesimulator  GCC_PREPROCESSOR_DEFINITIONS="${NE_OPTION_MACRO}"
simulatorLibPath="${buildDir}/${libName}_x86_64_${version}.a"
cp ./DerivedData/LeCloudStreamingUI/Build/Products/Release-iphonesimulator/libLeCloudStreaming.a "${simulatorLibPath}"
echo "****LibDir=$simulatorLibPath ******"
lipo -info "${simulatorLibPath}"


echo "*************************************"
echo "*******create all arch library *******"
allArchLibPath="${buildDir}/libLeCloudStreaming.a"
lipo -create "${iphoneLibPath}" "${simulatorLibPath}" -output "${allArchLibPath}"
echo "****LibDir=$allArchLibPath ******"
lipo -info "${allArchLibPath}"

lipo -detailed_info "${allArchLibPath}"

        
echo "*************************************"
echo ">>>>>> LCStreamingBundle building"
xcodebuild -scheme LCStreamingBundle -configuration Release -sdk iphoneos9.3
bundlePath="./DerivedData/LeCloudStreamingUI/Build/Products/Release-iphoneos/LCStreamingBundle.bundle"
echo "****bundlePath=$bundlePath ******"


echo "*******Building static library complete ******"

demoDir="../PushStreamDemo/Libs/LeCloudStreaming"

echo "*******拷贝发布lib，生成发布包 ******"
cp ${allArchLibPath} "${demoDir}/libLeCloudStreaming.a"
cp "LeCloudStreaming/LCStreamingManager.h" "${demoDir}/inc/LCStreamingManager.h"
cp "LeCloudStreaming/CaptureStreamingViewController.h" "${demoDir}/inc/CaptureStreamingViewController.h"
#cp "LeCloudStreaming/LCVidiconItem.h" "${demoDir}/inc/LCVidiconItem.h"
rm -rf "${demoDir}/res/LCStreamingBundle.bundle"
cp -r ${bundlePath} "${demoDir}/res/"


echo "************* 打包ipa ************"
mkdir  ./${outputDirName}
#cd ../PushStreamDemo
xcodebuild -project ../PushStreamDemo/PushStreamDemo.xcodeproj -target PushStreamDemo CODE_SIGN_IDENTITY="iPhone Distribution: Leshi Co., Ltd" PROVISIONING_PROFILE=fabd97d8-2ea0-4398-b5cb-61c1c5a96e3e
xcrun -sdk iphoneos PackageApplication \
        ../PushStreamDemo/build/Release-iphoneos/PushStreamDemo.app \
         -o `pwd`/${outputDirName}/PushStreamDemo.ipa
rm -rf ../PushStreamDemo/build


echo " "
echo "================================================================="
echo "*******最新lib及文件已生成，PushStreamDemo程序下lib已更新，请验证PushStreamDemo工程确保可用；滤镜相关库文件需手动更新 ******"
echo "*******开始将CP发布包打包到桌面 ******"
rm -rf ../PushStreamDemo/DerivedData
cp -r ../PushStreamDemo ./${outputDirName}/
#cp -r ~/Desktop/docs/ ./${outputDirName}/docs/

if [ -z $noPackage ];then
zip -r ~/Desktop/${outputDirName}.zip ./${outputDirName}
fi

rm -rdf ./${outputDirName}
rm -rdf "${buildDir}"

if [ -z $noDoc ];then
zip -r ~/Desktop/push_SDK_docs${dateToday}_v${version}.zip ../push_SDK_docs
fi

echo "*******打包完成，已存放在桌面******"

