---
name: gbc-rom-build-debug
description: Build and debug SnDream Chinese Crystal and Rangi42 Polished Crystal on macOS using isolated RGBDS versions and SameBoy; use for baseline builds, text-rendering checks and symbol debugging.
---

# GBC build and debug
Read [tested workflow](references/workflow.md) before building.

Prefer commands for builds and inspection. Use deterministic SameBoy core replays for repeatable screenshots; use emulator UI when the user needs to take over or inspect the live game. Keep Chinese Crystal on pinned RGBDS 0.7.0 and Polished on 1.0.3 for these baselines. Stage Chinese imports outside the original repository because system import modifies its source. Import system text, sync, import main text, then build.

Polished normal and debug builds share object names: clean or use separate build directories when switching variants. A debug filename does not prove debug flags were applied. Keep matching ROM, .sym and .map together. Confirm the intended emulator window and input focus before keys or console commands; inspect the result, since snapshots can lag and short key taps may not register.

Separate compilation, startup smoke tests and full regression claims. Loading this skill does not authorize localization implementation or multi-agent delegation.

For save creation, scene replay, user handoff, or localization regressions, read
[save and replay workflow](references/saves-and-regression.md). Keep evolving
page checklists, PR history and bug details in the project's handoff, not here.

## Image inspection and reporting

The user requires all image reading and visual analysis to be delegated to a subagent. The main agent must not inspect images first. Subagents return text findings and file paths, not image payloads. Only after a subagent reports a problem may the main agent inspect the relevant images. This is explicit authorization for image-review delegation only. Reports must still embed actual screenshots using absolute-path Markdown images, with matching full-screen English references for Chinese results. Embedding a file for the user does not require loading it into the main agent context.

每次验图必须新建 subagent，以 fork_turns=none 使用空白上下文，只传必要文字背景和图片路径；不得向已读图的旧 subagent 继续追加图片。仅当工具明确支持且确认清空该 agent 全部历史上下文后才可复用；followup 新一轮消息、重置工具会话均不等于清空 agent 上下文。单批图片保持精简，大批次拆给不同新 agent，避免任何会话累积接近50张。

读图 subagent 使用用户指定的 gpt-5.6-sol。创建时显式设置 model=gpt-5.6-sol 与 fork_turns=none，不继承主 agent 的 GPT-6 模型。
