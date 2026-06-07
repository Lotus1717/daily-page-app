import 'package:flutter_test/flutter_test.dart';
import 'package:daily_page/services/weread_config_store.dart';

void main() {
  group('WeReadConfigStore.validate', () {
    test('accepts semicolon format', () {
      final v = WeReadConfigStore.validate('wr_vid=123456; wr_skey=abcDEF');
      expect(v.isValid, isTrue);
      expect(v.normalized, 'wr_vid=123456; wr_skey=abcDEF');
      expect(v.savedKeys, ['wr_vid', 'wr_skey']);
    });

    test('accepts newline format', () {
      final v = WeReadConfigStore.validate('wr_vid=123456\nwr_skey=abcDEF');
      expect(v.isValid, isTrue);
      expect(v.normalized, 'wr_vid=123456; wr_skey=abcDEF');
      expect(v.savedKeys, ['wr_vid', 'wr_skey']);
    });

    test('strips Cookie: prefix', () {
      final v = WeReadConfigStore.validate('Cookie: wr_vid=1; wr_skey=2');
      expect(v.isValid, isTrue);
      expect(v.normalized, 'wr_vid=1; wr_skey=2');
    });

    test('preserves wr_rt and other keys', () {
      final v = WeReadConfigStore.validate(
        'wr_fp=abc; wr_vid=123; wr_skey=def; wr_rt=token%40x',
      );
      expect(v.isValid, isTrue);
      expect(
        v.normalized,
        'wr_vid=123; wr_skey=def; wr_rt=token%40x; wr_fp=abc',
      );
      expect(v.savedKeys, ['wr_vid', 'wr_skey', 'wr_rt', 'wr_fp']);
    });

    test('rejects missing wr_skey', () {
      final v = WeReadConfigStore.validate('wr_vid=123456');
      expect(v.isValid, isFalse);
      expect(v.error, contains('wr_skey'));
    });

    test('rejects missing wr_vid', () {
      final v = WeReadConfigStore.validate('wr_skey=abc');
      expect(v.isValid, isFalse);
      expect(v.error, contains('wr_vid'));
    });
  });

  group('WeReadConfigStore.keysFromSaved', () {
    test('returns keys without values', () {
      final keys = WeReadConfigStore.keysFromSaved(
        'wr_vid=1; wr_skey=2; wr_rt=3',
      );
      expect(keys, ['wr_vid', 'wr_skey', 'wr_rt']);
    });
  });
}
