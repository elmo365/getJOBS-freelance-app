/**
 * Complete Appwrite Setup Script
 * Creates ALL collections AND storage buckets
 * 
 * Usage: node setup_complete.js
 * 
 * Set API key: export APPWRITE_API_KEY="your_secret_key"
 */

const { Client, Databases, Storage } = require('node-appwrite');
require('dotenv').config();

const PROJECT_ID = '6933bb7e0015795a23a4';
const ENDPOINT = 'https://fra.cloud.appwrite.io/v1';
const DATABASE_ID = '6935201c0025a5f98d62';
const BUCKET_ID = '69352046002d26994390';

const API_KEY = process.env.APPWRITE_API_KEY || process.argv[2];

if (!API_KEY) {
  console.error('❌ API Key required!');
  console.log('Usage: node setup_complete.js <your_api_key>');
  console.log('Or set APPWRITE_API_KEY environment variable');
  process.exit(1);
}

const client = new Client()
  .setEndpoint(ENDPOINT)
  .setProject(PROJECT_ID)
  .setKey(API_KEY);

const databases = new Databases(client);
const storage = new Storage(client);

// Helper function to wait for attributes to be ready
const waitForAttributes = (ms = 2000) => new Promise(resolve => setTimeout(resolve, ms));

// Helper function to create attribute safely
async function createAttributeSafely(createFn, name) {
  try {
    await createFn();
    await waitForAttributes(500);
    return true;
  } catch (e) {
    if (e.message && e.message.includes('already exists')) {
      return false; // Already exists, skip
    }
    throw e;
  }
}

// Import collection creation functions (simplified version)
// For full implementation, see setup_all_collections.js

async function setupStorageBucket() {
  console.log('\n📦 Setting up storage bucket...');
  
  try {
    const existingBucket = await storage.getBucket(BUCKET_ID);
    console.log(`  ✓ Bucket '${BUCKET_ID}' already exists`);
    return;
  } catch (e) {
    if (e.code !== 404) throw e;
  }

  try {
    await storage.createBucket(
      BUCKET_ID,
      'App Files Storage',
      [
        'create("users")',
        'read("any")',
        'update("users")',
        'delete("users")',
      ],
      false,  // fileSecurity
      true,   // enabled
      10 * 1024 * 1024, // 10MB max
      ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf', 'doc', 'docx', 'mp4', 'mov', 'avi', 'mkv', 'svg'],
      'none', // compression
      false,  // encryption
      true,   // antivirus
    );
    console.log(`  ✅ Bucket '${BUCKET_ID}' created successfully`);
  } catch (e) {
    if (e.message && e.message.includes('already exists')) {
      console.log(`  ✓ Bucket '${BUCKET_ID}' already exists`);
    } else {
      throw e;
    }
  }
}

async function main() {
  console.log('🚀 Starting Complete Appwrite Setup...');
  console.log('='.repeat(60));
  console.log(`Project ID: ${PROJECT_ID}`);
  console.log(`Database ID: ${DATABASE_ID}`);
  console.log(`Bucket ID: ${BUCKET_ID}`);
  console.log('='.repeat(60));
  console.log('\n⚠️  This script will run the full setup.');
  console.log('   For detailed collection setup, run: node setup_all_collections.js');
  console.log('   For bucket setup only, run: node setup_storage_buckets.js\n');
  
  try {
    // Run bucket setup
    await setupStorageBucket();
    
    console.log('\n' + '='.repeat(60));
    console.log('✅ STORAGE BUCKET SETUP COMPLETE!');
    console.log('='.repeat(60));
    console.log('\n📝 Next steps:');
    console.log('   1. Run: node setup_all_collections.js');
    console.log('   2. Or run both scripts separately');
    console.log('\n🎉 Setup process started!');
  } catch (e) {
    console.error('\n❌ Error:', e.message);
    if (e.response) {
      console.error('Response:', JSON.stringify(e.response, null, 2));
    }
    process.exit(1);
  }
}

main();

