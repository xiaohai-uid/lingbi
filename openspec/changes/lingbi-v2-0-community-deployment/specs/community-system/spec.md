## ADDED Requirements

### Requirement: 自动更新检查器
The system SHALL check for new versions on GitHub Releases at startup and notify the user.

#### Scenario: 启动时检查更新
- **WHEN** 启动器初始化完成
- **THEN** 异步请求 GitHub Releases API
- **AND** 比较远程版本 vs 本地版本
- **AND** 有新版本时在 UI 显示通知横幅

#### Scenario: 用户忽略更新
- **WHEN** 用户点击"稍后提醒"
- **THEN** 通知关闭
- **AND** 下次启动时再次检查

#### Scenario: 用户下载更新
- **WHEN** 用户在启动器点击"检查更新"
- **THEN** 立即检查最新版本
- **AND** 显示新版本信息（版本号、发布日期、更新内容）
- **AND** 提供下载链接

### Requirement: Skill 市场
The system SHALL provide a built-in Skill marketplace where users can browse, install, and manage community-contributed skills.

#### Scenario: 浏览 Skill 列表
- **WHEN** 用户打开 Skill 市场面板
- **THEN** 从远程 skill-registry.json 获取 Skill 列表
- **AND** 显示每个 Skill 的名称、作者、评分、描述
- **AND** 区分"已安装"和"可安装"

#### Scenario: 安装 Skill
- **WHEN** 用户点击某个 Skill 的"安装"按钮
- **THEN** 从远程仓库下载 Skill 文件到本地 skills 目录
- **AND** 注册到 Skill 管理器
- **AND** 安装完成后状态更新为"已安装"
- **AND** 立即生效无需重启

#### Scenario: 卸载 Skill
- **WHEN** 用户在"已安装"页面点击"卸载"
- **THEN** 从 skills 目录删除 Skill 文件
- **AND** 从 Skill 管理器注销
- **AND** 状态更新为"可安装"

### Requirement: 社区网站
The community SHALL have a GitHub Pages website for documentation, skill directory, and changelog.

#### Scenario: 访问社区网站
- **WHEN** 用户访问社区网站 URL
- **THEN** 显示项目首页
- **AND** 导航栏包含：首页、文档、Skills、更新日志、贡献

#### Scenario: Skill 目录页面
- **WHEN** 用户点击导航栏的"Skills"
- **THEN** 显示 Skill 目录页面
- **AND** 每个 Skill 卡片显示：名称、作者、描述、版本
- **AND** 点击可查看详情

#### Scenario: 更新日志页面
- **WHEN** 用户点击"更新日志"
- **THEN** 显示按时间倒序排列的版本列表
- **AND** 每个版本显示：版本号、日期、变更内容