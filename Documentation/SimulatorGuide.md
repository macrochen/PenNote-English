# 模拟器文件操作指南

## 1. 查找运行中的模拟器
```bash
xcrun simctl list devices | grep Booted
```

## 2. 查看应用信息
```bash
xcrun simctl listapps 设备ID
 ```

例如：

```bash
xcrun simctl listapps 7B5E1B5A-9919-4B24-A5CC-559B4DFA129D
 ```

## 3. 复制文件到模拟器
```bash
cp "/Users/shi/workspace/PenNote English/Documentation/Vocabulary.md" "/Users/shi/Library/Developer/CoreSimulator/Devices/设备ID/data/Containers/Data/Application/应用ID/Documents/"
 ```
```

## 4. 快速使用示例
以下是一个完整的复制命令示例：

```bash
cp "/Users/shi/workspace/PenNote English/Documentation/Vocabulary.md" "/Users/shi/Library/Developer/CoreSimulator/Devices/7B5E1B5A-9919-4B24-A5CC-559B4DFA129D/data/Containers/Data/Application/C7FCC056-D196-4FA7-B5D4-5489DC9501D2/Documents/"
 ```

## 注意事项
1. 确保应用至少运行过一次，这样 Documents 目录才会创建
2. 设备ID和应用ID会随着模拟器重置而改变
3. Bundle ID 是 com.macrochen.PenNote-English