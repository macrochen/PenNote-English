#!/bin/bash

# 获取正在运行的模拟器ID
DEVICE_ID=$(xcrun simctl list devices | grep Booted | grep -o "[0-9A-F]\{8\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{12\}")

if [ -z "$DEVICE_ID" ]; then
    echo "错误：没有找到正在运行的模拟器"
    exit 1
fi

echo "模拟器 ID: $DEVICE_ID"

# 获取应用信息
APP_INFO=$(xcrun simctl listapps $DEVICE_ID)

# 打印应用详细信息
echo "应用详细信息："
echo "$APP_INFO" | grep -A15 "com.macrochen.PenNote-English"

# 提取 DataContainer 路径
APP_PATH=$(echo "$APP_INFO" | grep -A10 "com.macrochen.PenNote-English" | grep "DataContainer" | cut -d'"' -f2)

if [ -z "$APP_PATH" ]; then
    echo "错误：没有找到 PenNote English 应用"
    exit 1
fi

# 添加 Documents 目录
DOCUMENTS_PATH="${APP_PATH}Documents"

if [ -d "$DOCUMENTS_PATH" ]; then
    echo "应用文档目录: $DOCUMENTS_PATH"
else
    echo "警告：文档目录不存在，请确保应用已经运行过"
fi