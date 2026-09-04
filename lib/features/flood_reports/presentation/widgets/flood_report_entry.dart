import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/road_status.dart';

class FloodReportEntry extends StatelessWidget {
  const FloodReportEntry({
    super.key,
    required this.location,
    required this.floodDepth,
    required this.roadStatus,
    required this.createdAt,
    this.onTap,
  });

  final String location;
  final String floodDepth;
  final RoadStatus roadStatus;
  final DateTime createdAt;
  final VoidCallback? onTap;

  String get _createdAtLabel {
    final age = DateTime.now().difference(createdAt);
    if (age.inMinutes < 1) return 'Just now';
    if (age.inMinutes < 60) return '${age.inMinutes} min ago';
    if (age.inHours < 24) return '${age.inHours} hr ago';
    return '${age.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '$floodDepth • '),
                          TextSpan(
                            text: roadStatus.label,
                            style: TextStyle(color: roadStatus.color),
                          ),
                        ],
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                _createdAtLabel,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
