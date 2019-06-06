# Scripts

> 不善于运用自动化工具的程序猿，不是一个好司机。
那么让我们编写并分享吊炸天的自动化脚本吧！在GitHub上，我们既可以保存自己的劳动成果，也可以跟他人分享、切磋，简直就是利人利己！

----

### ramdisk.sh
###### 在Mac上创建虚拟内存；默认指定的是生成1G大小的虚拟内存
使用虚拟内存的好处就不多说了，能来找这个东西的人应该知道它的好处


### git_batch_change_name_email.sh
###### 批量修改git的commit信息中的user.name及email信息
当你换了公司或常用名，或者更换常用邮箱之后，修改相关信息非常方便
最后你可能需要强制更新一下远程库，否则远程库的信息是不会变的：git push --force


### linkmap.js
###### 分析Xcode编译时生成的linkmap文件；在原版的基础上增加了输出各模块百分比的功能


### createIPA.sh
###### 使用企业账号的证书，将xcode工程打包成IPA文件，可直接用于安装
默认使用当前文件夹的名字作为xCode工程的名字，并且当前文件夹为xCode工程所在的文件夹
如果不符合以上条件，修改脚本对应内容即可


### libStreamingSDK-packageScript.sh
###### 自己用到的一个xcode工程的编译、打包脚本
如果别人想要拿去使用，需要修改很多“写死的”地方，比如一些文件名，所以这个脚本可能并没有那么“智能”。但是，搞的太“智能”，就需要把脚本很多配置放在参数中，搞的像一个复杂的命令；而脚本是用来方便使用者自己一个人的，实在没有必要这么搞，动手改一下脚本就一劳永逸了，所以，这个脚本中有很多写死的部分。


### Project Monitoring/buildTimeCheck.rb
- 根据require或运行时提示安装对应的imgkit等依赖库
- 拉取Jenkins的数据接口，解析出近期打包作业的时间，生成highcharts图表
- 用于监控近期打包时间，超过一定阈值时，发送邮件给相关人作为提醒；需要配合同目录下的buildTimeGraph.html使用

### CocoaPods/getFileNamesWithFlag
###### 在Pods工程根目录执行；可根据需要输出target中的文件总个数、ARC/非ARC文件的个数、名字等信息

to be continued
