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
