# Manager Dashboard

A task management dashboard that syncs with Google Sheets. Used for tracking project tasks with categories, priorities, and progress.

## Architecture

- **Frontend**: `index.html` — Pure HTML/CSS/JS SPA (no build process)
- **Backend**: `google-apps-script.js` — Google Apps Script deployed as Web App
- **Data Source**: Google Sheets (source of truth)
- **Local Cache**: `tasks.json` — Auto-generated snapshot for offline/CLI access

## Reading Tasks

To get the current task list, read `tasks.json` in the project root. This file is synced from Google Sheets using `sync-tasks.sh`.

### Task Structure (tasks.json)

```json
{
  "synced_at": "2026-03-10T12:00:00.000Z",
  "categories": {
    "category_name": {
      "color": "#hex",
      "tasks": [
        {
          "id": 1,
          "task": "Task description",
          "done": false,
          "category": "category_name",
          "priority": 1,
          "est_hours": 2,
          "verified_in_code": false,
          "note": ""
        }
      ]
    }
  },
  "summary": {
    "total": 50,
    "done": 20,
    "remaining": 30,
    "percent": 40
  }
}
```

### Syncing Tasks

Run `./sync-tasks.sh` to download the latest tasks from Google Sheets into `tasks.json`.

```bash
chmod +x sync-tasks.sh
./sync-tasks.sh
```

### Google Sheets API

The Apps Script endpoint supports these actions via GET:

- **Read all**: `?action=read`
- **Toggle done**: `?action=toggle&id=ID&done=TRUE`
- **Update field**: `?action=update&id=ID&field=value`
- **Add task**: `?action=add&task=TEXT&category=CAT&priority=5`

Base URL: See `APPS_SCRIPT_URL` in `index.html`.

## Categories

| Category | Color | Description |
|----------|-------|-------------|
| מיידי | Red | Immediate/urgent tasks |
| באגים | Orange | Bug fixes |
| פיצ'רים עמר | Purple | Amr's features |
| פיצ'רים יובל לי | Blue | Yuval Li's features |
| טווח קרוב | Teal | Near-term tasks |
| טווח רחוק | Gray | Long-term tasks |
| Production | Green | Production issues |
| n8n אימות | Magenta | n8n authentication |

## Development

No build process needed. Open `index.html` in a browser or serve with any static file server.

The dashboard works on mobile and desktop — any changes made on one device sync through Google Sheets and appear on the other after refresh.
