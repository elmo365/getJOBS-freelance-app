import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/utils/app_design_system.dart';

/// System Health Monitoring Dashboard
/// Real-time monitoring of system health metrics and performance indicators
/// Tracks error rates, active users, storage, response times, and query performance
class AdminMonitoringDashboardScreen extends StatefulWidget {
  const AdminMonitoringDashboardScreen({super.key});

  @override
  State<AdminMonitoringDashboardScreen> createState() =>
      _AdminMonitoringDashboardScreenState();
}

class _AdminMonitoringDashboardScreenState
    extends State<AdminMonitoringDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, dynamic> _metrics = {
    'errorRate': 0.0,
    'slowQueries': 0,
    'activeUsers': 0,
    'storageUsage': 0.0,
    'avgResponseTime': 0.0,
    'lastUpdated': DateTime.now(),
  };

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    try {
      // Get error rates from audit logs
      final errorDocs = await _firestore
          .collection('admin_audit_logs')
          .where('type', isEqualTo: 'error')
          .where('timestamp',
              isGreaterThan: Timestamp.fromDate(
                  DateTime.now().subtract(const Duration(hours: 24))))
          .get();

      // Get slow queries from audit logs (>1000ms)
      final slowQueryDocs = await _firestore
          .collection('admin_audit_logs')
          .where('type', isEqualTo: 'performance')
          .where('responseTime', isGreaterThan: 1000)
          .where('timestamp',
              isGreaterThan: Timestamp.fromDate(
                  DateTime.now().subtract(const Duration(hours: 24))))
          .get();

      // Get active users (logged in within last 24 hours)
      final activeUsersDocs = await _firestore
          .collection('users')
          .where('lastActivity',
              isGreaterThan: Timestamp.fromDate(
                  DateTime.now().subtract(const Duration(hours: 24))))
          .get();

      // Calculate average response time (skip missing values instead of using 0)
      double totalResponseTime = 0;
      int responseTimeCount = 0;
      for (var doc in slowQueryDocs.docs) {
        // ignore: unnecessary_cast
        final data = doc.data() as Map<String, dynamic>;
        final responseTime = data['responseTime'] as num?;
        if (responseTime != null) {
          totalResponseTime += responseTime.toDouble();
          responseTimeCount++;
        } else {
          // Skip missing data points instead of including 0
          debugPrint('⚠️ Warning: Missing responseTime for query ${data['queryId']}');
        }
      }

      final avgResponseTime =
          responseTimeCount > 0 ? totalResponseTime / responseTimeCount : 0.0;

      // Calculate error rate (errors per 1000 operations)
      final totalOps = await _getTotalOperations();
      final errorRate = totalOps > 0 ? (errorDocs.size / totalOps) * 1000 : 0.0;

      // Calculate storage usage
      final storageUsage = await _estimateStorageUsage();

      setState(() {
        _metrics['errorRate'] = errorRate;
        _metrics['slowQueries'] = slowQueryDocs.size;
        _metrics['activeUsers'] = activeUsersDocs.size;
        _metrics['storageUsage'] = storageUsage;
        _metrics['avgResponseTime'] = avgResponseTime;
        _metrics['lastUpdated'] = DateTime.now();
      });
    } catch (e) {
      // Error loading metrics, metrics will retain previous values
    }
  }

  Future<int> _getTotalOperations() async {
    try {
      final docs = await _firestore
          .collection('admin_audit_logs')
          .where('timestamp',
              isGreaterThan: Timestamp.fromDate(
                  DateTime.now().subtract(const Duration(hours: 24))))
          .get();
      return docs.size;
    } catch (e) {
      return 0;
    }
  }

  Future<double> _estimateStorageUsage() async {
    try {
      // Estimate based on collections
      final collections = [
        'users',
        'jobs',
        'companies',
        'gigs',
        'tenders',
        'admin_audit_logs'
      ];
      double totalDocs = 0;

      for (final collection in collections) {
        final count = await _firestore.collection(collection).count().get();
        totalDocs += count.count ?? 0;
      }

      // Rough estimate: avg 10KB per document
      return (totalDocs * 10) / 1024; // Convert to MB
    } catch (e) {
      return 0.0;
    }
  }

  Color _getHealthColor(double value, {double redAbove = 50}) {
    if (value > redAbove) return Colors.red;
    if (value > redAbove * 0.6) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'System Monitoring',
        variant: AppBarVariant.primary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadMetrics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(AppDesignSystem.spaceM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Last updated time
              Padding(
                padding: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'System Status',
                      style: AppDesignSystem.screenTitle(context),
                    ),
                    Text(
                      'Updated: ${DateFormat('HH:mm:ss').format(_metrics['lastUpdated'])}',
                      style: AppDesignSystem.labelSmall(context).copyWith(
                        color: AppDesignSystem.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Health Summary Grid
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: AppDesignSystem.spaceM,
                crossAxisSpacing: AppDesignSystem.spaceM,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Error Rate
                  _MetricCard(
                    label: 'Error Rate',
                    value: '${_metrics['errorRate'].toStringAsFixed(2)}',
                    unit: 'per 1k ops',
                    color: _getHealthColor(_metrics['errorRate'] as double,
                        redAbove: 10),
                    icon: Icons.error_outline,
                  ),

                  // Slow Queries
                  _MetricCard(
                    label: 'Slow Queries',
                    value: '${_metrics['slowQueries']}',
                    unit: '> 1000ms',
                    color: _getHealthColor(
                        (_metrics['slowQueries'] as int).toDouble(),
                        redAbove: 50),
                    icon: Icons.speed,
                  ),

                  // Active Users
                  _MetricCard(
                    label: 'Active Users',
                    value: '${_metrics['activeUsers']}',
                    unit: 'last 24h',
                    color: Colors.blue,
                    icon: Icons.people,
                  ),

                  // Storage Usage
                  _MetricCard(
                    label: 'Storage',
                    value:
                        (_metrics['storageUsage'] as double).toStringAsFixed(1),
                    unit: 'MB',
                    color: _getHealthColor(_metrics['storageUsage'] as double,
                        redAbove: 5000),
                    icon: Icons.storage,
                  ),
                ],
              ),

              SizedBox(height: AppDesignSystem.spaceL),

              // Response Time Section
              AppCard(
                variant: SurfaceVariant.standard,
                child: Padding(
                  padding: EdgeInsets.all(AppDesignSystem.spaceM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            color: AppDesignSystem.brandBlue,
                          ),
                          SizedBox(width: AppDesignSystem.spaceS),
                          Text(
                            'Average Response Time',
                            style: AppDesignSystem.sectionHeader(context),
                          ),
                        ],
                      ),
                      SizedBox(height: AppDesignSystem.spaceM),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            (_metrics['avgResponseTime'] as double).toStringAsFixed(0),
                            style: AppDesignSystem.displayLarge(context)
                                .copyWith(
                              color: _getHealthColor(
                                  _metrics['avgResponseTime'] as double,
                                  redAbove: 1000),
                            ),
                          ),
                          Text(
                            'ms',
                            style: AppDesignSystem.bodyMedium(context).copyWith(
                              color: AppDesignSystem.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppDesignSystem.spaceM),
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: AppDesignSystem.borderRadiusS,
                          color: AppDesignSystem.chipBackground,
                        ),
                        child: ClipRRect(
                          borderRadius: AppDesignSystem.borderRadiusS,
                          child: LinearProgressIndicator(
                            value: (_metrics['avgResponseTime'] as double) >
                                    1000
                                ? 1.0
                                : (_metrics['avgResponseTime'] as double) / 1000,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getHealthColor(
                                  _metrics['avgResponseTime'] as double,
                                  redAbove: 1000),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppDesignSystem.spaceM),
                      Text(
                        'Target: < 500ms',
                        style: AppDesignSystem.labelSmall(context).copyWith(
                          color: AppDesignSystem.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: AppDesignSystem.spaceL),

              // Health Checklist
              AppCard(
                variant: SurfaceVariant.standard,
                child: Padding(
                  padding: EdgeInsets.all(AppDesignSystem.spaceM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Checklist',
                        style: AppDesignSystem.sectionHeader(context),
                      ),
                      SizedBox(height: AppDesignSystem.spaceM),
                      _HealthCheckItem(
                        label: 'Error Rate',
                        isHealthy:
                            (_metrics['errorRate'] as double) < 10,
                        detail:
                            '${(_metrics['errorRate'] as double).toStringAsFixed(2)} per 1k operations',
                      ),
                      _HealthCheckItem(
                        label: 'Query Performance',
                        isHealthy: (_metrics['slowQueries'] as int) < 50,
                        detail:
                            '${_metrics['slowQueries']} slow queries (>1000ms)',
                      ),
                      _HealthCheckItem(
                        label: 'Response Time',
                        isHealthy:
                            (_metrics['avgResponseTime'] as double) < 500,
                        detail:
                            '${(_metrics['avgResponseTime'] as double).toStringAsFixed(0)}ms average',
                      ),
                      _HealthCheckItem(
                        label: 'Storage',
                        isHealthy:
                            (_metrics['storageUsage'] as double) < 5000,
                        detail:
                            '${(_metrics['storageUsage'] as double).toStringAsFixed(1)} MB used',
                      ),
                      _HealthCheckItem(
                        label: 'Active Users',
                        isHealthy: true,
                        detail: '${_metrics['activeUsers']} active in last 24h',
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: AppDesignSystem.spaceL),

              // System Notes
              AppCard(
                variant: SurfaceVariant.flat,
                child: Padding(
                  padding: EdgeInsets.all(AppDesignSystem.spaceM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monitoring Info',
                        style: AppDesignSystem.labelMedium(context),
                      ),
                      SizedBox(height: AppDesignSystem.spaceM),
                      Text(
                        '• Error Rate: Errors per 1000 operations in last 24 hours\n'
                        '• Slow Queries: Number of operations exceeding 1000ms threshold\n'
                        '• Active Users: Users with activity in last 24 hours\n'
                        '• Storage: Estimated usage based on document count\n'
                        '• Response Time: Average latency of all operations',
                        style: AppDesignSystem.bodySmall(context).copyWith(
                          color: AppDesignSystem.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: SurfaceVariant.standard,
      child: Padding(
        padding: EdgeInsets.all(AppDesignSystem.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppDesignSystem.labelMedium(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ],
            ),
            SizedBox(height: AppDesignSystem.spaceS),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppDesignSystem.displayMedium(context).copyWith(
                    color: color,
                  ),
                ),
                Text(
                  unit,
                  style: AppDesignSystem.labelSmall(context).copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthCheckItem extends StatelessWidget {
  final String label;
  final bool isHealthy;
  final String detail;

  const _HealthCheckItem({
    required this.label,
    required this.isHealthy,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppDesignSystem.spaceS),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.check_circle : Icons.warning,
            color: isHealthy ? Colors.green : Colors.orange,
            size: 20,
          ),
          SizedBox(width: AppDesignSystem.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppDesignSystem.labelMedium(context),
                ),
                Text(
                  detail,
                  style: AppDesignSystem.labelSmall(context).copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
