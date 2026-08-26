import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// ZKTeco device client over TCP (port 4370) — port of the pyzk protocol.
class ZkLog {
  const ZkLog({
    required this.userId,
    required this.timestamp,
    required this.verifyMode,
    required this.inOutMode,
  });

  final int userId;
  final DateTime timestamp;
  final int verifyMode;
  final int inOutMode;
}

class ZkException implements Exception {
  ZkException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ZkClient {
  ZkClient({this.timeout = const Duration(seconds: 8)});

  final Duration timeout;
  Socket? _socket;
  int _sessionId = 0;
  int _replyId = 0;

  static const int cmdConnect = 1000;
  static const int cmdExit = 1001;
  static const int cmdEnableClock = 1002;
  static const int cmdAttLogRrq = 1333;
  static const int cmdAckOk = 8193; // 0x2000
  static const int cmdAckError = 8194; // 0x2001
  static const int cmdAckData = 8195; // 0x2000 + 3
  static const int cmdAckRetry = 8196;
  static const int cmdAckRepeat = 8197;
  static const int cmdAckUnauthorized = 8198;

  bool get isConnected => _socket != null;

  Uint8List _makeCommand(int command, [List<int> data = const []]) {
    final ByteData buf = ByteData(8 + data.length);
    buf.setUint16(0, command, Endian.little);
    buf.setUint16(2, 0, Endian.little);
    buf.setUint16(4, _sessionId, Endian.little);
    buf.setUint16(6, _replyId, Endian.little);
    const int offset = 8;
    for (var i = 0; i < data.length; i++) {
      buf.setUint8(offset + i, data[i]);
    }
    final Uint8List body = buf.buffer.asUint8List();
    final ByteData lengthPrefix = ByteData(4)
      ..setUint32(0, body.length, Endian.little);
    final Uint8List checksumInput = Uint8List(4 + body.length)
      ..setRange(0, 4, lengthPrefix.buffer.asUint8List(0, 4))
      ..setRange(4, 4 + body.length, body);
    final int checksum = _checksum(checksumInput);
    final ByteData checksumBytes = ByteData(2)
      ..setUint16(0, checksum, Endian.little);

    final ByteData top = ByteData(8)
      ..setUint16(0, 0x5050, Endian.little)
      ..setUint16(2, 0, Endian.little)
      ..setUint32(4, body.length, Endian.little);

    final Uint8List packet =
        Uint8List(8 + body.length + 2);
    packet.setRange(0, 8, top.buffer.asUint8List());
    packet.setRange(8, 8 + body.length, body);
    packet.setRange(
        8 + body.length, packet.length, checksumBytes.buffer.asUint8List(0, 2));

    return packet;
  }

  int _checksum(Uint8List msg) {
    Uint8List padded = msg;
    if (padded.length % 2 != 0) {
      padded = Uint8List.fromList([...padded, 0]);
    }
    int checksum = 0;
    final ByteData view = ByteData.view(padded.buffer);
    for (var i = 0; i < padded.length; i += 2) {
      checksum += view.getUint16(i, Endian.little);
      checksum &= 0xFFFF;
    }
    return (~checksum) & 0xFFFF;
  }

  Future<Uint8List> _sendCommand(int command, [List<int> data = const []]) async {
    final Socket? socket = _socket;
    if (socket == null) throw ZkException('غير متصل بالجهاز');
    _replyId = (_replyId + 1) & 0xFFFF;
    socket.add(_makeCommand(command, data));
    await socket.flush();

    final (Uint8List payload, int responseCommand) = await _readResponse();
    if (responseCommand == cmdAckOk || responseCommand == cmdAckData) {
      _sessionId = payload.length >= 2
          ? ByteData.view(payload.buffer, payload.offsetInBytes)
              .getUint16(0, Endian.little)
          : _sessionId;
      return payload;
    }
    if (responseCommand == cmdAckUnauthorized) {
      throw ZkException('الجهاز محمي بمفتاح اتصال (CommKey)');
    }
    throw ZkException('رفض الجهاز الأمر ($responseCommand)');
  }

  Future<(Uint8List, int)> _readResponse() async {
    final Socket? socket = _socket;
    if (socket == null) throw ZkException('غير متصل');

    final Uint8List header = await _readBytes(socket, 8);
    final ByteData headerView = ByteData.view(header.buffer);
    final int magic = headerView.getUint16(0, Endian.little);
    if (magic != 0x5050) throw ZkException('رد غير معروف من الجهاز');
    final int length = headerView.getUint32(4, Endian.little);
    if (length < 8 || length > 10 * 1024 * 1024) {
      throw ZkException('حجم رد غير منطقي من الجهاز');
    }

    final Uint8List payload = await _readBytes(socket, length);
    final ByteData view = ByteData.view(payload.buffer, payload.offsetInBytes);
    final int responseCommand = view.getUint16(4, Endian.little);
    final Uint8List data =
        payload.sublist(6, length - 2 >= 6 ? length - 2 : 6);

    return (data, responseCommand);
  }

  final List<int> _rxBuffer = [];
  StreamIterator<Uint8List>? _rxIterator;

  Future<Uint8List> _readBytes(Socket socket, int count) async {
    _rxIterator ??= StreamIterator<Uint8List>(socket);
    final Stopwatch watch = Stopwatch()..start();
    while (_rxBuffer.length < count) {
      if (watch.elapsed > timeout) {
        throw ZkException('انتهت مهلة الاتصال بالجهاز');
      }
      final bool hasMore = await _rxIterator!.moveNext().timeout(
            timeout,
            onTimeout: () => throw ZkException('مهلة القراءة'),
          );
      if (!hasMore) throw ZkException('انقطع الاتصال بالجهاز');
      _rxBuffer.addAll(_rxIterator!.current);
    }
    final Uint8List result = Uint8List.fromList(_rxBuffer.sublist(0, count));
    _rxBuffer.removeRange(0, count);
    return result;
  }

  Future<void> connect(String host, {int port = 4370}) async {
    await _rxIterator?.cancel();
    _rxIterator = null;
    _rxBuffer.clear();
    try {
      _socket = await Socket.connect(
        host,
        port,
        timeout: timeout,
      );
    } catch (_) {
      throw ZkException(
          'تعذر الاتصال — تأكد أن الجهاز والجوال على نفس الشبكة وأن IP صحيح');
    }
    _sessionId = 0;
    _replyId = 0;
    await _sendCommand(cmdConnect);
  }

  Future<List<ZkLog>> readAttendance() async {
    _replyId = (_replyId + 1) & 0xFFFF;
    _socket!.add(_makeCommand(cmdAttLogRrq, [
      0x05, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00,
    ]));
    await _socket!.flush();

    final List<ZkLog> logs = [];
    final Stopwatch watch = Stopwatch()..start();

    while (true) {
      if (watch.elapsed > const Duration(minutes: 2)) {
        throw ZkException('انتهت مهلة قراءة السجلات');
      }
      final (Uint8List payload, int command) = await _readResponse();
      if (command == cmdAckOk) {
        break;
      }
      if (command == cmdAckError) {
        throw ZkException('رفض الجهاز قراءة السجلات');
      }
      if (payload.isEmpty) continue;

      for (var offset = 0; offset + 16 <= payload.length; offset += 16) {
        final ByteData view =
            ByteData.view(payload.buffer, payload.offsetInBytes + offset, 16);
        final int uid = view.getUint32(0, Endian.little);
        final int verifyMode = payload[offset + 4];
        final int inOutMode = payload[offset + 5];
        final int timeRaw = view.getUint32(6, Endian.little);
        logs.add(ZkLog(
          userId: uid,
          timestamp: decodeZkTime(timeRaw),
          verifyMode: verifyMode,
          inOutMode: inOutMode,
        ));
      }
    }
    await enableDevice();
    return logs;
  }

  Future<void> enableDevice() async {
    _replyId = (_replyId + 1) & 0xFFFF;
    _socket?.add(_makeCommand(cmdEnableClock));
    await _socket?.flush();
  }

  Future<void> disconnect() async {
    try {
      _replyId = (_replyId + 1) & 0xFFFF;
      _socket?.add(_makeCommand(cmdExit));
      await _socket?.flush();
      await _socket?.close();
    } finally {
      await _rxIterator?.cancel();
      _rxIterator = null;
      _socket?.destroy();
      _socket = null;
      _sessionId = 0;
      _rxBuffer.clear();
    }
  }

  static DateTime decodeZkTime(int raw) {
    final int second = raw % 60;
    final int minute = (raw ~/ 60) % 60;
    final int hour = (raw ~/ 3600) % 24;
    final int day = (raw ~/ 86400) % 31;
    final int month = (raw ~/ 2678400) % 12 + 1;
    final int year = (raw ~/ 31536000) + 2000;
    return DateTime(year, month, day + 1, hour, minute, second);
  }
}

String zkHex(List<int> bytes) => bytes
    .map((b) => b.toRadixString(16).padLeft(2, '0'))
    .join(' ');
Uint8List zkUtf8(String s) => utf8.encode(s);
