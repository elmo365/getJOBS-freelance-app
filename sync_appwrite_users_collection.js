/**
 * Sync Users Collection Schema
 * Adds missing attributes/indexes if they don't exist
 */

const { Client, Databases } = require('node-appwrite');
require('dotenv').config();

const PROJECT_ID = '6933bb7e0015795a23a4';
const ENDPOINT = 'https://fra.cloud.appwrite.io/v1';
const DATABASE_ID = '6935201c0025a5f98d62';
const USERS_COLLECTION = 'users';

const API_KEY = process.env.APPWRITE_API_KEY || process.argv[2];

if (!API_KEY) {
  console.error('❌ API Key required!');
  console.log('Usage: node sync_appwrite_users_collection.js <your_api_key>');
  process.exit(1);
}

const client = new Client()
  .setEndpoint(ENDPOINT)
  .setProject(PROJECT_ID)
  .setKey(API_KEY);

const databases = new Databases(client);

function handleAttributeError(error, attr) {
  if (error?.code === 409 && error?.message?.includes('already exists')) {
    console.log(`  • Attribute '${attr}' already exists`);
    return;
  }
  throw error;
}

async function ensureStringAttribute(key, size, required = false) {
  try {
    await databases.createStringAttribute(
      DATABASE_ID,
      USERS_COLLECTION,
      key,
      size,
      required,
    );
    console.log(`  ✅ String attribute '${key}' created`);
  } catch (error) {
    handleAttributeError(error, key);
  }
}

async function ensureBooleanAttribute(key, required = false) {
  try {
    await databases.createBooleanAttribute(
      DATABASE_ID,
      USERS_COLLECTION,
      key,
      required,
    );
    console.log(`  ✅ Boolean attribute '${key}' created`);
  } catch (error) {
    handleAttributeError(error, key);
  }
}

async function ensureDatetimeAttribute(key, required = false) {
  try {
    await databases.createDatetimeAttribute(
      DATABASE_ID,
      USERS_COLLECTION,
      key,
      required,
    );
    console.log(`  ✅ Datetime attribute '${key}' created`);
  } catch (error) {
    handleAttributeError(error, key);
  }
}

async function ensureIndex(key, type, attributes) {
  try {
    await databases.createIndex(
      DATABASE_ID,
      USERS_COLLECTION,
      key,
      type,
      attributes,
    );
    console.log(`  ✅ Index '${key}' created`);
  } catch (error) {
    if (error?.code === 409 && error?.message?.includes('already exists')) {
      console.log(`  • Index '${key}' already exists`);
      return;
    }
    throw error;
  }
}

async function syncUsersCollection() {
  console.log('🔄 Syncing users collection schema...');

  // Ensure base collection exists
  try {
    await databases.getCollection(DATABASE_ID, USERS_COLLECTION);
    console.log('  ✓ Users collection exists');
  } catch (error) {
    console.error('❌ Users collection not found. Please run setup_all_collections.js first.');
    throw error;
  }

  // Required string attrs
  await ensureStringAttribute('name', 255, true);
  await ensureStringAttribute('email', 255, true);
  await ensureStringAttribute('user_image', 500, false);
  await ensureStringAttribute('phone_number', 50, false);
  await ensureStringAttribute('address', 500, false);
  await ensureStringAttribute('approvalStatus', 50, false);
  await ensureStringAttribute('rejectionReason', 500, false);
  await ensureStringAttribute('company_name', 255, false);
  await ensureStringAttribute('registration_number', 100, false);
  await ensureStringAttribute('industry', 100, false);
  await ensureStringAttribute('website', 255, false);
  await ensureStringAttribute('company_description', 2000, false);
  await ensureStringAttribute('accountType', 50, false);

  // Required booleans
  await ensureBooleanAttribute('isFreelancer', true);
  await ensureBooleanAttribute('isCompany', true);
  await ensureBooleanAttribute('isApproved', true);

  // Datetime
  await ensureDatetimeAttribute('approvalDate', false);

  // Indexes
  await ensureIndex('email_index', 'unique', ['email']);
  await ensureIndex('isCompany_index', 'key', ['isCompany']);
  await ensureIndex('approvalStatus_index', 'key', ['approvalStatus']);

  console.log('✅ Users collection schema is up to date!');
}

syncUsersCollection().catch((error) => {
  console.error('❌ Sync failed:', error.message || error);
  if (error?.response) {
    console.error('Response:', JSON.stringify(error.response, null, 2));
  }
  process.exit(1);
});
