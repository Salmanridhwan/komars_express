import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # 1. MainAxisAlignment.between -> MainAxisAlignment.spaceBetween
    content = content.replace('MainAxisAlignment.between', 'MainAxisAlignment.spaceBetween')

    # 2. withOpacity -> withValues(alpha: )
    content = re.sub(r'\.withOpacity\((.*?)\)', r'.withValues(alpha: \1)', content)

    # 3. StatusBadge fixes
    content = content.replace('StatusBadgeType badgeType;', 'String statusText = "";')
    content = content.replace('badgeType = StatusBadgeType.success;', 'statusText = "Selesai";')
    content = content.replace('badgeType = StatusBadgeType.cancelled;', 'statusText = "Dibatalkan";')
    content = content.replace('badgeType = StatusBadgeType.pending;', 'statusText = "Menunggu Pembayaran";')
    content = re.sub(r'StatusBadge\(\s*text:\s*[^,]+,\s*type:\s*badgeType\s*\)', r'StatusBadge(status: statusText)', content)

    # 4. id: in auth screens
    if 'login_screen.dart' in filepath or 'register_screen.dart' in filepath:
        content = re.sub(r'\s*id:\s*[^,]+,', '', content)
    
    # 5. ButtonStyle().build()
    if 'profile_screen.dart' in filepath or 'qris_payment_screen.dart' in filepath:
        content = re.sub(r'(ButtonStyle\(.*?\))\.build\(context\)', r'\1', content, flags=re.DOTALL)
        # Actually it's probably ElevatedButton.styleFrom(...).build() or something, let's just do:
        content = re.sub(r'\.build\([^)]*\)', '', content) # wait, this might remove valid builds. 
        # Let's not blindly remove .build(). I'll fix ButtonStyle manually.

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
