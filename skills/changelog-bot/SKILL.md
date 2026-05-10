---
name: changelog-bot
description: 通用 Git 项目 CHANGELOG 词条起草 skill（适用于 GitHub / GitLab / Gitea 等 Git 主机；可装入 Claude Code / Qoder / Cursor / 通用 LLM 等任意 AI Agent）。吃一个 PR / commit 区间 / diff,走查变更、按 Keep a Changelog 分类、产出"现象+根因+做法+影响"四要素齐全、引用 PR 号、放在 `[Unreleased]` 正确 section 下的待粘贴词条；不替作者 commit。按"输入与 CHANGELOG 现状 → diff 走查归类 → 逐条起草(颗粒度闸) → Breaking 特判 → 放置与输出 → 自检交接"六步走。Triggers on '/changelog-bot', 'changelog bot', 'propose a changelog entry', 'write a changelog entry', 'changelog for #123', '写个 changelog 词条', '这个 PR 的 changelog', '更新 CHANGELOG'.
---

# CHANGELOG Bot — 通用 Git 项目 CHANGELOG 词条起草（多 Agent 兼容）

## 触发条件

用户提到以下任一即激活：
- 显式：`/changelog-bot`、`changelog bot`、`写个 changelog 词条`、`更新 CHANGELOG`
- 隐式：`propose a changelog entry`、`changelog for #123`、`这个 PR 的 changelog 怎么写`、贴一段 diff 问"该写什么 changelog"

## 行为协议

你是 CHANGELOG 的起草人。你不决定"东西发没发"（那是 tag 的事），不决定"PR 能不能合"（那是 `pr-review` 的事）——你只把一段 diff 翻成**一条精确、有颗粒度、放对位置的 Keep a Changelog 词条**，然后**交给作者审定**。

激活后按以下步骤执行。**你只产出待粘贴的 markdown，绝不替作者 commit**——CHANGELOG 走普通 PR 合入（和 `release-sop` Step 4 / `pr-review` Step 5 同一条红线）。

---

### Step 0 — 输入识别 & CHANGELOG 现状

**先弄清输入是什么**：

| 输入 | 取数 |
|---|---|
| PR / MR 号 | GitHub `gh pr diff <N>` + `gh pr view <N> --json title,body` ; GitLab `glab mr diff <N>` ; Gitea `tea pr <N> --diff` |
| commit 区间 | `git log <A>..<B> --oneline` + `git diff <A>..<B>` |
| 分支 | `git diff main...<branch>` |
| 直接贴的 diff | 用户粘贴的内容 |

**再读 CHANGELOG 房规**——定位文件（`CHANGELOG.md` / `CHANGES.md` / `HISTORY.md` / `docs/changelog*`），扫最近 5–10 条词条，总结：

- 是不是 Keep a Changelog？用哪些 section（`Added` / `Changed` / `Deprecated` / `Removed` / `Fixed` / `Security`，有没有自定义的 `Breaking` 顶级段）？
- 单条词条的房规：现象是否加粗开头？PR 号写 `(#N)` 还是 `[#N]`？修 issue 用 `fixes #N` 还是 `closes #N`？语言（英文 / 中文 / 双语）？有没有"根因+做法+影响"这种颗粒度惯例？
- 有 `[Unreleased]` 段，还是每次发版直接起 `## [X.Y.Z] - YYYY-MM-DD`？（本类项目通常用 `[Unreleased]` 暂存，发版时由 `release-sop` 收口成 dated 段）

输出：**输入源 + CHANGELOG 路径 + 一段"房规摘要"**（接下来你产出的词条会严格照这个走）。让作者确认没认错文件/格式，再往下。

### Step 1 — Diff 走查 & 变更归类

走一遍 diff，把每个**有意义的**变更归到 Keep a Changelog 桶里：

| 桶 | 判据 |
|---|---|
| `Breaking`（若仓库用作顶级段）| 破坏现有用户：删/改 flag、改默认值、改 wire/文件格式、改 exit code、丢平台、抬最低运行时版本 |
| `Added` | 新功能 / 新 flag / 新 endpoint / 新文件 / 新能力 |
| `Changed` | 现有功能的行为变了（不是 bug 修复）：默认值、输出格式、错误信息、时序、性能特征（量级变化才值得写）|
| `Deprecated` | 标记为即将移除 |
| `Removed` | 移除了功能 |
| `Fixed` | bug 修复 |
| `Security` | 漏洞修复 / 安全加固 |

**滤掉非用户可观测的噪音**：纯重构、纯测试改动、CI 调整、格式化、不改行为的依赖 bump、内部文档 typo。
→ 如果**整个 PR 都是噪音**：输出"**无需 CHANGELOG 词条，因为 …**"——这是合法且常见的结果（对齐 `pr-review` Step 5 的豁免条款）。

### Step 2 — 逐条起草（颗粒度闸）

每个用户可观测变更，起草一条**四要素齐全**的词条：

1. **现象** — 用户/调用方能观测到的变化，**加粗、放句首**
2. **根因 / 触发条件** — 什么情况下会遇到、为什么会这样（`Fixed` / `Security` 尤其要写清触发条件）
3. **修复 / 实现方式** — 具体做了什么（不是"修好了"）
4. **影响面** — 谁受影响、要不要做什么（默认行为变了？opt-in？需要迁移？）

加上引用：PR 号 `(#N)`；修 issue 加 `fixes #N` / `closes #N`（按 Step 0 探到的房规）。

**直接打回重写的反模式**：`fix a bug`、`improve performance`、`update deps`、`various fixes`、`refactor X`（重构本身不是词条——除非它改了行为）、`misc`、`小修小补`。

→ 如果从 diff 里**填不满四要素**（比如只有"修了"的 diff、看不出根因）：**不编**。把能确定的现象/影响写好，明确标"需作者补根因"，问作者。

### Step 3 — Breaking change 特判

任一变更破坏现有用户（删/改/重命名 flag、改默认、改 wire/文件格式、改 exit code、丢平台、抬最低运行时版本）：

- 放进 `Breaking` 段（仓库若无此段：词条前缀 `**BREAKING:**`，并提示仓库该加这个段 / 按 SemVer 抬 major）
- 词条**必带迁移说明**："以前你 X，现在改 Y"
- 交叉核对：这需不需要 major 版本号 bump？需要就明说。

### Step 4 — 放置 & 输出

- **放哪**：`[Unreleased]` 段顶部、对应的 `### <桶>` 下（该子标题不存在就建）。**不放 tag commit、不放 dated 段**（把 dated 段切出来是 `release-sop` 的事）。
- **多个桶时**：按 Keep a Changelog 规范顺序输出——`Breaking` → `Added` → `Changed` → `Deprecated` → `Removed` → `Fixed` → `Security`。
- **输出形态**：① 一段可直接粘贴的 markdown；② 确切的文件路径；③ 一行"放在 `[Unreleased] > ### <桶>` 下"。作者要的话再给一个 diff hunk / patch。
- **不 commit**：你产出、作者审定改措辞、作者走普通 PR 合入。

### Step 5 — 自检 & 交接

交付前，拿 `pr-review` Step 5 会用的那几条闸自检一遍：

- [ ] 每条以**加粗"现象"**开头
- [ ] 带 PR 号；修 issue 带 `fixes #N`
- [ ] 无"修了个 bug / 优化 / update deps"这类无颗粒度词条
- [ ] 进对的 section；多 section 顺序对
- [ ] Breaking 有迁移说明
- [ ] 放在 `[Unreleased]`，不在 tag commit / dated 段

输出一行交接语：「粘到 `<文件>` 的 `[Unreleased] > ### <桶>` 下；能过 `pr-review` Step 5；下次发版 `release-sop` Step 4 会把它折进 dated 段」。

## 故障预案 / 边界情况

| 情况 | 处置 |
|---|---|
| 仓库没有 CHANGELOG 文件 | 不擅自定格式；问作者用不用 Keep a Changelog、放哪；建好骨架（含 `[Unreleased]`）再起词条 |
| 仓库不用 CHANGELOG（靠 GitHub Release Notes / commit message 自动生成）| 顺从现状——产出符合它格式的东西；若纯靠 commit message，就帮改 commit message，而不是硬塞一个 CHANGELOG.md |
| PR 跨多个不相关变更 | 一个变更一条词条，别合并成"做了一堆事"；顺带提示"这 PR 也许该拆"（交接给 `pr-review` Step 1）|
| diff 太大读不完 | 按文件 / 按 commit 分块归类；让作者确认有没有漏掉的用户可观测变化 |
| 看不出根因（只有 diff，没上下文）| 不编根因；标"需作者补"，先把现象/影响写好 |
| 依赖升级 PR | 默认噪音；**例外**：升级修了 CVE → `Security`；升级改了行为 → `Changed`。看上游 changelog 判断，别凭版本号猜 |
| 纯文档 / CI / 测试 / 格式化 PR | 输出"无需 CHANGELOG 词条，因为 …"——合法结果，不硬写 |
| 已经有人写了词条但不合规 | 不默默覆盖；指出哪条不合规、为什么、怎么改，给修订版让作者定 |
| 同一 `[Unreleased]` 里已有相关词条 | 判断是合并进去还是新起一条；别产生两条讲同一件事 |

## 红线（不可越）

1. **不替作者 commit CHANGELOG** —— 只产出待粘贴 markdown，作者审定后走普通 PR
2. **不编根因 / 影响面** —— 四要素填不满就标缺口、问作者
3. **不写无颗粒度词条**（`fix a bug` / `优化` / `update deps` / `misc`）
4. **不把 Breaking 藏进普通 section**，且必带迁移说明
5. **不把词条塞进 tag commit 或 dated 段** —— 永远进 `[Unreleased]`
6. **不替仓库改 CHANGELOG 格式** —— 顺从现状；要改先和作者对齐

## 与其他 skill 的衔接

- `pr-review` 的 **Step 5「CHANGELOG 词条核验」只判"有没有 / 格式对不对 / 颗粒度够不够"——内容由本 skill 生成**。本 skill 的 Step 5 自检刻意对齐 `pr-review` Step 5 的勾选项：做到"我产出的，那边一次过"。
- `release-sop` 的 **Step 4** 把 `[Unreleased]` 里本 skill 写的词条折进新的 `## [X.Y.Z] - YYYY-MM-DD` 段并打 tag —— 本 skill 永远不碰 dated 段、不打 tag。
- `hotfix-flow` 的紧急 PR 同样要词条（尤其 `Security`）；本 skill 给它产出。
- `issue-triage` 给出的 `fixes #N` 关联关系，是本 skill 决定词条里写不写 `fixes #N` 的依据。

## 输出风格

- 先报 Step 0 的「输入源 + CHANGELOG 路径 + 房规摘要」，让作者确认没认错文件 / 格式
- 每条词条：先给成品 markdown，再用一行点出"现象 / 根因 / 做法 / 影响"四要素各对应哪句（方便作者改措辞）
- 多 section 按 Keep a Changelog 顺序输出
- 收尾 = 待粘贴块 + 确切文件路径 + 一行"放哪 + 下游（`pr-review` / `release-sop`）会怎么消费它"
- 全程不 commit；明确告诉作者下一步是"你审定 → 走 PR 合入"
