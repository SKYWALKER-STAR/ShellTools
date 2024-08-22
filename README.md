# ShellTools

### 0.介绍
---
该仓库存放一些为了提高日常工作效率而编写的脚本

### 1.postop.sh
---
1. 该脚本通过传入端口号来停止相应的进程。

2. 编写该脚本的初衷是，日常工作中常常会遇到需要重复启停一个进程的情况。如果每次使用grep和ps工具启停则略显麻烦。考虑到在启停过程端口总是不变的，因此，根据端口杀死相应的进程是非常方便的。

3. 示例

	`
	/bin/bash postop.sh port
	`
### 2.file-update.sh
---
1. 该脚本获取两个参数，NEW_PREFIX和OLD_PREFIX.脚本将NEW_PREFIX中的内容复制到OLD_PREFIX目录中。该脚本使用的场景是，新旧目录都包含同样的文件，但是旧目录中还包含了其他无需操作的文件。该脚本只更新新旧目录中共同存在的文件。

2. 该脚本最初的作用是在ssh升级的过程中完成文件备份操作。ssh源码编译后，会产生多个目录及文件，例如ssh、scp、sshd等等，依次手动备份，工作量较大，效率低，且容易错漏，因此编写了该脚本。为了能够方便以后使用，于是将该脚本写成更加通用的形式，用作批量将一个目录中的部分文件复制到另一个目录中。

3. 示例

	旧目录
	`
	/usr/bin
	`

	新目录
	`
	/Downloads/software
	`

	旧目录里面包含三个文件:

	1. a.txt
	2. b.txt
	3. c.txt

	新目录里面包含两个文件:

	1. a.txt
	2. b.txt

	现在需要将新目录中的文件更新到旧目录中 ,并且将旧目录中的文件进行备份(只操作新旧目录中共同存在的文件，文件名一一对应)`/Downloads/software/ -> /usr/bin`,按照以下方式执行脚本即可:

	`
	/bin/bash file-update.sh /Downloads/software/ /usr/bin
	`

	执行后可使用diff命令对比两个目录的区别

	`
	diff -r /usr/bin /Downloads/software
	`

### 3. dist.sh
---
1. 脚本将指定的文件分发到相应的主机中,脚本接受三个参数，第一个参数是想要分发的文件，第二个参数是目的主机IP，该参数应该指定一个文件，脚本将逐行读取该文件，第三个参数是目标端口，脚本将使用第二个参数中指定的主机IP与第三个参数组成目的地址，默认的端口为23.

2. 该脚本最初的使用场景是在运维工作中需要批量在多台服务器上运行脚本,如何方便地将目标脚本传送到目标服务器上是一个需要解决的问题。该脚本使用scp工具批量将本地文件传输到目的机器上,解决脚本分发问题.

3. 示例

	`
	/bin/bash file-update.sh filePath iplist.txt port.txt
	`

	其中,iplist.txt 和 port.txt中的内容是每一行一一对应的

### 4. escmd.sh
---
1. 该脚本是快速执行elasticsearch相关命令的脚本文件，最初是在调试es集群时创建的。后续将不断维护更新，加入更多命令。

### 5. initialSystem.sh
---
1. Linux系统初始化脚本,该脚本的作用是快速将刚接手的服务器操作系统的环境转化为自己熟悉的样子,目前该脚本完成了以下内容
	1. 设置主机名称
	2. 将时区设置为shanghai
	3. 创建dev\wt\dsp三个用户（开发、运维、应用）
	3. 修改Linux系统安全参数
	4. 修改Linux系统内核参数
	5. 修改SSH配置
	6. 关闭SELinux
	7. 关闭Firewalld
	8. 禁用CTRL_ALT_DEL

### 6. service.sh
---
1. 服务启停脚本

2. 示例
	`
	/bin/bash service.sh start|stop|restart
	`

### 7. sendNotify.py
---
1. 构建MarkDown信息，使用HTTP协议发送。该脚本最初是用作向企微机器人发送Jenkins构建信息的

2. Require python3.8及以上

3. 示例
	`
	python sendNotify.py
	`
