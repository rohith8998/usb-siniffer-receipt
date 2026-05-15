#!/usr/bin/env python3 
import socket 
import os 
import time 
import requests 
  
SAVE_DIR  = '/home/rpi/receipt-sniffer/receipts' 
HOST      = '0.0.0.0' 
PORT      = 9100 
RFCOMM    = '/dev/rfcomm0' 
CLOUD_URL = 'https://script.google.com/macros/s/YOURURL/exec'  # replace 
  
os.makedirs(SAVE_DIR, exist_ok=True) 
  
print(f'Listening on port {PORT}...') 
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM) 
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1) 
server.bind((HOST, PORT)) 
server.listen(5) 
  
while True: 
    conn, addr = server.accept() 
    print(f'Connection from {addr}') 
    data = b'' 
    while True: 
        chunk = conn.recv(4096) 
        if not chunk: 
            break 
        data += chunk 
    conn.close() 
  
    if data: 
        filename = f'receipt_{int(time.time())}.bin' 
        path = os.path.join(SAVE_DIR, filename) 
        with open(path, 'wb') as f: 
            f.write(data) 
        print(f'Saved: {filename}') 
  
        try: 
            with open(RFCOMM, 'wb') as printer: 
                printer.write(data) 
                printer.write(b'\n\n\n') 
            print('Printed OK') 
        except Exception as e: 
            print(f'Print failed: {e}') 
  
        try: 
            r = requests.post(CLOUD_URL, json={ 
                'filename': filename, 
                'data': data.decode('utf-8', errors='replace') 
            }, timeout=10) 
            print(f'Cloud: {r.status_code}') 
        except Exception as e: 
            print(f'Cloud failed: {e}') SS