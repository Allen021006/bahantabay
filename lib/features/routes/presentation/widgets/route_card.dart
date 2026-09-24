import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/route_status.dart';
import 'status_badge.dart';

class RouteCard extends StatelessWidget {
  const RouteCard({
    super.key,
    required this.routeName,
    required this.startLabel,
    required this.endLabel,
    required this.status,
    required this.onTap,
  });

  final String routeName;
  final String startLabel;
  final String endLabel;
  final RouteStatus? status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: status?.backgroundColor ?? AppColors.mutedText,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$startLabel → $endLabel',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (status == null)
                      Text(
                        'Status not assessed',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (status != null) StatusBadge(status: status!),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right,
                color: AppColors.mutedText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
