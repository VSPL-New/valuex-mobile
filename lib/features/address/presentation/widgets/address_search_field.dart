import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/address_details.dart';
import '../../domain/address_suggestion.dart';
import '../providers/address_providers.dart';

/// Search-as-you-type address field. Picking a suggestion calls [onSelected] with the place's
/// details; the caller fills its own fields, which stay editable. Manual entry always works: when
/// the search fails the field says so and the caller's fields are still there.
class AddressSearchField extends ConsumerStatefulWidget {
  final ValueChanged<AddressDetails> onSelected;

  const AddressSearchField({super.key, required this.onSelected});

  @override
  ConsumerState<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends ConsumerState<AddressSearchField> {
  final _controller = TextEditingController();
  bool _picking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick(AddressSuggestion suggestion) async {
    if (_picking) return;
    setState(() => _picking = true);
    final details = await ref.read(addressSearchControllerProvider.notifier).select(suggestion);
    if (!mounted) return;
    setState(() => _picking = false);
    if (details == null) return;
    _controller.clear();
    widget.onSelected(details);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final search = ref.watch(addressSearchControllerProvider);
    final showPowered = !ref.watch(appConfigProvider).useMockAddressSearch;
    final showList = search.suggestions.isNotEmpty &&
        (search.status == AddressSearchStatus.results ||
            search.status == AddressSearchStatus.searching);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Text(l10n.addressSearchLabel, style: AppTextStyles.label)),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: l10n.addressSearchLabel,
          textField: true,
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.words,
            onChanged: ref.read(addressSearchControllerProvider.notifier).onQueryChanged,
            style: AppTextStyles.input,
            cursorColor: AppColors.brandPrimary,
            decoration: InputDecoration(
              hintText: l10n.addressSearchHint,
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.brandMutedText),
            ),
          ),
        ),
        if (search.status == AddressSearchStatus.searching && !showList)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  const SizedBox(width: 16, height: 16, child: LoadingIndicator(size: 16)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(l10n.addressSearchSearching, style: AppTextStyles.hint)),
                ],
              ),
            ),
          ),
        if (search.status == AddressSearchStatus.empty)
          _Note(text: l10n.addressSearchNoResults, icon: Icons.info_outline_rounded),
        if (search.status == AddressSearchStatus.unavailable)
          _Note(text: l10n.addressSearchUnavailable, icon: Icons.info_outline_rounded),
        if (showList) ...[
          const SizedBox(height: AppSpacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.brandSurface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.brandControlBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Column(
                children: [
                  for (var i = 0; i < search.suggestions.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: AppColors.brandBorder),
                    _SuggestionRow(
                      suggestion: search.suggestions[i],
                      onTap: () => _pick(search.suggestions[i]),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (showPowered)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(l10n.addressSearchPoweredBy, style: AppTextStyles.caption),
              ),
            ),
        ],
      ],
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Note({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 18, color: AppColors.brandMutedText),
            ),
            const SizedBox(width: AppSpacing.sm - 2),
            Expanded(child: Text(text, style: AppTextStyles.hint)),
          ],
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final AddressSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionRow({required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: suggestion.fullText,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 20, color: AppColors.brandLink),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.primaryText,
                        style: AppTextStyles.cardTitle.copyWith(fontWeight: FontWeight.w500),
                      ),
                      if (suggestion.secondaryText.isNotEmpty)
                        Text(suggestion.secondaryText, style: AppTextStyles.hint),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
