# /Users/tuboshu/Desktop/ops-2026/APP/摸鱼统计器 的 AGENTS.md 说明

## Skills
Skill 是一组保存在 `SKILL.md` 文件中的本地指令集合。下面列出当前会话中可用的 skill。每条记录都包含名称、描述和文件路径，使用某个 skill 时可以打开其源文件查看完整说明。

### 可用 skills
- `brainstorming`：在任何创造性工作之前必须使用，包括创建功能、构建组件、增加功能或修改行为。它用于探索用户意图、需求和设计，再进入实现。  
  文件：`/Users/tuboshu/.codex/superpowers/skills/brainstorming/SKILL.md`
- `dispatching-parallel-agents`：当面对 2 个以上彼此独立、无需共享状态或串行依赖的任务时使用。  
  文件：`/Users/tuboshu/.codex/superpowers/skills/dispatching-parallel-agents/SKILL.md`
- `executing-plans`：当你已经有书面实现计划，并希望在单独会话中按检查点执行时使用。  
  文件：`/Users/tuboshu/.codex/superpowers/skills/executing-plans/SKILL.md`
- `find-skills`：当用户询问“如何做 X”“找一个实现 X 的 skill”“有没有某个 skill 能做……”或表达想扩展能力时使用。  
  文件：`/Users/tuboshu/.agents/skills/find-skills/SKILL.md`
- `finishing-a-development-branch`：当实现完成、测试全部通过，并且需要决定如何集成工作时使用，用于指导合并、提 PR 或清理收尾。  
  文件：`/Users/tuboshu/.codex/superpowers/skills/finishing-a-development-branch/SKILL.md`
- `frontend-design`：用于创建具有高设计质量、可用于生产的前端界面。当用户要求构建 Web 组件、页面或应用时使用，生成有辨识度、打磨过的代码，而不是千篇一律的 AI 风格。  
  文件：`/Users/tuboshu/.codex/skills/frontend-design/SKILL.md`
- `gongzhonghao-writer`：一站式公众号文章创作工具，整合内容创作、可视化增强、HTML 样式生成三大功能，从主题到发布，一次生成可直接复制到微信公众号的精美文章。  
  文件：`/Users/tuboshu/.codex/skills/gongzhonghao-writer/SKILL.md`
- `receiving-code-review`：在接收代码评审反馈后、开始实现修改前使用，尤其适用于反馈不清晰或技术上可疑的情况。要求进行技术核实，而不是表演式认同或盲改。  
  文件：`/Users/tuboshu/.codex/superpowers/skills/receiving-code-review/SKILL.md`
- `requesting-code-review`：在完成任务、实现重大功能或准备合并前使用，用于验证工作是否满足要求。  
  文件：`/Users/tuboshu/.codex/superpowers/skills/requesting-code-review/SKILL.md`
- `seo-audit`：当用户想审计、评估或诊断站点 SEO 问题时使用，也适用于用户提到“SEO 审计”“技术 SEO”“为什么没排名”“SEO 问题”“页面 SEO”“meta 标签检查”“SEO 健康检查”等情况。  
  文件：`/Users/tuboshu/.agents/skills/seo-audit/SKILL.md`
- `subagent-driven-development`：当你要在当前会话中执行实现计划，并且这些任务可以拆成相互独立的子任务时使用。  
  文件：`/Users/tuboshu/.codex/superpowers/skills/subagent-driven-development/SKILL.md`
- `systematic-debugging`：遇到任何 bug、测试失败或异常行为时，必须先使用，再提出修复方案。  
  文件：`/Users/tuboshu/.codex/superpowers/skills/systematic-debugging/SKILL.md`
- `test-driven-development`：实现任何功能或修复任何 bug 之前必须使用。  
  文件：`/Users/tuboshu/.codex/superpowers/skills/test-driven-development/SKILL.md`
- `ui-ux-pro-max`：UI/UX 设计智能套件，包含 50 种风格、21 套色板、50 组字体搭配、20 类图表、9 种技术栈。可执行 `plan`、`build`、`create`、`design`、`implement`、`review`、`fix`、`improve`、`optimize`、`enhance`、`refactor`、`check UI/UX code` 等操作。适用于网站、落地页、仪表盘、后台、电商、SaaS、作品集、博客、移动应用，以及 `.html`、`.tsx`、`.vue`、`.svelte` 等文件。  
  文件：`/Users/tuboshu/.codex/skills/ui-ux-pro-max/SKILL.md`
- `using-git-worktrees`：在开始功能开发、需要与当前工作区隔离，或者在执行实现计划之前使用，用于创建隔离的 git worktree 并完成安全检查。  
  文件：`/Users/tuboshu/.codex/superpowers/skills/using-git-worktrees/SKILL.md`
- `using-superpowers`：开始任何对话时都要使用，建立如何发现和使用 skill 的规则，并要求在任何回复之前先调用 Skill 工具，即使只是澄清问题也不例外。  
  文件：`/Users/tuboshu/.codex/superpowers/skills/using-superpowers/SKILL.md`
- `verification-before-completion`：在声称工作已完成、问题已修复或测试已通过之前必须使用；在提交或创建 PR 前，要求先跑验证命令并确认输出。  
  文件：`/Users/tuboshu/.codex/superpowers/skills/verification-before-completion/SKILL.md`
- `writing-plans`：当你已经拿到一个多步骤任务的规格或需求，并且准备动代码之前使用。  
  文件：`/Users/tuboshu/.codex/superpowers/skills/writing-plans/SKILL.md`
- `writing-skills`：在创建新 skill、编辑现有 skill，或验证 skill 上线前是否工作正常时使用。  
  文件：`/Users/tuboshu/.codex/superpowers/skills/writing-skills/SKILL.md`
- `skill-creator`：当用户希望创建新 skill，或者更新现有 skill，以扩展 Codex 能力时使用。  
  文件：`/Users/tuboshu/.codex/skills/.system/skill-creator/SKILL.md`
- `skill-installer`：用于把精选 skill 或某个 GitHub 仓库路径中的 skill 安装到 `$CODEX_HOME/skills` 中。适用于用户要求列出可安装 skill、安装某个精选 skill，或从其他仓库安装 skill 的情况。  
  文件：`/Users/tuboshu/.codex/skills/.system/skill-installer/SKILL.md`
- `slides`：通过 artifacts 工具中预加载的 `@oai/artifact-tool` JavaScript 接口来构建、编辑、渲染、导入和导出演示文稿。  
  文件：`/Users/tuboshu/.codex/skills/.system/slides/SKILL.md`
- `spreadsheets`：通过 artifacts 工具中预加载的 `@oai/artifact-tool` JavaScript 接口来构建、编辑、重算、导入和导出电子表格工作簿。  
  文件：`/Users/tuboshu/.codex/skills/.system/spreadsheets/SKILL.md`

## 如何使用 skills
- 发现：上面的列表就是当前会话中可用的 skill 清单，包含名称、描述和文件路径。每个 skill 的正文都保存在对应路径下。
- 触发规则：如果用户点名某个 skill（用 `$SkillName` 或自然语言提到），或者当前任务明显符合某个 skill 的描述，你必须在本轮使用它。一次提到多个 skill，就都要用。除非后续再次提到，否则不要跨轮次继承 skill。
- 缺失或受阻：如果用户点名的 skill 不在列表中，或者对应路径无法读取，简短说明这一点，然后使用最佳替代方案继续。

### 使用 skill 的步骤
1. 在决定使用某个 skill 后，先打开它的 `SKILL.md`。只读取足够支撑当前任务的部分。
2. 如果 `SKILL.md` 里出现相对路径，例如 `scripts/foo.py`，先相对于该 skill 所在目录解析；只有在必要时再考虑其他路径。
3. 如果 `SKILL.md` 指向额外目录，例如 `references/`，只加载当前请求真正需要的文件，不要整包读取。
4. 如果 skill 目录里有 `scripts/`，优先运行或修改这些脚本，不要手写大段重复代码。
5. 如果 skill 带有 `assets/` 或模板，优先复用，不要从零重建。

## 协调与顺序
- 如果多个 skill 都适用，选择能覆盖当前请求的最小 skill 集合，并说明使用顺序。
- 简短说明你正在使用哪些 skill 以及原因。
- 如果某个明显相关的 skill 没用，说明跳过原因。

## 上下文卫生
- 控制上下文体积：长内容尽量总结，不要整段粘贴；只在需要时加载额外文件。
- 避免过深地追踪引用链：优先阅读 `SKILL.md` 直接指向的文件，除非确实被阻塞。
- 当存在多个变体，例如框架、供应商或业务域版本时，只选择与当前任务相关的参考文件，并说明你的选择。

## 安全与回退
- 如果某个 skill 因文件缺失、说明不清等原因无法顺利应用，说明问题所在，然后切换到次优方案继续完成任务。

