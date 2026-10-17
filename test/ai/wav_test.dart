import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sme_financial_copilot/ai/wav.dart';

void main() {
  test('wraps PCM in a valid 16 kHz mono 16-bit WAV header', () {
    final pcm = Uint8List.fromList(List.generate(320, (i) => i % 256));
    final wav = pcm16ToWav(pcm);
    final h = ByteData.sublistView(wav);

    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 16)), 'WAVEfmt ');
    expect(h.getUint32(4, Endian.little), 36 + 320);
    expect(h.getUint16(22, Endian.little), 1); // mono
    expect(h.getUint32(24, Endian.little), 16000);
    expect(h.getUint16(34, Endian.little), 16); // bits
    expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');
    expect(h.getUint32(40, Endian.little), 320);
    expect(wav.sublist(44), pcm);
  });
}
