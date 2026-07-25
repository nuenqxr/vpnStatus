# vpnStatus

SwiftBar plugin สำหรับแสดงสถานะ **Azure VPN Client** บน macOS Menu Bar พร้อม Connect / Disconnect จากเมนู

## ความต้องการ

- macOS 10.15 (Catalina) ขึ้นไป
- [Azure VPN Client](https://aka.ms/azvpnclientdownload)
- [SwiftBar](https://swiftbar.app/)

## ติดตั้ง SwiftBar (macOS)

### วิธีที่ 1 — Homebrew (แนะนำ)

```bash
brew install --cask swiftbar
```

### วิธีที่ 2 — ดาวน์โหลดตรง

1. เปิด [SwiftBar Releases](https://github.com/swiftbar/SwiftBar/releases/latest)
2. ดาวน์โหลดไฟล์ `.dmg` สำหรับ Mac
3. ลาก **SwiftBar** ไปที่โฟลเดอร์ **Applications**
4. เปิดแอปจาก Applications (ครั้งแรก macOS อาจถามให้อนุญาต — กด **Open**)

### ตั้งค่า SwiftBar ครั้งแรก

1. เปิด SwiftBar จาก Menu Bar (ไอคอนรูปขีดสามขีด)
2. เลือก **SwiftBar → Preferences…** (หรือ **Settings…**)
3. ตั้ง **Plugin Folder** เป็นโฟลเดอร์ที่จะเก็บ plugin (เช่น `~/Documents/scripts`)

## ติดตั้ง vpnStatus

```bash
git clone https://github.com/nuenqxr/vpnStatus.git ~/Documents/scripts
chmod +x ~/Documents/scripts/azure-vpn.10s.sh
```

ถ้า **Plugin Folder** ของ SwiftBar ชี้ไปที่โฟลเดอร์อื่น ให้ clone ไปที่นั่น หรือ symlink:

```bash
ln -s ~/Documents/scripts/azure-vpn.10s.sh /path/to/your/plugin-folder/azure-vpn.10s.sh
```

ไอคอน **Dev / Prod / Off** จะโผล่บน Menu Bar ภายใน ~10 วินาที (อัปเดตอัตโนมัติจากชื่อไฟล์ `.10s`)

## ไอคอนตามสถานะ

| สถานะ | ไฟล์ |
|--------|------|
| ไม่เชื่อมต่อ | `icons/superhero_1487217.png` |
| Development | `icons/superhero_1492453.png` |
| Production | `icons/superhero_1487248.png` |

ปรับชื่อไฟล์ได้ในตัวแปร `ICON_*_FILE` ที่ต้นสคริปต์

## ไอคอนแบบขยับ

สคริปต์รองรับ animation แบบ RunCat โดยวนเฟรม `icons/icon01.icns` ถึง `icons/icon14.icns` แต่ปิดไว้เป็นค่าเริ่มต้น เพื่อให้ SwiftBar แสดง icon แบบ static ตามสถานะ VPN

```bash
ANIMATE_BAR_ICON=false # true = ใช้ icon animation
ANIMATION_FRAME_SEC=1  # เปลี่ยนเฟรมทุกกี่วินาที
```

ข้อจำกัดของ SwiftBar: animation จะเปลี่ยนเฟรมตอน plugin refresh เท่านั้น ถ้าชื่อไฟล์ยังเป็น `azure-vpn.10s.sh` จะขยับทุก 10 วินาที ถ้าต้องการให้ขยับต่อเนื่องจริง ให้เปลี่ยนชื่อไฟล์ plugin เป็น `.1s.sh` เช่น `azure-vpn.1s.sh`

## แสดงสถานะใน RunCat Neo

RunCat Neo ใช้ Custom Metrics โดยอ่าน JSON file ที่เราเขียนไว้ สคริปต์ `runcat-vpn-metrics.sh` จะสร้างไฟล์:

```bash
~/.runcat/azure-vpn.json
```

ทดสอบเขียนไฟล์ด้วยคำสั่ง:

```bash
bash runcat-vpn-metrics.sh
```

จากนั้นเปิด RunCat Neo → Settings → Metrics → Custom Metrics → Add Custom Metrics Source แล้วเลือกไฟล์ `~/.runcat/azure-vpn.json`

ถ้าต้องการให้สถานะอัปเดตอัตโนมัติทุก 10 วินาที ให้ติดตั้ง LaunchAgent:

```bash
mkdir -p ~/Library/Application\ Support/runcat-vpn-metrics
cp runcat-vpn-metrics.sh ~/Library/Application\ Support/runcat-vpn-metrics/
cp dev.nuenqx.runcat.azure-vpn.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/dev.nuenqx.runcat.azure-vpn.plist
```

หยุดการอัปเดต:

```bash
launchctl bootout gui/$(id -u)/dev.nuenqx.runcat.azure-vpn
```

## ปรับแต่ง

```bash
ICON_SIZE=36        # ขนาดไอคอนบน Menu Bar
BAR_TEXT_SIZE=11    # ขนาดข้อความ Dev / Prod / Off
SHOW_BAR_LABEL=true # false = แสดงเฉพาะไอคอน
```

ชื่อ VPN profile ต้องตรงกับใน Azure VPN Client (ค่าเริ่มต้น: `Development Environment`, `Production Environment`)

## หมายเหตุ

- ตรวจสถานะผ่าน `scutil --nc` (แม่นกว่าเช็ค `utun` ใน `ifconfig`)
- หลังกด Connect/Disconnect สคริปต์จะรอจนสถานะเปลี่ยนจริง แล้ว refresh UI ทันที
