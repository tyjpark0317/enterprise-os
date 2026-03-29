---
name: send-email
description: Send emails via system automation. Use when asked to "send email", "email someone", or when any agent needs to send an email. Supports single/bulk sending, templates, and attachments.
---

## Send Email via System Automation

Automate email sending through the system's mail client (AppleScript on macOS, or equivalent).

### Flow

#### Step 1: Parse Input

Extract from user input:
- `to`: recipient email (required)
- `subject`: subject line (required)
- `body`: body text (required)
- `from`: sender account (optional, uses default)
- `cc`: carbon copy (optional)
- `attachment`: file path (optional)

If input is incomplete, ask the user.

#### Step 2: Compose Preview

Always show preview before sending:

```
=== Email Preview ===
From: sender@example.com
To: recipient@example.com
CC: (none)
Subject: Your subject here
Attachment: (none)
---
Body:
(email body here)
=== End Preview ===
```

**Never send without user confirmation.** "Send?" confirmation required.

#### Step 3: Send via System Automation

```bash
osascript <<'APPLESCRIPT'
tell application "Mail"
    set newMessage to make new outgoing message with properties {subject:"SUBJECT", content:"BODY", visible:false}
    tell newMessage
        make new to recipient at end of to recipients with properties {address:"TO_EMAIL"}
    end tell
    send newMessage
end tell
APPLESCRIPT
```

#### Step 4: Confirm Delivery

Report success or analyze failure with alternatives.

### Templates

Define project-specific email templates for outreach, follow-up, partnership, etc. Templates use `{name}`, `{platform}`, and other placeholders.

### Bulk Mode

CSV input format:
```csv
email,name,context
john@example.com,John Smith,Platform A
```

3-second delay between emails (spam prevention). Reconfirm every 10 emails.

### Safety Rules

1. **Never send without user confirmation** — preview + "Send?" required
2. **Bulk sending: reconfirm every 10** — prevent mistakes
3. **Sensitive info check** — warn if body contains passwords, API keys
4. **Send log** — record date, recipient, subject
5. **Daily limit: 50** — protect account (Gmail SMTP daily limit)

## Checklist

- [ ] Parse email input
- [ ] Show preview for user confirmation
- [ ] Send via system automation
- [ ] Log delivery result
