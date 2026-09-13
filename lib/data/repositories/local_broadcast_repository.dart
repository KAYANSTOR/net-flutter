import 'dart:convert';

import '../../core/result.dart';
import '../../domain/entities/broadcast.dart';
import '../../domain/entities/setting.dart';
import '../../domain/repositories/repositories.dart';

abstract interface class BroadcastRepository {
  Future<Result<List<BroadcastJob>>> listAll();
  Future<Result<BroadcastJob?>> findById(String id);
  Future<Result<void>> save(BroadcastJob job);
}

/// Persists broadcast jobs as JSON in [SettingsRepository] — no new Drift table.
final class LocalBroadcastRepository implements BroadcastRepository {
  const LocalBroadcastRepository(this.settings);

  final SettingsRepository settings;

  static const storageKey = 'broadcast_jobs';

  @override
  Future<Result<List<BroadcastJob>>> listAll() async {
    final raw = await _loadRaw();
    if (raw is Failure<List<BroadcastJob>>) return raw;
    return Success((raw as Success<List<BroadcastJob>>).value);
  }

  @override
  Future<Result<BroadcastJob?>> findById(String id) async {
    final all = await listAll();
    if (all is Failure<List<BroadcastJob>>) {
      return Failure(all.error);
    }
    final jobs = (all as Success<List<BroadcastJob>>).value;
    for (final job in jobs) {
      if (job.id == id) return Success(job);
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> save(BroadcastJob job) async {
    final all = await listAll();
    if (all is Failure<List<BroadcastJob>>) return Failure(all.error);
    final jobs = [...(all as Success<List<BroadcastJob>>).value];
    final index = jobs.indexWhere((j) => j.id == job.id);
    if (index >= 0) {
      jobs[index] = job;
    } else {
      jobs.add(job);
    }
    jobs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return settings.save(
      AppSetting(
        key: storageKey,
        value: jsonEncode(jobs.map((j) => j.toJson()).toList(growable: false)),
        updatedAt: job.updatedAt,
      ),
    );
  }

  Future<Result<List<BroadcastJob>>> _loadRaw() async {
    final found = await settings.find(storageKey);
    if (found is Failure<AppSetting?>) {
      return Failure(found.error);
    }
    final value = (found as Success<AppSetting?>).value?.value;
    if (value == null || value.trim().isEmpty) {
      return const Success(<BroadcastJob>[]);
    }
    try {
      final decoded = jsonDecode(value) as List<dynamic>;
      return Success(
        decoded
            .cast<Map<String, dynamic>>()
            .map((e) => BroadcastJob.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    } catch (error) {
      return Failure(
        AppFailure(code: 'broadcast_store_corrupt', message: error.toString()),
      );
    }
  }
}
