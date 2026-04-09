#!/bin/bash

# ==================== 配置 ====================
REMOTE_HOST="your_server_ip"
REMOTE_USER="root"
REMOTE_PORT="22"
REMOTE_DIR="/remote/backup/"
LOCAL_DIR="/local/backup/"
PASS_FILE="/root/.secure/rsync.pass"
LOG_FILE="/var/log/rsync_sync.log"

# ==================== 日志函数 ====================
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

# ==================== 开始同步 ====================
log_message "========== 开始同步远程备份 =========="
log_message "远程主机: ${REMOTE_HOST}"
log_message "远程目录: ${REMOTE_DIR}"
log_message "本地目录: ${LOCAL_DIR}"

# 创建本地目录
mkdir -p "${LOCAL_DIR}"

# 执行rsync同步
export SSHPASS=$(cat ${PASS_FILE})
rsync -avz --delete \
    --rsh="sshpass -e ssh -p ${REMOTE_PORT} -o StrictHostKeyChecking=no" \
    "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}" \
    "${LOCAL_DIR}" >> "${LOG_FILE}" 2>&1

if [ $? -eq 0 ]; then
    log_message "同步成功完成"
    
    # 显示同步的文件数量
    SYNC_COUNT=$(find "${LOCAL_DIR}" -type f -name "*.gz" | wc -l)
    log_message "当前本地备份文件数量: ${SYNC_COUNT}"
else
    log_message "同步失败！请检查网络和配置"
    exit 1
fi

log_message "========== 同步结束 ==========\n"
