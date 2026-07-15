const fs = require('fs');
const { execSync } = require('child_process');

const BASE = 'D:/lingbi-repair/';
const zh = JSON.parse(fs.readFileSync(BASE + 'lib/l10n/app_zh.arb', 'utf-8'));

// Build reverse map: Chinese string → key
const strToKey = {};
for (const [key, val] of Object.entries(zh)) {
  strToKey[val] = key;
}

// Files to process (most visible UI files first)
const files = [
  'lib/ui/pages/wg_editor_page.dart',
  'lib/ui/pages/wg_dashboard_page.dart',
  'lib/ui/pages/wg_workspace_page.dart',
  'lib/ui/pages/settings_page.dart',
  'lib/ui/pages/canon_page.dart',
  'lib/ui/pages/story_canvas_page.dart',
  'lib/ui/components/search_dialog.dart',
  'lib/ui/components/version_history_dialog.dart',
  'lib/ui/components/export_dialog.dart',
  'lib/ui/components/import_dialog.dart',
  'lib/ui/components/butterfly_analysis_dialog.dart',
  'lib/ui/components/character_graph_view.dart',
  'lib/ui/components/memory_panel.dart',
  'lib/ui/components/faction_view.dart',
  'lib/ui/components/identity_dialog.dart',
  'lib/ui/components/style_panel.dart',
  'lib/ui/components/writing_goal_card.dart',
  'lib/ui/components/writing_calendar_view.dart',
  'lib/ui/components/timeline_view.dart',
];

let totalReplaced = 0;

for (const relPath of files) {
  const path = BASE + relPath;
  if (!fs.existsSync(path)) {
    console.log('SKIP (not found):', relPath);
    continue;
  }
  let content = fs.readFileSync(path, 'utf-8');
  let fileChanged = false;

  // Replace const Text('...') patterns
  const re = /const Text\('([^']+)'\)/g;
  let m;
  let newContent = content;
  while ((m = re.exec(content)) !== null) {
    const chinese = m[1];
    const key = strToKey[chinese];
    if (key) {
      newContent = newContent.replace(
        m[0],
        "Text(AppLocalizations.of(context)!." + key + ")"
      );
      fileChanged = true;
      totalReplaced++;
    }
  }

  // Replace Text('...') without const
  const re2 = /Text\('([^']+)'\)/g;
  while ((m = re2.exec(content)) !== null) {
    const chinese = m[1];
    const key = strToKey[chinese];
    if (key) {
      newContent = newContent.replace(
        m[0],
        "Text(AppLocalizations.of(context)!." + key + ")"
      );
      fileChanged = true;
      totalReplaced++;
    }
  }

  if (fileChanged) {
    fs.writeFileSync(path, newContent, 'utf-8');
    console.log('UPDATED:', relPath);
  }
}

console.log('Total replacements:', totalReplaced);
console.log('Files processed:', files.length);
