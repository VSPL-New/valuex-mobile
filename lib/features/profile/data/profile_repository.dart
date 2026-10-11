import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/provider_retry.dart';
import '../../auth/data/models/auth_models.dart';
import '../../auth/domain/entities/user_profile.dart';

class ProfileAvatarCatalog {
  final List<String> ids;
  final String defaultId;

  const ProfileAvatarCatalog({required this.ids, required this.defaultId});

  factory ProfileAvatarCatalog.fromJson(Object? json) {
    final map = json as Map<String, dynamic>;
    return ProfileAvatarCatalog(
      ids: List<String>.from(map['avatarIds'] as List),
      defaultId: map['defaultAvatarId'] as String,
    );
  }
}

class ProfileRepository {
  final ApiClient client;

  ProfileRepository(this.client);

  Future<UserProfile> fetch() async =>
      (await client.get(ApiConstants.currentUser, parse: UserProfileModel.fromJson)).toEntity();

  Future<UserProfile> update({String? displayName, String? city}) async {
    final model = await client.patch(
      ApiConstants.currentUser,
      data: {
        if (displayName != null) 'displayName': displayName,
        if (city != null) 'city': city,
      },
      parse: UserProfileModel.fromJson,
    );
    return model.toEntity();
  }

  Future<ProfileAvatarCatalog> avatars() =>
      client.get('/avatars', parse: ProfileAvatarCatalog.fromJson);

  Future<UserProfile> selectAvatar(String id) async => (await client.put(
        '${ApiConstants.currentUser}/avatar',
        data: {'avatarId': id},
        parse: UserProfileModel.fromJson,
      ))
          .toEntity();
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);

final userProfileProvider = FutureProvider.autoDispose<UserProfile>(
  (ref) => ref.watch(profileRepositoryProvider).fetch(),
  retry: noAutoRetry,
);
