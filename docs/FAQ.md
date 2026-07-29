# 常见问题

## Windows 阻止安装器运行

当前公开安装器未使用商业代码签名证书，因此可能触发 SmartScreen。只从本仓库 Release 下载，使用同一 Release 的 `SHA256SUMS.txt` 核对文件后，再决定是否运行。来源不明或哈希不一致时请立即删除。

## 下载后只有源代码，没有程序

你下载了 GitHub 自动生成的 `Source code`。请回到 [Releases](https://github.com/xiaohai-uid/lingbi/releases/latest)，选择 `Lingbi-Setup-1.1.0.exe` 或 `Lingbi-Windows-Portable-1.1.0.zip`。

## 免安装版双击没有反应

先把 ZIP 完整解压，再从解压目录运行 `lingbi.exe`。不要直接在压缩包预览窗口运行，也不要只复制 EXE。

## 不配置 API Key 能用吗

可以使用本地项目、编辑、资料整理和导出。AI 生成、审稿和联网能力需要可用的模型或搜索服务。

## API Key 保存在哪里

灵笔优先使用 Windows 安全存储，不把密钥写进项目、日志或发布来源证明。安全存储不可用时，界面会提示密钥只能在当前会话使用。

## AI 一直提示限流或 429

这是模型提供商的频率或额度限制。等待后重试、降低并发、检查余额，或切换其他模型。灵笔会阻止这类错误文本被当成章节正文采用。

## 我的作品在哪里

默认位置是 `%USERPROFILE%\Documents\灵笔`。自定义项目位置时，以创建项目时选择的目录为准。

## 卸载会删除作品吗

不会主动删除作品目录。重要作品仍应单独备份，不能把“不会主动删除”等同于备份。

## 如何提交问题

先搜索已有 [Issues](https://github.com/xiaohai-uid/lingbi/issues)。新建 Issue 时写明灵笔版本、Windows 版本、操作步骤和实际现象；日志、截图和示例文本必须先删除 API Key 与私人内容。
