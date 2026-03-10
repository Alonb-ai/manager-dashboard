#!/bin/bash
# Sync tasks from Google Sheets to local tasks.json
# Usage: ./sync-tasks.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="$SCRIPT_DIR/tasks.json"

# Apps Script URL (same as in index.html)
APPS_SCRIPT_URL="https://script.google.com/macros/s/AKfycbw6TW4jymmpX_TjyypwcKbBCFl8LbI_4Ly6Lr8kr0ZJ4LgvOBMIY-0XEnXAk_gWOy6eow/exec"

echo "Syncing tasks from Google Sheets..."

# Fetch tasks via Apps Script API (follows redirects)
RESPONSE=$(curl -sL "${APPS_SCRIPT_URL}?action=read" 2>/dev/null)

if [ -z "$RESPONSE" ]; then
    echo "Error: No response from Google Sheets API"
    exit 1
fi

# Check if response is valid JSON with rows
if ! echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'rows' in d" 2>/dev/null; then
    echo "Error: Invalid response from API"
    echo "$RESPONSE" | head -c 200
    exit 1
fi

# Transform the flat rows into categorized structure with summary
python3 -c "
import json, sys
from datetime import datetime, timezone

data = json.loads('''$RESPONSE''')
rows = data.get('rows', [])

CAT_COLORS = {
    'מיידי': '#c76a6a',
    'באגים': '#d4a853',
    \"פיצ'רים עמר\": '#9b8ec4',
    \"פיצ'רים יובל לי\": '#6b9bc3',
    'טווח קרוב': '#6aada0',
    'טווח רחוק': '#8a8580',
    'Production': '#7ab07a',
    'n8n אימות': '#b87dbf'
}

categories = {}
total = 0
done = 0

for r in rows:
    cat = r.get('category', 'אחר')
    if cat not in categories:
        categories[cat] = {
            'color': CAT_COLORS.get(cat, '#8a8580'),
            'tasks': []
        }

    is_done = str(r.get('done', '')).upper() == 'TRUE'
    is_verified = str(r.get('verified_in_code', '')).upper() == 'TRUE'

    categories[cat]['tasks'].append({
        'id': int(r.get('id', 0)),
        'task': r.get('task', ''),
        'done': is_done,
        'category': cat,
        'priority': int(r.get('priority', 9)) if r.get('priority') else 9,
        'est_hours': float(r.get('est_hours', 0)) if r.get('est_hours') else 0,
        'verified_in_code': is_verified,
        'note': r.get('note', '')
    })

    total += 1
    if is_done:
        done += 1

remaining = total - done
pct = round(done / total * 100) if total > 0 else 0

output = {
    'synced_at': datetime.now(timezone.utc).isoformat(),
    'categories': categories,
    'summary': {
        'total': total,
        'done': done,
        'remaining': remaining,
        'percent': pct
    }
}

print(json.dumps(output, ensure_ascii=False, indent=2))
" > "$OUTPUT"

if [ $? -eq 0 ]; then
    # Print summary
    TOTAL=$(python3 -c "import json; d=json.load(open('$OUTPUT')); print(d['summary']['total'])")
    DONE=$(python3 -c "import json; d=json.load(open('$OUTPUT')); print(d['summary']['done'])")
    PCT=$(python3 -c "import json; d=json.load(open('$OUTPUT')); print(d['summary']['percent'])")
    echo "Synced successfully! $DONE/$TOTAL tasks done ($PCT%)"
    echo "Output: $OUTPUT"
else
    echo "Error: Failed to process task data"
    exit 1
fi
