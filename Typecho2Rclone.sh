#!/bin/bash

CONFIG_FILE="$PWD/TypechoBackupScript/config.txt"
BACKUP_SCRIPT_PATH="$PWD/TypechoBackupScript/Typecho2Rclone_script.sh"

# ANSI颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

function create_backup_script() {
    # 创建并写入备份脚本
    cat <<EOF > $BACKUP_SCRIPT_PATH
#!/bin/bash

# 固定备份文件路径
TMP_DIR="/tmp/typecho_temp"
mkdir -p \$TMP_DIR
BACKUP_FILE="\$TMP_DIR/typecho_backup_\$(date +"%Y%m%d%H%M%S").tar.gz"

# 复制 Typecho 网页文件夹至临时文件夹
cp -r $TYPECHO_DIR \$TMP_DIR

# 打包 Typecho 网页文件夹
tar -czvf \$BACKUP_FILE -C \$TMP_DIR .

# 使用 Rclone 移动（move）到网盘指定文件夹
rclone move \$BACKUP_FILE $REMOTE_NAME:$REMOTE_FOLDER -v

# 删除临时文件夹
rm -rf \$TMP_DIR

echo "Typecho 网页文件夹备份并通过 Rclone 上传到网盘完成！"
EOF
}

# 检测是否是首次运行
if [ ! -f "$BACKUP_SCRIPT_PATH" ]; then
    # 提示用户输入必要的变量
    while true; do
        read -p "请输入 Typecho 网页文件夹的绝对路径（例如：/www/typecho）: " TYPECHO_DIR

        # 验证目录是否存在
        if [ -d "$TYPECHO_DIR" ]; then
            break
        else
            echo "目录不存在，请重新输入。"
        fi
    done

    while true; do
        read -p "请输入 Rclone 的网盘配置的名称（例如：Onedrive_remote）: " REMOTE_NAME

        # 验证远程配置是否存在
        RCLONE_CONFIGS=$(rclone listremotes)
        if echo "$RCLONE_CONFIGS" | grep -q "$REMOTE_NAME"; then
            break
        else
            echo "Rclone配置不存在，请重新输入或完成相关Rclone配置。"
        fi
    done

    # 提示用户输入备份目录
    read -p "请输入 Rclone 远程文件夹的路径（例如：/backup/typecho）: " REMOTE_FOLDER

    # 提示用户输入自定义 cron 表达式，如果未输入则使用默认值
    read -p "请输入定时备份时间的 cron 表达式（默认：0 4 * * 1，星期一凌晨4点）: " CUSTOM_CRON
    CRON_EXPRESSION=${CUSTOM_CRON:-"0 4 * * 1"}

    # 创建文件夹前判断文件夹是否存在
    if [ ! -d "$PWD/TypechoBackupScript" ]; then
        mkdir -p "$PWD/TypechoBackupScript"
    else
        echo -e "${RED}$PWD/TypechoBackupScript文件夹已存在，无需再次创建。${NC}"
    fi
    
    # 创建并写入定时任务到 crontab
    CRON_JOB="$CRON_EXPRESSION /bin/bash $BACKUP_SCRIPT_PATH"
    (crontab -l ; echo "$CRON_JOB") | crontab -

    create_backup_script

    # 记录用户配置信息到文件
    echo "TYPECHO_DIR=\"$TYPECHO_DIR\"" > $CONFIG_FILE
    echo "REMOTE_NAME=\"$REMOTE_NAME\"" >> $CONFIG_FILE
    echo "REMOTE_FOLDER=\"$REMOTE_FOLDER\"" >> $CONFIG_FILE
    echo "CUSTOM_CRON=\"$CRON_EXPRESSION\"" >> $CONFIG_FILE

    # 提示用户安装完成
    echo -e "首次运行一键安装完成！已创建定时备份任务和备份脚本。"

    # 询问用户是否现在进行一次 Typecho 备份
    read -p "是否现在进行一次 Typecho 备份？（输入Y或N）: " MANUAL_RUN
    if [ "$MANUAL_RUN" == "Y" ] || [ "$MANUAL_RUN" == "y" ]; then
        /bin/bash $BACKUP_SCRIPT_PATH
    fi
else
    # 读取配置文件
    source $CONFIG_FILE

    # 显示脚本文件和定时任务状态
    echo -e "\n------ Typecho2Rclone备份脚本操作菜单 ------"
    
    # 检测脚本文件是否已安装
    if [ -f "$BACKUP_SCRIPT_PATH" ]; then
        echo -e "脚本文件状态: ${GREEN}已安装${NC}"
    else
        echo -e "脚本文件状态: ${RED}未安装${NC}"
    fi

    # 检测定时任务是否已安装
    CRONTAB_RESULT=$(crontab -l | grep "$BACKUP_SCRIPT_PATH")
    if [ -n "$CRONTAB_RESULT" ]; then
        echo -e "定时任务状态: ${GREEN}已安装${NC}"
    else
        echo -e "定时任务状态: ${RED}未安装${NC}"
    fi

    # 显示配置信息
	echo -e "------------------------------"
    echo -e "当前配置信息："
    echo "本地备份目录：$TYPECHO_DIR"
    echo "网盘远程目录：$REMOTE_FOLDER"
    echo "Rclone远程配置：$REMOTE_NAME"
    echo "定时备份时间的Cron表达式：$CUSTOM_CRON"

    # 菜单形式处理修改配置、卸载和手动备份功能
    while true; do
        echo -e "------------------------------"
        echo "1. 手动运行备份程序"
        echo "2. 修改配置信息"
        echo "3. 卸载脚本"
        echo "4. 退出"
        read -p "请输入操作的序号: " choice

        case $choice in
            1)
                /bin/bash $BACKUP_SCRIPT_PATH
                ;;
            2)
                # 提示用户输入修改后的变量
                while true; do
                    read -p "请输入新的 Typecho 网页文件夹的绝对路径（当前：$TYPECHO_DIR，跳过则不变）: " NEW_TYPECHO_DIR
                    if [ -d "$NEW_TYPECHO_DIR" ]||["$NEW_TYPECHO_DIR" = ""]; then
                        TYPECHO_DIR=${NEW_TYPECHO_DIR:-"$TYPECHO_DIR"}
                        break
                    else
                        echo "目录不存在，请重新输入。"
                    fi
                done

                while true; do
                    read -p "请输入新的 Rclone 的网盘配置的名称（当前：$REMOTE_NAME，跳过则不变）: " NEW_REMOTE_NAME
                        RCLONE_CONFIGS=$(rclone listremotes)
                    if echo "$RCLONE_CONFIGS" | grep -q "$NEW_REMOTE_NAME"|| [ "$NEW_REMOTE_NAME" = "" ]; then
                        REMOTE_NAME=${NEW_REMOTE_NAME:-"$REMOTE_NAME"}
                        break
                    else
                        echo "Rclone配置不存在，请重新输入或完成相关Rclone配置。"
                    fi
                done

                read -p "请输入新的 Rclone 远程文件夹的路径（当前：$REMOTE_FOLDER，跳过则不变）: " NEW_REMOTE_FOLDER
                REMOTE_FOLDER=${NEW_REMOTE_FOLDER:-"$REMOTE_FOLDER"}

                read -p "请输入新的定时备份时间的 cron 表达式（当前：$CUSTOM_CRON，跳过则不变）: " NEW_CUSTOM_CRON
                CUSTOM_CRON=${NEW_CUSTOM_CRON:-"$CUSTOM_CRON"}

                # 更新用户配置信息到文件
                echo "TYPECHO_DIR=\"$TYPECHO_DIR\"" > $CONFIG_FILE
                echo "REMOTE_NAME=\"$REMOTE_NAME\"" >> $CONFIG_FILE
                echo "REMOTE_FOLDER=\"$REMOTE_FOLDER\"" >> $CONFIG_FILE
                echo "CUSTOM_CRON=\"$CUSTOM_CRON\"" >> $CONFIG_FILE

                create_backup_script
                
                # 删除旧定时任务并写入写入定时任务到 crontab
                crontab -l | grep -v "$BACKUP_SCRIPT_PATH" | crontab -
                CRON_JOB="$CUSTOM_CRON /bin/bash $BACKUP_SCRIPT_PATH"
                (crontab -l ; echo "$CRON_JOB") | crontab -

                echo -e "${GREEN}配置信息修改完成！${NC}"
                ;;
            3)
                # 防误操作确认
                read -p "请输入\"Uninstall\"以确认卸载脚本: " UNINSTALL_CONFIRM
                if [ "$UNINSTALL_CONFIRM" == "Uninstall" ]; then
                    # 删除相关crontab命令和文件夹
                    crontab -l | grep -v "$BACKUP_SCRIPT_PATH" | crontab -
                    rm -rf "$PWD/TypechoBackupScript"
                    echo -e "${GREEN}脚本已卸载，相关定时任务和文件夹已删除。${NC}"
                    break
                else
                    echo -e "${RED}卸载操作已取消。${NC}"
                fi
                ;;
            4)
                echo "退出脚本。"
                break
                ;;
            *)
                echo -e "${RED}无效的选择，请重新输入。${NC}"
                ;;
        esac
    done
fi
