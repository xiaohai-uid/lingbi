const fs = require('fs');
const required = [
  'lib/ui/components/search_dialog.dart',
  'lib/ui/components/version_history_dialog.dart',
  'lib/ui/components/export_dialog.dart',
  'lib/ui/components/import_dialog.dart',
  'lib/ui/pages/story_canvas_page.dart',
];
let ok = true;
for (const f of required) {
  if (fs.existsSync(f)) {
    const stat = fs.statSync(f);
    console.log(`✅ ${f} (${stat.size} bytes)`);
  } else {
    console.log(`❌ ${f} MISSING`);
    ok = false;
  }
}
process.exit(ok ? 0 : 1);
