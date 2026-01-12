#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const projectId = process.env.FIREBASE_PROJECT_ID || process.env.GCLOUD_PROJECT;
if (!projectId) {
  console.error('Missing FIREBASE_PROJECT_ID or GCLOUD_PROJECT env var.');
  process.exit(1);
}

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('Missing GOOGLE_APPLICATION_CREDENTIALS for a service account.');
  process.exit(1);
}

const seedPath = process.argv[2]
  ? path.resolve(process.argv[2])
  : path.resolve(__dirname, '..', 'data', 'firestore_seed.json');

if (!fs.existsSync(seedPath)) {
  console.error(`Seed file not found: ${seedPath}`);
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId,
});

const db = admin.firestore();

async function writeCollection(collectionName, docs) {
  const entries = Object.entries(docs);
  for (const [docId, data] of entries) {
    await db.collection(collectionName).doc(docId).set(data, { merge: false });
  }
}

async function main() {
  const raw = fs.readFileSync(seedPath, 'utf8');
  const seed = JSON.parse(raw);

  for (const [collectionName, docs] of Object.entries(seed)) {
    if (docs && typeof docs === 'object' && !Array.isArray(docs)) {
      await writeCollection(collectionName, docs);
    }
  }

  console.log('Firestore seed completed.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
