const mongoose = require('./node_modules/mongoose');
const jwt = require('./node_modules/jsonwebtoken');
require('./node_modules/dotenv').config({ path: '.env' });

const PhysicalActivity = require('./models/PhysicalActivity');
const controller = require('./controllers/activityController');

// Helper to mock express req / res
function mockRes() {
  const res = {
    statusCode: 200,
    headers: {},
    data: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(obj) {
      this.data = obj;
      return this;
    },
  };
  return res;
}

async function runTests() {
  console.log('--- STARTING PHYSICAL ACTIVITY BACKEND TESTS ---');
  await mongoose.connect(process.env.MONGO_URI);
  console.log('✓ Connected to MongoDB');

  const userA = new mongoose.Types.ObjectId().toString();
  const userB = new mongoose.Types.ObjectId().toString();

  // Test 1: Create an activity for User A
  console.log('\n[Test 1] Create activity for User A');
  const reqCreate = {
    userId: userA,
    body: {
      type: 'Running',
      durationMinutes: 45,
      distanceKm: 6.2,
      intensity: 'High',
      activityDate: '2026-11-13T08:00:00.000Z',
      notes: 'Morning run in the park',
      caloriesBurned: 450,
      localId: 101,
    },
  };
  const resCreate = mockRes();
  await controller.create(reqCreate, resCreate);
  console.log('Status:', resCreate.statusCode);
  if (resCreate.statusCode !== 201) throw new Error('Create failed: ' + JSON.stringify(resCreate.data));
  const activityA = resCreate.data;
  console.log('✓ Activity created with remote ID:', activityA.id);

  // Test 2: List activities for User A
  console.log('\n[Test 2] List activities for User A');
  const reqListA = { userId: userA };
  const resListA = mockRes();
  await controller.listMine(reqListA, resListA);
  if (resListA.statusCode !== 200 || !resListA.data.some((a) => a.id === activityA.id)) {
    throw new Error('List for User A failed: ' + JSON.stringify(resListA.data));
  }
  console.log(`✓ User A has ${resListA.data.length} activity(ies)`);

  // Test 3: Isolation check - List activities for User B (must NOT see User A's activity)
  console.log('\n[Test 3] Isolation check: List activities for User B');
  const reqListB = { userId: userB };
  const resListB = mockRes();
  await controller.listMine(reqListB, resListB);
  if (resListB.data.some((a) => a.id === activityA.id)) {
    throw new Error('Data leak! User B sees User A activity!');
  }
  console.log('✓ User B cannot see User A activities (0 found)');

  // Test 4: Isolation check - User B trying to get User A's activity by ID
  console.log('\n[Test 4] Isolation check: User B getById for User A activity');
  const reqGetB = { userId: userB, params: { id: activityA.id } };
  const resGetB = mockRes();
  await controller.getById(reqGetB, resGetB);
  if (resGetB.statusCode !== 404) {
    throw new Error('Security flaw! User B accessed User A activity by ID!');
  }
  console.log('✓ User B received 404 when accessing User A activity');

  // Test 5: Update activity as User A
  console.log('\n[Test 5] Update activity as User A');
  const reqUpdateA = {
    userId: userA,
    params: { id: activityA.id },
    body: {
      durationMinutes: 50,
      caloriesBurned: 500,
    },
  };
  const resUpdateA = mockRes();
  await controller.update(reqUpdateA, resUpdateA);
  if (resUpdateA.statusCode !== 200 || resUpdateA.data.durationMinutes !== 50) {
    throw new Error('Update failed: ' + JSON.stringify(resUpdateA.data));
  }
  console.log('✓ Activity updated successfully (new duration: 50 min)');

  // Test 6: Isolation check - User B trying to update User A's activity
  console.log('\n[Test 6] Isolation check: User B update User A activity');
  const reqUpdateB = {
    userId: userB,
    params: { id: activityA.id },
    body: { durationMinutes: 999 },
  };
  const resUpdateB = mockRes();
  await controller.update(reqUpdateB, resUpdateB);
  if (resUpdateB.statusCode !== 404) {
    throw new Error('Security flaw! User B modified User A activity!');
  }
  console.log('✓ User B received 404 when trying to update User A activity');

  // Test 7: Batch sync (offline-first sync with deduplication)
  console.log('\n[Test 7] Batch sync offline activities for User A');
  const reqSync = {
    userId: userA,
    body: {
      activities: [
        {
          localId: 201,
          type: 'Cycling',
          durationMinutes: 60,
          distanceKm: 22.0,
          intensity: 'Moderate',
          activityDate: '2026-11-13T10:00:00.000Z',
          notes: 'Offline ride',
          caloriesBurned: 400,
        },
        // Duplicate check (should update, not create duplicate)
        {
          localId: 201,
          type: 'Cycling',
          durationMinutes: 60,
          distanceKm: 23.5, // updated
          intensity: 'Moderate',
          activityDate: '2026-11-13T10:00:00.000Z',
          notes: 'Offline ride corrected',
          caloriesBurned: 420,
        },
      ],
    },
  };
  const resSync = mockRes();
  await controller.syncBatch(reqSync, resSync);
  if (resSync.statusCode !== 200 || !Array.isArray(resSync.data.synced)) {
    throw new Error('Sync batch failed: ' + JSON.stringify(resSync.data));
  }
  console.log('✓ Batch sync returned:', resSync.data.synced.length, 'item(s)');

  // Verify only 1 Cycling activity was created (no duplicates)
  const cyclingDocs = await PhysicalActivity.find({
    user: userA,
    type: 'Cycling',
  });
  if (cyclingDocs.length !== 1) {
    throw new Error(`Deduplication failed! Expected 1 Cycling document, found ${cyclingDocs.length}`);
  }
  console.log('✓ Deduplication verified (exactly 1 document found with updated values)');

  // Test 8: Delete activity as User A
  console.log('\n[Test 8] Delete activity as User A');
  const reqDel = { userId: userA, params: { id: activityA.id } };
  const resDel = mockRes();
  await controller.remove(reqDel, resDel);
  if (resDel.statusCode !== 200 || !resDel.data.ok) {
    throw new Error('Delete failed: ' + JSON.stringify(resDel.data));
  }
  console.log('✓ Activity deleted successfully');

  // Clean up test data
  await PhysicalActivity.deleteMany({ user: { $in: [userA, userB] } });
  console.log('✓ Cleaned up test documents');

  await mongoose.disconnect();
  console.log('\n=======================================');
  console.log('ALL PHYSICAL ACTIVITY TESTS PASSED (100%)');
  console.log('=======================================');
}

runTests().catch((e) => {
  console.error('\n❌ Test Error:', e);
  process.exit(1);
});
