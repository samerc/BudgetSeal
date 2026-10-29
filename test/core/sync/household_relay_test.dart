import 'dart:convert';
import 'dart:typed_data';

import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/services/household_members.dart';
import 'package:budgetseal/core/sync/household_key.dart';
import 'package:budgetseal/core/sync/log_sync.dart';
import 'package:budgetseal/core/sync/relay_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'log_sync_test.dart' show dump, household, phone;

/// The relay (`relay/src/index.js`) in memory: same paths, same answers.
class FakeRelay {
  final auth = <String, String>{};
  final files = <String, Map<String, (Uint8List, int)>>{};

  late final client = MockClient((request) async {
    final parts = request.url.pathSegments;
    final hid = parts[2];
    final key = request.headers['authorization']!.replaceFirst('Bearer ', '');
    if (parts.length == 3 && request.method == 'PUT') {
      if (auth[hid] == null) {
        auth[hid] = key;
        files[hid] = {};
        return http.Response('{"created":true}', 201);
      }
      return http.Response('{}', auth[hid] == key ? 200 : 409);
    }
    if (auth[hid] == null) return http.Response('{}', 404);
    if (auth[hid] != key) return http.Response('{}', 401);
    final mine = files[hid]!;
    if (parts.length == 4) {
      return http.Response(
          jsonEncode({
            'files': [
              for (final e in mine.entries)
                {'name': e.key, 'version': e.value.$2, 'size': e.value.$1.length},
            ],
          }),
          200);
    }
    final name = parts[4];
    if (request.method == 'GET') {
      final f = mine[name];
      return f == null ? http.Response('{}', 404) : http.Response.bytes(f.$1, 200);
    }
    mine[name] = (request.bodyBytes, (mine[name]?.$2 ?? 0) + 1);
    return http.Response('{"version":${mine[name]!.$2}}', 200);
  });
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  tearDown(() => DeviceIdentity.debugSet('local'));

  group('household key', () {
    test('the invite code carries the key, and another relay when set', () {
      final k = HouseholdKey.generate();
      final back = HouseholdKey.fromCode(k.code)!;
      expect(back.secret, k.secret);
      expect(back.relayUrl, defaultRelayUrl);
      expect(k.code, startsWith('BS1-'));
      expect(k.code, isNot(contains('.')));

      final own = HouseholdKey(k.secret, relayUrl: 'https://relay.example.org');
      final ownBack = HouseholdKey.fromCode(own.code)!;
      expect(ownBack.relayUrl, 'https://relay.example.org');
      expect(ownBack.householdId, k.householdId);
    });

    test('anything else is not a code', () {
      expect(HouseholdKey.fromCode('hello'), isNull);
      expect(HouseholdKey.fromCode('BS1-short'), isNull);
      final plain = HouseholdKey(HouseholdKey.generate().secret,
          relayUrl: 'http://insecure.example.org');
      expect(HouseholdKey.fromCode(plain.code), isNull);
      expect(HouseholdKey.isOldInvite('PP-abc'), isTrue);
      expect(HouseholdKey.isOldInvite('BS1-abc'), isFalse);
    });

    test('id and password come from the key; the relay never gets the key',
        () {
      final a = HouseholdKey.generate();
      final b = HouseholdKey.generate();
      expect(a.householdId, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(HouseholdKey.fromCode(a.code)!.householdId, a.householdId);
      expect(HouseholdKey.fromCode(a.code)!.auth, a.auth);
      expect(a.householdId, isNot(b.householdId));
      expect(a.auth, isNot(b.auth));
      final secret = base64Url.encode(a.secret).replaceAll('=', '');
      expect(a.auth, isNot(contains(secret)));
    });

    test('sealed files open with the key and nothing else', () async {
      final k = HouseholdKey.generate();
      const text = '{"note":"Spinneys — قهوة — café","amount":12.5}';
      final sealed = await k.seal(text);
      expect(utf8.decode(sealed, allowMalformed: true), isNot(contains('Spinneys')));
      expect(await k.open(sealed), text);
      // Same text, new nonce: never the same bytes twice.
      expect(await k.seal(text), isNot(sealed));

      await expectLater(HouseholdKey.generate().open(sealed),
          throwsA(isA<FormatException>()));
      final tampered = Uint8List.fromList(sealed)..[sealed.length - 1] ^= 1;
      await expectLater(k.open(tampered), throwsA(isA<FormatException>()));
      await expectLater(k.open(Uint8List.fromList(utf8.encode('{"plain":1}'))),
          throwsA(isA<FormatException>()));
    });
  });

  group('relay provider', () {
    test('starts a household; another phone joins with its code', () async {
      final relay = FakeRelay();
      final a = RelayProvider(client: relay.client);
      expect(await a.connect(), isTrue);
      final k = (await a.key)!;
      expect(relay.auth[k.householdId], k.auth);

      final b = RelayProvider(client: relay.client);
      await b.join(HouseholdKey.fromCode(k.code)!);
      expect((await b.key)!.householdId, k.householdId);
    });

    test('a code for no household, or the wrong key, is refused', () async {
      final relay = FakeRelay();
      final b = RelayProvider(client: relay.client);
      await expectLater(b.join(HouseholdKey.generate()),
          throwsA(isA<RelayException>()
              .having((e) => e.error, 'error', RelayError.notFound)));
      expect(await b.isConnected, isFalse);

      final a = RelayProvider(client: relay.client);
      await a.connect();
      final k = (await a.key)!;
      relay.auth[k.householdId] = 'someone else';
      await expectLater(a.listLogFiles(),
          throwsA(isA<RelayException>()
              .having((e) => e.error, 'error', RelayError.unauthorized)));
    });

    test('two phones share a budget through it; the relay holds only '
        'ciphertext', () async {
      final relay = FakeRelay();
      final pa = RelayProvider(client: relay.client);
      await pa.connect();

      final a = await phone('phone-a');
      await household(a);
      await AllocationEngine(a).recordTransaction(
          householdId: 'h', accountId: 'bank', type: 'expense', note: 'Spinneys',
          lines: const [TxLine(amount: 12.5, currency: 'USD', categoryId: 'food')],
          baseCurrency: 'USD');
      await LogSync(a).sync(ProviderLogStore(pa));

      final pb = RelayProvider(client: relay.client);
      await pb.join(HouseholdKey.fromCode((await pa.key)!.code)!);
      final b = await phone('phone-b');
      await LogSync(b).replaceFrom(ProviderLogStore(pb));
      expect(await dump(b), await dump(a));

      await AllocationEngine(b).recordTransaction(
          householdId: 'h', accountId: 'cash', type: 'expense', note: 'Bakery',
          lines: const [TxLine(amount: 3, currency: 'USD', categoryId: 'food')],
          baseCurrency: 'USD');
      await LogSync(b).sync(ProviderLogStore(pb));
      DeviceIdentity.debugSet('phone-a');
      await LogSync(a).sync(ProviderLogStore(pa));
      expect(await dump(a), await dump(b));

      final stored = relay.files.values.single.values;
      expect(stored, isNotEmpty);
      for (final (bytes, _) in stored) {
        final asText = latin1.decode(bytes);
        expect(asText, isNot(contains('Spinneys')));
        expect(asText, isNot(contains('Bakery')));
        expect(asText, startsWith('BSR1'));
      }
    });
  });
}
