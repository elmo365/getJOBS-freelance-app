# BotsJobsConnect Admin Guide

## Overview

This guide provides instructions for administrators of the BotsJobsConnect platform. Administrators have special privileges to manage users, approve companies, and oversee platform operations.

## Default Admin Account

The default admin account is:
- **Email:** `ricardodiane365@gmail.com`
- **Access:** Full administrative privileges

## Admin Features

### 1. Admin Panel Access

Administrators can access the Admin Panel through:
- **Sidebar Menu:** Look for "Admin Panel" in the navigation drawer
- **Direct URL:** Navigate to the Admin Login screen

### 2. User Management

From the Admin Panel, you can:
- View all registered users (Job Seekers, Employers, Trainers)
- Approve or reject company registrations
- View user verification status
- Manage user roles and permissions

### 3. Company Verification (KYC)

Companies must submit the following documents for verification:
- **CIPA Certificate** (Required)
- **CIPA Extract** (Required)
- **BURS TIN Evidence** (Required)
- **Proof of Business Address** (Required)
- **Authority Letter / Resolution** (Optional)

To approve a company:
1. Go to Admin Panel → Company Approvals
2. Review submitted documents
3. Click "Approve" or "Reject" with reason

### 4. Job Management

Administrators can:
- View all posted jobs
- Remove inappropriate job listings
- Feature/highlight specific jobs
- View job statistics

### 5. Notification Management

Send platform-wide notifications:
1. Go to Admin Panel → Notifications
2. Select recipient type (All Users, Job Seekers, Employers, etc.)
3. Compose message and send

## Admin Login Process

1. Open the app
2. On the Welcome Screen, tap "Admin Login" at the bottom
3. Enter your admin credentials
4. Access the Admin Dashboard

**Note:** The admin login is also accessible by tapping the logo 5 times quickly on the Welcome Screen.

## Security Best Practices

1. **Never share admin credentials** with unauthorized users
2. **Log out** when not using the admin panel
3. **Review audit logs** regularly for suspicious activity
4. **Use strong passwords** and change them periodically

## Troubleshooting

### Cannot Access Admin Panel
- Verify your account has admin privileges
- Clear app cache and try again
- Contact the development team if issues persist

### Company Documents Not Loading
- Check your internet connection
- Documents are stored in Firebase Storage
- Large files may take longer to load

### Notification Not Sending
- Ensure you have proper permissions
- Check if FCM tokens are valid
- Review Firebase Cloud Functions logs

## Technical Details

### Admin User Structure

Admin users have the following flags in their Firestore document:
```json
{
  "isAdmin": true,
  "userType": "admin",
  "adminGrantedAt": "<timestamp>"
}
```

### Setting Up New Admins

To add a new admin programmatically:

```dart
import 'package:freelance_app/utils/admin_setup.dart';

// Set a user as admin
await AdminSetup.setAdminByEmail('new.admin@example.com');

// Check if user is admin
final isAdmin = await AdminSetup.isAdminByEmail('user@example.com');

// Remove admin privileges
await AdminSetup.removeAdminByEmail('former.admin@example.com');
```

### Firebase Security Rules

Admin operations are protected by Firebase Security Rules:
- Only authenticated admins can modify user roles
- Company approvals require admin privileges
- Job deletions are logged for audit purposes

## Contact & Support

For technical issues or questions:
- **Email:** support@botsjobsconnect.com
- **Documentation:** See `/docs` folder
- **Issue Tracker:** GitHub Issues

---

*Last Updated: December 2024*
*Version: 1.0.0*

