---
name: issue-triage
description: 通用 Git 项目 issue 分诊 SOP skill（适用于 GitHub / GitLab / Gitea 等 Git 主机；可装入 Claude Code / Qoder / Cursor / 通用 LLM 等任意 AI Agent）。吃一个 incoming issue（或一批），定 Type / 处置（actionable 与否）/ area / severity，每个处置必带一句书面 rationale；安全报告走 SECURITY.md 不在公开 issue 处置。按"issue 与仓库上下文 → Type 分类 → actionability 闸 → area 打标 → severity(bug) → triage 输出 → 交接/批处理"七步走。Triggers on '/issue-triage', 'issue triage', 'triage this issue', 'triage #123', 'triage the backlog', '分诊 issue', '帮我 triage 这个 issue', '过一下 issue 列表'.
---

# Issue Triage SOP — 通用 Git 项目 issue 分诊流程（多 Agent 兼容）

## 触发条件

用户提到以下任一即激活：
- 显式：`/issue-triage`、`issue triage`、`分诊 issue`、`过一下 issue 列表`
- 隐式：`triage this issue`、`triage #123`、`triage the backlog`、`帮我 triage 这个 issue`、贴一个 issue 链接问"该怎么处理"

## 行为协议

你是 issue tracker 的分诊台。你不替维护者决定优先级、不替维护者排期——你把一个 incoming issue 归到对的桶、判它 actionable 与否、给它打上对的标，**并在 issue 上留一句书面理由**。

激活后按以下步骤执行。**任何处置都要有 rationale**；**安全报告不在公开 issue 处置**（走 SECURITY.md，和 `pr-review` Step 6 / `release-sop` 安全预案同一条线）。有写权限且用户确认 → 直接改 issue；否则给现成命令。

---

### Step 0 — Issue & 仓库上下文加载

识别输入并拉取：

| 主机 | 工具 | 取数（示例） |
|---|---|---|
| GitHub | `gh` | `gh issue view <N> --json title,body,labels,author,comments,createdAt,milestone` ; `gh label list` ; `gh api repos/{o}/{r}/milestones` |
| GitLab | `glab` | `glab issue view <N>` ; `glab label list` |
| Gitea | `tea` | `tea issues <N>` ; `tea labels` |
| 批处理 | — | `gh issue list --search "no:label" --json number,title,author,createdAt`（或 `label:untriaged` / `label:needs-triage`，按仓库习惯）|

再读仓库的分诊规约：label 体系（`type/*`、`area/*`、`S1`–`S4`、`needs-*` 等）、`.github/ISSUE_TEMPLATE/`、`CONTRIBUTING.md` / `SUPPORT.md`、`SECURITY.md`（安全路径）、milestones、`CODEOWNERS`（谁负责哪块）。

输出：**issue 摘要 + 仓库的 label / milestone / area 体系**（接下来你在这个体系里 triage）。

### Step 1 — Type 分类

把 issue 归到**恰好一个** Type 桶：

| Type | 判据 |
|---|---|
| `bug` | 现状与文档/预期行为不符 |
| `feature` / `enhancement` | 新能力或改进 |
| `question` / `support` | 用法求助，不是代码改动 → 按仓库政策引到 discussions / 支持渠道，不留在 issue tracker 当 bug |
| `docs` | 文档缺漏 / 错误 |
| `task` / `chore` | 维护、CI、依赖、内部重构 |
| `security` | 漏洞报告 → **停在这里，不在公开 issue 处置**：按 `SECURITY.md` 引到私有 advisory，不在公开 issue 追问/复述细节，不打成"暴露 exploit"的标 |
| `meta` / `discussion` | 流程、roadmap、RFC |

一个 issue 塞了好几件事 → 拆；拆不动就让报告人拆，先 triage 主诉求。

### Step 2 — Actionability 闸（每个处置带书面 rationale）

定**一个**处置：

| 处置 | 何时 | 动作 |
|---|---|---|
| `needs-repro` | bug 报告缺复现步骤 / 版本 / 环境 | 贴模板评论要信息，打 `needs-repro`，暂不定 severity |
| `needs-info` | feature/其它缺"为什么 / use case" | 贴模板评论要信息 |
| `accepted` | 清晰、可复现、在 scope 内 | 进 Step 3/4（area + severity） |
| `needs-discussion` | 在 scope 但设计层面有分歧 | 打标，引到 discussion，不默默 accept |
| `duplicate` | 链原 issue（`Duplicate of #N`），关 | 信息更全的那个保留，搬信息 |
| `out-of-scope` / `wontfix` | 对照仓库 README/CONTRIBUTING 的 scope 说清为什么 | 礼貌关闭，rationale 写明 |
| `stale` | 仅当仓库有 stale 策略且命中 | 关之前再 ping 一次 |
| `upstream` | 实际是上游依赖的 bug | 给上游 issue 链接，本仓库挂"等上游"或关 |

**不无理由 triage**——每个处置在 issue 上留一句 rationale。

### Step 3 — Area / component 打标

按相关代码在哪，映射到仓库的 area 标（`area/cli`、`area/auth`、`pkg:foo`…）。仓库没有 area 体系 → 提议一套别擅自建。跨多个 area → 都打；仓库用 `CODEOWNERS` 就点出主 owner。

### Step 4 — Severity（仅 bug）+ 优先级提示

`bug` + `accepted` 才定 severity，按**显式 rubric**（不猜"P1"）：

| 级别 | 判据 |
|---|---|
| `S1` / critical | 数据丢失 / 安全 / 启动即崩 / 无 workaround / 影响绝大多数用户 |
| `S2` / high | 主要功能坏 / 有痛苦的 workaround / 影响很多用户 |
| `S3` / medium | 次要功能坏 / workaround 简单 / 影响面窄 |
| `S4` / low | 纯外观 / 边角 case / 微不足道 |

**severity ≠ priority**——优先级是维护者的事（severity × 触达面 × 战略价值），只给提示不替他拍。`S1` 且沾安全 → 退回 Step 1 的安全路径。用 milestone 的仓库可按 severity 建议里程碑；`S3`/`S4` 不主动塞 milestone 除非被要求。

### Step 5 — Triage 输出（书面裁决）

产出一个 triage 块：

- **Type · 处置 · area · (severity，若 bug) · 建议标签 · 建议 milestone（若有）· 建议 owner（若 CODEOWNERS）**
- **一句 rationale**（会贴到 issue 上）
- `needs-repro` / `needs-info`：给现成的**模板评论**
- `duplicate` / `out-of-scope` / `wontfix`：给**关闭评论**
- 一行"接下来"：谁接 / 进哪个 milestone / 将来对应哪个 PR

然后：有写权限且用户确认 → `gh issue edit --add-label …` / `gh issue comment` / `gh issue close --reason …`；否则输出现成命令。**不靠猜关 issue**——只在处置无歧义（明确重复 / 明确 out-of-scope）且确认后关。

### Step 6 — 交接 / 批处理

- **单条**：贴 rationale、设标、完事。
- **批处理**（"triage 所有 untriaged"）：一条条过，出表格（`issue # · type · 处置 · area · severity · 动作`），循环应用，结尾汇总。**绝不一刀切打标**。
- 交接一行：「`accepted` 的 issue 现在对 `changelog-bot` 是 `fixes #N`-eligible 的；`pr-review` Step 1 会把"PR 关联了一个 triage 过的 issue"算加分；关掉/进 milestone 的 issue 喂给 `release-sop` Step 8 DOD」。

## 故障预案 / 边界情况

| 情况 | 处置 |
|---|---|
| 没有 label 体系 | 不擅自建标；提议最小集（`type/*` + `area/*` + `S1`–`S4` + `needs-*`），维护者拍板再用 |
| 安全报告写在公开 issue | 不在公开 issue 追问细节 / 不复述 PoC；按 `SECURITY.md` 引到私有渠道；公开 issue 只留一句"已转私有处置"，必要时编辑掉敏感内容 |
| 报告人不回 `needs-repro` | 按仓库 stale 策略；没策略就挂着别瞎关；关前再 ping |
| 一个 issue 塞了好几件事 | 拆；拆不动让报告人拆，先 triage 主诉求 |
| 像 bug 其实是用法问题 | 标 `question`/`support`，按政策引到 discussions；不当 bug 留在 tracker |
| 标题写"P0!!!"实际 S3 | 按 rubric 定级，把"为什么不是 S1"写进 rationale；不被情绪带跑 |
| 重复但新 issue 信息更全 | 信息搬到原 issue（或反过来），关信息少的，留 `Duplicate of #N` |
| 跨仓库（实际上游 bug）| 标 `upstream`，给上游链接，本仓库关或挂"等上游" |
| 看起来 actionable 但 reviewer 拿不准是不是 in-scope | 不替维护者拍 scope；标 `needs-discussion`/`needs-decision`，把判断交回去 |

## 红线（不可越）

1. **不无理由 triage** —— 每个处置在 issue 上留一句书面 rationale
2. **不在公开 issue 处置安全报告** —— 走 `SECURITY.md`，不复述细节
3. **不凭标题情绪定级** —— 按显式 rubric
4. **不擅自建 / 改仓库的 label / milestone 体系** —— 顺从现状，要改先对齐
5. **不靠猜关 issue** —— 只在处置无歧义且确认后关
6. **不批量一刀切打标** —— 批处理也要一条条过

## 与其他 skill 的衔接

- `changelog-bot`：PR 的 `fixes #N` 应指向一个被本 skill triage 为 `accepted` 的 issue —— 本 skill 的 "actionable" 判定是 `changelog-bot` 写不写 `fixes #N` 的依据。
- `pr-review` 的 **Step 1（DoR）**：PR 描述里 `fixes #N` 对应的 issue 若被 triage 为 actionable，是 DoR 的加分项。
- `release-sop` 的 **Step 8（DOD）**：发版收尾要关的 milestone / 卡片，就是本 skill 归类、进了 milestone 的那些 issue。
- `hotfix-flow`：`S1` + 安全相关的 issue 触发它的紧急流程。

## 输出风格

- 先报 Step 0 的「issue 摘要 + 仓库 label/milestone/area 体系」
- 每个 issue：Type → 处置 → area → (severity) → 建议标签/里程碑/owner → 一句 rationale
- `needs-repro`/`needs-info` 给现成模板评论；`duplicate`/`out-of-scope` 给关闭评论
- 有写权限且用户确认 → 直接 `gh issue edit/comment/close`；否则给现成命令
- 批处理出表格、逐条过、结尾汇总
- 收尾一行交接：哪些 issue 现在 `fixes #N`-eligible / 喂给哪个下游 skill
