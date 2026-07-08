# Setup Claude Code Feishu (飞书) Notifications

This document guides Claude Code to install and configure Feishu webhook notifications. On a new machine, paste this file's content to Claude Code and let it execute.

## Prerequisites

- Claude Code is installed and running
- You have a Feishu group webhook URL (format: `https://open.feishu.cn/open-apis/bot/v2/hook/xxx`)

## Instructions for Claude Code

Please complete the following steps to set up Feishu notifications:

### Step 1: Install the notification plugin from my fork

```bash
# Add my fork as marketplace (has CC 2.1.x compatibility fix)
claude /plugin marketplace add starrliu/claude-notifications-go

# Install the plugin
claude /plugin install claude-notifications-go@claude-notifications-go
```

If `/plugin` commands are not available in your context, add these to `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "claude-notifications-go@claude-notifications-go": true
  },
  "extraKnownMarketplaces": {
    "claude-notifications-go": {
      "source": {
        "source": "github",
        "repo": "starrliu/claude-notifications-go"
      }
    }
  }
}
```

### Step 2: Ask the user for their Feishu webhook URL

Ask: "Please provide your Feishu webhook URL (飞书群机器人 webhook 地址)"

### Step 3: Create notification config

Write `~/.claude/claude-notifications-go/config.json`:

```json
{
  "notifications": {
    "desktop": { "enabled": false, "sound": false },
    "webhook": {
      "enabled": true,
      "preset": "lark",
      "url": "<USER_PROVIDED_WEBHOOK_URL>"
    },
    "suppressQuestionAfterTaskCompleteSeconds": 7
  },
  "statuses": {
    "task_complete": { "enabled": true, "title": "✅ Task Completed" },
    "review_complete": { "enabled": true, "title": "🔍 Review Completed" },
    "question": { "enabled": true, "title": "❓ Claude Has Questions" },
    "plan_ready": { "enabled": true, "title": "📋 Plan Ready for Review" }
  }
}
```

### Step 4: Fix hooks.json for CC 2.1.x compatibility

Find the installed plugin's hooks file:

```bash
HOOKS=$(find ~/.claude/plugins/cache/claude-notifications-go -name "hooks.json" -path "*/hooks/*" | head -1)
```

Replace all hook commands from the broken `args` format to bare command format. Each hook's `command` field should be:

```
${CLAUDE_PLUGIN_ROOT}/bin/hook-wrapper.sh handle-hook <EventName>
```

Where `<EventName>` is one of: `PreToolUse`, `Notification`, `Stop`, `SubagentStop`, `TeammateIdle`.

**Do NOT use** `"command": "sh"` with `"args": [...]` — that format is broken on CC 2.1.x.
**Do NOT use** quotes inside the command string (e.g. `sh "..."`) — causes quote collision with the harness.

The correct `hooks.json`:

```json
{
  "hooks": {
    "PreToolUse": [{ "matcher": "ExitPlanMode|AskUserQuestion", "hooks": [{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/bin/hook-wrapper.sh handle-hook PreToolUse", "timeout": 30 }] }],
    "Notification": [{ "matcher": "permission_prompt", "hooks": [{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/bin/hook-wrapper.sh handle-hook Notification", "timeout": 30 }] }],
    "Stop": [{ "hooks": [{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/bin/hook-wrapper.sh handle-hook Stop", "timeout": 30 }] }],
    "SubagentStop": [{ "hooks": [{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/bin/hook-wrapper.sh handle-hook SubagentStop", "timeout": 30 }] }],
    "TeammateIdle": [{ "hooks": [{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/bin/hook-wrapper.sh handle-hook TeammateIdle", "timeout": 30 }] }]
  }
}
```

### Step 5: Verify

```bash
BIN=$(find ~/.claude/plugins/cache/claude-notifications-go -name "claude-notifications-linux-amd64" -o -name "claude-notifications-darwin-arm64" | head -1)
echo '{"session_id":"test","tool_name":"ExitPlanMode"}' | "$BIN" handle-hook PreToolUse
```

If the user receives a 📋 card in Feishu, setup is complete.

### Step 6: Restart Claude Code

Tell the user: "Please fully quit and restart Claude Code for hooks to take effect."

## Notification Types

After setup, notifications are sent automatically:

| Icon | Trigger |
|------|---------|
| ✅ Task Completed | Claude finishes work (used tools like Write/Edit/Bash) |
| 🔍 Review Completed | Claude did read-only work + long text response |
| ❓ Claude Has Questions | Claude uses AskUserQuestion or needs permission |
| 📋 Plan Ready | Claude exits plan mode for user approval |

## Notes

- `settings.local.json` can override `settings.json` for machine-specific values (MODEL, URL, etc.)
- The webhook URL is group-specific; different machines can point to different groups
- If the plugin auto-updates and notifications break again, re-run Step 4
