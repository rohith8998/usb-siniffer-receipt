1) ssh into the pi
ssh rpi@192.168.137.126

2) Check bridge service is running
sudo systemctl status receipt-bridge

✓ Should show: active (running) in green. If not, run:
sudo systemctl restart receipt-bridge

3) Check Bluetooth printer is bound
ls /dev/rfcomm0
✓ Should show: /dev/rfcomm0
If missing, run:
sudo rfcomm bind 0 DC:0D:30:F6:AB:EA 1

4) Quick sanity test — send test print
echo "Test" > /dev/rfcomm0
✓ Printer should print the word Test. If so, everything is ready.


**System Packages

sudo apt update && sudo apt upgrade -y
 
sudo apt install -y \
    bluetooth \
    bluez \
    bluez-tools \
    pi-bluetooth \
    python3-pip \
    python3-venv \
    git \
    build-essential \
    libglib2.0-dev \
    libdbus-1-dev

**Python Packages
pip3 install --break-system-packages requests paho-mqtt pyserial


5) USB Gadget Mode
# Add to config.txt
echo "dtoverlay=dwc2" | sudo tee -a /boot/firmware/config.txt
 
# Add to cmdline.txt (must stay ONE single line)
sudo sed -i 's/rootwait/rootwait modules-load=dwc2,g_printer/' /boot/firmware/cmdline.txt
 
# Verify it is ONE line only:
cat /boot/firmware/cmdline.txt
⚠ If modules-load=dwc2,g_printer appears twice, open nano and delete the duplicate.

6) Bluetooth Configuration
sudo nano /etc/bluetooth/main.conf
Find and change these lines (use Ctrl+W to search):
Name = ReceiptSniffer
Class = 0x000100
 
# Add at the very bottom:
[Policy]
AutoEnable=true

sudo systemctl enable bluetooth
sudo systemctl start bluetooth
sudo systemctl status bluetooth
✓ Should show: active (running)

7) Reboot
sudo reboot
Wait 90 seconds, then SSH back in and verify:
lsmod | grep g_printer      # should return a line with g_printer
bluetoothctl show           # should show Powered: yes

If Powered: no, run:
sudo rfkill unblock bluetooth
sudo bluetoothctl power on

8) Pair the Printer
Power on printer and put in pairing/discoverable mode, then:
bluetoothctl
Inside the bluetoothctl prompt, run in order:
power on
agent NoInputNoOutput
default-agent
pairable on
scan on
Wait for DC:0D:30:F6:AB:EA BlueTooth Printer to appear, then:
scan off
pair DC:0D:30:F6:AB:EA
trust DC:0D:30:F6:AB:EA
connect DC:0D:30:F6:AB:EA
quit

9) Bind to rfcomm0
sudo rfcomm bind 0 DC:0D:30:F6:AB:EA 1
ls /dev/rfcomm0
✓ Should show: /dev/rfcomm0

10) Test Print
echo "Hello Printer" > /dev/rfcomm0
✓ Printer should physically print: Hello Printer

11)Bluetooth Setup Script
File location: /home/rpi/bt_setup.sh
Create with: nano /home/rpi/bt_setup.sh
#!/bin/bash
sleep 5
sudo rfkill unblock bluetooth
sudo bluetoothctl power on
sudo rfcomm release 0 2>/dev/null || true
 
# Retry rfcomm bind up to 10 times
for i in {1..10}; do
    sudo rfcomm bind 0 DC:0D:30:F6:AB:EA 1 2>/dev/null && echo 'Bluetooth ready' && exit 0
    echo "Attempt $i failed, retrying in 3s..."
    sleep 3
done
echo "Warning: Could not bind rfcomm0"
Make executable:
chmod +x /home/rpi/bt_setup.sh

12) Receipt Receiver Daemon
File location: /home/rpi/receipt-sniffer/receiver.py
Create directory first: mkdir -p /home/rpi/receipt-sniffer
Then: nano /home/rpi/receipt-sniffer/receiver.py

13) Systemd Service
File location: /etc/systemd/system/receipt-bridge.service
Create with: sudo nano /etc/systemd/system/receipt-bridge.service
[Unit]
Description=Receipt Sniffer Bridge
After=bluetooth.target
Wants=bluetooth.target
 
[Service]
Type=simple
User=rpi
ExecStartPre=/home/rpi/bt_setup.sh
ExecStart=/usr/bin/python3 /home/rpi/receipt-sniffer/receiver.py
Restart=always
RestartSec=10
 
[Install]
WantedBy=multi-user.target
Enable and start:

sudo systemctl daemon-reload
sudo systemctl enable receipt-bridge
sudo systemctl start receipt-bridge
sudo systemctl status receipt-bridge
✓ Should show: active (running)

14) Google Sheets Cloud Setup
14.1 Create the Sheet
•	Go to sheets.google.com
•	Create new sheet, name it Receipts
•	Note the Sheet ID from the URL: docs.google.com/spreadsheets/d/THIS_PART/edit

14.2 Deploy Apps Script Webhook
•	In your sheet: Extensions → Apps Script
•	Delete existing code, paste the script below
•	Save (give project any name)
•	Deploy → New Deployment → Type: Web app
•	Execute as: Me  |  Who has access: Anyone
•	Click Deploy → copy the Web app URL ending in /exec

Apps Script code to paste:
function doPost(e) {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  var data = JSON.parse(e.postData.contents);
 
  if (sheet.getLastRow() === 0) {
    sheet.appendRow(["Timestamp", "Filename", "Receipt Data", "Size"]);
  }
 
  sheet.appendRow([
    new Date(),
    data.filename,
    data.data,
    data.data.length
  ]);
 
  return ContentService
    .createTextOutput(JSON.stringify({"status": "ok"}))
    .setMimeType(ContentService.MimeType.JSON);
}

14.3 Test the Webhook
Run this on the Pi to confirm Google Sheets is receiving data:
python3 -c "
import requests
r = requests.post(
    'https://script.google.com/macros/s/YOURURL/exec',
    json={'filename': 'test.bin', 'data': 'Hello from Pi'},
    timeout=10
)
print(r.status_code, r.text)"
✓ Should return: 200  {"status": "ok"} and a new row appears in your sheet.

15) Interactive Billing Script
Save as: send_receipt_interactive.py on your Desktop
Run with: python send_receipt_interactive.py (from Desktop folder in PowerShell)

16) To Run the Billing Script
# In PowerShell:
cd Desktop
python send_receipt_interactive.py

17) Setup Before Presenting
Open two PowerShell windows side by side:

Window 1 — SSH + live logs (shows the audience what the Pi is doing):
ssh rpi@192.168.137.126
sudo journalctl -u receipt-bridge -f

Window 2 — billing script:
cd Desktop
python send_receipt_interactive.py
