import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/utils/app_theme.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/app_chip.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/models/news_model.dart';

/// News Corner - Dynamic plugin for news articles
/// Production-ready: Loads from Firestore 'news' collection
class NewsCornerScreen extends StatefulWidget {
  const NewsCornerScreen({super.key});

  @override
  State<NewsCornerScreen> createState() => _NewsCornerScreenState();
}

class _NewsCornerScreenState extends State<NewsCornerScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _keyword = '';
  int _selectedTabIndex = 0;

  // Error handling helper methods
  Widget _buildErrorCard(String message) {
    final theme = Theme.of(context);
    return AppCard(
      padding: AppDesignSystem.paddingM,
      elevation: 2,
      child: Text(
        message,
        style: theme.textTheme.labelLarge?.copyWith(
          color: Colors.red,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HintsWrapper(
      screenId: 'news_corner',
      child: Scaffold(
        resizeToAvoidBottomInset: true, // Critical for keyboard handling
        appBar: AppAppBar(
          title: 'News Corner',
          variant: AppBarVariant.primary,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchDialog,
            ),
          ],
        ),
        body: DefaultTabController(
          length: 4,
          initialIndex: _selectedTabIndex,
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                onTap: (index) {
                  setState(() => _selectedTabIndex = index);
                },
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Career'),
                  Tab(text: 'Tech'),
                  Tab(text: 'Business'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildNewsList(category: null),
                    _buildNewsList(category: 'Career'),
                    _buildNewsList(category: 'Tech'),
                    _buildNewsList(category: 'Business'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsList({String? category}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('news')
        .where('status', isEqualTo: 'published')
        .where('approvalStatus', isEqualTo: 'approved')
        .orderBy('approvalStatus', descending: false)
        .orderBy('publishedAt', descending: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading news: ${snapshot.error}'),
          );
        }

        final allNews = snapshot.data?.docs
                .map((doc) => NewsModel.fromMap(doc.data(), doc.id))
                .toList() ??
            [];

        final keyword = _keyword.trim().toLowerCase();
        final filtered = keyword.isEmpty
            ? allNews
            : allNews.where((n) {
                final title = n.title.toLowerCase();
                final content = n.content.toLowerCase();
                final author = (n.author ?? '').toLowerCase();
                final cat = n.category.toLowerCase();
                return title.contains(keyword) ||
                    content.contains(keyword) ||
                    author.contains(keyword) ||
                    cat.contains(keyword);
              }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: AppDesignSystem.paddingM,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.newspaper,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                  Text(
                    keyword.isEmpty
                        ? 'No news articles available'
                        : 'No articles match your search',
                    style: AppDesignSystem.titleMedium(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: AppDesignSystem.paddingM,
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final news = filtered[index];
            
            // Validate critical fields
            if (news.title.isEmpty) {
              debugPrint('❌ ERROR: Missing title for news article');
              return _buildErrorCard('News article incomplete (missing title)');
            }
            
            if (news.content.isEmpty) {
              debugPrint('❌ ERROR: Missing content for news article "${news.title}"');
              return _buildErrorCard('News article incomplete (missing content)');
            }
            
            if (news.author == null || news.author!.isEmpty) {
              debugPrint('⚠️ Warning: Missing author for news article "${news.title}"');
            }
            
            return _NewsCard(
              news: news,
              onTap: () => _showNewsDetails(news),
            );
          },
        );
      },
    );
  }

  void _showSearchDialog() {
    final controller = TextEditingController(text: _keyword);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true, // Allow scrolling when keyboard appears
          title: const Text('Search News'),
          content: TextField(
            controller: controller,
            scrollPadding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 80,
            ),
            decoration: const InputDecoration(
              labelText: 'Keyword',
              hintText: 'e.g. career, tech, business',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _keyword = '');
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () {
                setState(() => _keyword = controller.text);
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    ).then((_) => controller.dispose());
  }

  void _showNewsDetails(NewsModel news) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(news.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (news.imageUrl != null) ...[
                  Image.network(
                    news.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                ],
                Text(news.content),
                if (news.sourceUrl != null) ...[
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                  TextButton.icon(
                    onPressed: () {
                      // Open source URL
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Read Full Article'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsModel news;
  final VoidCallback onTap;

  const _NewsCard({
    required this.news,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.only(bottom: AppTheme.spacingM),
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (news.imageUrl != null)
            Image.network(
              news.imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: AppDesignSystem.paddingM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppChip(
                      label: news.category,
                    ),
                    if (news.isFeatured) ...[
                      AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                      Container(
                        padding: AppDesignSystem.paddingSymmetric(
                          horizontal: AppDesignSystem.spaceS,
                          vertical: AppDesignSystem.spaceXS,
                        ),
                        decoration: BoxDecoration(
                          color: botsYellow.withValues(alpha: 0.2),
                          borderRadius: AppDesignSystem.borderRadiusM,
                        ),
                        child: const Text(
                          'Featured',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: botsYellow,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                Text(
                  news.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                Text(
                  news.content.length > 150
                      ? '${news.content.substring(0, 150)}...'
                      : news.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: botsDarkGrey,
                  ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: botsDarkGrey),
                    AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
                    Text(
                      news.author ?? 'Unknown Author',
                      style: const TextStyle(
                        fontSize: 12,
                        color: botsDarkGrey,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.calendar_today, size: 16, color: botsDarkGrey),
                    AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
                    Text(
                      news.publishedAt != null
                          ? '${news.publishedAt!.day}/${news.publishedAt!.month}/${news.publishedAt!.year}'
                          : '—',
                      style: const TextStyle(
                        fontSize: 12,
                        color: botsDarkGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
