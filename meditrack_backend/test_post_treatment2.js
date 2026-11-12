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

// Test with oussama user - first login
async function test() {
  // Try to login with oussama user (password unknown, but let's check what happens with invalid token)
  const invalidToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZhZWUwNjkwOTk3ZTdmMjBhNWU5MTk4OSIsImlhdCI6MTc5NDQ5NTYwMCwiZXhwIjoxNzk3MDg3NjAwfQ.fake';
  
  const result = await req('POST', '/treatments', {
    medicationName: 'Test',
    medicationDosage: '500 mg',
    dose: '1 comprimé',
    reminderTimes: ['08:00', '20:00'],
    startDate: '2026-11-12',
    status: 'active'
  }, invalidToken);
  
  console.log('Invalid token - Status:', result.status, 'Body:', result.body);
  
  // Test with valid test user token
  const validToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZhZjVkNDZlNjZhZThhMjNiYzgxNWRhOSIsImlhdCI6MTc5NDQ5NTYwMCwiZXhwIjoxNzk3MDg3NjAwfQ.BEV8vj8j40RAvZczKH2ig3xhVqKdAdb_Dftmm_YOpmY';
  
  const result2 = await req('POST', '/treatments', {
    medicationName: 'Test 2',
    medicationDosage: '500 mg',
    dose: '1 comprimé',
    reminderTimes: ['08:00', '20:00'],
    startDate: '2026-11-12',
    status: 'active'
  }, validToken);
  
  console.log('Valid token - Status:', result2.status, 'Body:', result2.body);
  
  // Test with medicationId as string (like from phone app)
  const result3 = await req('POST', '/treatments', {
    medicationName: 'Test 3',
    medicationDosage: '500 mg',
    dose: '1 comprimé',
    reminderTimes: ['08:00', '20:00'],
    startDate: '2026-11-12',
    status: 'active',
    medicationId: 'some-string-id'
  }, validToken);
  
  console.log('With medicationId string - Status:', result3.status, 'Body:', result3.body);
}

test();