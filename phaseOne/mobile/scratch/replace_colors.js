const fs = require('fs');
const path = require('path');

function replaceInDir(dir) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const fullPath = path.join(dir, file);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      replaceInDir(fullPath);
    } else if (file.endsWith('.dart')) {
      let content = fs.readFileSync(fullPath, 'utf8');
      if (content.includes('0xFF1E4D2B')) {
        content = content.replace(/0xFF1E4D2B/g, '0xFF2D7A3A');
        fs.writeFileSync(fullPath, content, 'utf8');
        console.log(`Updated color in ${fullPath}`);
      }
    }
  }
}

replaceInDir(path.join(__dirname, '..', 'lib'));
console.log('Color alignment completed!');
