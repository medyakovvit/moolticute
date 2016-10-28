#!/bin/bash
set -ev

SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $SCRIPTDIR/../funcs.sh

rm -fr build_linux
mkdir build_linux
pushd build_linux

unset `env | \
grep -vi '^EDITOR=\|^HOME=\|^LANG=\|^PATH=\|^QTENVFILE=' | \
grep -vi 'PKG_CONFIG\|PROXY\|^PS1=\|^TERM=\|^TRAVIS_OS_NAME=\|^UPLOAD_KEY=' | \
   cut -d '=' -f1 | tr '\n' ' '`

OLD_PATH=$PATH
echo sourcing $QTENVFILE
source $QTENVFILE

make_version ..

qmake ../Moolticute.pro
make

export PATH=$OLD_PATH

popd
