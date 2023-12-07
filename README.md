# Typecho2Rclone
- 适用于自动备份 Typecho 博客并通过 Rclone 定时上传到远程存储的易用 Shell 脚本
- 理论上亦可适用于其他文件夹的定时备份。
- Powered by ChatGPT

## 功能特性

- 一键安装：首次运行脚本即可完成必要的配置和安装，包括创建定时任务和备份脚本
- 定时备份：可以设置定时任务，定期自动备份 Typecho 网站
- 手动备份：支持手动运行备份程序，方便用户随时备份数据
- 配置修改：提供菜单选项，用户可以方便地修改备份目录、远程目录、Rclone 远程配置和 Cron 表达式等信息
- 卸载脚本：提供卸载脚本的功能，包括删除相关定时任务和文件夹
- 灵活适用：理论上亦可适用于其他文件夹的定时备份，但请注意`/tmp`容量与需备份文件夹的体积。备份时需要在`/tmp`额外占用体积为` 需备份文件夹+需备份文件夹打包后的压缩文件` 的磁盘空间作为临时存储。

## 使用方法
- 请确保当前用户在当前工作目录下有创建文件权限，并已安装Curl
    
    ```
    bash -c "$(curl -sSL https://raw.githubusercontent.com/Florenxe/Typecho2Rclone/main/Typecho2Rclone.sh)"
    ```

0. **运行前：**
    - 请确保 Rclone 配置正确，能够成功进行文件上传

1. **首次运行：**
    - 执行 `Typecho2Rclone.sh` 脚本，按照提示输入 Typecho 文件夹绝对路径、Rclone 远程配置名称、远程文件夹路径、以及自定义 Cron 表达式等信息。
    - 脚本将创建子脚本和相关定时任务。

2. **非首次运行：**
    - 执行 `Typecho2Rclone.sh` 脚本，将显示当前脚本文件和定时任务的安装状态。
    - 提供菜单选项，用户可以手动运行备份、修改配置、卸载脚本等。

## 功能原理
<details>
    
 - 当用户首次运行脚本时，脚本将引导用户输入必要的配置信息，包括 Typecho 文件夹路径（TYPECHO_DIR）、Rclone 远程配置名称（REMOTE_NAME）、Rclone 远程文件夹路径（REMOTE_FOLDER）和定时备份的 Cron 表达式（CUSTOM_CRON）
   
   这些信息将被记录到配置文件（config.txt）中，同时创建用于定时备份的子脚本文件（Typecho2Rclone_script.sh）

 - 配置文件的内容如下：
```
TYPECHO_DIR="/path/to/typecho"
REMOTE_NAME="your_remote_config"
REMOTE_FOLDER="/path/to/remote/folder"
CUSTOM_CRON="0 4 * * 1"
```
 - 首次运行完成后，脚本会将子脚本文件 `Typecho2Rclone_script.sh` 写入指定目录，并创建定时任务，按照用户配置的时间定期执行备份操作。首次安装完成后，用户可以选择立即运行一次备份。
 - 备份步骤：
      1. `Typecho2Rclone_script.sh`会将Typecho文件夹复制到位于`/tmp/typecho_temp`的临时文件夹
      2. 将该临时文件夹打包成tar.gz后缀的压缩包
      3. Rclone将该tar.gz压缩包移动至指定远程文件夹
      4. 删除整个`/tmp/typecho_temp`临时文件夹
      5. 完成

 - 在非首次运行时，脚本将读取配置文件中的信息，显示当前脚本文件和定时任务的安装状态。用户可以选择手动运行备份程序、修改配置信息、卸载脚本或退出。

 - 当用户选择修改配置信息时，脚本将引导用户输入新的 Typecho 网页文件夹路径、Rclone 网盘配置名称、Rclone 远程文件夹路径和新的定时备份的 Cron 表达式。这些新的配置信息将被更新到配置文件中，同时备份脚本文件将重新生成。

</details>

## 配置文件

- 用户的首次输入将会被记录到 `./TypechoBackupScript/config.txt` 文件中，确保用户在非首次运行时能够查看和修改配置
- 配置文件明文存储：Typecho 文件夹绝对路径、Rclone 远程配置名称、远程文件夹路径、自定义 Cron 表达式

## 卸载脚本

如果需要卸载脚本，执行 `Typecho2Rclone.sh` 脚本，选择相应菜单选项并输入 "Uninstall"

## 操作菜单示例

<img src="https://raw.githubusercontent.com/Florenxe/Typecho2Rclone/main/menu.png" width="400px">

## 许可证

此脚本基于 [MIT 许可证](LICENSE)

