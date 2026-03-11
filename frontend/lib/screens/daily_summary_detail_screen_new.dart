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

                // Vitals Summary Section (NEW)
                _buildVitalsSummarySection(summary.vitalsSummary),
                const SizedBox(height: 20),

                // Fall Events Summary Section
                _buildFallEventsSummarySection(summary.fallEventsSummary),
                const SizedBox(height: 20),

                // Hourly Distribution Chart
                _buildHourlyChart(summary),
                const SizedBox(height: 20),
                
                // Vitals Trend Chart (NEW - Combined multi-line)
                if (summary.vitalsSummary != null && summary.vitalsSummary!.hasVitalsData) ...[
                  _buildVitalsTrendChart(summary.vitalsSummary!),
                  const SizedBox(height: 20),
                ],

                // Statistics Grid
                _buildStatisticsGrid(summary),
                const SizedBox(height: 20),
                
                // Vitals Anomalies (NEW)
                if (summary.vitalsSummary != null && 
                    summary.vitalsSummary!.anomalies.isNotEmpty) ...[
                  _buildVitalsAnomaliesSection(summary.vitalsSummary!.anomalies),
                  const SizedBox(height: 20),
                ],

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
                  handleBuiltInTouches: true,
                  touchTooltipData: BarTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final hour = group.x;
                      final hourStr = hour.toString().padLeft(2, '0');
                      return BarTooltipItem(
                        '$hourStr:00\n${rod.toY.toInt()} coughs',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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

  // ==================== VITALS SECTION ====================

  Widget _buildVitalsSummarySection(VitalsSummaryModel? vitalsSummary) {
    if (vitalsSummary == null || !vitalsSummary.hasVitalsData) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.monitor_heart_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No Vitals Recorded',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No vitals data was recorded for this day.\nEnsure your device is properly connected.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.monitor_heart,
                  color: Color(0xFF1E88E5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Vitals Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getVitalsSeverityColor(vitalsSummary.vitalsSeverityScore).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getVitalsSeverityLabel(vitalsSummary.vitalsSeverityScore),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getVitalsSeverityColor(vitalsSummary.vitalsSeverityScore),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Vitals Cards Grid
          _buildVitalsCardsGrid(vitalsSummary),
        ],
      ),
    );
  }

  Widget _buildVitalsCardsGrid(VitalsSummaryModel vitals) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildVitalCard(
                title: 'Heart Rate',
                icon: Icons.favorite,
                color: const Color(0xFFE53935),
                vital: vitals.heartRate,
                unit: 'bpm',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildVitalCard(
                title: 'Temperature',
                icon: Icons.thermostat,
                color: const Color(0xFFFF7043),
                vital: vitals.temperature,
                unit: '°C',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildVitalCard(
          title: 'Respiratory Rate',
          icon: Icons.air,
          color: const Color(0xFF42A5F5),
          vital: vitals.respiratoryRate,
          unit: 'breaths/min',
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildVitalCard({
    required String title,
    required IconData icon,
    required Color color,
    required SingleVitalSummaryModel? vital,
    required String unit,
    bool isFullWidth = false,
  }) {
    if (vital == null || vital.readingCount == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey[400], size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'No data',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    final statusColor = _getVitalStatusColor(vital.status);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  vital.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  vital.average.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildMinMaxLabel('Min', vital.min),
              _buildMinMaxLabel('Max', vital.max),
              Text(
                '${vital.readingCount} readings',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          if (vital.statusMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              vital.statusMessage,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: statusColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMinMaxLabel(String label, double? value) {
    return Text(
      '$label: ${value != null ? value.toStringAsFixed(1) : '--'}',
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey[600],
      ),
    );
  }

  Color _getVitalStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return const Color(0xFF43A047);
      case 'ELEVATED':
      case 'LOW':
        return const Color(0xFFFB8C00);
      case 'HIGH':
      case 'VERY_LOW':
        return const Color(0xFFE53935);
      case 'CRITICAL':
        return const Color(0xFF8E24AA);
      default:
        return const Color(0xFF78909C);
    }
  }

  Color _getVitalsSeverityColor(int score) {
    if (score >= 7) return const Color(0xFFE53935);
    if (score >= 4) return const Color(0xFFFB8C00);
    return const Color(0xFF43A047);
  }

  String _getVitalsSeverityLabel(int score) {
    if (score >= 7) return 'High Risk';
    if (score >= 4) return 'Moderate';
    return 'Normal';
  }

  Widget _buildVitalsTrendChart(VitalsSummaryModel vitalsSummary) {
    final hourlyData = vitalsSummary.hourlyVitals;
    if (hourlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: Color(0xFF8E24AA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Vitals Trend (24h)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildChartLegendItem('Heart Rate', const Color(0xFFE53935)),
              _buildChartLegendItem('Temperature', const Color(0xFFFF7043)),
              _buildChartLegendItem('Respiratory', const Color(0xFF42A5F5)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _buildMultiLineChart(hourlyData),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMultiLineChart(List<VitalsHourlyDataModel> hourlyData) {
    // Normalize values for combined chart display
    // HR: typically 60-100, normalize to 0-100
    // Temp: typically 36-38, normalize to 0-100
    // RR: typically 12-20, normalize to 0-100
    
    List<FlSpot> hrSpots = [];
    List<FlSpot> tempSpots = [];
    List<FlSpot> rrSpots = [];

    for (var data in hourlyData) {
      final hour = data.hour.toDouble();
      
      if (data.avgHeartRate != null) {
        // Normalize HR (40-140 range to 0-100)
        final normalizedHR = ((data.avgHeartRate! - 40) / 100) * 100;
        hrSpots.add(FlSpot(hour, normalizedHR.clamp(0, 100)));
      }
      
      if (data.avgTemperature != null) {
        // Normalize Temp (35-40 range to 0-100)
        final normalizedTemp = ((data.avgTemperature! - 35) / 5) * 100;
        tempSpots.add(FlSpot(hour, normalizedTemp.clamp(0, 100)));
      }
      
      if (data.avgRespiratoryRate != null) {
        // Normalize RR (8-30 range to 0-100)
        final normalizedRR = ((data.avgRespiratoryRate! - 8) / 22) * 100;
        rrSpots.add(FlSpot(hour, normalizedRR.clamp(0, 100)));
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 4,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                if (hour % 4 == 0 && hour <= 24) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 24,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          // Heart Rate Line
          if (hrSpots.isNotEmpty)
            LineChartBarData(
              spots: hrSpots,
              isCurved: true,
              color: const Color(0xFFE53935),
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFFE53935),
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
          // Temperature Line
          if (tempSpots.isNotEmpty)
            LineChartBarData(
              spots: tempSpots,
              isCurved: true,
              color: const Color(0xFFFF7043),
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFFFF7043),
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
          // Respiratory Rate Line
          if (rrSpots.isNotEmpty)
            LineChartBarData(
              spots: rrSpots,
              isCurved: true,
              color: const Color(0xFF42A5F5),
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFF42A5F5),
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchSpotThreshold: 20,
          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                const FlLine(
                  color: Colors.grey,
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: barData.color ?? Colors.blue,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            tooltipMargin: 10,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                String label;
                String value;
                Color lineColor;
                
                if (spot.barIndex == 0) {
                  // Denormalize HR
                  final hr = (spot.y / 100 * 100) + 40;
                  label = 'Heart Rate';
                  value = '${hr.toStringAsFixed(0)} bpm';
                  lineColor = const Color(0xFFE53935);
                } else if (spot.barIndex == 1) {
                  // Denormalize Temp
                  final temp = (spot.y / 100 * 5) + 35;
                  label = 'Temperature';
                  value = '${temp.toStringAsFixed(1)} °C';
                  lineColor = const Color(0xFFFF7043);
                } else {
                  // Denormalize RR
                  final rr = (spot.y / 100 * 22) + 8;
                  label = 'Respiratory';
                  value = '${rr.toStringAsFixed(0)} /min';
                  lineColor = const Color(0xFF42A5F5);
                }
                
                return LineTooltipItem(
                  '$label\n$value',
                  TextStyle(
                    color: lineColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVitalsAnomaliesSection(List<VitalsAnomalyModel>? anomalies) {
    if (anomalies == null || anomalies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber,
                  color: Color(0xFFE53935),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Vitals Alerts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${anomalies.length} alert${anomalies.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE53935),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...anomalies.take(5).map((anomaly) => _buildVitalsAnomalyItem(anomaly)),
          if (anomalies.length > 5)
            Center(
              child: Text(
                '+${anomalies.length - 5} more alerts',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVitalsAnomalyItem(VitalsAnomalyModel anomaly) {
    final severityColor = _getAnomalySeverityColor(anomaly.severity);
    final iconData = _getAnomalyIcon(anomaly.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, color: severityColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        anomaly.condition.isEmpty ? 'Anomaly Detected' : anomaly.condition,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: severityColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        anomaly.severity.isEmpty ? 'INFO' : anomaly.severity,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: severityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  anomaly.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                if (anomaly.value != 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Value: ${anomaly.value.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAnomalySeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'SEVERE':
      case 'CRITICAL':
        return const Color(0xFFD32F2F);
      case 'HIGH':
        return const Color(0xFFE53935);
      case 'MODERATE':
        return const Color(0xFFFB8C00);
      case 'LOW':
        return const Color(0xFFFDD835);
      default:
        return const Color(0xFF78909C);
    }
  }

  IconData _getAnomalyIcon(String type) {
    switch (type.toUpperCase()) {
      case 'HEART_RATE':
        return Icons.favorite;
      case 'TEMPERATURE':
        return Icons.thermostat;
      case 'RESPIRATORY_RATE':
        return Icons.air;
      default:
        return Icons.warning;
    }
  }

  // ==================== FALL EVENTS SECTION ====================

  Widget _buildFallEventsSummarySection(FallEventsSummaryModel? fallSummary) {
    if (fallSummary == null || !fallSummary.hasFallData) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.directions_walk_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No Fall Events',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No fall events were detected for this day.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final riskColor = _getFallRiskColor(fallSummary.fallRiskLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.directions_walk, color: riskColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Fall Events',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  fallSummary.fallRiskLevel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildFallStatCard(
                  'Total Falls',
                  fallSummary.totalFalls.toString(),
                  Icons.arrow_downward,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFallStatCard(
                  'Emergency',
                  fallSummary.emergencyFalls.toString(),
                  Icons.warning_amber_rounded,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFallStatCard(
                  'Max G-Force',
                  '${fallSummary.maxGForce.toStringAsFixed(1)}g',
                  Icons.speed,
                  Colors.purple,
                ),
              ),
            ],
          ),

          // Risk message
          if (fallSummary.fallRiskMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: riskColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: riskColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fallSummary.fallRiskMessage,
                      style: TextStyle(fontSize: 13, color: riskColor),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Individual fall events
          if (fallSummary.fallEvents.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Fall Events Timeline',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            ...fallSummary.fallEvents.map((event) => _buildFallEventTile(event)),
          ],
        ],
      ),
    );
  }

  Widget _buildFallStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFallEventTile(FallEventDetailModel event) {
    final levelColor = _getEmergencyLevelColor(event.emergencyLevel);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: levelColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: levelColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            event.isEmergency ? Icons.warning_amber_rounded : Icons.directions_walk,
            color: levelColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      event.time,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: levelColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        event.emergencyLevel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: levelColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'G-Force: ${event.gForce.toStringAsFixed(1)}g'
                  '${event.bpm != null ? '  •  HR: ${event.bpm!.toStringAsFixed(0)} bpm' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getFallRiskColor(String riskLevel) {
    switch (riskLevel.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFB71C1C);
      case 'HIGH':
        return const Color(0xFFE53935);
      case 'MODERATE':
        return const Color(0xFFFB8C00);
      case 'LOW':
        return const Color(0xFFFDD835);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  Color _getEmergencyLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFB71C1C);
      case 'WARNING':
        return const Color(0xFFFB8C00);
      case 'MONITORING':
        return const Color(0xFF1E88E5);
      default:
        return const Color(0xFF4CAF50);
    }
  }
}
// Force rebuild Wed Feb 18 01:38:26 +0530 2026
