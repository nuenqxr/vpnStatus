# vpnStatus

SwiftBar plugin สำหรับแสดงสถานะ **Azure VPN Client** บน macOS Menu Bar พร้อม Connect / Disconnect จากเมนู

## ความต้องการ

- macOS + [Azure VPN Client](https://aka.ms/azvpnclientdownload)
- [SwiftBar](https://swiftbar.app/) (`brew install --cask swiftbar`)

## ติดตั้ง

```bash
git clone https://github.com/nuenqxr/vpnStatus.git
chmod +x vpnStatus/azure-vpn.10s.sh
```

เปิด SwiftBar → เลือกโฟลเดอร์ที่ clone ไว้ (หรือ symlink ไฟล์ `.sh` เข้าโฟลเดอร์ plugin ของ SwiftBar)

## ไอคอนตามสถานะ

| สถานะ | ไฟล์ |
|--------|------|
| ไม่เชื่อมต่อ | `icons/icon04.icns` |
| Development | `icons/icon06.icns` |
| Production | `icons/icon13.icns` |

ปรับชื่อไฟล์ได้ในตัวแปร `ICON_*_FILE` ที่ต้นสคริปต์

## ปรับแต่ง

```bash
ICON_SIZE=24        # ขนาดไอคอนบน Menu Bar
BAR_TEXT_SIZE=11    # ขนาดข้อความ Dev / Prod / Off
SHOW_BAR_LABEL=true # false = แสดงเฉพาะไอคอน
```

ชื่อ VPN profile ต้องตรงกับใน Azure VPN Client (ค่าเริ่มต้น: `Development Environment`, `Production Environment`)

## หมายเหตุ

- ตรวจสถานะผ่าน `scutil --nc` (แม่นกว่าเช็ค `utun` ใน `ifconfig`)
- หลังกด Connect/Disconnect สคริปต์จะรอจนสถานะเปลี่ยนจริง แล้ว refresh UI ทันที
