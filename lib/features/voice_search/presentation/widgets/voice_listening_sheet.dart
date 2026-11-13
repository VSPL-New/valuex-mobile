import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/voice_error.dart';
import '../../domain/voice_language.dart';
import '../providers/voice_search_controller.dart';
import 'voice_notice_sheet.dart';

const String voiceTypeInsteadResult = '__type_instead__';

Future<String?> showVoiceListeningSheet(BuildContext context) async => showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const VoiceListeningSheet(),
    );

class VoiceListeningSheet extends ConsumerStatefulWidget {
  const VoiceListeningSheet({super.key});

  @override
  ConsumerState<VoiceListeningSheet> createState() => _VoiceListeningSheetState();
}

class _VoiceListeningSheetState extends ConsumerState<VoiceListeningSheet> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(voiceSearchControllerProvider.notifier);
    final state = ref.watch(voiceSearchControllerProvider);
    ref.listen(voiceSearchControllerProvider, (previous, next) {
      if (next.phase == VoiceSearchPhase.listening &&
          previous?.phase != VoiceSearchPhase.listening) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          l10n.voiceListening,
          Directionality.of(context),
        );
      }
      if (next.phase == VoiceSearchPhase.done && next.result != null) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          next.result!,
          Directionality.of(context),
        );
        Navigator.of(context).pop(next.result);
      }
    });
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          controller.start(showNotice: () => showVoiceNoticeSheet(context));
        }
      });
    }

    return SingleChildScrollView(
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.voicePanelTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Semantics(
                liveRegion: true,
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 350),
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    state.phase == VoiceSearchPhase.listening
                        ? Icons.mic_rounded
                        : Icons.mic_none_rounded,
                    size: 38,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  switch (state.phase) {
                    VoiceSearchPhase.starting => l10n.voiceStarting,
                    VoiceSearchPhase.listening || VoiceSearchPhase.finishing => l10n.voiceListening,
                    _ => '',
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.partialText.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 112),
                child: SingleChildScrollView(
                  child: Text(
                    state.partialText,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                _languageChip(l10n.voiceEnglish, VoiceLanguage.english, state.language, controller),
                _languageChip(l10n.voiceHindi, VoiceLanguage.hindi, state.language, controller),
              ],
            ),
            if (state.error case final error?) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_errorText(l10n, error), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              if (error == VoiceError.permissionBlocked)
                AppButton(
                    label: l10n.voiceOpenSettings, onPressed: () => controller.openSettings()),
              if (error == VoiceError.languageUnavailable)
                AppButton(
                  label: l10n.voiceSwitchLanguage,
                  onPressed: () => controller.switchLanguage(
                    state.language == VoiceLanguage.english
                        ? VoiceLanguage.hindi
                        : VoiceLanguage.english,
                  ),
                ),
              if (error == VoiceError.unavailable || error == VoiceError.networkRequired)
                TextButton(
                  onPressed: () => Navigator.pop(context, voiceTypeInsteadResult),
                  child: Text(l10n.voiceTypeInstead),
                ),
              if (error != VoiceError.permissionBlocked && error != VoiceError.languageUnavailable)
                TextButton(
                  onPressed: () => controller.start(),
                  child: Text(l10n.voiceTryAgain),
                ),
            ],
            if (state.phase == VoiceSearchPhase.starting ||
                state.phase == VoiceSearchPhase.listening ||
                state.phase == VoiceSearchPhase.finishing) ...[
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l10n.voiceStop,
                isLoading: state.phase != VoiceSearchPhase.listening,
                onPressed: controller.stop,
              ),
            ],
            TextButton(
              onPressed: () => controller.cancel().then((_) {
                if (context.mounted) Navigator.pop(context);
              }),
              child: Text(l10n.voiceCancel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageChip(
    String label,
    VoiceLanguage language,
    VoiceLanguage selected,
    VoiceSearchController controller,
  ) =>
      ChoiceChip(
        label: Text(label),
        selected: language == selected,
        onSelected: language == selected ? null : (_) => controller.switchLanguage(language),
      );

  String _errorText(AppLocalizations l10n, VoiceError error) => switch (error) {
        VoiceError.permissionDenied => l10n.voicePermissionDenied,
        VoiceError.permissionBlocked => l10n.voicePermissionBlocked,
        VoiceError.unavailable => l10n.voiceUnavailable,
        VoiceError.languageUnavailable => l10n.voiceLanguageUnavailable,
        VoiceError.noSpeech => l10n.voiceNoSpeech,
        VoiceError.networkRequired => l10n.voiceNetworkRequired,
        VoiceError.busy => l10n.voiceBusy,
      };
}
