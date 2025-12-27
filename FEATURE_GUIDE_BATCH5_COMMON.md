# 🔗 COMMON FEATURES GUIDE
## Easy-to-Understand Guide for Features Used Across All Roles
**Based on Real Code Analysis**  
**Updated:** December 25, 2025

---

## 📱 1. USER AUTHENTICATION - CREATE & LOGIN TO YOUR ACCOUNT

### What This Is

The system that lets you create an account and login securely.

### Account Creation Process

**Step 1: Sign Up Screen**
```
┌──────────────────────────────────┐
│  CREATE YOUR ACCOUNT             │
├──────────────────────────────────┤
│                                  │
│  Select Your Role:               │
│  [Job Seeker] [Employer]         │
│  [Trainer] [Admin]               │
│                                  │
│  Email Address:                  │
│  [email@example.com]             │
│  ✓ Valid email required          │
│                                  │
│  Password:                       │
│  [••••••••••]                    │
│  ✓ Minimum 8 characters          │
│  ✓ Must have uppercase           │
│  ✓ Must have numbers             │
│  ✓ Must have symbols (!@#$%...)  │
│                                  │
│  Full Name:                      │
│  [Your Full Name]                │
│                                  │
│  [Create Account]                │
│                                  │
└──────────────────────────────────┘
```

**Step 2: Email Verification**
```
You'll receive an email with a link.
- Click the link to verify email
- This proves your email is real
- Without verification, limited features
- Takes 2-3 minutes
```

**Step 3: Complete Your Profile**
```
After verification, add:
- Phone number
- Profile picture
- Bio/description
- Location
- Skills/experience
- (depending on your role)
```

### Password Requirements

**Your password MUST have:**
- ✓ At least 8 characters
- ✓ At least 1 UPPERCASE letter (A-Z)
- ✓ At least 1 lowercase letter (a-z)
- ✓ At least 1 number (0-9)
- ✓ At least 1 special character (!@#$%^&*)

**Good Password Examples:**
- MyPassword123!
- SecurePass@2024
- LongPassword#456

**Bad Password Examples:**
- password (no uppercase, number, symbol)
- 12345678 (only numbers)
- Password (no number, symbol)

### Login Process

**Step 1: Login Screen**
```
┌──────────────────────────────────┐
│  WELCOME BACK                    │
├──────────────────────────────────┤
│                                  │
│  Email:                          │
│  [your@email.com]                │
│                                  │
│  Password:                       │
│  [••••••••••]                    │
│                                  │
│  [Show Password]                 │
│                                  │
│  [Login]                         │
│  [Forgot Password?]              │
│  [Create Account]                │
│                                  │
└──────────────────────────────────┘
```

**Step 2: System Validates**
```
1. Checks email exists
2. Verifies password correct
3. Checks if account verified
4. Checks if account suspended
5. Logs you in
```

**Step 3: You're In!**
```
Your dashboard appears
- All your information
- Personalized content
- Your history
- Your messages
- Your actions
```

### Password Reset

**If You Forget Your Password:**
```
1. Click "Forgot Password?" link
2. Enter your email
3. Check your email inbox
4. Click reset link in email
5. Create new password
6. Login with new password
```

---

## 💬 2. MESSAGING - COMMUNICATE WITH OTHER USERS

### What This Is

Built-in chat system to message employers, job seekers, trainers, admins, etc.

### Messaging Types

**Job Seeker to Employer:**
- Ask questions about job
- Send application details
- Discuss pay/terms
- Negotiate offer

**Employer to Job Seeker:**
- Ask about experience
- Clarify job details
- Offer interview
- Send job offer

**Trainer to Student:**
- Schedule sessions
- Send resources
- Answer questions
- Provide feedback

**Admin to User:**
- Explain decisions
- Request information
- Send notifications
- Provide support

### Messaging Interface

**Message List View:**
```
┌──────────────────────────────────┐
│  YOUR MESSAGES                   │
├──────────────────────────────────┤
│ [Unread: 3] [All] [Archived]     │
│                                  │
│ 1. Sarah Johnson                 │
│    Last: "When can you start?"   │
│    2 hours ago                   │
│    [Unread] ●                    │
│    [Open Chat]                   │
│                                  │
│ 2. TechCorp Ltd                  │
│    Last: "Interview tomorrow"    │
│    8 hours ago                   │
│    [Read]                        │
│    [Open Chat]                   │
│                                  │
│ 3. John Trainer                  │
│    Last: "Session at 2pm"        │
│    1 day ago                     │
│    [Unread] ●                    │
│    [Open Chat]                   │
│                                  │
│ 4. Admin Support                 │
│    Last: "Your question:"        │
│    3 days ago                    │
│    [Read]                        │
│    [Open Chat]                   │
│                                  │
└──────────────────────────────────┘
```

**Individual Chat View:**
```
┌──────────────────────────────────┐
│ Sarah Johnson                    │
├──────────────────────────────────┤
│                                  │
│ [MESSAGES]                       │
│                                  │
│ ← Sarah: Hey! Interested in     │
│   the Developer role?            │
│   10:30 AM                       │
│                                  │
│                          Me: → |
│   Yes, I'm very interested!      │
│   When can I start?              │
│   10:45 AM                       │
│                                  │
│ ← Sarah: Next Monday OK?         │
│   We'll discuss salary           │
│   10:50 AM                       │
│                                  │
│ [Type message...] [Send] [Attach]
│                                  │
└──────────────────────────────────┘
```

### Message Features

**Send Text:**
- Type message
- Send immediately
- See "read" status

**Send Files:**
- Upload documents
- Share images
- Send CVs/portfolios

**Search Messages:**
- Find old conversations
- Search by keyword
- Filter by person

**Notifications:**
- Get alert when message arrives
- Badge shows unread count
- Can turn on/off

### Best Practices

**Professional Tone:**
- Be courteous
- Spell correctly
- Avoid slang
- Stay on topic

**Clear Communication:**
- Be specific
- Ask clear questions
- Provide context
- Quick responses

**Safety:**
- Don't share passwords
- Don't send financial info
- Report harassment
- Block bad users

---

## ⭐ 3. RATINGS & REVIEWS - RATE YOUR EXPERIENCE

### What This Is

System for rating people after you work with them. Helps others know who's good.

### Rating Scale

**⭐⭐⭐⭐⭐ (5 Stars)**
- Excellent experience
- Would work again
- Highly recommend
- No complaints

**⭐⭐⭐⭐ (4 Stars)**
- Good experience
- Minor issues
- Would work again
- Worth recommending

**⭐⭐⭐ (3 Stars)**
- Average experience
- Some issues
- Got the job done
- Not sure about next time

**⭐⭐ (2 Stars)**
- Poor experience
- Multiple issues
- Job incomplete
- Not recommended

**⭐ (1 Star)**
- Very bad experience
- Major problems
- Won't work again
- Bad quality

### How to Rate

**When You Can Rate:**
- After job completion
- After training session
- After gig work ends
- After transaction finishes

**Rating Process:**
```
1. Click "Rate" button
2. Choose 1-5 stars
3. Write optional comment
4. Submit rating
5. Rating appears on profile
```

**Good Review Example:**
```
⭐⭐⭐⭐⭐
"Excellent trainer! Very patient, 
explained everything clearly, 
great communication. Would 
definitely book again!"
```

**Bad Review Example:**
```
⭐
"Never delivered the work promised.
Unresponsive to messages. Total 
waste of money. Avoid!"
```

### Review Features

**Your Profile Shows:**
- Average rating (out of 5)
- Total number of reviews
- Latest reviews
- Rating breakdown (% at each star)

**Using Reviews:**
- People read before hiring you
- Good reviews attract work
- Bad reviews lose jobs
- Build your reputation

---

## 👤 4. USER PROFILES - YOUR PUBLIC PRESENCE

### What Your Profile Shows

Different information depending on your role.

### Job Seeker Profile

```
┌────────────────────────────────┐
│ YOUR PROFILE                   │
├────────────────────────────────┤
│                                │
│ 📸 [Profile Photo]             │
│ John Smith                      │
│ ⭐ 4.8 (15 reviews)            │
│                                │
│ ABOUT                          │
│ Experienced developer with     │
│ 5 years in web development.    │
│ Passionate about clean code.   │
│                                │
│ SKILLS                         │
│ • Python ⭐⭐⭐⭐⭐           │
│ • JavaScript ⭐⭐⭐⭐          │
│ • React ⭐⭐⭐⭐              │
│ • AWS ⭐⭐⭐                  │
│                                │
│ EXPERIENCE                     │
│ 5 years Software Development   │
│ 2 years Full-Stack Dev         │
│ Freelance: 1 year              │
│                                │
│ EDUCATION                      │
│ BSc Computer Science           │
│ University of Botswana         │
│                                │
│ LOCATION                       │
│ Gaborone, Botswana             │
│                                │
│ CONTACT                        │
│ Email: john@email.com          │
│ Phone: +267-xxx-xxxx           │
│ LinkedIn: john-dev             │
│                                │
│ PORTFOLIO                      │
│ [View My Projects]             │
│ [View My CV]                   │
│                                │
└────────────────────────────────┘
```

### Employer Profile

```
┌────────────────────────────────┐
│ COMPANY PROFILE                │
├────────────────────────────────┤
│                                │
│ 🏢 [Company Logo]              │
│ TechCorp Limited               │
│ ✓ Verified ✓                   │
│ ⭐ 4.9 (42 reviews)            │
│                                │
│ ABOUT COMPANY                  │
│ Leading technology company     │
│ specializing in software       │
│ development and consulting.    │
│                                │
│ INDUSTRY                       │
│ Information Technology         │
│                                │
│ SIZE                           │
│ 50-100 employees               │
│                                │
│ LOCATION                       │
│ Gaborone, Botswana             │
│ Remote work available          │
│                                │
│ CONTACT                        │
│ Email: hr@techcorp.bw          │
│ Phone: +267-xxx-xxxx           │
│ Website: www.techcorp.bw       │
│                                │
│ RECENT JOBS POSTED             │
│ • Senior Developer (Open)      │
│ • QA Engineer (3 hired)        │
│ • DevOps Engineer (Filled)     │
│                                │
│ HIRING STATS                   │
│ Jobs Posted: 25                │
│ Successfully Filled: 23        │
│ Average Rating: 4.9            │
│                                │
│ [Browse Their Jobs]            │
│ [Contact Company]              │
│                                │
└────────────────────────────────┘
```

### Trainer Profile

```
┌────────────────────────────────┐
│ TRAINER PROFILE                │
├────────────────────────────────┤
│                                │
│ 📸 [Trainer Photo]             │
│ Sarah Johnson                  │
│ ⭐ 4.8 (32 reviews)            │
│                                │
│ EXPERTISE                      │
│ • Excel Training               │
│ • PowerPoint Design            │
│ • Office Suite                 │
│                                │
│ EXPERIENCE                     │
│ 8 years training experience    │
│ 500+ students trained          │
│ 2,000+ hours delivered         │
│                                │
│ QUALIFICATIONS                 │
│ • Microsoft Certified          │
│ • Training Certificate         │
│ • Professional Development     │
│                                │
│ RATE                           │
│ 350 BWP per hour               │
│ Session Duration: 1 hour       │
│                                │
│ AVAILABILITY                   │
│ Weekdays: 9AM - 6PM            │
│ Weekends: By appointment       │
│                                │
│ ABOUT                          │
│ Patient and engaging trainer.  │
│ Customize lessons for each     │
│ student's learning style.      │
│                                │
│ [Book Training] [Send Message] │
│ [View Reviews]                 │
│                                │
└────────────────────────────────┘
```

### Profile Visibility

**Public (Everyone Sees):**
- Name & photo
- About/bio
- Skills & experience
- Average rating
- Reviews
- Contact info (if public)

**Private (Only You See):**
- Email
- Full phone number
- Passwords
- Financial info
- Private messages

**Privacy Settings:**
- Control what's public
- Hide contact info
- Block specific users
- Report harassment

---

## 🔔 5. NOTIFICATIONS - STAY UPDATED

### What Notifications Are

Alerts that tell you about important events happening on the platform.

### Notification Types

**Application Notifications:**
- Job application received
- Application status change
- Interview scheduled
- Offer sent/accepted

**Messaging Notifications:**
- New message received
- Someone commented
- Group chat activity
- Message replies

**Account Notifications:**
- Login from new device
- Password changed
- Account verified
- Suspension notice

**Platform Notifications:**
- Job approved/rejected
- Company verified
- Payment received
- Bid accepted

**Payment Notifications:**
- Payment sent
- Payment received
- Refund processed
- Wallet updated

### Where Notifications Appear

**In-App (Inside the App):**
- Bell icon at top
- Badge with number
- Notification center
- Click to see details

**Push Notifications (Phone):**
- Alert at top of screen
- Sound (if enabled)
- On lock screen
- Click to open app

**Email Notifications:**
- Sent to your email
- Summary of events
- Once per day
- Can unsubscribe

### Notification Settings

**What You Can Control:**
```
┌──────────────────────────────┐
│ NOTIFICATION SETTINGS        │
├──────────────────────────────┤
│                              │
│ ✓ Applications               │
│   [Receive] [Email] [Push]   │
│                              │
│ ✓ Messages                   │
│   [Receive] [Email] [Push]   │
│                              │
│ ✗ Marketing                  │
│   [Don't receive]            │
│                              │
│ ✓ Account Activity           │
│   [Receive] [Email only]     │
│                              │
│ ✓ Payment Alerts             │
│   [Receive] [Email] [Push]   │
│                              │
│ [Save Preferences]           │
│                              │
└──────────────────────────────┘
```

**Notification Examples:**

**Job Application:**
```
📧 "New Application Received"
Sarah Smith applied for 
Developer position
$10,000/month
[View Application]
```

**Message Received:**
```
💬 "New Message from TechCorp"
"Can you start next Monday?"
[Reply]
```

**Payment Received:**
```
💰 "Payment Received!"
$5,000 BWP for completed project
Pending: $500 | Paid: $5,000
[View Details]
```

---

## 🔒 6. ACCOUNT SECURITY & PRIVACY

### Password Security

**Keep Your Password Safe:**
- ✓ Don't share password
- ✓ Don't write it down
- ✓ Use unique password (not same as other sites)
- ✓ Change password regularly
- ✓ Don't use personal info

**Strong Passwords:**
- Minimum 8 characters
- Mix of uppercase/lowercase
- Include numbers
- Include symbols
- Not a dictionary word

### Two-Factor Authentication (2FA)

**What It Is:**
Extra security layer - needs two things to login:
1. Your password
2. Code from phone

**How It Works:**
```
1. Enter email and password
2. System sends code to phone
3. Enter code to prove it's you
4. Login successful
```

**Advantages:**
- Even if someone gets your password, they can't login
- Extra protection
- Takes 10 seconds
- Highly recommended

### Privacy Settings

**Control What's Visible:**
- Hide phone number
- Hide location
- Hide email
- Hide work history
- Private profile option

**Block Users:**
- Prevents them from messaging
- They can't see your profile
- They can't apply to your jobs
- You can unblock later

**Report Issues:**
- Report fraud
- Report harassment
- Report fake accounts
- Report inappropriate content
- Action taken within 24-48 hours

### Data Protection

**Your Data Is Protected By:**
- Secure servers
- Encrypted connections (HTTPS)
- Regular backups
- Access controls
- Privacy policy compliance

**What We Collect:**
- Basic info: name, email, phone
- Profile info: bio, skills, experience
- Transaction info: jobs, payments
- System info: login activity, device info

**What We Don't Share:**
- Password (even we can't see it)
- Credit card (never stored fully)
- Personal info (unless you make public)
- To third parties (except payment processors)

---

## 📊 FEATURES COMPARISON TABLE

| Feature | Job Seekers | Employers | Trainers | Admins |
|---------|-----------|-----------|----------|--------|
| Authentication | ✅ | ✅ | ✅ | ✅ |
| Messaging | ✅ | ✅ | ✅ | ✅ |
| Ratings | ✅ | ✅ | ✅ | ❌ |
| Notifications | ✅ | ✅ | ✅ | ✅ |
| User Profile | ✅ | ✅ | ✅ | ✅ |
| 2FA | ✅ | ✅ | ✅ | ✅ Recommended |
| Privacy Control | ✅ | ✅ | ✅ | Limited |
| Block Users | ✅ | ✅ | ✅ | ❌ |
| Report Users | ✅ | ✅ | ✅ | ✅ |

---

## 🆘 COMMON QUESTIONS

**Q: Is my password safe?**  
A: Yes. Passwords are encrypted and we can't see them. Even if hacked, your password stays secret.

**Q: How do I recover a deleted account?**  
A: Contact support within 30 days. After 30 days, account is permanently deleted.

**Q: Can I change my email?**  
A: Yes, go to Account Settings → Email. You'll need to verify the new email.

**Q: What if I forget my 2FA code?**  
A: Use backup codes (saved during setup) or contact support for identity verification.

**Q: How do I deactivate my account?**  
A: Settings → Account → Deactivate Account. You can reactivate within 90 days.

**Q: Can I have multiple accounts?**  
A: No. One email = one account. Multiple accounts violate terms.

**Q: How long are messages kept?**  
A: Forever, unless you delete. Archived messages still kept.

**Q: What happens if I'm reported?**  
A: Admin investigates within 24 hours. If rules broken, account suspended/banned.

**Q: Can I preview messages before sending?**  
A: Yes. Type message, review, then click Send.

**Q: How do I get verified status?**  
A: Employers: Submit company documents. Trainers: Complete verification process. System: Automatic for active users.

---

**END OF COMMON FEATURES GUIDE**

*This guide covers features used by all user types.*  
*All features described are real and implemented.*  
*Last updated: December 25, 2025*

