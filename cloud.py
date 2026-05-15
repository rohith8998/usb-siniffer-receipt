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
python3 -c " 
import requests 
r = requests.post( 
    'https://script.google.com/macros/s/YOURURL/exec', 
    json={'filename': 'test.bin', 'data': 'Hello from Pi'}, 
    timeout=10 
) 
print(r.status_code, r.text)" 