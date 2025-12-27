/**
 * Complete Appwrite Collections Setup Script
 * Analyzed from codebase to create ALL collections with ALL required fields
 * 
 * Usage: node setup_all_collections.js
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
  console.log('Usage: node setup_all_collections.js <your_api_key>');
  console.log('Or set APPWRITE_API_KEY environment variable');
  process.exit(1);
}

const client = new Client()
  .setEndpoint(ENDPOINT)
  .setProject(PROJECT_ID)
  .setKey(API_KEY);

const databases = new Databases(client);

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

async function createUsersCollection() {
  console.log('\n📦 Creating users collection...');
  
  try {
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
        'read("any")', // Public read for profiles
      ]
    );

    console.log('  → Adding attributes...');

    // String attributes
    const stringAttrs = [
      { key: 'name', size: 255, required: true },
      { key: 'email', size: 255, required: true },
      { key: 'user_image', size: 500, required: false },
      { key: 'phone_number', size: 50, required: false },
      { key: 'address', size: 500, required: false },
      { key: 'approvalStatus', size: 50, required: false },
      { key: 'rejectionReason', size: 500, required: false },
      { key: 'company_name', size: 255, required: false },
      { key: 'registration_number', size: 100, required: false },
      { key: 'industry', size: 100, required: false },
      { key: 'website', size: 255, required: false },
      { key: 'company_description', size: 2000, required: false },
      { key: 'accountType', size: 50, required: false }, // For legacy compatibility
    ];

    for (const attr of stringAttrs) {
      await createAttributeSafely(
        () => databases.createStringAttribute(DATABASE_ID, 'users', attr.key, attr.size, attr.required),
        attr.key
      );
    }

    // Boolean attributes
    const boolAttrs = [
      { key: 'isFreelancer', required: true },
      { key: 'isCompany', required: true },
      { key: 'isApproved', required: true },
    ];

    for (const attr of boolAttrs) {
      await createAttributeSafely(
        () => databases.createBooleanAttribute(DATABASE_ID, 'users', attr.key, attr.required),
        attr.key
      );
    }

    // DateTime attributes
    await createAttributeSafely(
      () => databases.createDatetimeAttribute(DATABASE_ID, 'users', 'approvalDate', false),
      'approvalDate'
    );

    // Wait for all attributes to be ready
    await waitForAttributes(3000);

    // Create indexes
    try {
      await databases.createIndex(DATABASE_ID, 'users', 'email_index', 'unique', ['email']);
    } catch (e) {}
    try {
      await databases.createIndex(DATABASE_ID, 'users', 'isCompany_index', 'key', ['isCompany']);
    } catch (e) {}
    try {
      await databases.createIndex(DATABASE_ID, 'users', 'approvalStatus_index', 'key', ['approvalStatus']);
    } catch (e) {}

    console.log('  ✅ users collection created successfully');
  } catch (e) {
    if (e.message && e.message.includes('already exists')) {
      console.log('  ✓ users collection already exists');
    } else {
      throw e;
    }
  }
}

async function createJobsCollection() {
  console.log('\n📦 Creating jobs collection...');
  
  try {
    await databases.getCollection(DATABASE_ID, 'jobs');
    console.log('  ✓ jobs collection already exists');
    return;
  } catch (e) {}

  try {
    await databases.createCollection(
      DATABASE_ID,
      'jobs',
      'Jobs',
      [
        'create("users")',
        'read("any")',
        'update("users")',
        'delete("users")',
      ]
    );

    console.log('  → Adding attributes...');

    // String attributes
    const stringAttrs = [
      { key: 'userId', size: 255, required: true },
      { key: 'id', size: 255, required: false }, // Legacy field
      { key: 'title', size: 255, required: true },
      { key: 'jobTitle', size: 255, required: false }, // Alternative field name
      { key: 'description', size: 5000, required: false },
      { key: 'desc', size: 5000, required: false }, // Alternative field name
      { key: 'category', size: 100, required: false },
      { key: 'jobCategory', size: 100, required: false }, // Alternative field name
      { key: 'location', size: 255, required: false },
      { key: 'address', size: 255, required: false }, // Alternative field name
      { key: 'salary', size: 100, required: false },
      { key: 'jobType', size: 50, required: false },
      { key: 'experienceLevel', size: 50, required: false },
      { key: 'status', size: 50, required: true },
      { key: 'name', size: 255, required: false }, // Employer name
      { key: 'email', size: 255, required: false }, // Employer email
      { key: 'user_image', size: 500, required: false }, // Employer image
      { key: 'deadline_date', size: 50, required: false }, // Legacy format
    ];

    for (const attr of stringAttrs) {
      await createAttributeSafely(
        () => databases.createStringAttribute(DATABASE_ID, 'jobs', attr.key, attr.size, attr.required),
        attr.key
      );
    }

    // Boolean attributes
    await createAttributeSafely(
      () => databases.createBooleanAttribute(DATABASE_ID, 'jobs', 'recruiting', false),
      'recruiting'
    );

    // Integer attributes
    await createAttributeSafely(
      () => databases.createIntegerAttribute(DATABASE_ID, 'jobs', 'applicants', false),
      'applicants'
    );

    // DateTime attributes
    await createAttributeSafely(
      () => databases.createDatetimeAttribute(DATABASE_ID, 'jobs', 'deadlineDate', false),
      'deadlineDate'
    );
    await createAttributeSafely(
      () => databases.createDatetimeAttribute(DATABASE_ID, 'jobs', 'deadline_timestamp', false),
      'deadline_timestamp'
    );
    await createAttributeSafely(
      () => databases.createDatetimeAttribute(DATABASE_ID, 'jobs', 'createdAt', false),
      'createdAt'
    );

    // Array attributes (for applicantsList - array of user IDs)
    await createAttributeSafely(
      () => databases.createStringAttribute(DATABASE_ID, 'jobs', 'applicantsList', 255, false, true), // Array of strings
      'applicantsList'
    );

    await waitForAttributes(3000);

    // Create indexes
    try {
      await databases.createIndex(DATABASE_ID, 'jobs', 'userId_index', 'key', ['userId']);
    } catch (e) {}
    try {
      await databases.createIndex(DATABASE_ID, 'jobs', 'status_index', 'key', ['status']);
    } catch (e) {}
    try {
      await databases.createIndex(DATABASE_ID, 'jobs', 'jobCategory_index', 'key', ['jobCategory']);
    } catch (e) {}
    try {
      await databases.createIndex(DATABASE_ID, 'jobs', 'createdAt_index', 'key', ['createdAt']);
    } catch (e) {}

    console.log('  ✅ jobs collection created successfully');
  } catch (e) {
    if (e.message && e.message.includes('already exists')) {
      console.log('  ✓ jobs collection already exists');
    } else {
      throw e;
    }
  }
}

async function createApplicationsCollection() {
  console.log('\n📦 Creating applications collection...');
  
  try {
    await databases.getCollection(DATABASE_ID, 'applications');
    console.log('  ✓ applications collection already exists');
    return;
  } catch (e) {}

  try {
    await databases.createCollection(
      DATABASE_ID,
      'applications',
      'Applications',
      [
        'create("users")',
        'read("users")',
        'update("users")',
        'delete("users")',
      ]
    );

    console.log('  → Adding attributes...');

    const stringAttrs = [
      { key: 'jobId', size: 255, required: true },
      { key: 'userId', size: 255, required: true },
      { key: 'applicantName', size: 255, required: false },
      { key: 'applicantImage', size: 500, required: false },
      { key: 'status', size: 50, required: true },
      { key: 'cover_letter', size: 2000, required: false },
      { key: 'cv_file_id', size: 255, required: false },
    ];

    for (const attr of stringAttrs) {
      await createAttributeSafely(
        () => databases.createStringAttribute(DATABASE_ID, 'applications', attr.key, attr.size, attr.required),
        attr.key
      );
    }

    await createAttributeSafely(
      () => databases.createDatetimeAttribute(DATABASE_ID, 'applications', 'appliedAt', false),
      'appliedAt'
    );
    await createAttributeSafely(
      () => databases.createDatetimeAttribute(DATABASE_ID, 'applications', 'reviewedDate', false),
      'reviewedDate'
    );

    await waitForAttributes(3000);

    // Create indexes
    try {
      await databases.createIndex(DATABASE_ID, 'applications', 'jobId_index', 'key', ['jobId']);
    } catch (e) {}
    try {
      await databases.createIndex(DATABASE_ID, 'applications', 'userId_index', 'key', ['userId']);
    } catch (e) {}
    try {
      await databases.createIndex(DATABASE_ID, 'applications', 'status_index', 'key', ['status']);
    } catch (e) {}
    try {
      await databases.createIndex(DATABASE_ID, 'applications', 'appliedAt_index', 'key', ['appliedAt']);
    } catch (e) {}

    console.log('  ✅ applications collection created successfully');
  } catch (e) {
    if (e.message && e.message.includes('already exists')) {
      console.log('  ✓ applications collection already exists');
    } else {
      throw e;
    }
  }
}

async function createInterviewsCollection() {
  console.log('\n📦 Creating interviews collection...');
  
  try {
    await databases.getCollection(DATABASE_ID, 'interviews');
    console.log('  ✓ interviews collection already exists');
    return;
  } catch (e) {}

  try {
    await databases.createCollection(
      DATABASE_ID,
      'interviews',
      'Interviews',
      [
        'create("users")',
        'read("users")',
        'update("users")',
        'delete("users")',
      ]
    );

    console.log('  → Adding attributes...');

    const stringAttrs = [
      { key: 'employerId', size: 255, required: true },
      { key: 'candidateId', size: 255, required: true },
      { key: 'jobId', size: 255, required: true },
      { key: 'type', size: 50, required: false },
      { key: 'location', size: 255, required: false },
      { key: 'meetingLink', size: 500, required: false },
      { key: 'notes', size: 1000, required: false },
      { key: 'status', size: 50, required: true },
      // Legacy field names for compatibility
      { key: 'employer_id', size: 255, required: false },
      { key: 'candidate_id', size: 255, required: false },
      { key: 'job_id', size: 255, required: false },
      { key: 'job_title', size: 255, required: false },
      { key: 'candidate_name', size: 255, required: false },
      { key: 'employer_name', size: 255, required: false },
      { key: 'meeting_link', size: 500, required: false },
      { key: 'duration', size: 50, required: false },
    ];

    for (const attr of stringAttrs) {
      await createAttributeSafely(
        () => databases.createStringAttribute(DATABASE_ID, 'interviews', attr.key, attr.size, attr.required),
        attr.key
      );
    }

    await createAttributeSafely(
      () => databases.createDatetimeAttribute(DATABASE_ID, 'interviews', 'scheduledDate', true),
      'scheduledDate'
    );
    await createAttributeSafely(
      () => databases.createDatetimeAttribute(DATABASE_ID, 'interviews', 'createdAt', false),
      'createdAt'
    );
    await createAttributeSafely(
      () => databases.createDatetimeAttribute(DATABASE_ID, 'interviews', 'updatedAt', false),
      'updatedAt'
    );
    // Legacy field
    await createAttributeSafely(
      () => databases.createDatetimeAttribute(DATABASE_ID, 'interviews', 'scheduled_date', false),
      'scheduled_date'
    );

    await waitForAttributes(3000);

    // Create indexes
    try {
      await databases.createIndex(DATABASE_ID, 'interviews', 'employerId_index', 'key', ['employerId']);
    } catch (e) {}
    try {
      await databases.createIndex(DATABASE_ID, 'interviews', 'candidateId_index', 'key', ['candidateId']);
    } catch (e) {}
    try {
      await databases.createIndex(DATABASE_ID, 'interviews', 'jobId_index', 'key', ['jobId']);
    } catch (e) {}
    try {
      await databases.createIndex(DATABASE_ID, 'interviews', 'scheduledDate_index', 'key', ['scheduledDate']);
    } catch (e) {}
    try {
      await databases.createIndex(DATABASE_ID, 'interviews', 'status_index', 'key', ['status']);
    } catch (e) {}

    console.log('  ✅ interviews collection created successfully');
  } catch (e) {
    if (e.message && e.message.includes('already exists')) {
      console.log('  ✓ interviews collection already exists');
    } else {
      throw e;
    }
  }
}

async function createCommentsCollection() {
  console.log('\n📦 Creating comments collection...');
  
  try {
    await databases.getCollection(DATABASE_ID, 'comments');
    console.log('  ✓ comments collection already exists');
    return;
  } catch (e) {}

  try {
    await databases.createCollection(
      DATABASE_ID,
      'comments',
      'Comments',
      [
        'create("users")',
        'read("any")',
        'update("users")',
        'delete("users")',
      ]
    );

    console.log('  → Adding attributes...');

    const stringAttrs = [
      { key: 'jobId', size: 255, required: true },
      { key: 'userId', size: 255, required: true },
      { key: 'content', size: 1000, required: true },
    ];

    for (const attr of stringAttrs) {
      await createAttributeSafely(
        () => databases.createStringAttribute(DATABASE_ID, 'comments', attr.key, attr.size, attr.required),
        attr.key
      );
    }

    await createAttributeSafely(
      () => databases.createBooleanAttribute(DATABASE_ID, 'comments', 'isEdited', false),
      'isEdited'
    );

    await createAttributeSafely(
      () => databases.createDatetimeAttribute(DATABASE_ID, 'comments', 'createdDate', false),
      'createdDate'
    );
    await createAttributeSafely(
      () => databases.createDatetimeAttribute(DATABASE_ID, 'comments', 'editedDate', false),
      'editedDate'
    );

    await waitForAttributes(3000);

    // Create indexes
    try {
      await databases.createIndex(DATABASE_ID, 'comments', 'jobId_index', 'key', ['jobId']);
    } catch (e) {}
    try {
      await databases.createIndex(DATABASE_ID, 'comments', 'userId_index', 'key', ['userId']);
    } catch (e) {}
    try {
      await databases.createIndex(DATABASE_ID, 'comments', 'createdDate_index', 'key', ['createdDate']);
    } catch (e) {}

    console.log('  ✅ comments collection created successfully');
  } catch (e) {
    if (e.message && e.message.includes('already exists')) {
      console.log('  ✓ comments collection already exists');
    } else {
      throw e;
    }
  }
}

async function main() {
  console.log('🚀 Starting Complete Appwrite Collections Setup...');
  console.log('='.repeat(60));
  console.log(`Project ID: ${PROJECT_ID}`);
  console.log(`Database ID: ${DATABASE_ID}`);
  console.log('='.repeat(60));
  
  try {
    await createUsersCollection();
    await createJobsCollection();
    await createApplicationsCollection();
    await createInterviewsCollection();
    await createCommentsCollection();
    
    console.log('\n' + '='.repeat(60));
    console.log('✅ ALL COLLECTIONS CREATED SUCCESSFULLY!');
    console.log('='.repeat(60));
    console.log('\n🎉 Your app is now ready to use!');
    console.log('   You can now register users, post jobs, and use all features.');
  } catch (e) {
    console.error('\n❌ Error:', e.message);
    if (e.response) {
      console.error('Response:', JSON.stringify(e.response, null, 2));
    }
    process.exit(1);
  }
}

main();

