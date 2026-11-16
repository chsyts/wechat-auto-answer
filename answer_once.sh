#!/system/bin/sh
# ==============================================================
# 微信单次接听脚本 (answer_once.sh) - 精准单次无重复版
# ==============================================================

LOG_FILE="/data/local/tmp/wx_auto_answer.log"
CONFIG_FILE="/sdcard/微信接听秒数.txt"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_msg "【单次接听流程开始】..."

# 1. 获取等待秒数
WAIT_SEC=3
if [ -f "$CONFIG_FILE" ]; then
    USER_VAL=$(cat "$CONFIG_FILE" 2>/dev/null | tr -cd '0-9')
    if [ -n "$USER_VAL" ] && [ "$USER_VAL" -ge 1 ]; then
        WAIT_SEC=$USER_VAL
    fi
fi

log_msg "缓冲等待 $WAIT_SEC 秒..."
sleep $WAIT_SEC

# 2. 点亮屏幕并解锁
IS_AWAKE=$(dumpsys power 2>/dev/null | grep -i "mWakefulness=" | grep -i "Awake")
if [ -z "$IS_AWAKE" ]; then
    input keyevent 26
    sleep 0.3
    input keyevent 82
    sleep 0.3
fi

# 3. 检查是否已被长辈手动接通（通话语音流 USAGE_VOICE_COMMUNICATION 已启动）
IS_CONNECTED=$(dumpsys audio 2>/dev/null | grep "state:started" | grep "USAGE_VOICE_COMMUNICATION")
if [ -n "$IS_CONNECTED" ]; then
    log_msg "【已接通】检测到通话已接听，无需代接，安全退出"
    exit 0
fi

# 4. 获取屏幕物理分辨率并计算坐标
RES=$(wm size 2>/dev/null | grep -oE '[0-9]+x[0-9]+' | tail -n 1)
SCREEN_W=$(echo "$RES" | cut -d'x' -f1)
SCREEN_H=$(echo "$RES" | cut -d'x' -f2)

# 实测精准中心坐标（1080x2340 下：顶部为 924, 408；全屏为 864, 1965）
TOP_X=$(( SCREEN_W * 855 / 1000 ))
TOP_Y=$(( SCREEN_H * 174 / 1000 ))
BOT_X=$(( SCREEN_W * 80 / 100 ))
BOT_Y=$(( SCREEN_H * 84 / 100 ))

# 5. 判断是全屏模式还是顶部卡片模式（只点目标按键一次，绝不乱点其他位置！）
IS_FULL_WIN=$(dumpsys window 2>/dev/null | grep -E "mCurrentFocus|mFocusedApp" | grep "com.tencent.mm.*VideoActivity")

if [ -n "$IS_FULL_WIN" ]; then
    log_msg "【全屏来电】仅精准点击右下角一次: ($BOT_X, $BOT_Y)"
    input tap $BOT_X $BOT_Y
else
    log_msg "【顶部卡片】仅精准点击右上角一次: ($TOP_X, $TOP_Y)"
    input tap $TOP_X $TOP_Y
fi

log_msg "【单次点击完成】接听命令已下发，进程彻底退出！"
exit 0
