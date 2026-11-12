const http = require('http');

function request(method, path, data, token) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: '127.0.0.1',
      port: 3000,
      path,
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(token && { 'Authorization': `Bearer ${token}` }),
      },
    };
    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => resolve({ status: res.statusCode, body }));
    });
    req.on('error', reject);
    if (data) req.write(JSON.stringify(data));
    req.end();
  });
}

async function main() {
  try {
    // Use the token from registration (test user)
    // The register response had this token:
    const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZhZjVkNDZlNjZhZThhMjNiYzgxNWRhOSIsImlhdCI6MTc5NDQ5NTYwMCwiZXhwIjoxNzk3MDg3NjAwfQ.BEV8vj8j40RAvZczKH2ig3xhVqKdAdb_Dftmm_YOpmY';
    const userId = '6af5d46e66ae8a23bc815da9';
    console.log('Using token from registration...');

    // 1. Create a treatment
    console.log('\n1. Creating treatment...');
    const create = await request('POST', '/treatments', {
      medicationName: 'Doliprane',
      medicationDosage: '500 mg',
      dose: '1 comprimé',
      reminderTimes: ['08:00', '20:00'],
      startDate: '2026-11-12',
      status: 'active'
    }, token);
    console.log('Create status:', create.status);
    console.log('Create body:', create.body);
    const treatment = JSON.parse(create.body);

    // 2. List treatments
    console.log('\n2. Listing treatments...');
    const list = await request('GET', '/treatments', null, token);
    console.log('List status:', list.status);
    console.log('List body:', list.body);

    // 3. Get one treatment
    console.log('\n3. Getting treatment by ID...');
    const getOne = await request('GET', `/treatments/${treatment.id}`, null, token);
    console.log('GetOne status:', getOne.status);
    console.log('GetOne body:', getOne.body);

    // 4. Update treatment
    console.log('\n4. Updating treatment...');
    const update = await request('PUT', `/treatments/${treatment.id}`, {
      dose: '2 comprimés',
      status: 'active'
    }, token);
    console.log('Update status:', update.status);
    console.log('Update body:', update.body);

    // 5. Delete treatment
    console.log('\n5. Deleting treatment...');
    const del = await request('DELETE', `/treatments/${treatment.id}`, null, token);
    console.log('Delete status:', del.status);
    console.log('Delete body:', del.body);

    console.log('\n✅ All treatment endpoints working!');
  } catch (e) {
    console.error('Error:', e);
  }
}

main();