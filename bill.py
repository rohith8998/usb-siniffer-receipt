import socket 
import datetime 
  
PI_IP  = '192.168.137.126' 
PI_PORT = 9100 
  
# ============================================ 
# EDIT YOUR SHOP DETAILS HERE 
SHOP_NAME    = 'MY SHOP NAME' 
SHOP_ADDRESS = '123 Main Street, Mumbai' 
SHOP_PHONE   = 'Tel: +91 98765 43210' 
SHOP_GSTIN   = 'GSTIN: 27XXXXX1234X1ZX' 
FOOTER_MSG   = 'Thank you for shopping with us!' 
FOOTER_MSG2  = 'Exchange within 7 days with receipt' 
# ============================================ 
  
def build_receipt(items, tax_percent=18): 
    WIDTH = 32 
    def divider(): return '-' * WIDTH + '\n' 
    def center(t): return t.center(WIDTH) + '\n' 
    def right_align(label, value): 
        v = f'Rs.{value:.2f}' 
        return label + ' ' * (WIDTH - len(label) - len(v)) + v + '\n' 
    def item_line(name, qty, price): 
        total = qty * price 
        line2 = f'  {qty} x Rs.{price:.2f}' 
        ts = f'Rs.{total:.2f}' 
        return name[:20] + '\n' + line2 + ' ' * (WIDTH-len(line2)-len(ts)) + ts + 
'\n' 
    now = datetime.datetime.now() 
    subtotal = sum(q*p for _,q,p in items) 
    tax = subtotal * tax_percent / 100 
    total = subtotal + tax 
    r  = '\n' 
    r += center(SHOP_NAME) 
    r += center(SHOP_ADDRESS) 
    r += center(SHOP_PHONE) 
    r += center(SHOP_GSTIN) 
    r += divider() 
    r += center(now.strftime('%d/%m/%Y  %I:%M %p')) 
    r += f'Bill No: {now.strftime("%Y%m%d%H%M%S")}\n' 
    r += divider() 
    r += 'ITEM                 QTY    PRICE\n' 
    r += divider() 
    for name, qty, price in items: r += item_line(name, qty, price) 
    r += divider() 
    r += right_align('Subtotal:', subtotal) 
    r += right_align(f'GST ({tax_percent}%):', tax) 
    r += divider() 
    r += right_align('TOTAL:', total) 
    r += divider() 
    r += '\n' + center(FOOTER_MSG) + center(FOOTER_MSG2) 
    r += '\n\n\n\n' 
    return r 
  
def send_to_pi(receipt_text): 
    data = receipt_text.encode('utf-8') 
    client = socket.socket(socket.AF_INET, socket.SOCK_STREAM) 
    client.connect((PI_IP, PI_PORT)) 
    client.sendall(data) 
    client.close() 
    print('Sent to Pi successfully') 
  
def get_items():
        items = [] 
    print('\n--- ADD ITEMS ---') 
    while True: 
        print(f'\nItem {len(items)+1}:') 
        name = input('  Item name: ').strip() 
        if not name: continue 
        try: qty = int(input('  Quantity: ')) 
        except: continue 
        try: price = float(input('  Price per unit (Rs.): ')) 
        except: continue 
        items.append((name, qty, price)) 
        print(f'  Added: {name} x{qty} @ Rs.{price:.2f}') 
        if input('\nAdd another item? (y/n): ').lower() != 'y': break 
    return items 
  
print('=' * 40) 
print('     RECEIPT BILLING SYSTEM') 
print('=' * 40) 
items = get_items() 
if not items: exit() 
try: tax = float(input('\nGST % (default 18): ') or '18') 
except: tax = 18.0 
receipt = build_receipt(items, tax) 
print('\nRECEIPT PREVIEW:') 
print(receipt) 
print('1 - Print receipt') 
print('2 - Save preview only (no print)') 
print('3 - Cancel') 
choice = input('Choice: ').strip() 
if choice == '1': send_to_pi(receipt); print('Done!') 
elif choice == '2': 
    fn = f'receipt_{datetime.datetime.now().strftime("%Y%m%d_%H%M%S")}.txt' 
    open(fn,'w').write(receipt); print(f'Saved to {fn}') 
else: print('Cancelled')