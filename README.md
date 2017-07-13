# FAutoArchiveShell
ios自动打包的脚本，包含Development，AdHoc，AppStore这3种打包方式，并且手动选择来上传到蒲公英或者fir.im
____

使用对应版本需要将该脚本的文件夹放到对应工程的根目录下，即包含xxxx.xcworkspace或者xxxx.xcodeproj文件的目录下，如将Shell单独放到一个目录下。

1.Shell文件下是Xcode 8下不需要证书的配置使用的，在使用时需要到Xcode下的project->General->Signing中关闭Automatically manage signing的勾选，并且选择对应的provisioning profile，然后在xcodebuild_archive.sh中填入对应的参数保存，运行脚本即可。

2.ShellOld是需要配置对应证书的，具体参数和详细的介绍可以查看[我的微博](http://www.jianshu.com/p/c35920c187ab)，如果有任何问题和意见可以给我留言，走过路过觉得不错，手动Star一下，谢谢。

