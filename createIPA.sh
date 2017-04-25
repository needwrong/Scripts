#created by NearEast
#updated 2017-05-04

#默认使用当前文件夹的名字作为xCode工程的名字，并且当前文件夹为xCode工程所在的文件夹
#如果不符合以上条件，修改脚本对应内容即可

version=$1
projectName=`pwd | awk -F "/" '{print $NF}'`
outputPath=~/Desktop/tmp
buildPath=${outputPath}/xcodeBuild

echo 'using version number '${version}
echo 'using projectName '${projectName}

dateToday=`date +%Y%m%d`
NE_BUILDID=${dateToday}.`git rev-list HEAD | wc -l | awk '{print $1}'`
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NE_BUILDID}" ${projectName}/Info.plist

if [ -z $version ];then
echo 'using old version number'
else
echo 'using new version:${version}'
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${version}" ${projectName}/Info.plist
fi

xcodebuild -workspace ${projectName}.xcworkspace -scheme ${projectName} -configuration Release clean build ARCHS='armv7 arm64' -sdk iphoneos CODE_SIGN_IDENTITY="iPhone Distribution: Leshi Co., Ltd" PROVISIONING_PROFILE=CommonEntpInHouseProvisionProfile SYMROOT="${buildPath}"

xcrun -sdk iphoneos PackageApplication \
${buildPath}/Release-iphoneos/${projectName}.app \
-o ${outputPath}/${projectName}${NE_BUILDID}.ipa

echo 'output ipa: '${outputPath}'/'${projectName}${NE_BUILDID}'.ipa'

rm -rf ${build_path}


