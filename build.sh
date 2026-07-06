#!/bin/bash

echo "🔢 Auto-incrementing buildNumber in pdxinfo..."
python3 -c "
import re
with open('source/pdxinfo', 'r') as f: data = f.read()
new_data = re.sub(r'buildNumber=(\d+)', lambda m: f'buildNumber={int(m.group(1))+1}', data)
with open('source/pdxinfo', 'w') as f: f.write(new_data)
"

echo "🎮 Compiling Willow..."
pdc source Willow.pdx

echo "📦 Zipping bundle for sideloading..."
rm -f Willow.zip
zip -r Willow.zip Willow.pdx

echo "✅ Build complete! You can now drag Willow.zip into play.date/account/sideload"
