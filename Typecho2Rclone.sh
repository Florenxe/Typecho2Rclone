#!/bin/bash

SCRIPT_DIR="$PWD/TypechoBackupScript"
CONFIG_FILE="$SCRIPT_DIR/config.txt"
BACKUP_SCRIPT_PATH="$SCRIPT_DIR/Typecho2Rclone_script.sh"

# ANSI颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

function create_backup_script() {
    local config=$1
    local archive_name=$(basename "$config" .txt)
    local backup_script="$SCRIPT_DIR/${archive_name}_backup.sh"
    
    # 读取配置文件
    source "$config"

    # 创建并写入备份脚本
    cat <<EOF > $backup_script
#!/bin/bash

# 固定备份文件路径
TMP_DIR="/tmp/${archive_name}_temp"
mkdir -p \$TMP_DIR
BACKUP_FILE="\$TMP_DIR/${archive_name}_backup_\$(date +"%Y%m%d%H%M%S").tar.gz"

# 复制 Typecho 网页文件夹至临时文件夹
cp -r $TYPECHO_DIR \$TMP_DIR

# 打包 Typecho 网页文件夹
tar -czvf \$BACKUP_FILE -C \$TMP_DIR .

# 使用 Rclone 移动（move）到网盘指定文件夹
rclone move \$BACKUP_FILE $REMOTE_NAME:$REMOTE_FOLDER -v

# 删除临时文件夹
rm -rf \$TMP_DIR

echo "$archive_name 备份并通过 Rclone 上传到网盘完成！"
EOF
}

# 函数：显示所有档案的状态
function show_archives() {
    echo -e "\n------ 已配置的备份档案 ------"
    for config in $SCRIPT_DIR/*.txt; do
        if [ -f "$config" ]; then
            local archive_name=$(basename "$config" .txt)
            echo -e "\n档案名：$archive_name"
            source "$config"
            echo "本地备份目录：$TYPECHO_DIR"
            echo "网盘远程目录：$REMOTE_FOLDER"
            echo "Rclone远程配置：$REMOTE_NAME"
            echo "定时备份时间的Cron表达式：$CUSTOM_CRON"
        fi
    done
}

# 函数：创建新档案
function create_new_archive() {
    read -p "请输入新的备份档案名称: " archive_name
    local config="$SCRIPT_DIR/${archive_name}.txt"
    
    if [ -f "$config" ]; then
        echo -e "${RED}该档案已存在，请选择其他名称。${NC}"
        return
    fi

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

    # 记录用户配置信息到文件
    echo "TYPECHO_DIR=\"$TYPECHO_DIR\"" > $config
    echo "REMOTE_NAME=\"$REMOTE_NAME\"" >> $config
    echo "REMOTE_FOLDER=\"$REMOTE_FOLDER\"" >> $config
    echo "CUSTOM_CRON=\"$CRON_EXPRESSION\"" >> $config

    # 创建备份脚本
    create_backup_script "$config"

    # 创建并写入定时任务到 crontab
    CRON_JOB="$CRON_EXPRESSION /bin/bash $SCRIPT_DIR/${archive_name}_backup.sh"
    (crontab -l ; echo "$CRON_JOB") | crontab -

    echo -e "${GREEN}新备份档案 \"$archive_name\" 创建成功！${NC}"
}

# 函数：删除档案
function delete_archive() {
    read -p "请输入要删除的备份档案名称: " archive_name
    local config="$SCRIPT_DIR/${archive_name}.txt"
    local backup_script="$SCRIPT_DIR/${archive_name}_backup.sh"

    if [ ! -f "$config" ]; then
        echo -e "${RED}该档案不存在，请检查名称。${NC}"
        return
    fi

    # 删除相关crontab命令和文件
    crontab -l | grep -v "$backup_script" | crontab -
    rm -f "$config"
    rm -f "$backup_script"

    echo -e "${GREEN}备份档案 \"$archive_name\" 已成功删除。${NC}"
}

# 创建文件夹
if [ ! -d "$SCRIPT_DIR" ]; then
    mkdir -p "$SCRIPT_DIR"
else
    echo -e "${RED}$SCRIPT_DIR文件夹已存在。${NC}"
fi

# 显示脚本菜单
while true; do
    echo -e "\n------ Typecho2Rclone备份脚本操作菜单 ------"
    echo "1. 显示所有备份档案"
    echo "2. 创建新的备份档案"
    echo "3. 删除现有备份档案"
    echo "4. 手动运行备份程序"
    echo "5. 退出"
    read -p "请输入操作的序号: " choice

    case $choice in
        1)
            show_archives
            ;;
        2)
            create_new_archive
            ;;
        3)
            delete_archive
            ;;
        4)
            read -p "请输入要手动运行的备份档案名称: " archive_name
            /bin/bash "$SCRIPT_DIR/${archive_name}_backup.sh"
            ;;
        5)
            echo "退出脚本。"
            break
            ;;
        *)
            echo -e "${RED}无效的选择，请重新输入。${NC}"
            ;;
    esac
done
