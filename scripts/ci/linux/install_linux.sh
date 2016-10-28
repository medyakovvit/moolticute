#!/bin/bash

SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $SCRIPTDIR/../funcs.sh

pushd $HOME

echo Downloading Qt
INSTALLER=qt-opensource-linux-x64-5.7.0.run
export QTENVFILE=$HOME/qt-5.7.0.env
wget -c https://download.qt.io/archive/qt/5.7/5.7.0/qt-opensource-linux-x64-5.7.0.run
echo Installing Qt
$SCRIPTDIR/extract-qt-installer $PWD/$INSTALLER $HOME/Qt

echo Create $ENVFILE
cat << EOF > $ENVFILE
export PATH=$HOME/Qt/5.7/gcc_64/bin:$PATH
EOF

popd
