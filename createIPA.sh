
version=$1
projectName=`pwd | awk -F "/" '{print $NF}'`

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

xcodebuild -workspace ${projectName}.xcworkspace -scheme ${projectName} -configuration Release clean build ARCHS='armv7 arm64' -sdk iphoneos10.2 CODE_SIGN_IDENTITY="iPhone Distribution: Leshi Co., Ltd" PROVISIONING_PROFILE=CommonEntpInHouseProvisionProfile

xcrun -sdk iphoneos PackageApplication \
`pwd`/DerivedData/${projectName}/build/Products/Release-iphoneos/${projectName}.app \
-o ~/Desktop/${projectName}${NE_BUILDID}.ipa

rm -rf build
