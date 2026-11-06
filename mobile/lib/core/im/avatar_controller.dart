import 'dart:typed_data';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/session_controller.dart';
import '../config/app_config_provider.dart';
import 'im_gateway.dart';

part 'avatar_controller.freezed.dart';
part 'avatar_controller.g.dart';

enum AvatarPhase { idle, picking, uploading, saving, saved }

enum AvatarFailure { type, size, pick, upload, save }

class AvatarException implements Exception {
  const AvatarException(this.failure);
  final AvatarFailure failure;
}

@freezed
abstract class AvatarEditState with _$AvatarEditState {
  const factory AvatarEditState({
    @Default(AvatarPhase.idle) AvatarPhase phase,
    double? progress,
    AvatarFailure? failure,
  }) = _AvatarEditState;
  const AvatarEditState._();
  bool get busy => [AvatarPhase.picking, AvatarPhase.uploading, AvatarPhase.saving].contains(phase);
}

String? avatarMime(Uint8List bytes) {
  bool prefix(List<int> magic) =>
      bytes.length >= magic.length &&
      List.generate(magic.length, (i) => bytes[i] == magic[i]).every((v) => v);
  if (prefix([137, 80, 78, 71, 13, 10, 26, 10])) return 'image/png';
  if (prefix([255, 216, 255])) return 'image/jpeg';
  if (bytes.length >= 12 &&
      prefix([82, 73, 70, 70]) &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }
  return null;
}

@riverpod
Future<DRFile?> Function() avatarPicker(Ref ref) {
  final config = ref.watch(appConfigProvider).live;
  return () async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: config.avatarExtensions,
    );
    if (files.isEmpty) return null;
    final file = files.single;
    if ((await file.length() ?? 0) > config.avatarMaxBytes) {
      throw const AvatarException(AvatarFailure.size);
    }
    return DRFile.fromBytes(await file.readAsBytes(), name: file.name);
  };
}

/// Upload through the same public-avatar SDK contract as desktop; publish the
/// profile only after upload completes. An old identity never saves a new one.
@riverpod
class AvatarController extends _$AvatarController {
  DRCancelToken? _cancel;
  int _generation = 0;
  @override
  AvatarEditState build() {
    ref.watch(currentUserProvider.select((user) => user?.id));
    ++_generation;
    _cancel?.cancel();
    ref.onDispose(() => _cancel?.cancel());
    return const AvatarEditState();
  }

  Future<bool> pickAndSave() async {
    if (state.busy) return false;
    final generation = _generation;
    final identity = ref.read(currentUserProvider)?.id;
    bool current() =>
        ref.mounted && _generation == generation && ref.read(currentUserProvider)?.id == identity;
    state = const AvatarEditState(phase: AvatarPhase.picking);
    try {
      final input = await ref.read(avatarPickerProvider)();
      if (!current()) return false;
      if (input == null) {
        state = const AvatarEditState();
        return false;
      }
      final config = ref.read(appConfigProvider).live;
      final bytes = input.bytes;
      final extension = (input.name ?? '').split('.').last.toLowerCase();
      if (bytes != null && bytes.length > config.avatarMaxBytes) {
        throw const AvatarException(AvatarFailure.size);
      }
      final mime = bytes == null ? null : avatarMime(bytes);
      if (mime == null || !config.avatarExtensions.contains(extension)) {
        throw const AvatarException(AvatarFailure.type);
      }
      state = const AvatarEditState(phase: AvatarPhase.uploading);
      final client = await ref.read(imClientProvider.future);
      if (!current()) return false;
      final token = DRCancelToken();
      _cancel = token;
      state = const AvatarEditState(phase: AvatarPhase.uploading);
      final task = client.files.upload(
        DRFile.fromBytes(bytes!, name: input.name!, mimeType: mime),
        purpose: UploadPurpose.userAvatar,
        kind: FileKind.image,
        cancel: token,
        onProgress: (loaded, total) {
          if (current() && state.phase == AvatarPhase.uploading) {
            state = state.copyWith(progress: total > 0 ? (loaded / total).clamp(0, 1) : null);
          }
        },
      );
      final uploaded = await task.result;
      if (!current()) return false;
      state = const AvatarEditState(phase: AvatarPhase.saving);
      await client.users.updateMe(avatarUrl: uploaded.url);
      if (!current()) return false;
      state = const AvatarEditState(phase: AvatarPhase.saved);
      return true;
    } on Object catch (error) {
      if (current()) {
        final failure = error is AvatarException
            ? error.failure
            : switch (state.phase) {
                AvatarPhase.saving => AvatarFailure.save,
                AvatarPhase.uploading => AvatarFailure.upload,
                _ => AvatarFailure.pick,
              };
        state = AvatarEditState(failure: failure);
      }
      return false;
    } finally {
      if (current()) _cancel = null;
    }
  }
}
