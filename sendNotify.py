#!/usr/local/bin/python3.8
#-*- coding:utf-8 -*-

import os
import urllib
import requests

#获取需要的环境变量
#CHAT_WEBHOOK_URL=os.environ['WECHAT_ALERT']
TYPE_NAME=os.environ['TYPE']
JOB_NAME=os.environ['JOB_NAME']
BUILD_URL=os.environ['BUILD_URL']
BUILD_USER=os.environ['BUILD_USER']
DEPLOY_NAME=os.environ['DEPLOY_NAME']
BUILD_RES=os.environ['BUILD_RES']
headers={"Content-Type": "application/json;charset=utf-8"}

#机器人地址
CHAT_WEBHOOK_URL=""

#构建成功通知
markdown_success = '''<font color=\"info\">**Jenkins 任务通知**</font>\n
 >构建状态：<font color='green'>**构建成功**</font>
 >构建用户：<font color=\"comment\">{build_user}</font>
 >构建项目：<font color=\"comment\">{job_name}</font>
 >构建方式：<font color=\"comment\">{type_name}</font>
 >构建包名：<font color=\"comment\">{deploy_name}</font>
 >项目路径：<font color=\"comment\">{build_url}</font>
'''.format(build_user=BUILD_USER,job_name=JOB_NAME,type_name=TYPE_NAME,deploy_name=DEPLOY_NAME,build_url=urllib.parse.unquote(BUILD_URL))

#构建失败通知
markdown_failed = '''<font color=\"red\">**Jenkins 任务通知**</font>\n
 >构建状态：<font color='red'>**构建失败**</font> 
 >构建用户：<font color=\"comment\">{build_user}</font>
 >构建项目：<font color=\"comment\">{job_name}</font>
 >构建方式：<font color=\"comment\">{type_name}</font>
 >构建包名：<font color=\"comment\">{deploy_name}</font>
 >项目路径：<font color=\"comment\">{build_url}</font>
'''.format(build_user=BUILD_USER,job_name=JOB_NAME,type_name=TYPE_NAME,deploy_name=DEPLOY_NAME,build_url=urllib.parse.unquote(BUILD_URL))

#构建取消通知
markdown_aborted = '''<font color=\"warning\">**Jenkins 任务通知**</font>\n
 >构建状态：<font color='warning'>**构建取消**</font> 
 >构建用户：<font color=\"comment\">{build_user}</font>
 >构建项目：<font color=\"comment\">{job_name}</font>
 >构建方式：<font color=\"comment\">{type_name}</font>
 >构建包名：<font color=\"comment\">{deploy_name}</font>
 >项目路径：<font color=\"comment\">{build_url}</font>
'''.format(build_user=BUILD_USER,job_name=JOB_NAME,type_name=TYPE_NAME,deploy_name=DEPLOY_NAME,build_url=urllib.parse.unquote(BUILD_URL))

def buildSuccess():
    content = {
	"msgtype": "markdown",
	"markdown": {
		"content": markdown_success
	}
    }

    rv = requests.post(url=CHAT_WEBHOOK_URL,json=content,headers=headers)

def buildFailed():
    content = {
	"msgtype": "markdown",
	"markdown": {
		"content": markdown_failed
	}
    }

    rv = requests.post(url=CHAT_WEBHOOK_URL,json=content,headers=headers)

def buildAborted():
    content = {
	"msgtype": "markdown",
	"markdown": {
		"content": markdown_aborted
	}
    }

    rv = requests.post(url=CHAT_WEBHOOK_URL,json=content,headers=headers)

def main():
    if BUILD_RES == 'success':
       buildSuccess()
    elif BUILD_RES == 'aborted':
       buildAborted()
    else:
       buildFailed()

if __name__ == '__main__':
	main()
