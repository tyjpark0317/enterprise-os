---
name: notion-api
description: Access Notion workspace via API without MCP
---

# Notion API Direct Access

MCP 없이 Notion API를 직접 호출하여 워크스페이스와 상호작용합니다.

## Setup

Notion Integration Token이 필요합니다:
1. https://www.notion.so/my-integrations 에서 Internal Integration 생성
2. 환경 변수 설정: `export NOTION_API_KEY=secret_xxx`
3. 연결할 페이지/DB에서 Integration 추가 (Share → Invite)

## Operations

### 1. Search

```bash
curl -s -X POST "https://api.notion.com/v1/search" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"query": "검색어", "page_size": 10}' | jq '.results[] | {id: .id, title: (.properties.title.title[0].plain_text // .properties.Name.title[0].plain_text // "untitled")}'
```

### 2. Read Page

```bash
curl -s "https://api.notion.com/v1/blocks/{page_id}/children?page_size=100" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" | jq '.results[] | {type: .type, text: (.paragraph.rich_text[0].plain_text // .heading_1.rich_text[0].plain_text // .heading_2.rich_text[0].plain_text // "")}'
```

### 3. Create Page

```bash
curl -s -X POST "https://api.notion.com/v1/pages" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{
    "parent": {"page_id": "PARENT_PAGE_ID"},
    "properties": {"title": {"title": [{"text": {"content": "New Page Title"}}]}},
    "children": [
      {"object": "block", "type": "paragraph", "paragraph": {"rich_text": [{"text": {"content": "Page content"}}]}}
    ]
  }'
```

### 4. Update Page Properties

```bash
curl -s -X PATCH "https://api.notion.com/v1/pages/{page_id}" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"properties": {"Status": {"select": {"name": "Done"}}}}'
```

### 5. Append Content to Page

```bash
curl -s -X PATCH "https://api.notion.com/v1/blocks/{page_id}/children" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"children": [{"object": "block", "type": "paragraph", "paragraph": {"rich_text": [{"text": {"content": "Appended content"}}]}}]}'
```

## Fallback

NOTION_API_KEY가 없으면 Notion MCP(`mcp__claude_ai_Notion__*`)를 사용합니다.
현재 Notion MCP는 Anthropic 관리 서버로 별도 API 키 없이 작동하므로, API 키 설정 전에는 MCP를 계속 사용하세요.

## Notes

- Notion API Version: 2022-06-28 (최신)
- Rate limit: 3 requests/second
- 페이지 ID는 32자 hex (대시 포함 가능)
