import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:deeprespond_im/io.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/real_backend.dart';

void main() {
  if (Platform.environment['OPENMEETING_REAL_TEST'] != '1') return;
  test('real IM SDK: two accounts, messages and group lifecycle', () async {
    HttpOverrides.global = RealNetwork();
    final results = Results('im-real');
    final host = await RealAccount.restore('rtchostvalidation');
    final member = await RealAccount.restore('rtcmembervalidation');
    final hostApi = host.client(), memberApi = member.client();
    DRClient? a, b;
    String? group;
    final suffix = DateTime.now().millisecondsSinceEpoch;
    Future<DRClient> login(RealAccount account, String profile) async {
      final api = account.client();
      final ticket = (await api.post<Map<String, dynamic>>('/api/v1/im/ticket')).data!;
      final im = await DRClient.create(
        DRClientOptions(
          appKey: ticket['app_key'] as String,
          apiUrl: Uri.parse(ticket['api_url'] as String),
          platform: IoPlatform(
            dataDir: Directory('.dart_tool/acceptance/$suffix-$profile').absolute.path,
            platformName: 'windows',
            database: const DefaultDatabaseOpener(background: false),
          ),
          ticketProvider: (_) async =>
              (await api.post<Map<String, dynamic>>('/api/v1/im/ticket')).data!['ticket'] as String,
        ),
      );
      await im.auth.loginWithTicket(ticket: ticket['ticket'] as String);
      if (im.connection.state.kind != 'ready') {
        try {
          await im.connection.waitUntilReady(timeout: const Duration(seconds: 15));
        } catch (_) {
          throw StateError('IM connection: ${im.connection.diagnostics()}');
        }
      }
      return im;
    }

    try {
      await results.step('真实 IM 双账号登录', '业务票据换取 SDK 登录态，身份与业务一致', () async {
        a = await login(host, 'host');
        b = await login(member, 'member');
        expect(a!.auth.currentUser?.username, host.id);
        expect(b!.auth.currentUser?.username, member.id);
        return {'accounts': 2, 'platform': 'SDK IoPlatform，真实 HTTP/WS/SQLite；系统钥匙串未覆盖'};
      });
      await results.step('真实单聊发送与对端收取', '对端 SDK 消息列表收到唯一文本', () async {
        final view = await a!.conversations.openSingle(member.id);
        final peer = await b!.conversations.openSingle(host.id);
        final messages = b!.messages.open(peer.conversationKey);
        await messages.stream
            .firstWhere((s) => s.loading == MessageListLoading.none)
            .timeout(const Duration(seconds: 15));
        final text = 'Flutter真实联调-$suffix';
        final received = messages.stream.firstWhere(
          (s) => s.items.any((m) => m.body?['text'] == text),
        );
        await a!.messages.send(
          SendTarget.conversation(view.conversationKey),
          OutgoingContent.text(text),
          options: const SendOptions(waitUntilSent: true),
        );
        final snapshot = await received.timeout(const Duration(seconds: 25));
        expect(snapshot.items.any((m) => m.body?['text'] == text), isTrue);
        messages.dispose();
        return '发送及对端接收通过';
      });
      await results.step('真实群创建、公告和解散', '创建独立测试群，更新公告后服务端回读一致', () async {
        final created = await a!.groups.create(
          name: 'Flutter验收-$suffix',
          type: GroupType.private,
          members: [member.id],
        );
        group = created.groupId;
        expect(created.results.every((m) => m.ok), isTrue);
        await a!.groups.update(group!, name: 'Flutter验收更新-$suffix', announcement: '移动端真实 SDK 公告验证');
        final snapshot = await a!.groups.get(group!, refresh: true);
        expect(snapshot?.group.name, 'Flutter验收更新-$suffix');
        await a!.groups.dismiss(group!);
        group = null;
        return '创建、成员结果、更新回读及解散通过';
      });
      late MessageView sent;
      final content = utf8.encode('Flutter attachment acceptance $suffix');
      await results.step('真实 IM 文件上传', '文件消息上传并获得服务端序号', () async {
        final peer = await a!.conversations.openSingle(member.id);
        sent = await a!.messages.send(
          SendTarget.conversation(peer.conversationKey),
          OutgoingContent.file(
            DRFile.fromBytes(Uint8List.fromList(content), name: 'flutter-$suffix.txt'),
            name: 'flutter-$suffix.txt',
          ),
          options: const SendOptions(waitUntilSent: true),
        );
        expect(sent.seq, isNotNull);
        return '上传和消息服务端确认通过；原生文件选择器未覆盖';
      });
      Object? downloadFailure;
      try {
        await results.step('真实 IM 文件下载', '对端下载并逐字节校验内容', () async {
          final file = File('.dart_tool/acceptance/received-$suffix.txt').absolute;
          try {
            await b!.files.download(sent.body!['url'] as String, file.path);
          } catch (_) {
            final resolved = await b!.files.resolveUrl(sent.body!['url'] as String);
            final uri = Uri.parse(resolved.downloadUrl);
            final client = HttpClient();
            try {
              final response = await (await client.getUrl(uri)).close();
              final body = await utf8.decoder.bind(response).join();
              final diagnostic = {
                'status': response.statusCode,
                'host': uri.host,
                'scheme': uri.scheme,
                'storageCode': RegExp(r'<Code>([^<]+)</Code>').firstMatch(body)?.group(1),
                'storageMessage': RegExp(r'<Message>([^<]+)</Message>').firstMatch(body)?.group(1),
              };
              await File('${artifactRoot.path}/logs/file-download-diagnostic.json')
                  .writeAsString(jsonEncode(diagnostic));
            } finally {
              client.close(force: true);
            }
            rethrow;
          }
          expect(await file.readAsBytes(), content);
          return '下载字节比对通过';
        });
      } catch (error) {
        downloadFailure = error;
      }
      await results.step('真实 IM 撤回', '服务端接受撤回，SDK 列表出现撤回状态', () async {
        await a!.messages.recall(sent.conversationId!, sent.seq!);
        final list = a!.messages.open(sent.conversationId!);
        await list.stream
            .firstWhere((s) => s.items.any((m) => m.seq == sent.seq && m.recalled != null))
            .timeout(const Duration(seconds: 15));
        list.dispose();
        return '撤回同步通过';
      });
      expect(downloadFailure, isNull, reason: '下载失败须保留失败状态；查看 file-download-diagnostic.json');
    } finally {
      if (group != null) await a?.groups.dismiss(group!);
      await a?.auth.logout();
      await b?.auth.logout();
      hostApi.close();
      memberApi.close();
      HttpOverrides.global = null;
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
