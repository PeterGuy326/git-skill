---
name: release-sop
description: 通用 Git 项目发布 SOP 引导 skill（适用于 GitHub / GitLab / Gitea 等 Git 主机；可装入 Claude Code / Qoder / Cursor / 通用 LLM 等任意 AI Agent）。按"PR准入回放 → Pre-flight → CHANGELOG → 打Tag → 盯盘 → 发布后验证 → DOD"七步走，每步有 gate、命令、失败处置；自动识别项目类型（Go/Node/Python/Rust/Docker）适配命令。Triggers on '/release-sop', 'release sop', '发版sop', '走发版流程', '帮我发版', 'cut a release', 'tag and release'.
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

向用户问清以下，缺一不补齐就**禁止进入 Step 2**：

1. **目标版本号** `vX.Y.Z`（必须 SemVer，含 `v` 前缀）
2. **Release Captain**（必须是单一具名 owner，不接受"我们"）
3. **本次发版核心价值**（一句话，将写入 CHANGELOG 段落首句）
4. **是否含 Breaking change**（含则要求列出 breaking 项）

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

### Step 4 — CHANGELOG 终稿

引导用户在 `CHANGELOG.md` 顶端按 Keep a Changelog 格式起新段落：

```markdown
## [X.Y.Z] - YYYY-MM-DD

<一句话总览>

### Breaking | Added | Changed | Fixed | Deprecated | Removed | Security
- **<用户可观测现象>** (#PR, fixes #ISSUE) — <根因 + 修复方式 + 影响面>
```

约束：
- 每条以"现象"开头加粗
- 必带 PR 号；修 issue 必带 `fixes #N`
- 禁止"修了一个 bug"这类无颗粒度描述
- CHANGELOG 走普通 PR 合入 main，不夹带在 tag commit 里

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

## 输出风格

- 每个 step 开始前：明确告诉用户当前阶段、要做什么、通过标准是什么
- 用户粘命令输出后：先判定"通过/失败"，再决定是否进入下一步
- 失败时：直接给故障预案对应条目，不让用户自己翻文档
- 完成后：必须输出闭环报告，否则视为未完成
