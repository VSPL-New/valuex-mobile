// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_change_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Two-step change of the mobile number or email: enter the new value, then confirm the code
/// sent to it. The current value stays active on the server until the code is confirmed.

@ProviderFor(ContactChangeController)
const contactChangeControllerProvider = ContactChangeControllerFamily._();

/// Two-step change of the mobile number or email: enter the new value, then confirm the code
/// sent to it. The current value stays active on the server until the code is confirmed.
final class ContactChangeControllerProvider
    extends $NotifierProvider<ContactChangeController, ContactChangeState> {
  /// Two-step change of the mobile number or email: enter the new value, then confirm the code
  /// sent to it. The current value stays active on the server until the code is confirmed.
  const ContactChangeControllerProvider._(
      {required ContactChangeControllerFamily super.from, required ContactKind super.argument})
      : super(
          retry: null,
          name: r'contactChangeControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$contactChangeControllerHash();

  @override
  String toString() {
    return r'contactChangeControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ContactChangeController create() => ContactChangeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContactChangeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContactChangeState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ContactChangeControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contactChangeControllerHash() => r'97f0277e6273ff426b602798a98386572556c3f1';

/// Two-step change of the mobile number or email: enter the new value, then confirm the code
/// sent to it. The current value stays active on the server until the code is confirmed.

final class ContactChangeControllerFamily extends $Family
    with
        $ClassFamilyOverride<ContactChangeController, ContactChangeState, ContactChangeState,
            ContactChangeState, ContactKind> {
  const ContactChangeControllerFamily._()
      : super(
          retry: null,
          name: r'contactChangeControllerProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Two-step change of the mobile number or email: enter the new value, then confirm the code
  /// sent to it. The current value stays active on the server until the code is confirmed.

  ContactChangeControllerProvider call(
    ContactKind kind,
  ) =>
      ContactChangeControllerProvider._(argument: kind, from: this);

  @override
  String toString() => r'contactChangeControllerProvider';
}

/// Two-step change of the mobile number or email: enter the new value, then confirm the code
/// sent to it. The current value stays active on the server until the code is confirmed.

abstract class _$ContactChangeController extends $Notifier<ContactChangeState> {
  late final _$args = ref.$arg as ContactKind;
  ContactKind get kind => _$args;

  ContactChangeState build(
    ContactKind kind,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(
      _$args,
    );
    final ref = this.ref as $Ref<ContactChangeState, ContactChangeState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<ContactChangeState, ContactChangeState>, ContactChangeState, Object?, Object?>;
    element.handleValue(ref, created);
  }
}
