import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import '../models/movement.dart';
import '../repositories/movement_repository.dart';

class SyncService {
  final MovementRepository _repo = MovementRepository();
  final ApiService _api = ApiService.instance;
  Timer? _timer;
  bool _running = false;
  StreamSubscription<dynamic>? _connectivitySub;
  final Connectivity _connectivity = Connectivity();
  bool _connectivityPluginAvailable = true;
  static const _queuedSyncKey = 'sync_queued';

  // Run sync every X seconds when enabled
  void startAutoSync({Duration interval = const Duration(seconds: 30)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _syncOnce());
    // start listening to connectivity changes
    if (_connectivityPluginAvailable) {
      try {
        _connectivitySub ??= _connectivity.onConnectivityChanged.listen((res) {
          if (kDebugMode) debugPrint('connectivity changed: $res');
          final dynamic r = res;
          ConnectivityResult? effective;
          if (r is ConnectivityResult) {
            effective = r;
          } else if (r is List && r.isNotEmpty) {
            final first = r.first;
            if (first is ConnectivityResult) effective = first;
          }
          if (effective != null && effective != ConnectivityResult.none) {
            // attempt immediate sync if network available
            _syncOnce();
          }
        });
      } on MissingPluginException {
        _connectivityPluginAvailable = false;
        if (kDebugMode) debugPrint('connectivity plugin not available; skipping connectivity listener');
      } catch (e) {
        if (kDebugMode) debugPrint('failed to listen connectivity: $e');
      }
    }
  }

  void stopAutoSync() {
    _timer?.cancel();
    _timer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  Future<void> _syncOnce() async {
    if (_running) return;
    _running = true;
    try {
      // Check connectivity before attempting network operations
      if (_connectivityPluginAvailable) {
        try {
          final connRaw = await _connectivity.checkConnectivity();
          final dynamic r = connRaw;
          ConnectivityResult? conn;
          if (r is ConnectivityResult) conn = r;
          else if (r is List && r.isNotEmpty) {
            final first = r.first;
            if (first is ConnectivityResult) conn = first;
          }
          if (conn == ConnectivityResult.none) {
            if (kDebugMode) debugPrint('No connectivity: queuing sync');
            await _queueSync();
            return;
          }
        } on MissingPluginException {
          // plugin not registered on this platform / during hot-reload; avoid noisy logs
          _connectivityPluginAvailable = false;
          if (kDebugMode) debugPrint('connectivity plugin not available; proceeding without connectivity checks');
        } catch (e) {
          if (kDebugMode) debugPrint('connectivity check failed: $e');
          // proceed — optimistic attempt
        }
      }
      final pending = await _repo.fetchPending();
      for (final m in pending) {
        try {
          if (m.syncStatus == 'pending_delete') {
            // delete on server, then remove local row
            final serverId = m.serverId;
            if (serverId != null && serverId.isNotEmpty) {
              final resp = await _api.deleteMovimiento(serverId);
              if (resp.statusCode == 200 || resp.statusCode == 204) {
                await _repo.removeLocal(m.id!);
              }
            } else {
              // no server id - just remove locally
              await _repo.removeLocal(m.id!);
            }
          } else {
            final payload = _movementToDto(m);
            final resp = await _api.postMovimiento(payload);
            if (resp.statusCode == 201 || resp.statusCode == 200) {
              // server returns a document with _id
              final data = resp.data as Map<String, dynamic>;
              final serverId = data['_id'] ?? data['id']?.toString() ?? '';
              await _repo.markSyncedLocal(m.id!, serverId.toString());
            }
          }
        } catch (e) {
          if (kDebugMode) debugPrint('sync failed for movement ${m.id}: $e');
          // leave as pending; next sync will retry
        }
      }
      // After pushing pending local items, pull from server and upsert locally
      try {
        // fetch server movements (server may support pagination; here we fetch all)
        final resp = await _api.getMovimientos();
        if (resp.statusCode == 200) {
          final data = resp.data as List<dynamic>;
          for (final doc in data) {
            try {
              await _repo.upsertFromServer(doc as Map<String, dynamic>);
            } catch (e) {
              if (kDebugMode) debugPrint('upsertFromServer failed: $e');
            }
          }
          // After upserting server documents, remove any local rows that reference
          // a server_id which no longer exists on the server — but only if they
          // are not pending local changes. This keeps local DB in sync when the
          // server has deleted documents (and the local row isn't queued for
          // an update/delete).
          try {
            final serverIds = <String>{};
            for (final doc in data) {
              final id = (doc as Map<String, dynamic>)['_id'] ?? doc['id'];
              if (id != null) serverIds.add(id.toString());
            }

            final local = await _repo.fetchAll();
            for (final m in local) {
              // only consider rows that have a server id and are not pending
              // for upload/delete. If the server doesn't know about the id,
              // and the local row isn't pending, remove it locally.
              if (m.serverId != null && m.serverId!.isNotEmpty) {
                final pending = (m.syncStatus == 'pending' || m.syncStatus == 'pending_delete');
                if (!serverIds.contains(m.serverId!) && !pending) {
                  try {
                    await _repo.removeLocal(m.id!);
                  } catch (e) {
                    if (kDebugMode) debugPrint('failed removing orphan local movement ${m.id}: $e');
                  }
                }
              }
            }
          } catch (e) {
            if (kDebugMode) debugPrint('reconcile local vs server failed: $e');
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('pull from server failed: $e');
      }
          // clear queued flag on successful sync
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_queuedSyncKey);
          } catch (_) {}
    } finally {
      _running = false;
    }
  }

  Map<String, dynamic> _movementToDto(Movement m) {
    return {
      'type': m.type,
      'amount': m.amount,
      'description': m.description,
      'accountFrom': m.accountFrom,
      'accountTo': m.accountTo,
      'currency': m.currency,
      'status': m.status,
      'reference': m.reference,
      'valueDate': m.valueDate?.toIso8601String(),
    };
  }

  Future<void> manualSyncOnce() => _syncOnce();

  Future<void> _queueSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_queuedSyncKey, true);
    } catch (e) {
      if (kDebugMode) debugPrint('failed to persist queued sync: $e');
    }
  }

  /// If a sync was queued while offline, call this to attempt it now.
  Future<void> tryConsumeQueuedSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queued = prefs.getBool(_queuedSyncKey) ?? false;
      if (queued) {
        if (kDebugMode) debugPrint('consuming queued sync');
        await _syncOnce();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('failed to read queued sync: $e');
    }
  }
}
