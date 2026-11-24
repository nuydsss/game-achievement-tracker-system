// Seeds the read-only catalog (games + achievements) into Cloud Firestore.
// The Admin SDK bypasses security rules, which is why the app itself cannot write these.
//
// Usage:
//   1. Firebase console > Project settings > Service accounts > Generate new private key
//   2. Save it as tools/seed/serviceAccountKey.json  (already git-ignored)
//   3. cd tools/seed && npm install && node seed.js
const admin = require('firebase-admin');
const path = require('path');

const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');

admin.initializeApp({ credential: admin.credential.cert(require(keyPath)) });
const db = admin.firestore();

const games = require('./games.json');
const achievements = require('./achievements.json');

async function main() {
  const batch = db.batch();

  for (const g of games) {
    // total_achievements is recalculated from the achievements file
    const total = achievements.filter(a => a.game_id === g.game_id).length;
    batch.set(db.collection('games').doc(g.game_id), { ...g, total_achievements: total });
  }
  for (const a of achievements) {
    batch.set(db.collection('achievements').doc(a.achievement_id), a);
  }

  await batch.commit();
  console.log(`Seeded ${games.length} games and ${achievements.length} achievements.`);
}

main().catch(err => { console.error(err); process.exit(1); });
