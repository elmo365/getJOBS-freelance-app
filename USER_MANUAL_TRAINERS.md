# Trainers Complete Guide

A comprehensive guide for trainers using the Bots Jobs Connect to teach courses and conduct live training sessions.

---

## Table of Contents

1. [Getting Started as a Trainer](#getting-started-as-a-trainer)
2. [Dashboard & Overview](#dashboard--overview)
3. [Creating & Managing Courses](#creating--managing-courses)
4. [Live Sessions](#live-sessions)
5. [Student Management](#student-management)
6. [Earnings & Payments](#earnings--payments)
7. [Ratings & Reviews](#ratings--reviews)
8. [Best Practices](#best-practices)

---

## Getting Started as a Trainer

### Account Setup

**Step 1: Create Account**
1. Open Bots Jobs Connect
2. Tap **"Sign Up"**
3. Select **"Trainer"** as account type
4. Fill in:
   - Full Name
   - Email
   - Password
   - Phone Number
   - Bio (about your training experience)

**Step 2: Complete Profile**
1. Add professional photo
2. Write detailed bio highlighting your expertise
3. Add qualifications/certifications
4. Add social links (LinkedIn, portfolio, etc.)
5. Set your hourly rate for sessions

**Step 3: Verify**
1. Check email for verification link
2. Click link to verify
3. Return to app
4. Profile is now active

### Profile Optimization

Your trainer profile is key to attracting students:

**Essential Information**:
- Professional photo (headshot)
- Detailed bio (150-300 words)
- Areas of expertise
- Years of experience
- Qualifications/degrees
- Languages spoken
- Teaching style

**Recommended Additions**:
- Portfolio of past work/courses
- Student testimonials
- YouTube channel or teaching videos
- GitHub profile (for technical trainers)
- Personal website
- Certification details

**Example Bio**:
"Senior Flutter trainer with 8+ years in mobile app development. Specializing in Dart, Firebase, and UI/UX. I've trained 1000+ students with 95% satisfaction rate. Certified Google Flutter Developer. Available for live sessions and course creation."

---

## Dashboard & Overview

### Trainer Home Screen

The trainer dashboard shows key metrics:

**Statistics Section**:
- **Total Courses**: Number of courses you've created
- **Total Students**: Cumulative enrolled students
- **Average Rating**: Your average rating from students
- **Upcoming Sessions**: Count of scheduled live sessions

**Recent Courses**:
- Shows 3-5 most recent courses
- Displays enrollment count for each
- Shows course status

**Upcoming Live Sessions**:
- Next scheduled sessions
- Date, time, and student count
- Quick action buttons

### Dashboard Code Reference

File: [lib/screens/trainers/trainers_home.dart](lib/screens/trainers/trainers_home.dart)

```dart
// Key metrics loaded from Firestore
Future<void> _loadDashboard() async {
  // Get all courses for this trainer
  final coursesSnap = await _firestore
      .collection('courses')
      .where('trainerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .get();

  // Calculate total students and average rating
  int studentsTotal = 0;
  double ratingSum = 0;
  int ratingCount = 0;

  final courses = coursesSnap.docs.map((d) {
    final data = d.data();
    
    // Add to student count
    final enrolled = data['enrolledCount'];
    if (enrolled is int) studentsTotal += enrolled;
    
    // Add to rating calculation
    final rating = data['ratingAvg'];
    if (rating is num) {
      ratingSum += rating.toDouble();
      ratingCount += 1;
    }

    return {
      'id': d.id,
      'title': data['title'],
      'students': data['enrolledCount'] ?? 0,
      'createdAt': data['createdAt'],
      'status': data['status'],
    };
  }).toList();

  // Get upcoming live sessions
  final sessionsSnap = await _firestore
      .collection('live_sessions')
      .where('trainerId', isEqualTo: uid)
      .where('scheduledAt', isGreaterThan: now)
      .orderBy('scheduledAt')
      .limit(5)
      .get();
}
```

---

## Creating & Managing Courses

### Course Structure

**Course Components**:
1. **Basic Info**: Title, description, category
2. **Content**: Lessons, modules, assignments
3. **Requirements**: Prerequisites, skills needed
4. **Pricing**: Course fee (if applicable)
5. **Media**: Course thumbnail, promotional images
6. **Status**: Draft → Pending → Approved → Published

### Creating a Course

**Step 1: Start New Course**
1. Go to **Courses** screen
2. Tap **"+"** icon (top right)
3. Or click **"Create New Course"** button

**Step 2: Fill Basic Information**

```dart
// Course creation dialog
showDialog(
  context: context,
  builder: (context) {
    return AlertDialog(
      title: const Text('Create New Course'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            StandardInput(
              controller: titleController,
              label: 'Title',
              hint: 'e.g. Flutter Fundamentals',
              prefixIcon: Icons.video_library,
            ),
            StandardInput(
              controller: descriptionController,
              label: 'Description',
              hint: 'What will students learn?',
              prefixIcon: Icons.description,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  },
);
```

Enter:
- **Title**: Clear, specific course title
  - Good: "Flutter App Development for Beginners"
  - Bad: "Mobile Development"
- **Description**: What students will learn (100-500 words)
  - Learning outcomes
  - Topics covered
  - Who should enroll

**Step 3: Add Course Details**
1. **Category**: Select from list
2. **Level**: Beginner, Intermediate, Advanced
3. **Duration**: Estimated completion time
4. **Price**: Course fee (₱0 for free courses)
5. **Thumbnail**: Upload course image (500x300 recommended)

**Step 4: Add Course Content**
1. Create modules/sections
2. Add lessons to each section
3. Add resources (PDFs, links, files)
4. Add assignments or quizzes

**Step 5: Submit for Approval**
1. Review all information
2. Click **"Submit Course"**
3. Status changes to "Pending"
4. Admin will review within 24-48 hours
5. You'll get approval/rejection email

### Course Status Flow

```
Draft → Pending Approval → Approved → Published → Archived
   ↓           ↓              ↓          ↓          ↓
 Editing    Admin Review   Live &    Students    No longer
            In Progress   Accepting   Enrolling    Available
                          Students
```

### Managing Your Courses

**Courses Screen Layout**:

**Tab 1: Published Courses**
- Courses approved and live
- Students can enroll
- Show enrollment count
- Show ratings
- Tap to view details

**Tab 2: Drafts**
- Courses pending approval
- Still being edited
- Can be modified
- Can be deleted before submission

**Actions on Course Card**:
- **Tap Card**: View course details
- **Swipe Left**: Delete (draft only) or Archive
- **Edit Button**: Modify course content
- **View Analytics**: See enrollment, reviews, etc.

### Editing a Published Course

**Can Edit**:
- ✅ Description
- ✅ Content (add/remove lessons)
- ✅ Pricing
- ✅ Requirements
- ❌ Title (requires reapproval)
- ❌ Category (requires reapproval)

**How to Edit**:
1. Open published course
2. Tap **"Edit"** button
3. Modify content
4. Tap **"Save"**
5. Changes take effect immediately

### Deleting a Course

**For Drafts** (Pending Approval):
1. Swipe left on course
2. Tap **"Delete"**
3. Confirm deletion

**For Published Courses**:
1. Tap **"More Options"** (...)
2. Select **"Archive Course"**
3. Course no longer visible to students
4. Can be restored later

---

## Live Sessions

### Scheduling Live Sessions

Live sessions let you teach directly to students.

**Step 1: Create Session**
1. Go to **Live Sessions** screen
2. Tap **"Schedule New Session"**
3. Fill in details:
   - **Title**: Session topic
   - **Description**: What you'll cover
   - **Date & Time**: When session occurs
   - **Duration**: How long (e.g., 1 hour)
   - **Max Capacity**: How many students
   - **Associated Course** (optional)

**Step 2: Set Session Details**

```dart
// Live session creation
_showCreateSessionDialog() {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime selectedDateTime = DateTime.now();
  
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Schedule Live Session'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              // Session title
              StandardInput(
                controller: titleController,
                label: 'Session Title',
                hint: 'e.g., Building Your First Flutter App',
              ),
              // Session description
              StandardInput(
                controller: descriptionController,
                label: 'What will you cover?',
                hint: 'Brief overview of session content',
                maxLines: 3,
              ),
              // Date and time picker
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date & Time'),
                        ElevatedButton(
                          onPressed: () => _selectDateTime(),
                          child: Text(
                            DateFormat('MMM dd, yyyy HH:mm')
                                .format(selectedDateTime)
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Duration
              StandardInput(
                controller: durationController,
                label: 'Duration (minutes)',
                hint: 'e.g., 60',
                keyboardType: TextInputType.number,
              ),
              // Max students
              StandardInput(
                controller: capacityController,
                label: 'Max Students',
                hint: 'e.g., 30',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          StandardButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          StandardButton(
            label: 'Schedule Session',
            onPressed: _createSession,
          ),
        ],
      );
    },
  );
}
```

**Step 3: Confirm and Publish**
1. Review all details
2. Click **"Schedule Session"**
3. Session is now scheduled
4. Students can enroll
5. Notification sent to interested students

### Running a Live Session

**Before Session** (30 minutes before):
1. Open scheduled session
2. Tap **"Join Session"**
3. Allow camera/microphone access
4. Test your audio and video
5. Check screen sharing (if needed)

**During Session**:
- All enrolled students will see you
- Can see student list
- Can mute/unmute students
- Can end session anytime
- Session is recorded (optional)

**After Session**:
- Recording is available for students
- Session rating opened for feedback
- Students can ask questions in chat
- Can download attendance report

### Session Types

**Live Q&A**:
- Answer student questions
- Quick technical guidance
- Short format (15-30 min)
- Usually free

**Tutorial Session**:
- Teach specific topic
- Step-by-step instruction
- Medium format (45-90 min)
- May be free or paid

**Workshop**:
- Hands-on project work
- Full course structure
- Long format (2-4 hours)
- Usually paid

**Office Hours**:
- One-on-one or small groups
- Student-directed
- Flexible duration
- May be free or paid

---

## Student Management

### Viewing Your Students

**Access Student List**:
1. Go to any course
2. Tap **"Students"** tab
3. See all enrolled students

**Student List Shows**:
- Student name and photo
- Enrollment date
- Completion percentage
- Last active date
- Rating given (if any)
- Assignment scores

### Student Engagement

**Track Progress**:
1. Tap on student name
2. View:
   - Lessons completed
   - Assignments submitted
   - Videos watched
   - Time spent
   - Quiz scores

**Send Messages**:
1. From student profile
2. Tap **"Message"** button
3. Send personalized message
4. Student receives notification

**Provide Feedback**:
1. View student's assignments
2. Add comments/grades
3. Provide constructive feedback
4. Student notified of update

### Handling Issues

**Student Not Engaging**:
1. Send personalized message
2. Offer help/support
3. Share resources
4. Ask about blockers

**Cheating/Integrity**:
1. Document evidence
2. Contact student first
3. If serious, report to admin
4. Admin handles investigation

**Student Disputes/Complaints**:
1. Try to resolve directly
2. Offer refund if reasonable
3. If unresolved, escalate to admin
4. Admin mediates

---

## Earnings & Payments

### How You Earn

**Revenue Sources**:
1. **Course Enrollment**: Students pay to enroll
2. **Live Session Fees**: If you charge for sessions
3. **Assignments/Certifications**: Issuing certificates

**Commission Structure**:
- Platform takes commission (typically 20-30%)
- You receive balance in wallet
- Minimum withdrawal: ₱500

### Earnings Dashboard

**View Earnings**:
1. Go to **Profile** → **Wallet/Payments**
2. See:
   - Total earned (all time)
   - Current balance
   - Pending amount
   - Transactions history

**Earnings Breakdown**:
- By course
- By time period
- By student
- By activity type

### Withdrawing Money

**Process**:
1. Go to **Wallet**
2. Tap **"Withdraw"**
3. Enter amount (minimum ₱500)
4. Select bank account
5. Review details
6. Tap **"Confirm Withdrawal"**

**Processing**:
- Usually 1-3 business days
- Bank dependent
- May have small fee
- Check status in history

### Payment Records

**Invoice Generation**:
- Can download invoices
- Needed for taxes
- Shows all earnings
- Monthly or custom period

**Tax Documentation**:
- Keep records for tax purposes
- Report income to BIR
- Get necessary documentation from app
- Consult accountant for guidance

---

## Ratings & Reviews

### Student Ratings

**How Ratings Work**:
- Students can rate course 1-5 stars
- Can also leave written review
- Ratings visible on your profile
- Average rating calculated automatically

**Rating Scale**:
- ⭐ 5 stars: Excellent instructor
- ⭐⭐ 4 stars: Very good
- ⭐⭐⭐ 3 stars: Good
- ⭐⭐⭐⭐ 2 stars: Needs improvement
- ⭐⭐⭐⭐⭐ 1 star: Poor quality

### Managing Reviews

**View Reviews**:
1. Go to course details
2. Scroll to reviews section
3. See all student feedback
4. Filter by rating
5. Sort by date/rating

**Respond to Reviews**:
1. Find the review
2. Tap **"Reply"**
3. Write professional response
4. Address concerns
5. Thank for feedback

**Example Response**:
"Thank you for the feedback! I'm sorry the course didn't fully meet your expectations. I'd be happy to help clarify any topics. Please feel free to message me. 👍"

### Improving Your Rating

**Tips**:
- ✅ Clear explanations
- ✅ Responsive to questions
- ✅ Regular course updates
- ✅ Engaging content
- ✅ Provide excellent support
- ✅ Update based on feedback
- ✅ Be professional always
- ✅ Address negative feedback constructively

---

## Best Practices

### Course Design

**Structure Effectively**:
1. Divide into logical modules
2. Start with basics
3. Progress to advanced
4. Include real-world examples
5. Have clear learning objectives
6. Break content into digestible lessons
7. Include exercises/practice
8. End with capstone project

**Quality Content**:
- ✅ Clear audio (use good microphone)
- ✅ Good video quality
- ✅ Professional presentation
- ✅ Consistent branding
- ✅ Regular updates
- ✅ Current material
- ✅ Engaging style
- ✅ Interactive components

**Lesson Format**:
1. Introduction (2-3 minutes)
2. Learning objectives
3. Main content (10-20 minutes)
4. Demonstrations (live coding, walkthroughs)
5. Exercises (hands-on practice)
6. Summary (recap key points)
7. Resources (additional materials)

### Student Engagement

**Keep Students Engaged**:
- ✅ Respond to messages within 24 hours
- ✅ Grade assignments promptly (within 3-5 days)
- ✅ Provide constructive feedback
- ✅ Use discussion forums
- ✅ Host Q&A sessions regularly
- ✅ Create community among students
- ✅ Recognize achievements
- ✅ Share additional resources

**Communication Tips**:
- Be professional but friendly
- Be responsive and helpful
- Celebrate student successes
- Encourage questions
- Admit when you don't know
- Provide specific feedback
- Be patient with beginners
- Follow up on concerns

### Pricing Strategy

**Free vs Paid**:
- **Free**: Build audience, get reviews, establish authority
- **Paid**: Generate income, attract serious students

**Pricing Guidelines**:
- Research competitor pricing
- Consider course depth and length
- Factor in your expertise level
- Start lower, increase with ratings
- Offer discounts for bundles
- Have occasional promotions

**Example Pricing**:
- Beginner course: ₱500-₱1,500
- Intermediate: ₱1,500-₱3,500
- Advanced: ₱3,500-₱8,000
- Bundle (3+ courses): 20-30% discount

### Marketing Your Courses

**Promotion Strategies**:
1. **Profile Optimization**: Complete, professional profile
2. **Social Media**: Share course updates and tips
3. **Testimonials**: Showcase student success
4. **Free Content**: Share sample lessons
5. **Discounts**: Limited-time promotions
6. **Referrals**: Reward student referrals
7. **Collaborations**: Partner with other trainers
8. **Content Marketing**: Blog posts, YouTube

### Technical Requirements

**Your Setup**:
- Good internet connection (5+ Mbps)
- Quality microphone (USB or headset)
- Quality camera/webcam
- Good lighting
- Quiet room
- Updated software/OS
- Backup internet option
- Recording capability

**Student Requirements**:
- Internet connection
- Browser (Chrome, Firefox, Safari)
- Speakers or headphones
- (Camera optional for most sessions)

---

## Troubleshooting

### Course Not Getting Approved

**Problem**: Stuck in "Pending" status

**Possible Causes**:
- Incomplete information
- Inappropriate content
- Poor quality description
- Missing required fields
- Similar course already exists

**Solutions**:
1. Wait 24-48 hours (normal review time)
2. Check email for rejection reason
3. Update course based on feedback
4. Resubmit
5. Contact admin if no response

### Live Session Issues

**Problem**: Can't connect to session

**Solutions**:
1. Check internet connection
2. Allow camera/microphone permissions
3. Refresh browser
4. Try different browser
5. Restart app
6. Update app to latest version

**Problem**: Audio/Video problems

**Solutions**:
1. Check microphone works
2. Check camera works
3. Test in Settings first
4. Reduce video quality
5. Close other apps
6. Check lighting
7. Move closer to router

### Students Not Enrolling

**Problem**: Course has zero/few enrollments

**Possible Reasons**:
- Poor course description
- Low or new trainer rating
- High price
- Course not discoverable
- Wrong category

**Solutions**:
1. Improve course description
2. Add course thumbnail
3. Get initial reviews (offer discount)
4. Optimize course title (keywords)
5. Ask enrolled students to rate
6. Promote on social media
7. Reduce price temporarily

---

## Support & Resources

### Help & Support

**In-App Help**:
1. Settings → Help & Support
2. Browse FAQ
3. Watch tutorial videos

**Contact Support**:
- Email: support@getjobs.com
- Include course/session ID
- Describe issue clearly
- Attach screenshots

**Community Forum**:
- Connect with other trainers
- Share tips and experiences
- Get peer support
- Access shared resources

### Trainer Resources

**Available Resources**:
- Course template examples
- Video editing guides
- Live streaming tips
- Student engagement ideas
- Pricing guides
- Marketing templates
- Technical setup guides

---

## Conclusion

The getJOBS Trainer platform empowers you to reach and educate students worldwide. Focus on quality content, excellent student service, and continuous improvement. Good luck with your teaching journey! 🎓

---

*Last Updated: 2024*
*Platform: getJOBS Freelance App*
