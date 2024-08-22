#!/bin/bash
# 该脚本用于应用程序的启动停止,请用 "bash" 执行该脚本;

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR=`dirname ${SCRIPT_PATH}`
BASE_DIR=`cd ${SCRIPT_DIR} && pwd`

#启动用户
USER="admin"
#应用程序名称
APP_NAME="APPLICATION_NAME"
#应用程序端口
APP_PORT="8085"
#日志文件
NOHUP_LOG="console_output.log"
#启动命令
COMMAND=""
#启动参数
PARA=''

STOP_SERVICE(){
    LISTEN=`netstat -alntp | grep 'LISTEN' | grep "${APP_PORT}" | wc -l`
    if [ "${LISTEN}" == '1' ];then
        fuser -k ${APP_PORT}/tcp && \
        echo "${APP_NAME} stopped successfully..."
    else
        echo "${APP_NAME} program does not exist..."
    fi
}

START_SERVICE(){
    LISTEN=`netstat -alntp | grep 'LISTEN' | grep "${APP_NAME}" | grep "${APP_PORT}" | wc -l`
    if [ "${LISTEN}" == '0' ];then
        cd ${BASE_DIR} && \
        su ${USER} -s /bin/bash -c "nohup ${COMMAND} ${JAVA_PARA} -jar ${BASE_DIR}/${APP_NAME} >> ${BASE_DIR}/${NOHUP_LOG} 2>&1 &"
    else
        echo "${APP_PORT} is already occupied..."
    fi

    for i in {1..10}
    do
        LISTEN=`netstat -alntp | grep 'LISTEN' | grep "${APP_NAME}" | grep "${APP_PORT}" | wc -l`
        if [ "${LISTEN}" == '1' ];then
            echo "${APP_NAME} started successfully..."
            break
        else
            sleep 12
        fi
    done
    
    LISTEN=`netstat -alntp | grep 'LISTEN' | grep "${APP_NAME}" | grep "${APP_PORT}" | wc -l`
    if [ "${LISTEN}" == '0' ];then
        echo "${APP_NAME} started failed..."
        exit 1
    fi
}

case "$1" in
  stop)
    STOP_SERVICE
  ;;
  start)
    START_SERVICE
  ;;
  restart)
    STOP_SERVICE
    sleep 3
    START_SERVICE
  ;;
  *)
    echo "USAGE: bash service.sh <'stop'|'start'|'restart'>"
  ;;
esac

