import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/presentation/widgets/profile_menu_section.dart';
import '../../domain/app_notification.dart';
import '../notification_presentation.dart';

/// One notification. Unread ones have a tinted background, a bar on the left and a dot, and are
/// announced as "Unread" so the state never depends on colour alone.
class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const NotificationCard({super.key, required this.notification, required this.onTap});

  static const double _bar = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unread = !notification.read;
    final alert = notification.isAlert;
    final time = notificationTimeLabel(context, notification.createdAt);
    final radius = BorderRadius.circular(AppRadius.lg);
    final spoken = [
      if (unread) l10n.notificationUnread,
      notification.title,
      notification.body,
      time,
    ].join('. ');

    return Semantics(
      button: true,
      label: spoken,
      excludeSemantics: true,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: unread
              ? Color.alphaBlend(
                  AppColors.brandPrimary.withValues(alpha: 0.04),
                  AppColors.brandSurface,
                )
              : AppColors.brandSurface,
          borderRadius: radius,
          border: Border.all(color: AppColors.brandBorder),
          boxShadow: profileCardShadow,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: alert
                                ? AppColors.brandError.withValues(alpha: 0.12)
                                : AppColors.brandMuted,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: SizedBox.square(
                            dimension: 40,
                            child: Icon(
                              notificationIcon(notification),
                              size: 20,
                              color: alert ? AppColors.brandError : AppColors.brandLink,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification.title,
                                      style: unread
                                          ? AppTextStyles.cardTitle
                                          : AppTextStyles.cardTitle.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                    ),
                                  ),
                                  if (unread) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    const Padding(
                                      padding: EdgeInsets.only(top: 6),
                                      child: SizedBox.square(
                                        dimension: 8,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: AppColors.brandPrimary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(notification.body, style: AppTextStyles.bodySecondary),
                              const SizedBox(height: AppSpacing.sm),
                              Text(time, style: AppTextStyles.hint),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (unread)
                const Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: _bar,
                  child: ColoredBox(color: AppColors.brandPrimary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
