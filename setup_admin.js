/**
 * Admin Setup Script for Bots Jobs Connect
 * 
 * This script allows you to promote existing users to admin via command line.
 * 
 * Usage:
 *   node setup_admin.js <email1> <email2> ...
 * 
 * Example:
 *   node setup_admin.js admin@example.com support@botsjobs.com
 * 
 * Prerequisites:
 *   - Node.js installed
 *   - Firebase Admin SDK credentials (serviceAccountKey.json)
 *   - User accounts must already exist in Firebase
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
try {
  const serviceAccount = require('./serviceAccountKey.json');
  
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  
  console.log('✅ Firebase Admin SDK initialized');
} catch (error) {
  console.error('❌ Error initializing Firebase Admin SDK:', error.message);
  console.log('\n📝 Make sure you have serviceAccountKey.json in the project root.');
  console.log('   Download it from Firebase Console > Project Settings > Service Accounts');
  process.exit(1);
}

const db = admin.firestore();

/**
 * Promote a user to admin by email
 */
async function promoteToAdmin(email) {
  try {
    console.log(`\n🔍 Looking for user: ${email}`);
    
    // Search for user by email
    const usersRef = db.collection('users');
    const snapshot = await usersRef.where('email', '==', email.toLowerCase()).limit(1).get();
    
    if (snapshot.empty) {
      console.log(`❌ User not found: ${email}`);
      console.log('   User must create an account first before being promoted to admin.');
      return false;
    }
    
    const userDoc = snapshot.docs[0];
    const userData = userDoc.data();
    
    // Check if already admin
    if (userData.isAdmin === true) {
      console.log(`ℹ️  User is already an admin: ${email}`);
      return true;
    }
    
    // Update user to admin
    await userDoc.ref.update({
      isAdmin: true,
      adminSetupDate: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log(`✅ Successfully promoted to admin: ${email}`);
    console.log(`   User ID: ${userDoc.id}`);
    console.log(`   Name: ${userData.name || 'N/A'}`);
    
    return true;
  } catch (error) {
    console.error(`❌ Error promoting ${email}:`, error.message);
    return false;
  }
}

/**
 * Main function
 */
async function main() {
  console.log('🚀 Bots Jobs Connect - Admin Setup Script');
  console.log('==========================================\n');
  
  // Get emails from command line arguments
  const emails = process.argv.slice(2);
  
  if (emails.length === 0) {
    console.log('❌ No email addresses provided\n');
    console.log('Usage:');
    console.log('  node setup_admin.js <email1> <email2> ...\n');
    console.log('Example:');
    console.log('  node setup_admin.js admin@example.com support@botsjobs.com\n');
    process.exit(1);
  }
  
  console.log(`📧 Processing ${emails.length} email(s)...\n`);
  
  let successCount = 0;
  let failCount = 0;
  
  // Process each email
  for (const email of emails) {
    const success = await promoteToAdmin(email.trim());
    if (success) {
      successCount++;
    } else {
      failCount++;
    }
  }
  
  // Summary
  console.log('\n==========================================');
  console.log('📊 Summary:');
  console.log(`   ✅ Successfully promoted: ${successCount}`);
  console.log(`   ❌ Failed: ${failCount}`);
  console.log('==========================================\n');
  
  if (successCount > 0) {
    console.log('✨ Admins can now log in via the Admin Login screen in the app.');
  }
  
  process.exit(failCount > 0 ? 1 : 0);
}

// Run the script
main().catch(error => {
  console.error('\n❌ Fatal error:', error);
  process.exit(1);
});
