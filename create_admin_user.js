// create_admin_user.js
const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const SERVICE_ACCOUNT_PATH = path.resolve(__dirname, 'testora-ee95f-firebase-adminsdk-fbsvc-5c8add13f2.json');
if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
  console.error('Service account file not found at', SERVICE_ACCOUNT_PATH);
  process.exit(1);
}
admin.initializeApp({
  credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)),
});

const auth = admin.auth();
const db = admin.firestore();

const ADMIN_EMAIL = 'herciomoreira3@gmail.com';
const ADMIN_PASSWORD = '12345678';
const ADMIN_NAME = 'Hercio Moreira';
const ADMIN_SCHOOL = 'Ezame';

(async () => {
  try {
    let user;
    try {
      user = await auth.createUser({
        email: ADMIN_EMAIL,
        password: ADMIN_PASSWORD,
        displayName: ADMIN_NAME,
      });
      console.log('Auth user created, UID:', user.uid);
    } catch (e) {
      if (e.code === 'auth/email-already-exists') {
        user = await auth.getUserByEmail(ADMIN_EMAIL);
        console.log('User already existed, UID:', user.uid);
      } else {
        throw e;
      }
    }
    const userRef = db.collection('users').doc(user.uid);
    await userRef.set({
      uid: user.uid,
      email: ADMIN_EMAIL,
      name: ADMIN_NAME,
      role: 'admin',
      school: ADMIN_SCHOOL,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    console.log('Firestore admin profile written.');
  } catch (err) {
    console.error('Error provisioning admin user:', err);
  } finally {
    await admin.app().delete();
    process.exit(0);
  }
})();
