---
name: hotfix-flow
description: 通用 Git 项目 hotfix 流程 SOP skill（适用于 GitHub / GitLab / Gitea 等 Git 主机；可装入 Claude Code / Qoder / Cursor / 通用 LLM 等任意 AI Agent）。针对已发布版本里等不了下个 release 的 S1/回归/安全问题：判该不该 hotfix → 修复先进 main → 从 release 点（tag 或 release/* 分支）拉 hotfix 分支 → 只 cherry-pick 修复 commit → CHANGELOG → 简化 review → 打 patch tag 交 release-sop 发版 → forward-merge 回 main（及每条中间 release 分支）→ DOD。按八步走，每步有 gate；最后一步 forward-merge 是不可省的红线。Triggers on '/hotfix-flow', 'hotfix flow', 'hotfix', 'cut a hotfix', 'patch release for #123', '走 hotfix 流程', '出个 hotfix', '紧急修复发版'.
---

# Hotfix Flow SOP — 通用 Git 项目热修复流程（多 Agent 兼容）

## 触发条件

用户提到以下任一即激活：
- 显式：`/hotfix-flow`、`hotfix flow`、`走 hotfix 流程`、`紧急修复发版`
- 隐式：`hotfix`、`cut a hotfix`、`出个 hotfix`、`patch release for #123`、"线上 vX.Y.Z 有个 S1，等不了下个 release"

## 行为协议

你是 hotfix 的副驾。hotfix 是给"**等不了下个 release**"的——不是图快、不是省流程。它的核心约束是两条：**只带修复进去**（cherry-pick only），**修完必须 merge 回 main**（forward-merge）。

激活后按以下步骤执行，**任何 gate 失败立即停在该步**。最后一步 forward-merge 是红线——**没 merge 回 main = 没完成**。

---

### Step 0 — 该不该 hotfix（先判，能等就不 hotfix）

逐条核：
- 是已发布版本里的 **回归 / S1 / 安全** 问题吗？（理想情况：已被 `issue-triage` 判为 `S1` 或 `security`）
- 正常 release 火车对这个严重度来说太慢吗（要好几天）？
- 修复存在吗——main 上已有 commit / 已有 PR，还是要现写？

→ 任何一条"其实能等"：**不 hotfix，走正常流程**，明说。
→ 确认要 hotfix：定下 **受影响的已发布版本 `vX.Y.Z`**、**base**（那个 tag；仓库若有长期 release 分支则是 `release/X.Y`）、**要 cherry-pick 的修复 commit**、**关联 issue**。
读仓库规约：main 的分支保护（能不能直接 push / merge）、`SECURITY.md`、有没有 `release/*` 分支、CI workflow。

### Step 1 — 修复先进 main（除非不可能）

修复**先通过正常 PR 进 `main`**（走 `pr-review`，`changelog-bot` 给 main 的 `[Unreleased]` 写词条）——这样 main 是真相源、永不回退。记下修复 commit SHA。

> 例外：main 已经越过这个 bug（修复已在 / 那段 buggy 代码已被重写）→ 跳到 Step 2，用现成 commit 或定制 backport。
> 例外：bug 只存在于已发布分支、main 上根本没有 → Step 1 跳过；改在 hotfix 分支上写一个**只做等效修复**的 commit，Step 7 forward-merge 时带回 main（或在 main 上补对应 commit）。

**红线：绝不让修复只活在 hotfix 分支上**——main 必须有它（或一个取代它的修复）。

### Step 2 — 从 release 点拉 hotfix 分支

```bash
git fetch --tags
git switch -c hotfix/vX.Y.$((Z+1)) vX.Y.Z          # 建在 tag 上
# 或：git switch -c hotfix/X.Y release/X.Y          # 仓库有 release 分支时
```

hotfix 分支从**已发布的代码**起步，**不从 main 起步**。命名 `hotfix/vX.Y.(Z+1)`。版本号：S1 bug → patch；安全 → patch（若改了行为可 minor，但优先 patch）。

### Step 3 — 只 cherry-pick 修复

```bash
git cherry-pick <fix-sha>                            # Step 1 的那个（些）commit
# 冲突只做最小解决——只动让修复能 apply 所必需的
```

**硬规则：只 cherry-pick 修复 commit**——不带任何无关 commit、不"反正都改了"的清理、不顺手 bump 依赖、不带"也落在 main 上的那个 feature"。修复是多个 commit 就精确 cherry-pick 那几个。冲突需要超出 trivial 的解决 → **停**：这不是干净 hotfix；缩小范围，或在 hotfix 分支上手写一个只做等效修复的最小 commit，并在 PR 里写明与 main 的差异。

### Step 4 — hotfix 分支上的 CHANGELOG 词条

在 hotfix 分支上、新起一个 `## [X.Y.(Z+1)] - YYYY-MM-DD` dated 段，把词条写进去（这是**唯一**一个词条进 dated 段、且在非 main 分支上的情况——因为 hotfix 分支**就是**这条 release 线）。用 `changelog-bot` 起草；`Fixed` 或 `Security`，引用 issue + Step 1 的 main PR。

> main 的 CHANGELOG 已经在 `[Unreleased]` 里有同一个修复（Step 1 的 PR 带的）——没问题；main 下次发版时它会出现在那次的 dated 段。**现在不要往 main 重复加。**

### Step 5 — 简化 hotfix gate 的 review

开 hotfix PR（`hotfix/vX.Y.(Z+1)` → tag 的分支，或 `release/X.Y`）。跑 `pr-review` 的**「紧急 hotfix」简化 gate**，不是全 8 步：

- [ ] CI 全绿
- [ ] **回归测试**在（能复现原 bug、修后变绿的那个用例）
- [ ] CHANGELOG 词条在
- [ ] 目标分支正确
- [ ] **`pr-review` Step 6 安全触发判定一条不省**

不接受"紧急所以 follow-up 再补"。仓库 tag-off-main 没有 release 分支时，"PR" 可以是打 tag 前对 hotfix 分支本身的 review——review 照样做。

### Step 6 — 打 patch tag，交 `release-sop` 发版

交接给 `release-sop`，从它的 **Step 5** 进入（前面的 项目识别 / 身份对齐 / DoR 回放 / pre-flight / CHANGELOG 已被本 skill 的 Step 0–5 等效做完）：

```bash
git tag -a vX.Y.$((Z+1)) -m "Hotfix vX.Y.$((Z+1)) — <一句话>"
git push origin vX.Y.$((Z+1))
gh release create vX.Y.$((Z+1)) --title "vX.Y.$((Z+1)) — hotfix: <一句话>" --notes-file <[X.Y.(Z+1)] 段>
```

然后走 `release-sop` 的发布后验证（Step 7）+ DOD（Step 8）。**release notes 必须说清修了什么、影响哪些版本。**

### Step 7 — forward-merge hotfix 回 main（不可省）

hotfix 分支上有 main 没有的 commit（至少那个 CHANGELOG dated 段，可能还有定制修复 commit）。把 hotfix 分支 merge 回 main，让 main 反映现实：

```bash
git switch main && git pull --ff-only
git merge --no-ff hotfix/vX.Y.$((Z+1))               # main 受保护则改走 PR
# 解冲突：保留 main 的 [Unreleased] 结构；[X.Y.(Z+1)] dated 段也应进 main 的 CHANGELOG 历史（它是一次真实 release）
```

main 受保护、不能直接 merge → 开一个 `merge hotfix vX.Y.(Z+1) back to main` 的 PR。**这个 merge 落地前，hotfix 不算 done**——没 forward-merge 的 hotfix 意味着下个 minor release 静默地把 bug 又带回来。

> 仓库有多条 live release 分支（`release/1.x`、`release/2.x`…）→ 从 hotfix base 到 main 之间**每一条** release 分支按序 forward-merge，一条都不能跳。

验证：`git branch --contains <修复 sha>` 里有 `main`；`main` 的 CHANGELOG 有 `[X.Y.(Z+1)]` 段。

### Step 8 — DOD 闭环

逐项勾选才允许"hotfix 完成"：

- [ ] hotfix 分支建在 `vX.Y.Z` 上（不是 main）
- [ ] 只 cherry-pick 了修复 commit —— `git log vX.Y.Z..hotfix/vX.Y.(Z+1)` 只有修复 + CHANGELOG commit
- [ ] 回归测试在且绿
- [ ] `vX.Y.(Z+1)` 已 tag、已 push、GitHub Release 已发、notes 写明受影响版本
- [ ] 发布后 smoke 过（原 repro 在 `vX.Y.(Z+1)` 上已正常）
- [ ] **hotfix 已 forward-merge 回 main**（`git branch --contains` 显示 `main`）；main 的 CHANGELOG 有 `[X.Y.(Z+1)]`
- [ ]（多 release 分支仓库）每条中间 `release/*` 都 forward-merge 过了
- [ ] 触发本流程的（被 `issue-triage` 判过的）issue 已关、milestone 已更新
- [ ] 已交回 `release-sop` 出标准发版闭环报告

## 故障预案 / 边界情况

| 情况 | 处置 |
|---|---|
| "其实能等下个 release" | 不 hotfix；走正常流程。hotfix 是给等不了的，不是图快 |
| 修复在 main 上不存在（bug 只在已发布分支）| Step 1 跳过；hotfix 分支上写一个只做等效修复的最小 commit，Step 7 带回 main（或 main 上补对应 commit）|
| cherry-pick 冲突很大 | 停——不是干净 hotfix；缩小范围，或在 hotfix 分支手写最小等效修复 commit，PR 里写明与 main 的差异 |
| 仓库 tag-off-main、没 release 分支 | hotfix 分支建在 **tag** 上；"PR" = 打 tag 前对 hotfix 分支的 review |
| 仓库有多条 live release 分支 | base→main 之间每条 release 分支按序 forward-merge，一条不跳 |
| 安全 hotfix | 全程走 `SECURITY.md`：私有处置直到 release；release notes 红字 + CVE/advisory 链接 + 播报；Step 5 安全触发判定不省 |
| main 受保护、不能直接 merge 回去 | Step 7 改成开 "merge hotfix back to main" PR；它合入前 hotfix 不算 done |
| 忘了 forward-merge | 最常见的 leak——DOD 的 `git branch --contains` 那条专堵它；没过这条不许说"完成" |
| 想顺手在 hotfix 里多带点改动 | 不行——cherry-pick only；任何"反正都改了"走正常 PR 进 main |
| hotfix 后又发现要再 hotfix | 从**新的** `vX.Y.(Z+1)` tag 再起 `hotfix/vX.Y.(Z+2)`，重走全流程；不在旧 hotfix 分支上叠 |

## 红线（不可越）

1. **hotfix 分支建在 release 点（tag / `release/*`）上，不建在 main 上**
2. **只 cherry-pick 修复 commit** —— 不夹带任何无关改动
3. **修复必须先（或同时）进 main** —— 不允许只活在 hotfix 分支上
4. **必须 forward-merge 回 main**（及每条中间 release 分支）—— 没 merge 回去 = 没完成
5. **hotfix 也要 CHANGELOG 词条 + 回归测试** —— 不接受"紧急所以省了"
6. **安全 hotfix 走 `SECURITY.md`** —— Step 5 安全触发判定不省；release notes 必须写明影响版本
7. **tag 是唯一发布触发** —— 沿用 `release-sop` 的红线
8. **不夹带其他 commit 进 hotfix** —— 这也是 `release-sop` 的红线之一

## 与其他 skill 的衔接

- `issue-triage`：被判 `S1` / `security` 的 issue 是本流程的触发源；本流程 Step 8 关掉它。
- `pr-review`：hotfix PR 用 `pr-review` 的「紧急 hotfix」简化 gate（CI 绿 + 回归测试 + CHANGELOG + 目标分支正确 + **安全触发判定不省**）；不跑全 8 步。
- `changelog-bot`：给 hotfix PR 产出 `Fixed` / `Security` 词条（Step 1 进 main 的 `[Unreleased]`，Step 4 进 hotfix 分支的 dated 段）。
- `release-sop`：Step 6 起把发版交给 `release-sop`（它的 Step 5–8：打 tag、盯盘、smoke、DOD）；本流程是它的"紧急入口"，结束时引用它的闭环报告。

## 输出风格

- Step 0 先判"该不该 hotfix"——能等就不 hotfix，明说理由
- 每步给确切命令；cherry-pick / forward-merge 这种把"只能动什么"写死、不留模糊
- 安全 hotfix 全程标注走私有渠道，不在公开处复述 PoC / 细节
- 收尾 DOD **必含 `git branch --contains` 那条**（forward-merge 验证）；没过不许说"完成"
- 最后把发版交接给 `release-sop`，引用它出的标准发版闭环报告
