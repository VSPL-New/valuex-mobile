import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/gradients.dart';

/// The first letters of the first two words of [name], upper-cased; works for any script.
String buyerInitials(String? name) {
  final words = (name ?? '').trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2);
  return words.map((w) => String.fromCharCode(w.runes.first).toUpperCase()).join();
}

/// A 24 px brand circle with the buyer's initials. Decorative: the name is read from the text
/// beside it.
class BuyerInitialsAvatar extends StatelessWidget {
  final String? name;

  const BuyerInitialsAvatar({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: const BoxDecoration(gradient: AppGradients.brand, shape: BoxShape.circle),
        child: Text(
          buyerInitials(name),
          maxLines: 1,
          textScaler: TextScaler.noScaling,
          style: const TextStyle(
            color: AppColors.brandOnPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
