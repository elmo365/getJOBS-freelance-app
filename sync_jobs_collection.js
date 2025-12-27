/**
 * Sync Jobs Collection Schema
 * Adds missing attributes for job approval workflow
 */

const { Client, Databases } = require('node-appwrite');
require('dotenv').config();

const PROJECT_ID = '6933bb7e0015795a23a4';
const ENDPOINT = 'https://fra.cloud.appwrite.io/v1';
const DATABASE_ID = '6935201c0025a5f98d62';
const JOBS_COLLECTION = 'jobs';

const API_KEY = process.env.APPWRITE_API_KEY || process.argv[2];

if (!API_KEY) {
  console.error('❌ API Key required!');
  console.log('Usage: node sync_jobs_collection.js <your_api_key>');
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
      JOBS_COLLECTION,
      key,
      size,
      required,
    );
    console.log(`  ✅ String attribute '${key}' created`);
  } catch (error) {
    handleAttributeError(error, key);
  }
}

async function ensureBooleanAttribute(key, required = false, defaultValue = null) {
  try {
    const params = {
      databaseId: DATABASE_ID,
      collectionId: JOBS_COLLECTION,
      key,
      required,
    };
    
    if (defaultValue !== null) {
      params.default = defaultValue;
    }
    
    await databases.createBooleanAttribute(
      DATABASE_ID,
      JOBS_COLLECTION,
      key,
      required,
      defaultValue,
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
      JOBS_COLLECTION,
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
      JOBS_COLLECTION,
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

async function syncJobsCollection() {
  console.log('🔄 Syncing jobs collection schema...');

  // Ensure base collection exists
  try {
    await databases.getCollection(DATABASE_ID, JOBS_COLLECTION);
    console.log('  ✓ Jobs collection exists');
  } catch (error) {
    console.error('❌ Jobs collection not found. Please run setup_all_collections.js first.');
    throw error;
  }

  // Core job attributes (should already exist)
  await ensureStringAttribute('title', 255, true);
  await ensureStringAttribute('description', 5000, true);
  await ensureStringAttribute('category', 100, false);
  await ensureStringAttribute('location', 255, false);
  await ensureStringAttribute('salary', 100, false);
  await ensureStringAttribute('jobType', 50, false);
  await ensureStringAttribute('experienceLevel', 50, false);
  await ensureStringAttribute('status', 50, false);
  await ensureStringAttribute('userId', 255, true);
  
  // New approval workflow attributes
  await ensureBooleanAttribute('isApproved', false);
  await ensureStringAttribute('approvalStatus', 50, false);
  await ensureDatetimeAttribute('approvalDate', false);
  await ensureStringAttribute('rejectionReason', 500, false);
  
  // Timestamps
  await ensureDatetimeAttribute('createdAt', false);
  await ensureDatetimeAttribute('deadlineDate', false);

  // Indexes for efficient queries
  await ensureIndex('userId_index', 'key', ['userId']);
  await ensureIndex('category_index', 'key', ['category']);
  await ensureIndex('status_index', 'key', ['status']);
  await ensureIndex('approvalStatus_index', 'key', ['approvalStatus']);
  await ensureIndex('isApproved_index', 'key', ['isApproved']);

  console.log('✅ Jobs collection schema is up to date!');
}

syncJobsCollection().catch((error) => {
  console.error('❌ Sync failed:', error.message || error);
  if (error?.response) {
    console.error('Response:', JSON.stringify(error.response, null, 2));
  }
  process.exit(1);
});

