SKIPUNZIP=0

ui_print "*****************************************"
ui_print "*        微信来电自动接听模块(助老版)   *"
ui_print "*           单次生命周期纯净版          *"
ui_print "*****************************************"
ui_print "- 正在部署后台自动化接听服务..."

set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/answer_once.sh 0 0 0755

# 初始化配置文件：如果用户手机上还没有配置文件，默认创建为 3 秒方便测试
CONFIG_PATH="/sdcard/微信接听秒数.txt"
if [ ! -f "$CONFIG_PATH" ]; then
    echo "3" > "$CONFIG_PATH"
    ui_print "- 已创建配置文件：/sdcard/微信接听秒数.txt"
    ui_print "- 当前默认设置为：3 秒（方便测试）"
else
    CURRENT_SEC=$(cat "$CONFIG_PATH" 2>/dev/null | tr -cd '0-9')
    ui_print "- 读取到已有配置：${CURRENT_SEC:-3} 秒"
fi

ui_print "-----------------------------------------"
ui_print "【特性】：每次来电独立启动一个生命周期，"
ui_print "执行完毕立即彻底退出销毁，不驻留无效进程！"
ui_print "-----------------------------------------"
ui_print "- 安装完成！请重启手机生效。"
ui_print "*****************************************"
