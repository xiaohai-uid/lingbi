# 灵笔零基础使用指南

这份指南面向不使用命令行的 Windows 用户。

## 1. 下载正确的文件

打开 [GitHub Releases](https://github.com/xiaohai-uid/lingbi/releases/latest)：

- 普通用户下载 `Lingbi-Setup-1.1.0.exe`。
- 不想安装时，下载 `Lingbi-Windows-Portable-1.1.0.zip`。
- 不要下载 GitHub 自动生成的 `Source code (zip)`；那是源代码，不能双击运行。

## 2. 安装版

1. 双击 `Lingbi-Setup-1.1.0.exe`。
2. 如果 SmartScreen 弹窗，请先确认文件来自本仓库 Release，并核对 `SHA256SUMS.txt`。
3. 确认无误后选择“更多信息 → 仍要运行”。
4. 按安装向导完成安装，从桌面或开始菜单启动“灵笔”。

卸载不会主动删除 `%USERPROFILE%\Documents\灵笔` 中的作品。

## 3. 免安装版

1. 右键 ZIP，选择“全部解压缩”。
2. 打开解压后的文件夹，双击 `lingbi.exe`。
3. 不要只把 `lingbi.exe` 单独拖走；旁边的 DLL 和 `data` 目录也是程序的一部分。

## 4. 首次配置 AI

首次启动会显示配置向导：

1. 阅读隐私说明。
2. 选择 SenseNova、DeepSeek、OpenAI、Anthropic 或自定义兼容端点。
3. 输入自己的 API Key。
4. 选择模型并运行连接测试。

API Key 只用于连接所选提供商，并存入 Windows 安全存储。模型服务的可用性、限额和费用由提供商决定。

## 5. 创建第一本书

1. 点击“新建项目”。
2. 填写书名、题材和创作目标。
3. 在左侧章节区新建章节并开始写作。
4. 使用 AI 时先检查候选稿，满意后再点击采用。
5. 完成章节后运行章节结算，只确认真正发生的事实。

项目默认保存在 `%USERPROFILE%\Documents\灵笔`。建议把整个作品目录纳入日常备份。

## 6. 导出作品

在项目的“发布”区域选择 Markdown、TXT、DOCX 或 PDF。导出前检查章节顺序、标题和正文；AI 审稿结果只是建议，不能代替作者终审。

## 7. 升级

1. 先备份 `%USERPROFILE%\Documents\灵笔`。
2. 退出正在运行的灵笔。
3. 下载并运行新版安装器；安装到原目录即可升级。
4. 启动后打开一份旧项目，确认章节和资料正常。

仍未解决的问题请查看[常见问题](FAQ.md)，提交 Issue 时不要附带 API Key 或未脱敏的私人作品。
