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

const validToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZhZjVkNDZlNjZhZThhMjNiYzgxNWRhOSIsImlhdCI6MTc5NDQ5NTYwMCwiZXhwIjoxNzk3MDg3NjAwfQ.BEV8vj8j40RAvZczKH2ig3xhVqKdAdb_Dftmm_YOpmY';

async function test() {
  // Test with medicationId as integer (like from SQLite)
  const result1 = await req('POST', '/treatments', {
    medicationName: 'Test Int ID',
    medicationDosage: '500 mg',
    dose: '1 comprimé',
    reminderTimes: ['08:00', '20:00'],
    startDate: '2026-11-12',
    status: 'active',
    medicationId: 42
  }, validToken);
  console.log('With medicationId integer - Status:', result1.status, 'Body:', result1.body);

  // Test with medicationId as null
  const result2 = await req('POST', '/treatments', {
    medicationName: 'Test Null ID',
    medicationDosage: '500 mg',
    dose: '1 comprimé',
    reminderTimes: ['08:00', '20:00'],
    startDate: '2026-11-12',
    status: 'active',
    medicationId: null
  }, validToken);
  console.log('With medicationId null - Status:', result2.status, 'Body:', result2.body);

  // Test without medicationId
  const result3 = await req('POST', '/treatments', {
    medicationName: 'Test No ID',
    medicationDosage: '500 mg',
    dose: '1 comprimé',
    reminderTimes: ['08:00', '20:00'],
    startDate: '2026-11-12',
    status: 'active'
  }, validToken);
  console.log('Without medicationId - Status:', result3.status, 'Body:', result3.body);
}

test();