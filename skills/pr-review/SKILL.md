---
name: pr-review
description: 通用 Git 项目 PR 评审 SOP skill（适用于 GitHub / GitLab / Gitea 等 Git 主机；可装入 Claude Code / Qoder / Cursor / 通用 LLM 等任意 AI Agent）。按"PR上下文加载 → 元信息核对(DoR) → 变更分类与接口影响分析 → 代码实质审查 → 测试覆盖核验 → CHANGELOG词条核验 → 安全评审触发判定 → 评审结论"八步走，每步有 gate、命令、失败处置；产出 APPROVE / REQUEST_CHANGES / BLOCK 三选一结论与逐条理由。Triggers on '/pr-review', 'pr review', 'review this pr', 'review #123', '评审 PR', '帮我看下这个 PR', '过一下这个 PR'.
---

# PR Review SOP — 通用 Git 项目 PR 评审流程（多 Agent 兼容）

## 触发条件

用户提到以下任一即激活：
- 显式：`/pr-review`、`pr review`、`评审 PR`、`过一下这个 PR`
- 隐式：`review this PR`、`review #123`、`帮我看下这个 PR`、`这个 MR 能合吗`、贴一个 PR/MR 链接并问"行不行"

## 行为协议

你是 Reviewer 的副驾。你不是点赞机——你是「这条变更值不值得进 main」的 co-owner。

激活后立即按以下步骤执行，**任何 gate 失败立即停在该步并给出结论档位，不允许跳过、不允许"先合了再补"**。

评审的最终产物只有三档：`✅ APPROVE` / `🔁 REQUEST_CHANGES` / `⛔ BLOCK`。模糊措辞（"看起来还行"、"应该没问题"）一律视为未完成评审。

---

### Step 0 — PR 上下文加载

识别 Git 主机并拉取 PR 全貌：

| 主机 | 工具 | 取数命令（示例） |
|---|---|---|
| GitHub | `gh` | `gh pr view <N> --json title,body,baseRefName,headRefName,additions,deletions,changedFiles,labels,state` ; `gh pr diff <N>` ; `gh pr checks <N>` |
| GitLab | `glab` | `glab mr view <N>` ; `glab mr diff <N>` ; `glab ci status` |
| Gitea | `tea` | `tea pr <N>` ; `tea pr <N> --diff` |
| 无 CLI | 浏览器/手贴 | 要求用户粘贴：标题、描述、目标分支、diff stat、CI 状态、关联 issue |

输出 **PR 上下文摘要表**（让用户确认评审对象没搞错）：PR 号 + 标题、作者、源→目标分支、diff stat（+X / −Y / N files）、当前 CI 状态、关联 issue、标签。

### Step 1 — PR 元信息核对（DoR — Definition of Ready）

逐条勾选，**任意一项 NO → 停在 Step 1，结论档位 ≥ `🔁 REQUEST_CHANGES`**，并列出缺什么、怎么补：

- [ ] 标题符合仓库约定（如 `type(scope): summary`，或仓库 `CONTRIBUTING.md` 规定的格式）
- [ ] 描述说清 **What / Why**，不是空的也不是只有一行 commit message
- [ ] 关联了 issue（`closes #N` / `fixes #N` / `refs #N`），或在描述里说明"无对应 issue，因为 …"
- [ ] 目标分支正确（不是直接 PR 到受保护的 release/tag 分支，不是 PR 错仓库）
- [ ] PR 体量可评审（超大 PR：> ~400 行净变更 或 跨 > ~15 文件 → 要求拆分，或要求作者提供"按文件/按提交的改动说明"以便分块过）
- [ ] commit 历史干净，或作者已声明合并时 squash（不接受一堆 `wip` / `fix typo` / `回退一下` 直接进 main）

### Step 2 — 变更分类与接口/行为影响分析

走一遍 diff，把每块改动归类：

| 类别 | 判据 | 评审强度 |
|---|---|---|
| 纯内部重构 | 无任何对外可观测变化（输出、行为、性能特征不变） | 轻 |
| 行为变更 | 用户/调用方可观测的行为变了（默认值、输出格式、错误信息、时序） | 中 |
| 接口变更 | CLI flag / API endpoint / 函数或方法签名 / 配置项 / 文件或 wire 格式 / 环境变量 | 重 |
| 数据/迁移变更 | DB schema、持久化格式、缓存键、消息格式 | 重 + 需迁移说明 |

对每个「行为 / 接口 / 数据」变更逐条核：

- [ ] **是否 Breaking？** 是 → PR 描述必须显式标 `BREAKING`，且 CHANGELOG 必须进 `Breaking` 段，且要有升级/迁移说明
- [ ] **文档同步了吗？** 涉及 CLI/API/config → `README` / `docs/` / `--help` 文案 / man / OpenAPI 等对应更新在同一 PR
- [ ] **有无向后兼容路径？** 接口变更应优先"加新的 + 标弃用旧的"，而非直接删/改；直接破坏要有正当理由

Gate：有接口/数据变更但**没文档、或没 CHANGELOG、或破坏性却没标 breaking** → 结论档位 ≥ `🔁 REQUEST_CHANGES`（破坏性未标 → 直接 `⛔ BLOCK`）。

### Step 3 — 代码实质审查（逐行/逐块）

这一步产出**行级评论清单**而非单一 gate：`file:line — 问题 — 建议`，每条标 `[blocking]` 或 `[nit]`。检查维度：

- [ ] **正确性**：实现真的解决了 PR/issue 描述的问题？能对照 issue 的复现步骤走通？逻辑分支有没有写反、off-by-one、错误的边界比较
- [ ] **边界与失败**：空输入 / 超大输入 / nil-or-null / 并发访问 / 超时 / 部分失败 / 重试 是否处理；外部调用失败时状态是否一致
- [ ] **错误处理**：错误是被吞掉了还是上抛/包装；日志/错误信息够不够定位问题；不要 `catch {}` 静默
- [ ] **资源**：文件句柄 / 连接 / 锁 / goroutine / 定时器 是否会泄漏；循环里有没有 N+1 查询、无界缓冲、热路径上的重复分配
- [ ] **并发**：共享状态有没有竞态；锁的粒度和顺序；`pull_request` 事件里有没有 TOCTOU
- [ ] **可读性/一致性**：命名、注释密度、错误处理风格是否与**周边代码**一致（不是与某种"最佳实践"一致——与这个文件一致）
- [ ] **意外副作用**：是否动了 PR 描述里没提的现有行为（顺手改的格式化、顺手 bump 的依赖、顺手删的"看起来没用"的代码）

Gate：存在 `[blocking]` 项 → 结论档位 ≥ `🔁 REQUEST_CHANGES`。

### Step 4 — 测试覆盖核验

- [ ] **新功能有新测试**，且测试与实现**同一个 PR**提交（不接受"功能先合，测试下个 PR 补"）
- [ ] **Bug fix 有回归测试**——存在一个能在修复前复现该 bug、修复后变绿的用例
- [ ] 改动路径上的**现有测试仍在跑**（不是被 `skip` / `xfail` / 注释 / 删掉来"让 CI 过"）
- [ ] **CI 全绿**：lint / 单测 / 集成测试 / race / 覆盖率阈值 / policy / 构建 / 打包 dry-run——用 `gh pr checks <N>`（或对应主机命令）核，红的看失败 job 末尾日志
- [ ] 覆盖率没有明显下滑（若仓库有阈值，低于阈值即视为红）

Gate：**无任何测试的功能 PR / CI 红 / 关键 job 失败** → 直接 `⛔ BLOCK`（这是硬阻断，不是 request-changes）。CI 还在跑 → 不出 `APPROVE`，标 `⏳ pending CI`，CI 完再定档。

### Step 5 — CHANGELOG 词条核验

- [ ] 行为 / 接口 / 安全 / 数据 相关 PR → diff 里能看到 `CHANGELOG.md`（或仓库等价文件）新增词条
- [ ] 词条格式合规（参照仓库现有风格，典型 Keep a Changelog）：以**用户可观测现象**开头加粗、带 PR 号、修 issue 带 `fixes #N`、进对的段（`Breaking` / `Added` / `Changed` / `Fixed` / `Deprecated` / `Removed` / `Security`）
- [ ] **禁止无颗粒度词条**："fix a bug"、"改了点东西"、"优化"——必须是"现象 + 根因 + 修复方式 + 影响面"
- [ ] 豁免项要写明理由：纯内部重构 / 纯 CI / 纯 docs typo / 纯测试 → 可不写 CHANGELOG，但要在评审结论里写一行"无需 CHANGELOG，因为 …"

注：本 skill 只判"**有没有 / 格式对不对**"。词条**内容怎么写**交给 `changelog-bot`；这里不替作者起草，只把关。

Gate：该有词条却没有、或词条无颗粒度 → 结论档位 ≥ `🔁 REQUEST_CHANGES`。

### Step 6 — 安全评审触发判定（必跑，命中或不命中都要显式写结论）

命中**任一**条 → 评审结论标 `🔒 SECURITY REVIEW REQUIRED`，@ 安全负责人 / 按 `SECURITY.md` 流程走，**reviewer 不自行放行**：

- 改动 认证 / 鉴权 / 会话 / 令牌 / 密码哈希 / OAuth 流程
- 改动 加解密 / 签名校验 / 随机数来源 / 证书校验
- 处理用户输入的 解析器 / 反序列化 / 模板渲染 / SQL 拼接 / shell 调用 / 文件路径拼接 / URL 构造
- 改动 权限模型 / ACL / 多租户隔离 / CORS / CSP / SSRF 防护点
- 新增或升级**依赖**（含传递依赖）——看 lockfile diff，留意来源不明、版本跳跃大、近期有 CVE 的包
- 改动 CI/CD：secret 读取范围、`pull_request_target` / `workflow_run` 触发、第三方 action pin、自托管 runner 上跑不受信代码
- 暴露新网络端点 / 新文件上传 / 新外部回调 / 反射型用户数据回显

未命中 → 写一行"**无安全评审触发项**（已对照清单逐条核）"。不允许跳过这一步。

### Step 7 — 评审结论（闭环报告）

产出**三选一结论 + 逐条理由**，markdown 表格：

| 结论 | 含义 | 何时给 |
|---|---|---|
| ✅ APPROVE | 可以合 | Step 1–6 全过，无 `[blocking]` 项，无未过 gate，CI 全绿（或绿后自动转 approve），安全无触发或已走流程 |
| 🔁 REQUEST_CHANGES | 改完再看 | 存在**可修复**的未过项：元信息不全 / 缺文档 / 缺测试说明 / 缺 CHANGELOG / 有 `[blocking]` 代码问题 |
| ⛔ BLOCK | 现在不能合 | CI 红 / 关键 job 失败 / 功能 PR 零测试 / 破坏性变更未标 breaking / 命中安全触发项但未走安全流程 / PR 打错目标分支到受保护分支 |

结论报告**必含**：
- PR 号 + 标题、源→目标分支、diff stat
- 变更分类结果（每块归到哪一类）
- 各 Step 的 gate 勾选结果（过 / 不过）
- **未过项清单**——每条带"怎么修"，不让作者猜
- 安全触发判定结论（命中项列表，或"无触发项"）
- 行级评论清单（`[blocking]` 在前，`[nit]` 在后）
- **最终结论一行**：`结论：✅/🔁/⛔ — <一句话原因>`

## 故障预案 / 边界情况

| 情况 | 处置 |
|---|---|
| CI 还在跑 | 不出 `APPROVE`；先标 `⏳ pending CI`，把其他档位结论先给出，CI 完再定 |
| 作者 = 唯一维护者 | 仍走全流程；不允许 self-approve 跳 gate；必要时要求第二人 review 或外部确认 |
| 紧急 hotfix PR | 走简化 gate（CI 绿 + 回归测试 + CHANGELOG 词条 + 目标分支正确），但 **Step 6 安全触发判定一条都不能省**；合并后交回 `hotfix-flow` / `release-sop` |
| diff 太大读不完 | 不"抽样放行"；要求作者拆 PR，拆不了则要求"按文件/按提交的改动说明"，逐块过 Step 2/3 |
| 机器人/依赖升级 PR | 重点：lockfile diff + 上游 changelog + CI；锁文件之外的改动一律视为可疑、单独问 |
| 改了 vendored / 生成代码 | 要求同 PR 附上"用什么命令/什么版本重新生成的"，不接受手改生成物 |
| reviewer 经验不足以判某块（如密码学、底层并发） | 不硬撑 `APPROVE`；标该块"需领域专家复核"，结论档位 ≥ `🔁 REQUEST_CHANGES` |

## 红线（不可越）

1. **不在 CI 红的状态下 `APPROVE`**
2. **不放行无任何测试的功能 PR**
3. **不放行未标 breaking 的破坏性接口/数据变更**
4. **命中安全触发项 → 必须走安全评审，reviewer 不自行放行**
5. **不接受"测试 / CHANGELOG / 文档下个 PR 补"作为合并条件**
6. **不 self-approve 跳过任何 gate；不"信任作者所以免检"**
7. **不把"风格 nit"当 blocker，也不把 blocker 降级成 nit 来放行**

## 与其他 skill 的衔接

- 本 skill 把守的 gate，正是 `release-sop` 的 **Step 2「PR 准入回放（DoR Check）」**事后回放的那几条——这里过了，发版那里才不会被卡。两者共用同一套硬闸哲学：每步有书面 gate、失败即停、无"以后再修"。
- CHANGELOG 词条：本 skill 只判**有无 / 格式**；词条**内容生成**交给 `changelog-bot`。
- hotfix PR：用本 skill 的「故障预案」里的简化 gate；合并后交回 `hotfix-flow` → `release-sop`。
- issue 关联：PR 描述里的 `fixes #N` 是否对应一个被 `issue-triage` 判为 actionable 的 issue，可作为 Step 1 的加分项。

## 输出风格

- 先输出 **Step 0 的 PR 上下文摘要表**，让用户确认评审对象没搞错，再往下走
- 每个 Step：先一句话说"这步在查什么、通过标准是什么"，再给勾选结果
- 不过的 gate：每条都带"怎么修"，不让作者去翻文档/猜
- **结论必须三档之一明确给出**——`✅ APPROVE` / `🔁 REQUEST_CHANGES` / `⛔ BLOCK`，禁止"看起来还行"这种模糊话
- Step 6 安全触发判定**无论命中与否都要显式写一行**
- 收尾必须是闭环报告（含未过项清单 + 行级评论 + 最终结论一行），否则视为未完成评审
