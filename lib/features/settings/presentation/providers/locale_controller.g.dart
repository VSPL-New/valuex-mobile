// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The language the app UI is shown in: the saved choice, otherwise English. The phone's own
/// language is not used.

@ProviderFor(LocaleController)
final localeControllerProvider = LocaleControllerProvider._();

/// The language the app UI is shown in: the saved choice, otherwise English. The phone's own
/// language is not used.
final class LocaleControllerProvider extends $NotifierProvider<LocaleController, Locale> {
  /// The language the app UI is shown in: the saved choice, otherwise English. The phone's own
  /// language is not used.
  LocaleControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'localeControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$localeControllerHash();

  @$internal
  @override
  LocaleController create() => LocaleController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale>(value),
    );
  }
}

String _$localeControllerHash() => r'25928319575326901421df993e96892a32221704';

/// The language the app UI is shown in: the saved choice, otherwise English. The phone's own
/// language is not used.

abstract class _$LocaleController extends $Notifier<Locale> {
  Locale build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Locale, Locale>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<Locale, Locale>, Locale, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// The row chosen on the Language screen or sheet but not saved yet; going back drops it.

@ProviderFor(PendingLanguage)
final pendingLanguageProvider = PendingLanguageProvider._();

/// The row chosen on the Language screen or sheet but not saved yet; going back drops it.
final class PendingLanguageProvider extends $NotifierProvider<PendingLanguage, Locale> {
  /// The row chosen on the Language screen or sheet but not saved yet; going back drops it.
  PendingLanguageProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'pendingLanguageProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pendingLanguageHash();

  @$internal
  @override
  PendingLanguage create() => PendingLanguage();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale>(value),
    );
  }
}

String _$pendingLanguageHash() => r'dd5d8bd1c2dad346d018e7a742a35f372a4e1da7';

/// The row chosen on the Language screen or sheet but not saved yet; going back drops it.

abstract class _$PendingLanguage extends $Notifier<Locale> {
  Locale build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Locale, Locale>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<Locale, Locale>, Locale, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
