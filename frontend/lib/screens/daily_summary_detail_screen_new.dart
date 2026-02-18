import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/daily_summary_detail_model.dart';
import '../repositories/summary_repository.dart';

class DailySummaryDetailScreenNew extends StatefulWidget {
  final DateTime selectedDate;
  final String deviceId;
  final SummaryRepository repository;

  const DailySummaryDetailScreenNew({
    super.key,
    required this.selectedDate,
    required this.deviceId,
    required this.repository,
  });

  @override
  State<DailySummaryDetailScreenNew> createState() => _DailySummaryDetailScreenNewState();
}

class _DailySummaryDetailScreenNewState extends State<DailySummaryDetailScreenNew> {
  late Future<DailySummaryDetailModel> _summaryFuture;

  @override
  void initState() {
    super.initState();
    print('🔍 Repository type: ${widget.repository.runtimeType}'); // DEBUG
    print('📅 Loading summary for: ${widget.selectedDate}');
    _summaryFuture = widget.repository.getDailySummaryDetail(
      widget.deviceId,
      widget.selectedDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FutureBuilder<DailySummaryDetailModel>(
          future: _summaryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFA8E6CF),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading summary',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No data for this date',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.data?.message ?? 'No cough events recorded',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final summary = snapshot.data!;
            return _buildSummaryContent(summary);
          },
        ),
      ),
    );
  }

  Widget _buildSummaryContent(DailySummaryDetailModel summary) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _getFormattedDate(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Stats Card
                _buildMainStatsCard(summary),
                const SizedBox(height: 20),

                // Hourly Distribution Chart
                _buildHourlyChart(summary),
                const SizedBox(height: 20),

                // Statistics Grid
                _buildStatisticsGrid(summary),
                const SizedBox(height: 20),

                // Patterns
                if (summary.patterns.isNotEmpty) ...[
                  _buildPatternsSection(summary.patterns),
                  const SizedBox(height: 20),
                ],

                // Health Insights
                if (summary.insights.isNotEmpty) ...[
                  _buildInsightsSection(summary.insights),
                  const SizedBox(height: 20),
                ],

                // Recommendations
                if (summary.recommendations.isNotEmpty) ...[
                  _buildRecommendationsSection(summary.recommendations),
                  const SizedBox(height: 20),
                ],

                // Comparison
                _buildComparisonCard(summary.comparison),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainStatsCard(DailySummaryDetailModel summary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getSeverityGradient(summary.severityLevel),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${summary.totalCoughs}',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'TOTAL COUGHS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              summary.severityLevel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChart(DailySummaryDetailModel summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hourly Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: summary.hourlyDistribution
                    .map((h) => h.count.toDouble())
                    .reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${group.x}:00\n${rod.toY.toInt()} coughs',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 4 == 0) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: summary.hourlyDistribution.map((hourly) {
                  return BarChartGroupData(
                    x: hourly.hour,
                    barRods: [
                      BarChartRodData(
                        toY: hourly.count.toDouble(),
                        color: hourly.hour == summary.peakHour
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFA8E6CF),
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid(DailySummaryDetailModel summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBF9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow('Coughs/Hour', '${summary.coughFrequency.toStringAsFixed(1)}'),
          _buildStatRow('Avg Confidence', '${summary.avgConfidence.toStringAsFixed(1)}%'),
          _buildStatRow('Avg Volume', '${summary.avgVolume.toStringAsFixed(0)}'),
          _buildStatRow('Night Coughs', '${summary.nightCoughs} (${summary.nightPercentage.toStringAsFixed(1)}%)'),
          _buildStatRow('Day Coughs', '${summary.dayCoughs}'),
          _buildStatRow('Peak Hour', '${summary.peakHour}:00'),
          _buildStatRow('Severity Score', '${summary.severityScore}/100'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternsSection(List<CoughPatternModel> patterns) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detected Patterns',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...patterns.map((pattern) => _buildPatternCard(pattern)),
        ],
      ),
    );
  }

  Widget _buildPatternCard(CoughPatternModel pattern) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBF9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getPatternColor(pattern.type),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getPatternIcon(pattern.type),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pattern.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  pattern.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${pattern.confidence.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(List<HealthInsightModel> insights) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Health Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...insights.map((insight) => _buildInsightCard(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(HealthInsightModel insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getInsightBackgroundColor(insight.severity),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getInsightBorderColor(insight.severity),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getInsightIcon(insight.severity),
                color: _getInsightIconColor(insight.severity),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getInsightIconColor(insight.severity),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  insight.severity,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight.description,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(List<String> recommendations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBF9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommendations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...recommendations.map((rec) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rec,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(DailyComparisonModel comparison) {
    final isIncreasing = comparison.change > 0;
    final isDecreasing = comparison.change < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Compared to Yesterday',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text(
                    'Yesterday',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${comparison.yesterdayCoughs}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Icon(
                isIncreasing
                    ? Icons.arrow_upward
                    : isDecreasing
                        ? Icons.arrow_downward
                        : Icons.remove,
                color: isIncreasing
                    ? Colors.red
                    : isDecreasing
                        ? Colors.green
                        : Colors.grey,
                size: 32,
              ),
              Column(
                children: [
                  const Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isIncreasing ? "+" : ""}${comparison.change}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isIncreasing
                          ? Colors.red
                          : isDecreasing
                              ? Colors.green
                              : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    final monthNames = [
      "", "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    
    String suffix = "th";
    final day = widget.selectedDate.day;
    if (day % 10 == 1 && day != 11) suffix = "st";
    else if (day % 10 == 2 && day != 12) suffix = "nd";
    else if (day % 10 == 3 && day != 13) suffix = "rd";

    return 'Daily Health Summary\n${day}$suffix ${monthNames[widget.selectedDate.month]}, ${widget.selectedDate.year}';
  }

  List<Color> _getSeverityGradient(String level) {
    switch (level.toUpperCase()) {
      case 'GOOD':
      case 'LOW':
        return [const Color(0xFF4CAF50), const Color(0xFF66BB6A)];
      case 'MODERATE':
        return [const Color(0xFFFFA726), const Color(0xFFFFB74D)];
      case 'HIGH':
      case 'SEVERE':
        return [const Color(0xFFEF5350), const Color(0xFFE57373)];
      default:
        return [const Color(0xFF90CAF9), const Color(0xFF64B5F6)];
    }
  }

  IconData _getPatternIcon(String type) {
    switch (type.toUpperCase()) {
      case 'NOCTURNAL':
        return Icons.nightlight;
      case 'CLUSTER':
        return Icons.group_work;
      case 'SPIKE':
        return Icons.trending_up;
      default:
        return Icons.info;
    }
  }

  Color _getPatternColor(String type) {
    switch (type.toUpperCase()) {
      case 'NOCTURNAL':
        return const Color(0xFF5C6BC0);
      case 'CLUSTER':
        return const Color(0xFFFF7043);
      case 'SPIKE':
        return const Color(0xFFEC407A);
      default:
        return const Color(0xFF78909C);
    }
  }

  IconData _getInsightIcon(String severity) {
    switch (severity.toUpperCase()) {
      case 'HIGH':
      case 'SEVERE':
        return Icons.warning;
      case 'MODERATE':
        return Icons.info;
      case 'LOW':
      case 'INFO':
        return Icons.lightbulb;
      default:
        return Icons.info;
    }
  }

  Color _getInsightIconColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'HIGH':
      case 'SEVERE':
        return const Color(0xFFE53935);
      case 'MODERATE':
        return const Color(0xFFFB8C00);
      case 'LOW':
      case 'INFO':
        return const Color(0xFF43A047);
      default:
        return const Color(0xFF1E88E5);
    }
  }

  Color _getInsightBackgroundColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'HIGH':
      case 'SEVERE':
        return const Color(0xFFFFEBEE);
      case 'MODERATE':
        return const Color(0xFFFFF3E0);
      case 'LOW':
      case 'INFO':
        return const Color(0xFFE8F5E9);
      default:
        return const Color(0xFFE3F2FD);
    }
  }

  Color _getInsightBorderColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'HIGH':
      case 'SEVERE':
        return const Color(0xFFFFCDD2);
      case 'MODERATE':
        return const Color(0xFFFFE0B2);
      case 'LOW':
      case 'INFO':
        return const Color(0xFFC8E6C9);
      default:
        return const Color(0xFFBBDEFB);
    }
  }
}
// Force rebuild Wed Feb 18 01:38:26 +0530 2026
