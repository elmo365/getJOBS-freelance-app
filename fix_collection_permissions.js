/**
 * Fix Collection Permissions Script
 * Updates permissions on existing collections to allow unverified users
 * 
 * Usage: node fix_collection_permissions.js
 * 
 * Set API key: export APPWRITE_API_KEY="your_secret_key"
 */

const { Client, Databases } = require('node-appwrite');
require('dotenv').config();

const PROJECT_ID = '6933bb7e0015795a23a4';
const ENDPOINT = 'https://fra.cloud.appwrite.io/v1';
const DATABASE_ID = '6935201c0025a5f98d62';

const API_KEY = process.env.APPWRITE_API_KEY || process.argv[2];

if (!API_KEY) {
  console.error('❌ API Key required!');
  console.log('Usage: node fix_collection_permissions.js <your_api_key>');
  console.log('Or set APPWRITE_API_KEY environment variable');
  process.exit(1);
}

const client = new Client()
  .setEndpoint(ENDPOINT)
  .setProject(PROJECT_ID)
  .setKey(API_KEY);

const databases = new Databases(client);

// Correct permissions for each collection (allows unverified users)
const COLLECTION_PERMISSIONS = {
  'users': [
    'create("users")',      // Any authenticated user can create
    'read("users")',        // Any authenticated user can read
    'update("users")',      // Any authenticated user can update
    'delete("users")',      // Any authenticated user can delete
    'read("any")',          // Public read for profiles
  ],
  'jobs': [
    'create("users")',      // Any authenticated user can create
    'read("any")',          // Public read
    'update("users")',      // Any authenticated user can update
    'delete("users")',      // Any authenticated user can delete
  ],
  'applications': [
    'create("users")',      // Any authenticated user can create
    'read("users")',        // Any authenticated user can read
    'update("users")',      // Any authenticated user can update
    'delete("users")',      // Any authenticated user can delete
  ],
  'interviews': [
    'create("users")',      // Any authenticated user can create
    'read("users")',        // Any authenticated user can read
    'update("users")',      // Any authenticated user can update
    'delete("users")',      // Any authenticated user can delete
  ],
  'comments': [
    'create("users")',      // Any authenticated user can create
    'read("any")',          // Public read
    'update("users")',      // Any authenticated user can update
    'delete("users")',      // Any authenticated user can delete
  ],
};

async function fixCollectionPermissions(collectionId, collectionName) {
  console.log(`\n🔧 Fixing permissions for '${collectionId}' collection...`);
  
  try {
    // Get current collection
    const collection = await databases.getCollection(DATABASE_ID, collectionId);
    
    // Update permissions
    await databases.updateCollection(
      DATABASE_ID,
      collectionId,
      collectionName,
      COLLECTION_PERMISSIONS[collectionId]
    );
    
    console.log(`  ✅ Permissions updated for '${collectionId}'`);
    console.log(`     Permissions: ${COLLECTION_PERMISSIONS[collectionId].join(', ')}`);
    
  } catch (e) {
    if (e.code === 404) {
      console.log(`  ⚠️  Collection '${collectionId}' not found. Skipping...`);
    } else {
      console.error(`  ❌ Error updating '${collectionId}': ${e.message}`);
      throw e;
    }
  }
}

async function main() {
  console.log('🚀 Fixing Collection Permissions...');
  console.log('='.repeat(60));
  console.log(`Project ID: ${PROJECT_ID}`);
  console.log(`Database ID: ${DATABASE_ID}`);
  console.log('='.repeat(60));
  console.log('\n📝 This will update permissions to allow unverified users.');
  console.log('   Permissions will use create("users") instead of users("verified")');
  
  try {
    // Fix permissions for all collections
    await fixCollectionPermissions('users', 'Users');
    await fixCollectionPermissions('jobs', 'Jobs');
    await fixCollectionPermissions('applications', 'Applications');
    await fixCollectionPermissions('interviews', 'Interviews');
    await fixCollectionPermissions('comments', 'Comments');
    
    console.log('\n' + '='.repeat(60));
    console.log('✅ ALL PERMISSIONS FIXED!');
    console.log('='.repeat(60));
    console.log('\n📋 Summary:');
    console.log('   ✅ All collections now use create("users") permissions');
    console.log('   ✅ Unverified users can now create/read/update documents');
    console.log('   ✅ No email verification required for access');
    console.log('\n🎉 Your app should now work without email verification!');
    console.log('   Try registering a new user - it should work now.');
    
  } catch (e) {
    console.error('\n❌ Error:', e.message);
    if (e.response) {
      console.error('Response:', JSON.stringify(e.response, null, 2));
    }
    process.exit(1);
  }
}

main();

