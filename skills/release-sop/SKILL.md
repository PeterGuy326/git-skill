---
name: release-sop
description: 通用 Git 项目发布 SOP 引导 skill（适用于 GitHub / GitLab / Gitea 等 Git 主机；可装入 Claude Code / Qoder / Cursor / 通用 LLM 等任意 AI Agent）。按"项目识别 → 身份对齐 → 版本号推荐 → PR准入回放 → Pre-flight → Cut PR → 打Tag → 盯盘 → 发布后验证 → 群消息公告 → DOD"十一步走，每步有 gate、命令、失败处置；自动读取最新 tag + `[Unreleased]` 按 SemVer 推荐 patch / minor / major 让 Captain 反问确认，CHANGELOG 走单独 Cut PR 过队友 review（禁止 self-approve），发版后强制发结构化群公告（钉钉/飞书/Slack/Teams/Discord）触达 Watch 仓库以外的用户。Triggers on '/release-sop', 'release sop', '发版sop', '走发版流程', '帮我发版', 'cut a release', 'tag and release'.
---

# Release SOP — 通用 Git 项目发布流程（多 Agent 兼容）

## 触发条件

用户提到以下任一即激活：
- 显式：`/release-sop`、`release sop`、`发版 sop`、`走发版流程`
- 隐式：`帮我发版`、`发 vX.Y.Z`、`cut a release`、`tag and release`、`打 tag 发布`

## 行为协议

你是 Release Captain 的副驾。你不是按钮工——你是承诺的 co-owner。

激活后立即按以下步骤执行，**任何 gate 失败立即停在该步，不允许跳过**。

---

### Step 0 — 项目识别

读取仓库根目录，识别项目类型与发布工具：

| 探针 | 推断 |
|---|---|
| `.goreleaser.yaml` / `.goreleaser.yml` | Go + GoReleaser |
| `package.json` 含 `"publishConfig"` 或 npm scripts | Node + npm |
| `pyproject.toml` / `setup.py` | Python + poetry/twine |
| `Cargo.toml` 含 `[package]` | Rust + cargo |
| `Dockerfile` + GHCR/Docker Hub 配置 | Docker image |
| `.github/workflows/release*.yml` | 已有 release 自动化 |

输出探测结论：项目类型、发布工具、CI workflow 路径、发布渠道清单。

### Step 1 — 身份对齐（必跑，不能跳）

向用户问清以下，缺一不补齐就**禁止进入 Step 1.5**：

1. **Release Captain**（必须是单一具名 owner，不接受"我们"）
2. **本次发版核心价值**（一句话，将写入 CHANGELOG 段落首句）
3. **是否含 Breaking change**（含则要求列出 breaking 项；此项决定 Step 1.5 的 bump 推荐）

> 版本号 `vX.Y.Z` 不在这里手输 —— 由 Step 1.5 按 SemVer 自动推荐再让 Captain 确认。禁止让 Captain 凭空报号。

### Step 1.5 — 版本号推荐（先推荐，再反问）

skill 自跑下述三条命令，**不让 Captain 直接报版本号**，由 skill 读最新 tag + `[Unreleased]` 段后按 SemVer 推荐：

```bash
git fetch --tags
LATEST=$(git tag --sort=-v:refname | head -1)
git log "$LATEST"..HEAD --oneline
awk '/^## \[Unreleased\]/{flag=1;next} /^## \[/{flag=0} flag' CHANGELOG.md
```

按 SemVer 给出 bump 推荐（**Step 1 中 Captain 显式声明的 Breaking 标志优先**）：

| `[Unreleased]` / commits 中含的信号 | 推荐 bump | 例 |
|---|---|---|
| `### Breaking` / `BREAKING CHANGE:` / `feat!:` / `fix!:` / Captain 显式声明 Breaking | **major** (X+1.0.0) | v0.7.2 → v1.0.0 |
| `### Added` 或 `feat(...)` 且无 Breaking | **minor** (X.Y+1.0) | v0.7.2 → v0.8.0 |
| 仅 `### Fixed` / `### Changed` / `### Security` / `### Docs` / `### Removed`（无新增功能、无 Breaking） | **patch** (X.Y.Z+1) | v0.7.2 → v0.7.3 |
| `[Unreleased]` 段空白 / 内容稀缺 | **STOP** | 回 `changelog-bot` 先把已合 PR 的词条补进 `[Unreleased]`，**禁止**在 release-sop 里硬写 |
| 仓库尚无任何 tag（首发） | **由 Captain 显式选号** | 默认推 `v0.1.0`；若项目宣称已稳定可选 `v1.0.0` |

输出格式（强制反问，不允许跳）：

```
[版本推荐]
  上个 tag        : v0.7.2
  自此 commit 数  : N
  [Unreleased] 段 : a 个 ### Added, b 个 ### Fixed, c 个 Breaking
  SemVer 推荐     : 🟢 minor → v0.8.0
  理由            : <一句话；命中哪条规则>
请 Captain 确认:
  [Y] 用推荐 v0.8.0
  [P] 改 patch → vX.Y.Z+1
  [N] 改 minor → vX.Y+1.0
  [M] 改 major → vX+1.0.0
  [其他: 我手输 vA.B.C]
```

Captain 回复明确后，目标版本号 `vX.Y.Z` 锁定，进 Step 2。**SemVer 0.x 阶段一切照常，0.x → 1.0 不自动触发 major**——必须由 Captain 在 Step 1 显式声明"宣告 1.0 稳定"才走 major 路径。

### Step 2 — PR 准入回放（DoR Check）

读取仓库 `CONTRIBUTING.md` 与 `.github/workflows/*.yml`，逐条回放 PR 阶段应过的闸：

- [ ] CI 全绿（lint / unit test / integration test / race / coverage / policy）
- [ ] 行为/接口变化对应 PR 已写好 CHANGELOG 词条
- [ ] 单测/回归测试与实现同 PR 提交
- [ ] 涉及打包/installer 已 dry-run

任意一项 NO → 停在 Step 2，要求用户回 PR 流程修复。

### Step 3 — Pre-flight

按 Step 0 探测的项目类型，引导用户执行对应命令并粘贴输出。命令模板：

```bash
git checkout main && git pull --ff-only
<lint command>
<test command>
<package dry-run command>
<artifact integrity check>
```

具体命令参考：

- **Go + GoReleaser**: `goreleaser release --snapshot --clean`
- **Node + npm**: `npm ci && npm test && npm pack --dry-run`
- **Python + poetry**: `poetry install && poetry run pytest && poetry build`
- **Rust + cargo**: `cargo test && cargo publish --dry-run`
- **Docker**: `docker build -t <img>:test . && docker run --rm <img>:test --version`

验收：所有命令绿、产物清单完整、版本号正确。

### Step 4 — Cut PR（rename `[Unreleased]` → `[X.Y.Z]`，**单独 PR + 过队友 review**）

**关键认知**：本步骤**不是**现写 CHANGELOG 内容 —— 内容应在每个 feature/fix PR 合入时由 `changelog-bot` 已经写进 `[Unreleased]`。本步骤只做一件事：把 `[Unreleased]` 这个游标推进成一个**有日期的版本段**，并通过单独的 Cut PR 让团队评审。

#### Step 4a — Pre-cut gate（开 Cut PR 之前先验）

检查 `[Unreleased]` 内容是否达 `pr-review` Step 5 / `changelog-bot` Step 2 的 granularity：

- [ ] 每条以加粗"现象"开头
- [ ] 带 PR 号 `(#N)`；修 issue 带 `fixes #N`
- [ ] 含根因 + 修复方式 + 影响面（无"修了一个 bug"这类无颗粒度描述）
- [ ] 有 Breaking 时单独 `### Breaking` 段 + 迁移说明

**任意一条不达标 / `[Unreleased]` 为空** ⇒ STOP，回 `changelog-bot` 把已合 PR 的词条补全/重写；**禁止**在 Cut PR 里硬塞新内容（那样 Cut PR 就掺杂了内容写作，队友 review 的颗粒度会糊，团队评审保不住）。

#### Step 4b — Cut PR 的内容（唯一改动是 CHANGELOG）

单开分支 `release/vX.Y.Z`，**该 PR 唯一改动是 `CHANGELOG.md`**：

```markdown
## [Unreleased]

## [X.Y.Z] - YYYY-MM-DD

<一句话总览（取自 Step 1 的"核心价值"）>

### Breaking | Added | Changed | Fixed | Deprecated | Removed | Security
<把原 [Unreleased] 段的内容原样挪下来>
```

即：在 `[Unreleased]` 上方留一个空白 `[Unreleased]` 占位（给下一个发版用），原内容套进 `[X.Y.Z] - YYYY-MM-DD` 段并补上一句话总览。**不允许**在 Cut PR 里同时改代码、改测试、改其他 doc——一旦掺杂，回退并拆分。

#### Step 4c — Cut PR 必须过 pr-review（红线 6）

- PR 标题约定：`docs(changelog): cut vX.Y.Z — <一句话核心价值>`
- 走完整 `pr-review` 流程（Step 1 DoR / Step 5 CHANGELOG gate / Step 7 verdict）
- **Author 不能 approve 自己的 PR**；至少 1 个 teammate review 通过才允许合
- 合并方式：仓库设置而定（rebase / squash / merge-commit，参考 `hotfix-flow` Step 7 同款判断）
- 单人维护项目例外：PR body 必须显式声明 `sole-maintainer release: 本仓库由 @<owner> 单人维护，无可指派 reviewer`，且 Cut PR 创建后 ≥24h cool-off 才允许自合（给自己留时间冷处理回看）。任何捷径都视同违反红线 6

Cut PR 合并到 `main` 之后，再进 Step 5 打 tag —— **tag 必须打在 Cut PR 合并后的 HEAD 上**，否则 release notes 会和 tag 对不上。

### Step 4 ↔ Step 5 因果链（关键认知：Cut PR 合并 ≠ 触发发布）

新手最容易踩的认知陷阱：以为 Cut PR 合到 `main` 那一刻就开始打包发布。**不是**。Cut PR 只是给 `CHANGELOG.md` 盖日期+版本号章，**它合不合都不触发任何 CI 构建/打包/推包动作**。真正的"发布开关"是 Step 5 那一行 `git push origin vX.Y.Z` —— tag 推到远程那一刻 CI 才起飞。

```
[Cut PR 合并到 main]
      ↓
[CHANGELOG 里 [Unreleased] → [X.Y.Z] - DATE 定型]   ← 什么 CI 都不会动
      ↓
[Captain 亲手 git tag -a vX.Y.Z && git push origin vX.Y.Z]   ← ★ 真正的发布触发器（红线 1）
      ↓
[release.yml 监听到 tag push 起飞]
      ↓
[CI 自动: 构建 → 打包 → 上传 Release → 推 registry → 通知下游]
```

| 动作 | 谁做 | 触发什么 |
|---|---|---|
| Cut PR 合并 | 队友 review 通过后 merge | **不触发任何 CI 发布动作** —— 仅让 main 上 `[Unreleased]` 定型成 `[X.Y.Z] - DATE` |
| `git tag -a vX.Y.Z && git push origin vX.Y.Z` | Release Captain 亲手敲（Step 5） | **CI 起飞** —— `release.yml` 跑构建/打包/推包/通知 |
| 构建·打包·推包·下游通知 | CI 全自动（Step 6 盯盘） | —— |

**为什么故意在 Cut PR 合并和 tag push 之间留一个人工闸门？**

- 万一 Cut PR 合错（版本号笔误、Captain 改主意），还能在 `main` 上 revert CHANGELOG；CI 没起飞，包没出去
- 一旦 tag 推出去、CI 跑完、包推到 npm/PyPI/GHCR，红线 2"禁止 unpublish 同号包"约束 —— 不可逆
- 所以 tag push 必须是**人工动作 + 看一眼 `git log -1 --oneline` 确认 HEAD 就是 Cut PR 的 merge commit**（Step 5 第一条命令的作用）

**无 `release.yml` 的纯 docs/skill 仓**：tag 推出去 CI 不会自动发任何包，需要 Captain 手敲 `gh release create vX.Y.Z --notes-from-tag` 创建 GitHub Release（这才有 Release URL 给下游 curl）。

### Step 5 — 打 Tag 触发发布

```bash
git checkout main && git pull --ff-only
git log -1 --oneline    # 确认 HEAD 是 CHANGELOG 落地的 commit
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z
```

push 后立即把 GitHub Actions URL 给用户，进入"盯盘"。

### Step 6 — 盯盘 release.yml

逐步确认每个 step 的通过标志（参考 Step 0 的 workflow 路径）：

| 通用 Step | 通过标志 |
|---|---|
| Checkout / Setup runtime | 版本与代码声明一致 |
| Build & Package | dist/ 产物完整 |
| Upload to GitHub Release | Release 页 asset 齐全 |
| Publish to registry | 包仓库出现新版本 |
| Notify downstream | webhook 已发出 |

每一步出问题 → 进 §故障预案，不允许跳到 Step 7。

### Step 7 — 发布后验证

要求 Captain 亲自跑（不能假设"CI 过了就行"）：

```bash
# 二进制/包下载校验
curl -fL -o /tmp/artifact <release URL>
sha256sum /tmp/artifact

# 干净环境 smoke
HOME=$(mktemp -d) <install command>
HOME=$(mktemp -d) <bin> --version | grep "vX.Y.Z"
HOME=$(mktemp -d) <bin> --help >/dev/null

# 关键路径功能验证
<至少 1 个用户最常用功能>
```

### Step 7.5 — 群消息公告（发版后告知下游）

GitHub Release 发出 + Step 7 smoke 通过后、Step 8 DOD 闭环之前，向团队 / 用户群发一条**结构化公告**。底层逻辑：**Release 页是技术档案，群消息是触达**。两者内容一致但呈现密度不同 —— 一个给会点 GitHub 的人，一个给只看群的人。少了这步，发版等于只发给了 Watch 仓库的人。

#### 通用模板（项目类型无关）

````markdown
## 📦 <project> vX.Y.Z 已发布

**<一句话重磅价值 —— 为什么这一版值得用户立刻关心>**

### <product-icon> <核心功能 1>

<2–3 行解释：覆盖什么场景；为什么是 minor / patch / major>

```bash
<示例命令 1>
<示例命令 2>
```

### <product-icon> <核心功能 2>

<同上>

```bash
<示例命令>
```

### 底层增强

<不直接对外但支撑上面功能的内部变化，1–3 行；带 PR 号>

---

**Release**：<GitHub Release URL>

**升级**：

```bash
<自带升级命令，e.g. dws upgrade>             # 已装过的升级路径
<包管理器全局安装命令，e.g. npm i -g pkg@X>  # 通过包管理器装的路径
```
````

#### 格式约束（实战回踩出来的）

- **图标只用渲染干净的几个** —— 钉钉 / 飞书 / Slack / Teams 里 emoji 渲染差异大。建议**仅保留头部 `📦` + 产品级图标**（如 📊 表格 / 📚 知识库 / 🧠 AI / 🔒 安全）；section 头的装饰图标（`⬆️ 升级` / `⚙️ 底层增强` / `📦 Release` 这类）**用加粗代替**，避免不同客户端 fallback 成方块
- **重磅句必须人话** —— 不要"性能优化 / 体验提升"。说"X 命令现在能用了" / "Y 接口加了 Z 参数" / "上游 W bug 修了"
- **每个 section 配命令示例** —— 群消息读者多数不会点开 Release 页详读，命令示例是他们 5 秒内判断"我用不用得上"的唯一依据
- **底层增强单独一段** —— 分清"用户可感知的" vs "为支撑上面那些做的内部改造"；后者带 PR 号让感兴趣的人能跳 GitHub 看
- **升级命令双路径** —— 项目自带升级机制（`dws upgrade` / `gh extension upgrade` 之类）+ 第三方包管理器全局装路径，覆盖两种典型用户

#### 通道适配

| 通道 | 发法 |
|---|---|
| 钉钉 DingTalk | 自定义机器人 webhook，payload `{"msgtype":"markdown","markdown":{"title":"<project> vX.Y.Z","text":"<模板渲染结果>"}}`；HMAC-SHA256 签名按 webhook 配置带 |
| 飞书 Lark | 自定义机器人 webhook，`msg_type=interactive` 卡片或 `msg_type=text` 文本 |
| Slack | Incoming Webhook，payload `{"text":"<>"}` 或 Block Kit |
| Microsoft Teams | Incoming Webhook，payload `{"@type":"MessageCard","text":"<>"}` |
| Discord | Webhook，payload `{"content":"<>"}` |
| 纯邮件 / 内网 IM | 手贴模板进去 |

#### 工作示例（dws v1.0.25 实例）

> 取自 DingTalk Workspace CLI v1.0.25 发版实例：钉钉表格 / 知识库两个产品上线，CLI 加了 19 个子命令。仅保留头部 📦 + 产品图标 📊 📚，section 头去掉装饰 emoji 改加粗。

````markdown
## 📦 dws v1.0.25 已发布

**重磅：钉钉表格 (sheet) 和 知识库 (wiki) 两个产品正式上线 CLI**

### 📊 钉钉表格 `dws sheet`

覆盖 **19 个子命令**，几乎打通钉钉表格的全部数据操作场景 —— 建表、读写、范围操作、行列增删/移动、合并/拆分、查找替换、筛选视图、图片写入。

```bash
dws sheet create --name "周报模板"
dws sheet list --node <nodeId>
dws sheet range read --node <nodeId> --sheet-id <id> --range A1:Z100
dws sheet append --node <nodeId> --sheet-id <id> --values '[["name","age"],["张三",18]]'
```

### 📚 知识库 `dws wiki`

知识库空间（space）创建/查询/搜索 + 成员（member）增删改的完整 CRUD。

```bash
dws wiki space create --name "工程效能"
dws wiki space search --keyword 知识库
dws wiki member add --space <id> --user <userId> --role READER
```

### 底层增强

为支撑 sheet/wiki 的复杂场景（如 sheet 导出的异步 submit → poll → download），底层加了 CLI 别名扩展（`range read` 同时认 `range get`）、严格 JSON transform、多步 pipeline 执行器（#246 / #247）。

---

**Release**：https://github.com/DingTalk-Real-AI/dingtalk-workspace-cli/releases/tag/v1.0.25

**升级**：

```bash
dws upgrade                              # 已装过 dws
npm i -g dingtalk-workspace-cli@1.0.25   # 通过 npm 安装
```
````

#### Gate

- [ ] 模板填完，Release URL 已粘贴，命令示例**本机至少跑过一遍**
- [ ] 已发送至 **默认团队群** + **下游用户群**（两者通常不同；缺一不算闭环；纯内部工具仅发团队群）
- [ ] 观察 1 小时回复 / 表情反馈，无人报 "装不上" / "用不了" 再进 Step 8（如果有 → 回 Step 7 / 故障预案）

### Step 8 — DOD 闭环

逐项勾选才允许"发布完成"：

- [ ] tag `vX.Y.Z` 在 main HEAD
- [ ] GitHub Release 含全部预期 asset + checksums
- [ ] 所有目标包仓库可拉取
- [ ] CHANGELOG 与 release 内容一致
- [ ] smoke test 在 ≥2 平台通过
- [ ] 团队/下游已周知（即 Step 7.5 群消息公告已发，且观察 1 小时无故障反馈）
- [ ] milestone / 卡片关闭

输出闭环报告（markdown 表格）：版本号、Captain、tag SHA、Release URL、各包仓库 URL、smoke 结果、耗时。

## 自动化轨道（release-please 模式，可选）

不想每次手开 Cut PR 分支、手打 tag？接入 [`googleapis/release-please-action`](https://github.com/googleapis/release-please-action)，把 Step 1.5 / Step 4b / Step 5 打字活儿全自动化，**保留 Step 4c 队友 review + Step 6/7/8 人工盯盘 / smoke / DOD**。底层逻辑不变：tag 仍是唯一发布触发器（红线 1），人工闸门仍在 Cut PR review（红线 6）。

### 自动化吃掉哪几步

| SKILL 步骤 | 手动模式 | release-please 模式 |
|---|---|---|
| Step 1.5 版本推荐 | skill 跑 `git tag` + `awk` + 反问 Captain | **自动** —— bot 读 Conventional Commits (`feat:` / `fix:` / `feat!:`) 自己算下一个版本号 |
| Step 4a Pre-cut gate | 人审 `[Unreleased]` 颗粒度 | `changelog-bot` + `pr-review` 仍在 PR 阶段把关；bot 不写超出 commit 信息的内容 |
| Step 4b Cut PR 内容 | Captain 手开 `release/vX.Y.Z` 分支改 CHANGELOG | **自动** —— bot 永远维护一个常开 Release PR，main 每来一个 commit 就刷新它的版本号与 CHANGELOG |
| Step 4c Cut PR review | 队友 review，红线 6 | **不变** —— Release PR 仍是 PR，照走 `pr-review`；红线 6 仍生效（author 不 self-approve；单人维护项目 24h cool-off） |
| Step 5 打 tag + push | Captain 亲手 `git tag && git push` | **自动** —— 合 Release PR 那一刻 bot 自动 `git tag vX.Y.Z` + 创建 GitHub Release |
| Step 6/7/8 盯盘 + smoke + DOD | 人工 | **不变** —— tag 推出去 CI 起飞，盯盘/smoke 仍要 Captain 亲自跑 |

### 接入成本：~20 行 YAML

新增 `.github/workflows/release-please.yml`：

```yaml
name: release-please
on:
  push:
    branches: [main]
permissions:
  contents: write
  pull-requests: write
jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: googleapis/release-please-action@v4
        with:
          release-type: simple        # 纯仓库/docs；Node 用 node；Go 用 go；Python 用 python；Rust 用 rust
          package-name: <your-repo-name>
```

另需两个文件：
- `.release-please-manifest.json` —— 当前版本号 e.g. `{".": "0.7.2"}`
- `release-please-config.json` —— changelog section 映射（默认 `feat` → Features / `fix` → Bug Fixes；可改写为 Keep-a-Changelog 风格 Added/Changed/Fixed）

### 与 release.yml 配合（发包项目）

下游构建（GoReleaser / npm publish / docker push）继续监听 tag push：

```yaml
on:
  push:
    tags: ['v*']
```

release-please bot 推 tag → release.yml 触发 → 全链路零手动落地。

### 触发条件：Conventional Commits

要让 release-please 算对版本号，PR commit/title 必须遵守 [Conventional Commits](https://www.conventionalcommits.org/)：

| commit 前缀 | release-please 推 bump |
|---|---|
| `feat:` / `feat(scope):` | minor |
| `fix:` / `fix(scope):` / `perf:` / `refactor:` | patch |
| `feat!:` / `fix!:` / footer `BREAKING CHANGE:` | major |
| `docs:` / `test:` / `chore:` / `ci:` / `build:` | 不触发 release（除非 footer 标 `Release-As: vX.Y.Z`） |

本仓库已有的 commit 习惯（`feat(hotfix-flow): ...`、`fix(hotfix-flow): ...`、`docs(changelog): ...`）天然兼容。

### 不推荐的两个替代品

- **`semantic-release`** —— 每次 push 到 main 就自动 tag 发包，**跳过 Cut PR 这个人工闸门**，与红线 6 / 红线 1 的 "tag-only trigger + 人工确认" 哲学正面冲突；仅适合"持续发布"场景（每 commit 一发，不需要队友 review 整个版本）
- **`changesets`** —— 要求开发者每次 PR 手写 `.changeset/*.md` 文件，再由 bot 累积；更适合 monorepo（pnpm/Turborepo）；单仓库太重

### 何时选 release-please vs 手动 SOP？

| 场景 | 推荐轨道 |
|---|---|
| 发布频次 ≥ 每月 1 次；commit 习惯已用 Conventional Commits | **release-please** |
| 发布频次低（季度/半年）；不想引入第三方 bot | **手动 SOP**（Step 1.5 + Step 4 Cut PR 手动版） |
| 多仓库 / monorepo | release-please 的 monorepo 模式（一个 manifest 管多 package） |
| 仓库无外网 / 内网企业镜像 / GitHub Action 不可用 | **手动 SOP**（release-please bot 跑不了） |

无论哪条轨道，**SKILL 的 Step 0–Step 8 都是认知抓手**——知道每一步在管什么，才能判断 release-please bot 行为是否符合预期；红线 1–8 在两条轨道下都生效，自动化不豁免任何一条红线。

## 故障预案

| 阶段 | 现象 | 处置 |
|---|---|---|
| Step 1.5 版本推荐 | 仓库尚无任何 tag（首发版本） | 默认推 `v0.1.0`；项目宣告稳定可选 `v1.0.0`；让 Captain 显式确认，**绝不**自动决定 |
| Step 1.5 版本推荐 | `[Unreleased]` 段空白 / 内容稀缺 | STOP；回 `changelog-bot` 把已合 PR 的词条补进 `[Unreleased]`，再回 release-sop |
| Step 4 Cut PR | `[Unreleased]` 词条不达 granularity（"修了一个 bug"等） | 暂停 Cut，回 `changelog-bot` 重写词条；**禁止**在 Cut PR 里硬塞新内容 |
| Step 4 Cut PR | Author 想 self-approve | 拒绝；找 teammate review；单人维护项目走"PR body 显式声明 + 24h cool-off" |
| Step 4 Cut PR | Cut PR 里夹带了代码/测试改动 | 退回；要求 Author 把非 CHANGELOG 改动拆成另一 PR，Cut PR 保持单一职责 |
| 构建失败 | dist 不全 | 看 Actions 日志末尾 50 行；锁工具版本；**绝不**手工上传残缺包 |
| 发包 401/403 | 凭据过期 | 维护者轮换，重跑 workflow |
| 发包版本冲突 | 同号已存在 | **禁止 unpublish 重发**，必须 bump patch |
| Release 资产缺漏 | gh release view 少文件 | 手工 `gh release upload --clobber` 补传 |
| 下游通知失败 | webhook 静默 | 检查 secret；按需手工 `curl --fail` 重放 |

## 回滚

优先级：**bump 新版本 > yank 旧版本 > 删 tag**。

- 严重 P0：发 patch + Release 标 `⚠️ Yanked` + 包仓库 deprecate
- 安全/合规：同上 + 红字播报 + 走 SECURITY.md 流程
- 删 tag 仅限 push 30 分钟内 且 release.yml 未成功

## 红线（不可越）

1. **不在 CI 红的状态下打 tag**
2. **不 unpublish 同号包**
3. **不跳过 PR 准入回放**
4. **不让 Captain 同时跑两个 release**
5. **不夹带其他 commit 进 hotfix**
6. **Cut PR 不允许 self-approve / self-merge** —— 必须过队友 `pr-review`；单人维护项目走"PR body 显式声明 `sole-maintainer release` + 24h cool-off"且仅作例外，不构成默认路径
7. **`[Unreleased]` 为空 / 词条不达 granularity 时不允许 Cut** —— 强制回 `changelog-bot` 先把 PR 阶段欠下的词条补全，禁止在 Cut PR 里现写内容
8. **版本号必须由 Step 1.5 按 SemVer 推荐后 Captain 反问确认** —— 不允许 Captain 在 Step 1 凭空报号绕过推荐

## 输出风格

- 每个 step 开始前：明确告诉用户当前阶段、要做什么、通过标准是什么
- 用户粘命令输出后：先判定"通过/失败"，再决定是否进入下一步
- 失败时：直接给故障预案对应条目，不让用户自己翻文档
- 完成后：必须输出闭环报告，否则视为未完成
