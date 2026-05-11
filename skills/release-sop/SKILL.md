---
name: release-sop
description: 通用 Git 项目发布 SOP 引导 skill（适用于 GitHub / GitLab / Gitea 等 Git 主机；可装入 Claude Code / Qoder / Cursor / 通用 LLM 等任意 AI Agent）。按"项目识别 → 身份对齐 → 版本号推荐 → PR准入回放 → Pre-flight → Cut PR → 打Tag → 盯盘 → 发布后验证 → DOD"十步走，每步有 gate、命令、失败处置；自动读取最新 tag + `[Unreleased]` 按 SemVer 推荐 patch / minor / major 让 Captain 反问确认，CHANGELOG 走单独 Cut PR 过队友 review（禁止 self-approve）。Triggers on '/release-sop', 'release sop', '发版sop', '走发版流程', '帮我发版', 'cut a release', 'tag and release'.
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

### Step 8 — DOD 闭环

逐项勾选才允许"发布完成"：

- [ ] tag `vX.Y.Z` 在 main HEAD
- [ ] GitHub Release 含全部预期 asset + checksums
- [ ] 所有目标包仓库可拉取
- [ ] CHANGELOG 与 release 内容一致
- [ ] smoke test 在 ≥2 平台通过
- [ ] 团队/下游已周知
- [ ] milestone / 卡片关闭

输出闭环报告（markdown 表格）：版本号、Captain、tag SHA、Release URL、各包仓库 URL、smoke 结果、耗时。

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
