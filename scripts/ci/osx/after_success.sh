#!/bin/bash

set -ev

#
# creating the Moolticute.dmg with Applications link
#

SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $SCRIPTDIR/../funcs.sh

VERSION="$(get_version .)"

#Only build if the commit we are building is for the last tag
if [ "$(git rev-list -n 1 $VERSION)" != "$(cat .git/HEAD)"  ]; then
    echo "Not uploading package"
    return 0
fi

QTDIR="/usr/local/opt/qt5"
APP=Moolticute
# this directory name will also be shown in the title when the DMG is mounted
TEMPDIR=build/$APP
SIGNATURE="Raoul Hecky"
NAME=`uname`

if [ "$NAME" != "Darwin" ]; then
    echo "This is not a Mac"
    exit 1
fi

cat build/$APP.app/Contents/Info.plist

echo "Changing bundle identifier"
sed -i -e 's/com.yourcompany.Moolticute/com.Mooltipass.Moolticute/g' build/$APP.app/Contents/Info.plist
# removing backup plist
rm -f build/$APP.app/Contents/Info.plist-e

# Copy daemon to bundle
cp build/moolticuted build/$APP.app/Contents/MacOS/

#Get 3rd party tools
wget_retry https://calaos.fr/mooltipass/tools/macos/mc-agent -O build/$APP.app/Contents/MacOS/mc-agent
wget_retry https://calaos.fr/mooltipass/tools/macos/mc-cli -O build/$APP.app/Contents/MacOS/mc-cli

# use macdeployqt to deploy the application
echo "Calling macdeployqt"
$QTDIR/bin/macdeployqt build/$APP.app
if [ "$?" -ne "0" ]; then
    echo "Failed to run macdeployqt"
    exit 1
fi

#Call fix to change all rpath
wget_retry https://raw.githubusercontent.com/aurelien-rainone/macdeployqtfix/master/macdeployqtfix.py
python macdeployqtfix.py build/$APP.app/Contents/MacOS/moolticute /usr/local/Cellar/qt5/5.*/
python macdeployqtfix.py build/$APP.app/Contents/MacOS/moolticuted /usr/local/Cellar/qt5/5.*/

#setup keychain
KEYCHAIN="travis.keychain"
KEYCHAIN_PW="mooltipass"

security create-keychain -p $KEYCHAIN_PW $KEYCHAIN
security default-keychain -s $KEYCHAIN
security set-keychain-settings $KEYCHAIN
security unlock-keychain -p $KEYCHAIN_PW $KEYCHAIN
security import $HOME/cert.p12 -k $KEYCHAIN -P "$CODESIGN_OSX_PASS" -A
security set-key-partition-list -S apple-tool:,apple: -s -k $KEYCHAIN_PW $KEYCHAIN

# Use first ID
security find-identity -v $KEYCHAIN
export ID=$(security find-identity -v $KEYCHAIN | grep "1)" | sed "s/^ *1) *\([^ ]*\).*/\1/")

#Sign binaries!
codesign --deep --force --verbose --sign $ID --keychain $KEYCHAIN build/$APP.app

echo "Verifying code signed app"
codesign --verify --verbose=4 build/$APP.app
spctl --assess --verbose=4 --raw build/$APP.app

#install appdmg https://github.com/LinusU/node-appdmg a tool to create awesome dmg !
npm install -g appdmg
appdmg mac/appdmg.json build/$APP-$VERSION.dmg

#sign dmg
codesign --force --verify --verbose --sign "$ID" build/$APP-$VERSION.dmg

echo "Verifying code signed disk image"
codesign --verify --verbose=4 build/$APP-$VERSION.dmg
spctl --assess --verbose=4 --raw build/$APP-$VERSION.dmg

echo "Removing keys"
# remove keys
security delete-keychain $KEYCHAIN

#create update manifest
cat > build/updater.json <<EOF
{ "updates": { "osx": { "latest-version": "$VERSION", "download-url": "https://calaos.fr/mooltipass/macos/$APP-$VERSION.dmg" }}}
EOF

upload_file build/$APP-$VERSION.dmg $(shasum -a 256 build/$APP-$VERSION.dmg | cut -d' ' -f1) "macos"
upload_file build/updater.json $(shasum -a 256 build/updater.json | cut -d' ' -f1) "macos"

PATH=${PATH}:$(pwd)/scripts/lib create_github_release_osx ${BUILD_TAG}

exit 0

