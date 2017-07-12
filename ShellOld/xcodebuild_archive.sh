#!/bin/sh

echo "~~~~~~~~~~~~~~~~开始执行脚本~~~~~~~~~~~~~~~~"


########################以下是需要根据工程修改的参数###############################
#工程名
PROJECTNAME="xxxx"
#需要编译的 targetName
TARGET_NAME="xxxx"

#设置蒲公英参数
USER_KEY="xxxx"
API_KEY="xxxx"

#设置fir的token
FIR_TOKEN="xxxx"

# ADHOC
#证书名#描述文件
DEVCODE_SIGN_IDENTITY="iPhone Developer: xxxx"
DEVPROVISIONING_PROFILE_NAME="xxxx"
DEVPROVISIONING_PROFILE_SPECIFIER="xxxx"

ADHOCCODE_SIGN_IDENTITY="iPhone Distribution: xxxx"
ADHOCPROVISIONING_PROFILE_NAME="xxxx"
ADHOCPROVISIONING_PROFILE_SPECIFIER="xxxx"

#是否是工作空间
ISWORKSPACE=true
# 1.不上传 2.上传到蒲公英 3.上传到fir.im 4.上传到app store
UploadType="1"

####################################################################

#证书名
CODE_SIGN_IDENTITY=${DEV_CODE_SIGN_IDENTITY}
#描述文件
PROVISIONING_PROFILE_NAME=${DEV_PROVISIONING_PROFILE_NAME}

PROVISIONING_PROFILE_SPECIFIER=${DEVPROVISIONING_PROFILE_SPECIFIER}

ExportOptionsPlist="./shell/DevelopmentExportOptionsPlist.plist"
Deployment="development"
cd ..

echo "~~~~~~~~~~~~~~~~选择打包方式~~~~~~~~~~~~~~~~"
echo "		1 Development (默认)"
echo "		2 Ad Hoc (需要iPhone Distribution证书)"
echo "		3 App Store"

# 读取用户输入并存到变量里
read parameter
sleep 0.5
method="$parameter"

# 判读用户是否有输入
if [ -n "$method" ]
then
if [ "$method" = "1" ]
then
Deployment="development"
ExportOptionsPlist="./shell/DevelopmentExportOptionsPlist.plist"
CODE_SIGN_IDENTITY=${DEVCODE_SIGN_IDENTITY}
PROVISIONING_PROFILE_NAME=${DEVPROVISIONING_PROFILE_NAME}
PROVISIONING_PROFILE_SPECIFIER=${DEVPROVISIONING_PROFILE_SPECIFIER}
elif [ "$method" = "2" ]
then
Deployment="ad-hoc"
ExportOptionsPlist="./shell/AdHocExportOptionsPlist.plist"
CODE_SIGN_IDENTITY=${ADHOCCODE_SIGN_IDENTITY}
PROVISIONING_PROFILE_NAME=${ADHOCPROVISIONING_PROFILE_NAME}
PROVISIONING_PROFILE_SPECIFIER=${ADHOCPROVISIONING_PROFILE_SPECIFIER}
elif [ "$method" = "3" ]
then
Deployment="app-store"
ExportOptionsPlist="./shell/AppStoreExportOptionsPlist.plist"

else
echo "参数无效...."
exit 1
fi
else
Deployment="development"
fi

echo "~~~~~~~~~~~~~~~~选择上传方式~~~~~~~~~~~~~~~~"
echo "		1 不上传 (默认)"
echo "		2 上传到蒲公英"
echo "		3 上传到fir.im"
echo "		4 上传到app store"

# 读取用户输入并存到变量里
read parameter
sleep 0.5
uploadMethod="$parameter"

# 判读用户是否有输入
if [ -n "$uploadMethod" ]
then
if [ "$uploadMethod" = "1" ] || [ "$uploadMethod" = "2" ] || [ "$uploadMethod" = "3" ] || [ "$uploadMethod" = "4" ]
then
UploadType="$uploadMethod"
else
echo "参数无效...."
exit 1
fi
else
UploadType="1"
fi

# 开始时间
beginTime=`date +%s`
DATE=`date '+%Y-%m-%d-%T'`

#编译模式 工程默认有 Debug Release
CONFIGURATION_TARGET=Release
#编译路径
BUILDPATH=~/Desktop/${TARGET_NAME}_${DATE}
#archivePath
ARCHIVEPATH=${BUILDPATH}/${TARGET_NAME}.xcarchive
#输出的ipa目录
IPAPATH=${BUILDPATH}


echo "~~~~~~~~~~~~~~~~开始编译~~~~~~~~~~~~~~~~~~~"

if [ $ISWORKSPACE = true ]
then
# 清理 避免出现一些莫名的错误
xcodebuild clean -workspace ${PROJECTNAME}.xcworkspace \
-configuration \
${CONFIGURATION} -alltargets

#开始构建
xcodebuild -verbose archive -workspace ${PROJECTNAME}.xcworkspace \
-scheme ${TARGET_NAME} \
-archivePath ${ARCHIVEPATH} \
-configuration ${CONFIGURATION_TARGET} \
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
PROVISIONING_PROFILE="${PROVISIONING_PROFILE_NAME}" \
PROVISIONING_PROFILE_SPECIFIER="${PROVISIONING_PROFILE_SPECIFIER}" || exit

else
# 清理 避免出现一些莫名的错误
xcodebuild clean -project ${PROJECTNAME}.xcodeproj \
-configuration \
${CONFIGURATION} -alltargets

#开始构建
xcodebuild -verbose archive -project ${PROJECTNAME}.xcodeproj \
-scheme ${TARGET_NAME} \
-archivePath ${ARCHIVEPATH} \
-configuration ${CONFIGURATION_TARGET} \
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
PROVISIONING_PROFILE="${PROVISIONING_PROFILE_NAME}" \
PROVISIONING_PROFILE_SPECIFIER="${PROVISIONING_PROFILE_SPECIFIER}" || exit
fi

echo "~~~~~~~~~~~~~~~~检查是否构建成功~~~~~~~~~~~~~~~~~~~"
# xcarchive 实际是一个文件夹不是一个文件所以使用 -d 判断

if [ -d "$ARCHIVEPATH" ]
then
echo "构建成功......"
else
echo "构建失败......"
rm -rf $BUILDPATH
exit 1
fi
endTime=`date +%s`
ArchiveTime="构建时间$[ endTime - beginTime ]秒"


echo "~~~~~~~~~~~~~~~~导出ipa~~~~~~~~~~~~~~~~~~~"

beginTime=`date +%s`

xcodebuild -verbose -exportArchive \
-archivePath ${ARCHIVEPATH} \
-exportOptionsPlist ${ExportOptionsPlist} \
-exportPath ${IPAPATH} || exit

echo "~~~~~~~~~~~~~~~~检查是否成功导出ipa~~~~~~~~~~~~~~~~~~~"

IPAPATH=${IPAPATH}/${TARGET_NAME}.ipa
if [ -f "$IPAPATH" ]
then
echo "导出ipa成功......"
open $BUILDPATH
else
echo "导出ipa失败......"
# 结束时间
endTime=`date +%s`
echo "$ArchiveTime"
echo "导出ipa时间$[ endTime - beginTime ]秒"
exit 1
fi

endTime=`date +%s`
ExportTime="导出ipa时间$[ endTime - beginTime ]秒"

echo "~~~~~~~~~~~~~~~~上传ipa~~~~~~~~~~~~~~~~~~~"


if [ ${UploadType} = "1" ]
then
#不上传
echo "只保留到本地"

elif [ ${UploadType} = "2" ]
then
#通过api上传到蒲公英当中
RESULT=$(curl -F "file=@${IPAPATH}" -F "uKey=${USER_KEY}" -F "_api_key=${API_KEY}" https://qiniu-storage.pgyer.com/apiv1/app/upload)
echo "\n已上传至蒲公英"
echo $RESULT

elif [ ${UploadType} = "3" ]
then
#通过api上传到fir.im
fir login -T ${FIR_TOKEN}       # fir.im token
fir publish ${IPAPATH}
echo "\n已上传至fir.im"

elif [ ${UploadType} = "4" ]
then
echo "上传至app store，暂未处理"

else
echo "只保留到本地"
fi

echo "~~~~~~~~~~~~~~~~配置信息~~~~~~~~~~~~~~~~~~~"
echo "开始执行脚本时间: ${DATE}"
echo "编译模式: ${CONFIGURATION_TARGET}"
echo "打包文件路径: ${ARCHIVEPATH}"
echo "打包类别: ${Deployment}"
echo "导出ipa路径: ${IPAPATH}"

echo "$ArchiveTime"
echo "$ExportTime"

exit 0

