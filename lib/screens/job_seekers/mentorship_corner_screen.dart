import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class MentorshipCornerScreen extends StatefulWidget {
  const MentorshipCornerScreen({super.key});

  @override
  State<MentorshipCornerScreen> createState() => _MentorshipCornerScreenState();
}

class _MentorshipCornerScreenState extends State<MentorshipCornerScreen> {
  @override
  Widget build(BuildContext context) {
    return HintsWrapper(
      screenId: 'mentorship_corner',
      child: Scaffold(
      appBar: AppAppBar(
        title: 'Mentorship Corner',
        variant: AppBarVariant.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search mentors
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Find Mentors'),
                Tab(text: 'My Mentorships'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildFindMentorsTab(),
                  _buildMyMentorshipsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildFindMentorsTab() {
    return ListView(
      padding: AppDesignSystem.paddingM,
      children: [
        _MentorCard(
          name: 'Dr. Sarah Johnson',
          title: 'Senior Software Engineer',
          company: 'Tech Corp',
          specialization: 'Career Development',
          rating: 4.8,
          students: 150,
          onTap: () {
            // View mentor profile
          },
        ),
        _MentorCard(
          name: 'Michael Chen',
          title: 'Product Manager',
          company: 'StartupXYZ',
          specialization: 'Product Management',
          rating: 4.9,
          students: 200,
          onTap: () {
            // View mentor profile
          },
        ),
        _MentorCard(
          name: 'Emily Rodriguez',
          title: 'UX Designer',
          company: 'Design Studio',
          specialization: 'UI/UX Design',
          rating: 4.7,
          students: 120,
          onTap: () {
            // View mentor profile
          },
        ),
      ],
    );
  }

  Widget _buildMyMentorshipsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: botsDarkGrey,
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          const Text(
            'No active mentorships',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          const Text(
            'Connect with a mentor to get started',
            style: TextStyle(color: botsDarkGrey),
          ),
        ],
      ),
    );
  }
}

class _MentorCard extends StatelessWidget {
  final String name;
  final String title;
  final String company;
  final String specialization;
  final double rating;
  final int students;
  final VoidCallback onTap;

  const _MentorCard({
    required this.name,
    required this.title,
    required this.company,
    required this.specialization,
    required this.rating,
    required this.students,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppDesignSystem.paddingM,
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: botsBlue.withValues(alpha: 0.1),
                child: Text(
                  name[0],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: botsBlue,
                  ),
                ),
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                    Text(
                      '$title at $company',
                      style: const TextStyle(
                        color: botsDarkGrey,
                      ),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                    Chip(
                      label: Text(specialization),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                    Row(
                      children: [
                        Icon(Icons.star, color: botsYellow, size: 16),
                        AppDesignSystem.horizontalSpace(
                            AppDesignSystem.spaceXS),
                        Text(
                          rating.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                        Icon(Icons.people, color: botsDarkGrey, size: 16),
                        AppDesignSystem.horizontalSpace(
                            AppDesignSystem.spaceXS),
                        Text(
                          '$students students',
                          style: const TextStyle(
                            color: botsDarkGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
