/**
 * Appwrite Collections Auto-Setup Script
 * Run this ONCE to create all required collections
 * 
 * Usage: node setup_collections.js
 * 
 * Make sure to set your API key:
 * export APPWRITE_API_KEY="your_secret_key"
 * OR
 * Create a .env file with: APPWRITE_API_KEY=your_secret_key
 */

const { Client, Databases } = require('node-appwrite');
require('dotenv').config();

const PROJECT_ID = '6933bb7e0015795a23a4';
const ENDPOINT = 'https://fra.cloud.appwrite.io/v1';
const DATABASE_ID = '6935201c0025a5f98d62';

const API_KEY = process.env.APPWRITE_API_KEY || process.argv[2];

if (!API_KEY) {
  console.error('❌ API Key required!');
  console.log('Usage: node setup_collections.js <your_api_key>');
  console.log('Or set APPWRITE_API_KEY environment variable');
  process.exit(1);
}

const client = new Client()
  .setEndpoint(ENDPOINT)
  .setProject(PROJECT_ID)
  .setKey(API_KEY);

const databases = new Databases(client);

async function createUsersCollection() {
  console.log('📦 Creating users collection...');
  
  try {
    // Check if exists
    await databases.getCollection(DATABASE_ID, 'users');
    console.log('  ✓ users collection already exists');
    return;
  } catch (e) {
    // Doesn't exist, create it
  }

  try {
    // Create collection
    await databases.createCollection(
      DATABASE_ID,
      'users',
      'Users',
      [
        'create("users")',
        'read("users")',
        'update("users")',
        'delete("users")',
        'read("any")', // Public read
      ]
    );

    // Add attributes
    const attributes = [
      { type: 'string', key: 'name', size: 255, required: true },
      { type: 'string', key: 'email', size: 255, required: true },
      { type: 'string', key: 'user_image', size: 255, required: false },
      { type: 'string', key: 'phone_number', size: 50, required: false },
      { type: 'string', key: 'address', size: 500, required: false },
      { type: 'boolean', key: 'isFreelancer', required: true },
      { type: 'boolean', key: 'isCompany', required: true },
      { type: 'boolean', key: 'isApproved', required: true },
      { type: 'string', key: 'approvalStatus', size: 50, required: false },
      { type: 'datetime', key: 'approvalDate', required: false },
      { type: 'string', key: 'rejectionReason', size: 500, required: false },
      { type: 'string', key: 'company_name', size: 255, required: false },
      { type: 'string', key: 'registration_number', size: 100, required: false },
      { type: 'string', key: 'industry', size: 100, required: false },
      { type: 'string', key: 'website', size: 255, required: false },
      { type: 'string', key: 'company_description', size: 2000, required: false },
    ];

    for (const attr of attributes) {
      try {
        if (attr.type === 'string') {
          await databases.createStringAttribute(
            DATABASE_ID,
            'users',
            attr.key,
            attr.size,
            attr.required,
            undefined,
            attr.default
          );
        } else if (attr.type === 'boolean') {
          await databases.createBooleanAttribute(
            DATABASE_ID,
            'users',
            attr.key,
            attr.required
          );
        } else if (attr.type === 'datetime') {
          await databases.createDatetimeAttribute(
            DATABASE_ID,
            'users',
            attr.key,
            attr.required
          );
        }
        // Wait a bit for attribute to be ready
        await new Promise(resolve => setTimeout(resolve, 500));
      } catch (e) {
        if (!e.message.includes('already exists')) {
          console.log(`  ⚠️  Error creating ${attr.key}: ${e.message}`);
        }
      }
    }

    // Wait for all attributes to be ready
    await new Promise(resolve => setTimeout(resolve, 3000));

    // Create index
    try {
      await databases.createIndex(
        DATABASE_ID,
        'users',
        'email_index',
        'unique',
        ['email']
      );
    } catch (e) {
      // Index might already exist
    }

    console.log('  ✅ users collection created successfully');
  } catch (e) {
    if (e.message.includes('already exists')) {
      console.log('  ✓ users collection already exists');
    } else {
      throw e;
    }
  }
}

async function main() {
  console.log('🚀 Starting Appwrite Collections Setup...\n');
  
  try {
    await createUsersCollection();
    // Add other collections here...
    
    console.log('\n✅ Setup complete! Your app is ready to use.');
  } catch (e) {
    console.error('\n❌ Error:', e.message);
    process.exit(1);
  }
}

main();

