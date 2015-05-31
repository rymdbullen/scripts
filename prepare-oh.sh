#!/bin/bash
#
# Script for downloading and setting up the latest version of openhab 
# Options to install habmin (default) or not, a specific habmin version or master (default)
# Downloads zip files to /root
# Creates a temporary folder in /tmp with "mktemp -d"
#

##
## Setting up parameters
##
INSTALL_HABMIN=${INSTALL_HABMIN:-true}
HABMIN_VERSION=${HABMIN_VERSION:-master}
ZIP_FILE_HABMIN="habmin.zip"
DL_DIR="/root"

BASE_DIR="$(dirname "$(readlink -f "$0")")"
URL=$(curl --silent -kIXGET https://github.com/openhab/openhab/releases/latest | grep Location)
AFTER_SLASH=$(basename "$URL" | tr -d '\r')
VERSION_OH=${AFTER_SLASH:1}

if [ "${HABMIN_VERSION}" == "master" ]; then
    URL_HABMIN="https://github.com/cdjackson/HABmin/archive/master.zip"
else
    URL=$(curl --silent -kIXGET https://github.com/cdjackson/HABmin/releases/latest | grep Location)
    AFTER_SLASH=$(basename "$URL" | tr -d '\r')
    VERSION_HABMIN=${AFTER_SLASH:0}
    URL_HABMIN="https://github.com/cdjackson/HABmin/releases/download/${VERSION_HABMIN}/habmin.zip"
fi

ZIP_FILE_RUNTIME="distribution-${VERSION_OH}-runtime.zip"
ZIP_FILE_ADDONS="distribution-${VERSION_OH}-addons.zip"
ZIP_FILE_GREENT="distribution-${VERSION_OH}-greent.zip"
BASE_URL="https://github.com/openhab/openhab/releases/download/v${VERSION_OH}"
BASE_URL='https://bintray.com/artifact/download/openhab/bin'
URL_RUNTIME="${BASE_URL}/${ZIP_FILE_RUNTIME}"
URL_ADDONS="${BASE_URL}/${ZIP_FILE_ADDONS}"
URL_GREENT="${BASE_URL}/${ZIP_FILE_GREENT}"

##
## prepare temp dirs
##
TMP_OH_DIR=$(mktemp -d)
TMP_HABMIN_DIR=$(mktemp -d)
mkdir ${TMP_OH_DIR}/addons-available

##
## wget OH
##
if [ ! -f ${DL_DIR}/${ZIP_FILE_RUNTIME} ]; then
    curl -k -L ${URL_RUNTIME} -o ${DL_DIR}/${ZIP_FILE_RUNTIME}
fi
if [ ! -f ${DL_DIR}/${ZIP_FILE_ADDONS} ]; then
    curl -k -L ${URL_ADDONS} -o ${DL_DIR}/${ZIP_FILE_ADDONS}
fi
if [ ! -f ${DL_DIR}/${ZIP_FILE_GREENT} ]; then
    curl -k -L ${URL_GREENT} -o ${DL_DIR}/${ZIP_FILE_GREENT}
fi
if [ "${INSTALL_HABMIN}" == "true" ]; then
  if [ ! -f ${DL_DIR}/${ZIP_FILE_HABMIN} ]; then
    curl -k -L ${URL_HABMIN} -o ${DL_DIR}/${ZIP_FILE_HABMIN}
  fi
fi

##
## unzip
##
unzip ${DL_DIR}/${ZIP_FILE_RUNTIME} -d ${TMP_OH_DIR}/
unzip ${DL_DIR}/${ZIP_FILE_GREENT}  -d ${TMP_OH_DIR}/webapps
unzip ${DL_DIR}/${ZIP_FILE_ADDONS}  -d ${TMP_OH_DIR}/addons-available

if [ "${HABMIN_VERSION}" == "master" ]; then
    unzip ${DL_DIR}/${ZIP_FILE_HABMIN} -d ${TMP_OH_DIR}/webapps
    mv ${TMP_OH_DIR}/webapps/HABmin-master ${TMP_OH_DIR}/webapps/habmin
    cd ${TMP_OH_DIR}/addons
    ADDONS=$(ls ${TMP_OH_DIR}/webapps/habmin/addons/*.jar)
    for f in ${ADDONS}
    do
        ln -s ../addons-available/$(basename ${f}) .
    done
    mv ${TMP_OH_DIR}/webapps/habmin/addons/*.jar ${TMP_OH_DIR}/addons-available/
    rmdir ${TMP_OH_DIR}/webapps/habmin/addons
else
    unzip ${DL_DIR}/${ZIP_FILE_HABMIN} -d ${TMP_OH_DIR}/
    ln -s ../addons-available/*.habmin*.jar .
    ln -s ../addons-available/org.openhab.binding.zwave-${VERSION_OH}.jar .
fi


##
## remove zip files
##
#rm ${TMP_OH_DIR}/${ZIP_FILE_RUNTIME}
#rm ${TMP_OH_DIR}/${ZIP_FILE_GREENT}
#rm ${TMP_OH_DIR}/${ZIP_FILE_ADDONS}


##
## cleanup
##
#rm -rf $TMP_OH_DIR
rm ${TMP_OH_DIR}/*.bat

cowsay "Done preparing Openhab version ${VERSION_OH} in ${TMP_OH_DIR}"
