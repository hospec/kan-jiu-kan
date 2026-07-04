import 'dart:async';
import 'package:dio/dio.dart';
import '../models/signal_source.dart';
import 'database_service.dart';

class SignalChecker {
  final Dio _dio;
  SignalChecker({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(connectTimeout: Duration(seconds: 3), receiveTimeout: Duration(seconds: 3)));

  Future<List<CheckedSource>> checkBatch(List<SignalSource> sources, {int concurrency = 10}) async {
    final results = <CheckedSource>[];
    for (var i = 0; i < sources.length; i += concurrency) {
      final end = i + concurrency > sources.length ? sources.length : i + concurrency;
      final chunk = sources.sublist(i, end);
      final chunkResults = await Future.wait(chunk.map(_checkOne));
      results.addAll(chunkResults);
    }
    results.sort((a, b) => (a.latencyMs ?? 9999).compareTo(b.latencyMs ?? 9999));
    return results;
  }

  Future<CheckedSource> _checkOne(SignalSource source) async {
    final sw = Stopwatch()..start();
    try {
      final resp = await _dio.head(source.url);
      sw.stop();
      return CheckedSource(source: source, isAvailable: resp.statusCode == 200, latencyMs: sw.elapsedMilliseconds);
    } catch (_) {
      sw.stop();
      return CheckedSource(source: source, isAvailable: false, latencyMs: sw.elapsedMilliseconds);
    }
  }

  Future<void> updateAvailability(List<CheckedSource> results, [DatabaseService? db]) async {
    db ??= DatabaseService();
    for (final r in results) { if (!r.isAvailable) await db.markSourceUnavailable(r.source.id); }
  }
}

class CheckedSource {
  final SignalSource source;
  final bool isAvailable;
  final int? latencyMs;
  const CheckedSource({required this.source, required this.isAvailable, this.latencyMs});
}
