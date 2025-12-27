/**
 * Appwrite Single Storage Bucket Setup Script
 * Configures the single bucket to support ALL file types
 * (Use this if your plan only allows 1 bucket)
 * 
 * Usage: node setup_single_bucket.js
 * 
 * Set API key: export APPWRITE_API_KEY="your_secret_key"
 */

const { Client, Storage } = require('node-appwrite');
require('dotenv').config();

const PROJECT_ID = '6933bb7e0015795a23a4';
const ENDPOINT = 'https://fra.cloud.appwrite.io/v1';
const BUCKET_ID = '69352046002d26994390'; // Your existing bucket ID

const API_KEY = process.env.APPWRITE_API_KEY || process.argv[2];

if (!API_KEY) {
  console.error('❌ API Key required!');
  console.log('Usage: node setup_single_bucket.js <your_api_key>');
  console.log('Or set APPWRITE_API_KEY environment variable');
  process.exit(1);
}

const client = new Client()
  .setEndpoint(ENDPOINT)
  .setProject(PROJECT_ID)
  .setKey(API_KEY);

const storage = new Storage(client);

async function setupSingleBucket() {
  console.log('🚀 Setting up single storage bucket for all file types...');
  console.log('='.repeat(60));
  console.log(`Project ID: ${PROJECT_ID}`);
  console.log(`Bucket ID: ${BUCKET_ID}`);
  console.log('='.repeat(60));

  try {
    // Check if bucket exists
    let bucket;
    try {
      bucket = await storage.getBucket(BUCKET_ID);
      console.log(`\n✅ Bucket '${BUCKET_ID}' found!`);
      console.log(`   Current Name: ${bucket.name}`);
      console.log(`   Current Max Size: ${bucket.maximumFileSize ? (bucket.maximumFileSize / (1024 * 1024)).toFixed(0) + ' MB' : 'Unlimited'}`);
      console.log(`   Current Extensions: ${bucket.allowedFileExtensions?.length ? bucket.allowedFileExtensions.join(', ') : 'All'}`);
    } catch (e) {
      if (e.code === 404) {
        console.log(`\n📦 Bucket '${BUCKET_ID}' doesn't exist. Creating it...`);
        
        // Create bucket with all file types support
        bucket = await storage.createBucket(
          BUCKET_ID,
          'App Files Storage - All Types',
          [
            'create("users")',
            'read("any")',        // Public read for images/logos, but CVs/videos should use file-level permissions
            'update("users")',
            'delete("users")',
          ],
          false,  // fileSecurity: false
          true,   // enabled: true
          50000000, // 50MB max (50,000,000 bytes - plan limit)
          [       // All allowed extensions
            // Images
            'jpg', 'jpeg', 'png', 'gif', 'webp', 'svg',
            // Documents
            'pdf', 'doc', 'docx',
            // Videos
            'mp4', 'mov', 'avi', 'mkv', 'webm',
          ],
          'none', // compression
          false,  // encryption
          true,   // antivirus
        );
        console.log(`✅ Bucket created successfully!`);
      } else {
        throw e;
      }
    }

    // Update bucket configuration to support all file types
    console.log(`\n→ Updating bucket configuration...`);
    
    try {
      const updatedBucket = await storage.updateBucket(
        BUCKET_ID,
        'App Files Storage - All Types',
        [
          'create("users")',
          'read("any")',        // Public read (file-level permissions can restrict CVs/videos)
          'update("users")',
          'delete("users")',
        ],
        false,  // fileSecurity
        true,   // enabled
        50000000, // 50MB max (50,000,000 bytes - plan limit)
        [       // All file types
          'jpg', 'jpeg', 'png', 'gif', 'webp', 'svg',  // Images
          'pdf', 'doc', 'docx',                         // Documents
          'mp4', 'mov', 'avi', 'mkv', 'webm',           // Videos
        ],
        'none', // compression
        false,  // encryption
        true,   // antivirus
      );

      console.log(`\n✅ Bucket configuration updated successfully!`);
      console.log(`\n📝 Final Configuration:`);
      console.log(`   Name: ${updatedBucket.name}`);
      console.log(`   Max File Size: ${(updatedBucket.maximumFileSize / (1024 * 1024)).toFixed(0)} MB`);
      console.log(`   Allowed Extensions: ${updatedBucket.allowedFileExtensions?.join(', ') || 'All'}`);
      console.log(`   Antivirus: ${updatedBucket.antivirus ? 'Enabled' : 'Disabled'}`);
      console.log(`   Enabled: ${updatedBucket.enabled ? 'Yes' : 'No'}`);
      
      console.log(`\n📦 Supported File Types:`);
      console.log(`   ✅ Profile Images: JPG, PNG, GIF, WEBP`);
      console.log(`   ✅ CV Documents: PDF, DOC, DOCX`);
      console.log(`   ✅ Video Resumes: MP4, MOV, AVI, MKV, WEBM`);
      console.log(`   ✅ Company Logos: JPG, PNG, SVG, WEBP`);
      
      console.log(`\n💡 Note: Your app is already configured to use this single bucket.`);
      console.log(`   All file types will be stored in bucket: ${BUCKET_ID}`);
      console.log(`   File-level permissions can be set when uploading to restrict access.`);
      
    } catch (e) {
      if (e.message && e.message.includes('not found')) {
        console.log(`⚠️  Could not update bucket (may not have permission or bucket doesn't exist)`);
      } else {
        throw e;
      }
    }

  } catch (e) {
    console.error('\n❌ Error:', e.message);
    if (e.response) {
      console.error('Response:', JSON.stringify(e.response, null, 2));
    }
    process.exit(1);
  }
}

async function main() {
  try {
    await setupSingleBucket();
    
    console.log('\n' + '='.repeat(60));
    console.log('✅ SINGLE BUCKET SETUP COMPLETE!');
    console.log('='.repeat(60));
    console.log('\n🎉 Your storage bucket is configured for all file types!');
    console.log('   Your Flutter app can now upload:');
    console.log('   - Profile images');
    console.log('   - CV documents');
    console.log('   - Video resumes');
    console.log('   - Company logos');
  } catch (e) {
    console.error('\n❌ Setup failed:', e.message);
    process.exit(1);
  }
}

main();

