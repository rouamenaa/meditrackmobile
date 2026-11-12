const http = require('http');

function req(method, path, data, token) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: '127.0.0.1',
      port: 3000,
      path,
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(token && { 'Authorization': 'Bearer ' + token })
      }
    };
    const r = http.request(options, (res) => {
      let b = '';
      res.on('data', c => b += c);
      res.on('end', () => resolve({ status: res.statusCode, body: b }));
    });
    r.on('error', reject);
    if (data) r.write(JSON.stringify(data));
    r.end();
  });
}

const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZhZjVkNDZlNjZhZThhMjNiYzgxNWRhOSIsImlhdCI6MTc5NDQ5NTYwMCwiZXhwIjoxNzk3MDg3NjAwfQ.BEV8vj8j40RAvZczKH2ig3xhVqKdAdb_Dftmm_YOpmY';

req('POST', '/treatments', {
  medicationName: 'Doliprane',
  medicationDosage: '500 mg',
  dose: '1 comprimé',
  reminderTimes: ['08:00', '20:00'],
  startDate: '2026-11-12',
  status: 'active'
}, token).then(x => console.log('Status:', x.status, 'Body:', x.body));