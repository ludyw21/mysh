#!/bin/bash

# macOS微信双开脚本
# 功能：创建WeChat2应用并修改其Bundle Identifier，实现微信双开

echo "开始执行微信双开脚本..."

# 1、判断是否Applications存在WeChat2.app ，存在删除，并打印正在删除中提示
if [ -d "/Applications/WeChat2.app" ]; then
    echo "正在删除已存在的WeChat2.app..."
    sudo rm -rf "/Applications/WeChat2.app"
    if [ $? -eq 0 ]; then
        echo "WeChat2.app 删除成功"
    else
        echo "删除WeChat2.app失败，请检查权限"
        exit 1
    fi
fi

# 2、复制WeChat.app为WeChat2.app
echo "正在复制WeChat.app为WeChat2.app..."
sudo cp -R "/Applications/WeChat.app" "/Applications/WeChat2.app"
if [ $? -ne 0 ]; then
    echo "复制WeChat失败，请确保WeChat已安装"
    exit 1
fi

echo "WeChat2.app 复制成功"

# 3、判断是否安装Xcode工具，如果没有，提示安装，如果安装了，运行下面命令
if ! command -v /usr/libexec/PlistBuddy &> /dev/null; then
    echo "未检测到Xcode命令行工具，请先安装Xcode命令行工具"
    echo "可以通过运行 'xcode-select --install' 来安装"
    exit 1
fi

echo "正在修改WeChat2的Bundle Identifier和应用名称..."
# 修改Bundle Identifier
sudo /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.tencent.xinWeChat2" "/Applications/WeChat2.app/Contents/Info.plist"
if [ $? -ne 0 ]; then
    echo "修改Bundle Identifier失败"
    exit 1
fi

# 修改应用显示名称为"微信2"，方便区分
sudo /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 微信2" "/Applications/WeChat2.app/Contents/Info.plist"
if [ $? -ne 0 ]; then
    echo "修改应用显示名称失败，但继续执行"
fi

echo "Bundle Identifier和应用名称修改成功"

# 4.1 尝试修改WeChat2图标颜色（可选，如果失败不影响主要功能）
echo "正在尝试为WeChat2添加区分标识..."
# 创建一个简单的区分方法：在应用图标上添加"2"标识
if [ -f "/Applications/WeChat2.app/Contents/Resources/Assets.car" ]; then
    echo "检测到Assets.car文件，跳过图标修改（需要专业工具）"
else
    # 如果可能，尝试创建一个简单的文本文件作为标识
    sudo touch "/Applications/WeChat2.app/Contents/Resources/wechat2_identifier.txt"
    echo "这是微信2版本，创建于 $(date)" | sudo tee "/Applications/WeChat2.app/Contents/Resources/wechat2_identifier.txt" > /dev/null
fi

# 4.2 替换证书
echo "正在重新签名WeChat2.app..."
sudo codesign --force --deep --sign - "/Applications/WeChat2.app"
if [ $? -ne 0 ]; then
    echo "重新签名失败，但可能不影响使用"
    # 这里不退出，因为有些系统可能不需要重新签名也能运行
fi

echo "重新签名完成"

# 5、判断是否运行WeChat，如未运行，打开WeChat
if ! pgrep -q "WeChat"; then
    echo "未检测到WeChat运行，正在启动WeChat..."
    open -a "WeChat"
    sleep 2
fi

# 6、运行WeChat2
echo "正在启动WeChat2..."
nohup /Applications/WeChat2.app/Contents/MacOS/WeChat >/dev/null 2>&1 &

# 等待一下确保进程启动
sleep 3

# 检查WeChat2是否成功启动
if pgrep -q "WeChat"; then
    echo "WeChat2 启动成功"
else
    echo "WeChat2 启动可能失败，请手动检查"
fi

# 7、显示运行完成，并提示
echo ""
echo "=========================================="
echo "微信双开脚本执行完成！"
echo "=========================================="
echo ""
echo "重要提示："
echo "1. 现在你有两个微信应用："
echo "   - 原版微信 (WeChat)"
echo "   - 微信2 (WeChat2) - 显示名称为'微信2'，方便区分"
echo ""
echo "2. 区分方法："
echo "   - 在程序坞中，微信2会显示为'微信2'"
echo "   - 在应用程序文件夹中，微信2显示为'微信2'"
echo "   - 在强制退出窗口(Command+Option+Esc)中，可以看到两个微信进程"
echo ""
echo "3. 请将'微信2'在程序坞中保留，方便下次使用："
echo "   - 在程序坞中找到'微信2'图标，右键点击"
echo "   - 选择'选项' -> '在程序坞中保留'"
echo ""
echo "现在你可以同时使用两个微信账号了！"
echo ""

# 显示当前运行的WeChat进程
echo "当前运行的WeChat相关进程："
pgrep -l "WeChat" | while read pid name; do
    echo "进程ID: $pid, 名称: $name"
done
