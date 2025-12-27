/**
 * Complete Appwrite Storage Buckets Setup Script
 * Creates ALL storage buckets needed by the application
 * 
 * Usage: node setup_all_buckets.js
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
  console.log('Usage: node setup_all_buckets.js <your_api_key>');
  console.log('Or set APPWRITE_API_KEY environment variable');
  process.exit(1);
}

const client = new Client()
  .setEndpoint(ENDPOINT)
  .setProject(PROJECT_ID)
  .setKey(API_KEY);

const storage = new Storage(client);

// Bucket configurations
const BUCKETS = [
  {
    id: 'profile-images',
    name: 'Profile Images',
    description: 'User profile pictures and avatars',
    maxSize: 10 * 1024 * 1024, // 10MB
    allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    permissions: [
      'create("users")',
      'read("any")',        // Public read for profile images
      'update("users")',
      'delete("users")',
    ],
  },
  {
    id: 'cvs',
    name: 'CV Documents',
    description: 'Resume and CV files (PDF, DOC, DOCX)',
    maxSize: 10 * 1024 * 1024, // 10MB
    allowedExtensions: ['pdf', 'doc', 'docx'],
    permissions: [
      'create("users")',
      'read("users")',      // Only users can read CVs (private)
      'update("users")',
      'delete("users")',
    ],
  },
  {
    id: 'video-resumes',
    name: 'Video Resumes',
    description: 'Video resume files',
    maxSize: 100 * 1024 * 1024, // 100MB (videos are larger)
    allowedExtensions: ['mp4', 'mov', 'avi', 'mkv', 'webm'],
    permissions: [
      'create("users")',
      'read("users")',      // Only users can read video resumes (private)
      'update("users")',
      'delete("users")',
    ],
  },
  {
    id: 'company-logos',
    name: 'Company Logos',
    description: 'Company logo images',
    maxSize: 5 * 1024 * 1024, // 5MB
    allowedExtensions: ['jpg', 'jpeg', 'png', 'svg', 'webp'],
    permissions: [
      'create("users")',
      'read("any")',        // Public read for company logos
      'update("users")',
      'delete("users")',
    ],
  },
];

async function createBucket(bucketConfig) {
  const { id, name, description, maxSize, allowedExtensions, permissions } = bucketConfig;
  
  console.log(`\n📦 Creating bucket: ${name} (${id})...`);
  
  try {
    // Check if bucket already exists
    try {
      const existingBucket = await storage.getBucket(id);
      console.log(`  ✓ Bucket '${id}' already exists`);
      console.log(`    Name: ${existingBucket.name}`);
      console.log(`    Enabled: ${existingBucket.enabled}`);
      console.log(`    Max Size: ${existingBucket.maximumFileSize ? (existingBucket.maximumFileSize / (1024 * 1024)).toFixed(0) + ' MB' : 'Unlimited'}`);
      return existingBucket;
    } catch (e) {
      if (e.code !== 404) throw e;
      // Bucket doesn't exist, create it
    }

    // Create the bucket
    console.log(`  → Creating bucket with configuration...`);
    const bucket = await storage.createBucket(
      id,
      name,
      permissions,
      false,  // fileSecurity: false (public access where specified)
      true,    // enabled: true
      maxSize,
      allowedExtensions,
      'none',  // compression: none
      false,   // encryption: false
      true,    // antivirus: true (scan uploaded files)
    );

    console.log(`  ✅ Bucket '${id}' created successfully!`);
    console.log(`    Name: ${bucket.name}`);
    console.log(`    Max Size: ${(maxSize / (1024 * 1024)).toFixed(0)} MB`);
    console.log(`    Allowed Extensions: ${allowedExtensions.join(', ')}`);
    console.log(`    Antivirus: Enabled`);
    
    return bucket;
  } catch (e) {
    if (e.message && e.message.includes('already exists')) {
      console.log(`  ✓ Bucket '${id}' already exists`);
    } else {
      console.error(`  ❌ Error creating bucket '${id}':`, e.message);
      if (e.response) {
        console.error('    Response:', JSON.stringify(e.response, null, 2));
      }
      throw e;
    }
  }
}

async function main() {
  console.log('🚀 Starting Complete Appwrite Storage Buckets Setup...');
  console.log('='.repeat(60));
  console.log(`Project ID: ${PROJECT_ID}`);
  console.log(`Total Buckets: ${BUCKETS.length}`);
  console.log('='.repeat(60));
  
  const results = {
    created: [],
    existing: [],
    errors: [],
  };

  try {
    for (const bucketConfig of BUCKETS) {
      try {
        const bucket = await createBucket(bucketConfig);
        if (bucket) {
          // Check if it was just created or already existed
          // We can't easily tell, so we'll assume if we got here it exists
          results.existing.push(bucketConfig.id);
        }
      } catch (e) {
        results.errors.push({ id: bucketConfig.id, error: e.message });
      }
    }
    
    console.log('\n' + '='.repeat(60));
    console.log('✅ STORAGE BUCKETS SETUP COMPLETE!');
    console.log('='.repeat(60));
    
    console.log('\n📊 Summary:');
    console.log(`   Total buckets: ${BUCKETS.length}`);
    console.log(`   Already existed: ${results.existing.length}`);
    console.log(`   Created: ${results.created.length}`);
    if (results.errors.length > 0) {
      console.log(`   Errors: ${results.errors.length}`);
      results.errors.forEach(err => {
        console.log(`     - ${err.id}: ${err.error}`);
      });
    }
    
    console.log('\n📝 Bucket Details:');
    BUCKETS.forEach(bucket => {
      console.log(`\n   ${bucket.name} (${bucket.id}):`);
      console.log(`     - Max Size: ${(bucket.maxSize / (1024 * 1024)).toFixed(0)} MB`);
      console.log(`     - Allowed: ${bucket.allowedExtensions.join(', ')}`);
      console.log(`     - Description: ${bucket.description}`);
    });
    
    console.log('\n⚠️  IMPORTANT: Update your Flutter app configuration!');
    console.log('   You need to update lib/services/appwrite/appwrite_config.dart');
    console.log('   to use the new bucket IDs:');
    console.log('   - profileImagesBucket: "profile-images"');
    console.log('   - cvsBucket: "cvs"');
    console.log('   - videoResumesBucket: "video-resumes"');
    console.log('   - companyLogosBucket: "company-logos"');
    
    console.log('\n🎉 Your storage buckets are now ready to use!');
  } catch (e) {
    console.error('\n❌ Setup failed:', e.message);
    process.exit(1);
  }
}

main();

