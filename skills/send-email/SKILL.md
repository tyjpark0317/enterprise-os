---
name: send-email
description: Send emails via system automation. Use when asked to "send email", "email someone", or when any agent needs to send an email. Supports single/bulk sending, templates, and attachments.
---

## Send Email via System Automation

Automate email sending through the system's mail client.

### Flow

1. **Parse Input** — extract to, subject, body, from, cc, attachment
2. **Compose Preview** — show preview to user before sending
3. **Send** — execute via system mail automation (AppleScript on macOS, or equivalent)
4. **Confirm Delivery** — report success/failure

### Safety Rules

1. **Never send without user confirmation** — preview + "Send?" required
2. **Bulk sending: reconfirm every 10** — prevent mistakes
3. **Sensitive info check** — warn if body contains passwords, API keys
4. **Send log** — record date, recipient, subject
5. **Daily limit: 50** — protect account

### Templates

Define project-specific email templates for outreach, follow-up, partnership, etc.

## Checklist

- [ ] Parse email input
- [ ] Show preview for user confirmation
- [ ] Send via system automation
- [ ] Log delivery result
