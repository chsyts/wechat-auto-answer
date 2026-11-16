#!/system/bin/sh
MODDIR=/data/adb/modules/wechat_auto_answer

LOG_FILE="/data/local/tmp/wx_auto_answer.log"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 微信来电硬件级守护服务已启动" > "$LOG_FILE"

pkill -f "answer_once.sh" 2>/dev/null

while true; do
    sleep 1

    # 1. 硬件级核心检测：活跃播放器列表中存在微信来电响铃流 (state:started + USAGE_NOTIFICATION_RINGTONE)
    IS_RING_AUDIO=$(dumpsys audio 2>/dev/null | grep "state:started" | grep "USAGE_NOTIFICATION_RINGTONE")

    # 2. 窗口级检测：微信全屏通话界面
    IS_FULL_VOIP=$(dumpsys window 2>/dev/null | grep -E "mCurrentFocus|mFocusedApp" | grep "com.tencent.mm" | grep -iE "Voip|VideoActivity")

    # 只要正在响铃，或者处于全屏通话窗口
    if [ -n "$IS_RING_AUDIO" ] || [ -n "$IS_FULL_VOIP" ]; then
        # 排除已接通的通话 (已进入语音通讯流)
        IS_CONNECTED=$(dumpsys audio 2>/dev/null | grep "state:started" | grep "USAGE_VOICE_COMMUNICATION")
        if [ -n "$IS_CONNECTED" ]; then
            sleep 2
            continue
        fi

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 硬件侦测到来电信号，启动接听程序..." >> "$LOG_FILE"

        # 执行单次生命周期接听
        sh "$MODDIR/answer_once.sh"

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 接听指令已发送，进入通话保护锁定状态..." >> "$LOG_FILE"

        # 锁定：只要还在通话中，绝不重复触发
        while true; do
            sleep 2
            IN_CALL=$(dumpsys audio 2>/dev/null | grep "state:started" | grep "USAGE_VOICE_COMMUNICATION")
            IN_WIN=$(dumpsys window 2>/dev/null | grep -E "mCurrentFocus|mFocusedApp" | grep "com.tencent.mm" | grep -iqE "Voip|VideoActivity")
            if [ -z "$IN_CALL" ] && [ -z "$IN_WIN" ]; then
                break
            fi
        done

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 通话已结束挂断，解除锁定，恢复正常待命状态。" >> "$LOG_FILE"
        sleep 2
    fi
done
