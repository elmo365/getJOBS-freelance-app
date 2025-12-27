const fs = require('fs');
const path = require('path');

function walk(dir, cb) {
  fs.readdirSync(dir).forEach(file => {
    const full = path.join(dir, file);
    if (fs.statSync(full).isDirectory()) {
      walk(full, cb);
    } else {
      cb(full);
    }
  });
}

const root = path.resolve(__dirname, '..');
const suspicious = [];

walk(root, (file) => {
  if (!file.endsWith('.dart') && !file.endsWith('.js')) return;
  if (file.includes('node_modules') || file.includes('build')) return;

  const text = fs.readFileSync(file, 'utf8');
  const lines = text.split('\n');
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].includes("collection('ratings')") || lines[i].includes('.collection("ratings")')) {
      // look ahead 8 lines to see if isApproved is present
      const snippet = lines.slice(i, i + 12).join('\n');
      const hasIsApproved = snippet.includes("isApproved") || snippet.includes("'isApproved'") || snippet.includes('isApproved', 0);
      // allow admin screens and functions (server) - skip files in /lib/screens/admin/ or /functions/
      const isAdminFile = file.includes(path.join('lib','screens','admin'));
      const isFunctionsFile = file.includes(path.join('functions'));
      const isMyRatings = file.includes('my_ratings_screen.dart');
      if (!hasIsApproved && !isAdminFile && !isFunctionsFile && !isMyRatings) {
        suspicious.push({ file, line: i + 1, context: snippet });
      }
    }
  }
});

if (suspicious.length === 0) {
  console.log('No suspicious ratings queries found.');
  process.exit(0);
}

console.log('Suspicious ratings queries (missing isApproved):');
for (const s of suspicious) {
  console.log(`- ${s.file}:${s.line}`);
}
process.exit(1);
