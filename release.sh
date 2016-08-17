# Working only on OS X

version=$(sed -nE 's/.*version="([0-9.]+).*/\1/p' config.xml)
printf "New version [$version]: "
read new_version

if [ -n "${new_version}" ];
  then
    perl -pe "s/(version=)\"([0-9.]+)\"/ q{version=\"$new_version\"} /ge" -i config.xml
fi
perl -pe 's/(android-versionCode=)\"(\d+)\"/ q{android-versionCode="} . (1 + $2) . q{"} /ge' -i config.xml
perl -pe 's/(ios-CFBundleVersion=)\"(\d+)\"/ q{ios-CFBundleVersion="} . (1 + $2) . q{"} /ge' -i config.xml

node hooks/downloadCache.js

cordova build android
cordova compile android --release --device
open -R platforms/android/build/outputs/apk/android-armv7-release.apk

cordova build ios
cordova compile ios --release --device
open -R platforms/ios/build/device/*.ipa
