// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messaging_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(imVideoPlayer)
final imVideoPlayerProvider = ImVideoPlayerFamily._();

final class ImVideoPlayerProvider
    extends
        $FunctionalProvider<
          AsyncValue<ImVideoSession>,
          ImVideoSession,
          FutureOr<ImVideoSession>
        >
    with $FutureModifier<ImVideoSession>, $FutureProvider<ImVideoSession> {
  ImVideoPlayerProvider._({
    required ImVideoPlayerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'imVideoPlayerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$imVideoPlayerHash();

  @override
  String toString() {
    return r'imVideoPlayerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ImVideoSession> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ImVideoSession> create(Ref ref) {
    final argument = this.argument as String;
    return imVideoPlayer(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ImVideoPlayerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$imVideoPlayerHash() => r'30e6b81942694e167f84dda43a98cdadbefc5085';

final class ImVideoPlayerFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ImVideoSession>, String> {
  ImVideoPlayerFamily._()
    : super(
        retry: null,
        name: r'imVideoPlayerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ImVideoPlayerProvider call(String url) =>
      ImVideoPlayerProvider._(argument: url, from: this);

  @override
  String toString() => r'imVideoPlayerProvider';
}

@ProviderFor(imConversations)
final imConversationsProvider = ImConversationsProvider._();

final class ImConversationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ConversationView>>,
          List<ConversationView>,
          Stream<List<ConversationView>>
        >
    with
        $FutureModifier<List<ConversationView>>,
        $StreamProvider<List<ConversationView>> {
  ImConversationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imConversationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imConversationsHash();

  @$internal
  @override
  $StreamProviderElement<List<ConversationView>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ConversationView>> create(Ref ref) {
    return imConversations(ref);
  }
}

String _$imConversationsHash() => r'b0686e1d4e78d33759e53f3c308cb67f62428f78';

@ProviderFor(imFriends)
final imFriendsProvider = ImFriendsProvider._();

final class ImFriendsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Friend>>,
          List<Friend>,
          Stream<List<Friend>>
        >
    with $FutureModifier<List<Friend>>, $StreamProvider<List<Friend>> {
  ImFriendsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imFriendsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imFriendsHash();

  @$internal
  @override
  $StreamProviderElement<List<Friend>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Friend>> create(Ref ref) {
    return imFriends(ref);
  }
}

String _$imFriendsHash() => r'd5fee9dacb1ea19121f6a11dde50827def67048f';

@ProviderFor(imGroups)
final imGroupsProvider = ImGroupsProvider._();

final class ImGroupsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GroupView>>,
          List<GroupView>,
          Stream<List<GroupView>>
        >
    with $FutureModifier<List<GroupView>>, $StreamProvider<List<GroupView>> {
  ImGroupsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imGroupsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imGroupsHash();

  @$internal
  @override
  $StreamProviderElement<List<GroupView>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GroupView>> create(Ref ref) {
    return imGroups(ref);
  }
}

String _$imGroupsHash() => r'a57ce5014689d0b865421bac885125cd7685e50f';

@ProviderFor(imMessageList)
final imMessageListProvider = ImMessageListFamily._();

final class ImMessageListProvider
    extends
        $FunctionalProvider<
          AsyncValue<MessageList>,
          MessageList,
          FutureOr<MessageList>
        >
    with $FutureModifier<MessageList>, $FutureProvider<MessageList> {
  ImMessageListProvider._({
    required ImMessageListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'imMessageListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$imMessageListHash();

  @override
  String toString() {
    return r'imMessageListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MessageList> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MessageList> create(Ref ref) {
    final argument = this.argument as String;
    return imMessageList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ImMessageListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$imMessageListHash() => r'96c3ebac7140d6ac721fdac1aff5bfa90c580278';

final class ImMessageListFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MessageList>, String> {
  ImMessageListFamily._()
    : super(
        retry: null,
        name: r'imMessageListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ImMessageListProvider call(String key) =>
      ImMessageListProvider._(argument: key, from: this);

  @override
  String toString() => r'imMessageListProvider';
}

@ProviderFor(imMessages)
final imMessagesProvider = ImMessagesFamily._();

final class ImMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<MessageListSnapshot>,
          MessageListSnapshot,
          Stream<MessageListSnapshot>
        >
    with
        $FutureModifier<MessageListSnapshot>,
        $StreamProvider<MessageListSnapshot> {
  ImMessagesProvider._({
    required ImMessagesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'imMessagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$imMessagesHash();

  @override
  String toString() {
    return r'imMessagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<MessageListSnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<MessageListSnapshot> create(Ref ref) {
    final argument = this.argument as String;
    return imMessages(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ImMessagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$imMessagesHash() => r'b7830e23efe3b2d1725e2b9782a8c1a3f47ddb7f';

final class ImMessagesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<MessageListSnapshot>, String> {
  ImMessagesFamily._()
    : super(
        retry: null,
        name: r'imMessagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ImMessagesProvider call(String key) =>
      ImMessagesProvider._(argument: key, from: this);

  @override
  String toString() => r'imMessagesProvider';
}

@ProviderFor(imMembers)
final imMembersProvider = ImMembersFamily._();

final class ImMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GroupMember>>,
          List<GroupMember>,
          Stream<List<GroupMember>>
        >
    with
        $FutureModifier<List<GroupMember>>,
        $StreamProvider<List<GroupMember>> {
  ImMembersProvider._({
    required ImMembersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'imMembersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$imMembersHash();

  @override
  String toString() {
    return r'imMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<GroupMember>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GroupMember>> create(Ref ref) {
    final argument = this.argument as String;
    return imMembers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ImMembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$imMembersHash() => r'61235372000c7c32e37ec0bcd83891b17f8eb42b';

final class ImMembersFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<GroupMember>>, String> {
  ImMembersFamily._()
    : super(
        retry: null,
        name: r'imMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ImMembersProvider call(String id) =>
      ImMembersProvider._(argument: id, from: this);

  @override
  String toString() => r'imMembersProvider';
}

@ProviderFor(imGroupInfo)
final imGroupInfoProvider = ImGroupInfoFamily._();

final class ImGroupInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<GroupInfo?>,
          GroupInfo?,
          FutureOr<GroupInfo?>
        >
    with $FutureModifier<GroupInfo?>, $FutureProvider<GroupInfo?> {
  ImGroupInfoProvider._({
    required ImGroupInfoFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'imGroupInfoProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$imGroupInfoHash();

  @override
  String toString() {
    return r'imGroupInfoProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<GroupInfo?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<GroupInfo?> create(Ref ref) {
    final argument = this.argument as String;
    return imGroupInfo(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ImGroupInfoProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$imGroupInfoHash() => r'9ef52a88b916be4f6196d2e14e80d7be140b9f1c';

final class ImGroupInfoFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<GroupInfo?>, String> {
  ImGroupInfoFamily._()
    : super(
        retry: null,
        name: r'imGroupInfoProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ImGroupInfoProvider call(String id) =>
      ImGroupInfoProvider._(argument: id, from: this);

  @override
  String toString() => r'imGroupInfoProvider';
}

@ProviderFor(imConversation)
final imConversationProvider = ImConversationFamily._();

final class ImConversationProvider
    extends
        $FunctionalProvider<
          AsyncValue<ConversationView?>,
          ConversationView?,
          FutureOr<ConversationView?>
        >
    with
        $FutureModifier<ConversationView?>,
        $FutureProvider<ConversationView?> {
  ImConversationProvider._({
    required ImConversationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'imConversationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$imConversationHash();

  @override
  String toString() {
    return r'imConversationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ConversationView?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ConversationView?> create(Ref ref) {
    final argument = this.argument as String;
    return imConversation(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ImConversationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$imConversationHash() => r'4c78f15c622e197af90035e9cf25c0559487b065';

final class ImConversationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ConversationView?>, String> {
  ImConversationFamily._()
    : super(
        retry: null,
        name: r'imConversationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ImConversationProvider call(String key) =>
      ImConversationProvider._(argument: key, from: this);

  @override
  String toString() => r'imConversationProvider';
}

@ProviderFor(imInvitations)
final imInvitationsProvider = ImInvitationsProvider._();

final class ImInvitationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GroupRequest>>,
          List<GroupRequest>,
          FutureOr<List<GroupRequest>>
        >
    with
        $FutureModifier<List<GroupRequest>>,
        $FutureProvider<List<GroupRequest>> {
  ImInvitationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imInvitationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imInvitationsHash();

  @$internal
  @override
  $FutureProviderElement<List<GroupRequest>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GroupRequest>> create(Ref ref) {
    return imInvitations(ref);
  }
}

String _$imInvitationsHash() => r'e78858e233067b9bd9eec6084e2d991883035469';

@ProviderFor(ImRequests)
final imRequestsProvider = ImRequestsProvider._();

final class ImRequestsProvider
    extends $AsyncNotifierProvider<ImRequests, List<FriendRequest>> {
  ImRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imRequestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imRequestsHash();

  @$internal
  @override
  ImRequests create() => ImRequests();
}

String _$imRequestsHash() => r'7a3d208d545d9d7b41de0f937aabba6840af8102';

abstract class _$ImRequests extends $AsyncNotifier<List<FriendRequest>> {
  FutureOr<List<FriendRequest>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<FriendRequest>>, List<FriendRequest>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<FriendRequest>>, List<FriendRequest>>,
              AsyncValue<List<FriendRequest>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(MessagingActions)
final messagingActionsProvider = MessagingActionsProvider._();

final class MessagingActionsProvider
    extends $AsyncNotifierProvider<MessagingActions, void> {
  MessagingActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messagingActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messagingActionsHash();

  @$internal
  @override
  MessagingActions create() => MessagingActions();
}

String _$messagingActionsHash() => r'ecdb3fcd08ea09cf53b7a89ecfaf06deeefd85e0';

abstract class _$MessagingActions extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
