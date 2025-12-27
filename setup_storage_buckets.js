/**
 * Appwrite Storage Buckets Setup Script
 * Creates all required storage buckets for the application
 * 
 * Usage: node setup_storage_buckets.js
 * 
 * Set API key: export APPWRITE_API_KEY="your_secret_key"
 */

const { Client, Storage } = require('node-appwrite');
require('dotenv').config();

const PROJECT_ID = '6933bb7e0015795a23a4';
const ENDPOINT = 'https://fra.cloud.appwrite.io/v1';

const API_KEY = process.env.APPWRITE_API_KEY || process.argv[2];

if (!API_KEY) {
  console.error('❌ API Key required!');
  console.log('Usage: node setup_storage_buckets.js <your_api_key>');
  console.log('Or set APPWRITE_API_KEY environment variable');
  process.exit(1);
}

const client = new Client()
  .setEndpoint(ENDPOINT)
  .setProject(PROJECT_ID)
  .setKey(API_KEY);

const storage = new Storage(client);

// Bucket configuration
const BUCKET_ID = '69352046002d26994390'; // Single bucket for all file types

async function createStorageBucket() {
  console.log('\n📦 Creating storage bucket...');
  console.log('='.repeat(60));
  console.log(`Project ID: ${PROJECT_ID}`);
  console.log(`Bucket ID: ${BUCKET_ID}`);
  console.log('='.repeat(60));

  try {
    // Check if bucket already exists
    try {
      const existingBucket = await storage.getBucket(BUCKET_ID);
      console.log(`\n✅ Bucket '${BUCKET_ID}' already exists!`);
      console.log(`   Name: ${existingBucket.name}`);
      console.log(`   Enabled: ${existingBucket.enabled}`);
      console.log(`   Maximum File Size: ${existingBucket.maximumFileSize || 'Unlimited'} bytes`);
      console.log(`   Allowed Extensions: ${existingBucket.allowedFileExtensions?.join(', ') || 'All'}`);
      return;
    } catch (e) {
      if (e.code !== 404) throw e;
      // Bucket doesn't exist, create it
    }

    // Create the bucket
    console.log('\n→ Creating bucket...');
    const bucket = await storage.createBucket(
      BUCKET_ID,
      'App Files Storage', // Name
      [
        'create("users")',      // Users can create files
        'read("any")',           // Anyone can read files (public access)
        'update("users")',       // Users can update their own files
        'delete("users")',       // Users can delete their own files
      ],
      false,  // fileSecurity: false (public access)
      true,   // enabled: true
      10 * 1024 * 1024, // maximumFileSize: 10MB (10 * 1024 * 1024 bytes)
      [       // allowedFileExtensions: All common file types
        'jpg', 'jpeg', 'png', 'gif', 'webp', // Images
        'pdf', 'doc', 'docx',                 // Documents
        'mp4', 'mov', 'avi', 'mkv',          // Videos
        'svg',                                // Vector graphics
      ],
      'none', // compression: none (can be 'none', 'gzip', 'zstd')
      false,  // encryption: false
      true,   // antivirus: true (scan uploaded files)
    );

    console.log('\n✅ Storage bucket created successfully!');
    console.log(`   Bucket ID: ${bucket.$id}`);
    console.log(`   Name: ${bucket.name}`);
    console.log(`   Enabled: ${bucket.enabled}`);
    console.log(`   Maximum File Size: ${bucket.maximumFileSize} bytes (${bucket.maximumFileSize / (1024 * 1024)} MB)`);
    console.log(`   Allowed Extensions: ${bucket.allowedFileExtensions?.join(', ') || 'All'}`);
    console.log(`   Antivirus: ${bucket.antivirus ? 'Enabled' : 'Disabled'}`);

  } catch (e) {
    if (e.message && e.message.includes('already exists')) {
      console.log(`\n✅ Bucket '${BUCKET_ID}' already exists!`);
    } else {
      console.error('\n❌ Error creating bucket:', e.message);
      if (e.response) {
        console.error('Response:', JSON.stringify(e.response, null, 2));
      }
      throw e;
    }
  }
}

async function main() {
  console.log('🚀 Starting Appwrite Storage Buckets Setup...');
  
  try {
    await createStorageBucket();
    
    console.log('\n' + '='.repeat(60));
    console.log('✅ STORAGE BUCKET SETUP COMPLETE!');
    console.log('='.repeat(60));
    console.log('\n📝 Bucket Configuration:');
    console.log('   - Single bucket for all file types');
    console.log('   - Profile images, CVs, video resumes, company logos');
    console.log('   - Maximum file size: 10MB');
    console.log('   - Public read access');
    console.log('   - Users can create/update/delete their own files');
    console.log('\n🎉 Your storage is now ready to use!');
  } catch (e) {
    console.error('\n❌ Setup failed:', e.message);
    process.exit(1);
  }
}

main();

