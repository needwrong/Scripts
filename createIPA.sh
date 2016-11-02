
version=$1

dateToday=`date +%Y%m%d`
NE_BUILDID=${dateToday}.`git rev-list HEAD | wc -l | awk '{print $1}'`
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NE_BUILDID}" HandyPushStream/Info.plist

if [ -z $version ];then
echo 'using old version number'
else
echo 'using new version:${version}'
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${version}" HandyPushStream/Info.plist
fi

xcodebuild -workspace HandyPushStream.xcworkspace -scheme HandyPushStream -configuration Release clean build ARCHS='armv7 arm64' -sdk iphoneos10.0 CODE_SIGN_IDENTITY="iPhone Distribution: Leshi Co., Ltd" PROVISIONING_PROFILE=fabd97d8-2ea0-4398-b5cb-61c1c5a96e3e

xcrun -sdk iphoneos PackageApplication \
`pwd`/DerivedData/HandyPushStream/build/Products/Release-iphoneos/HandyPushStream.app \
-o ~/Desktop/HandyPushStream${NE_BUILDID}.ipa

rm -rf build
