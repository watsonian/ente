import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/network.dart';
import 'package:photos/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserRemoteFlagService {
  final _dio = Network.instance.getDio();
  final _logger = Logger((UserRemoteFlagService).toString());
  final _config = Configuration.instance;
  late SharedPreferences _prefs;

  UserRemoteFlagService._privateConstructor();

  static final UserRemoteFlagService instance =
      UserRemoteFlagService._privateConstructor();

  static const String recoveryVerificationFlag = "recoveryKeyVerified";
  static const String needRecoveryKeyVerification =
      "needRecoveryKeyVerification";

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool shouldShowRecoveryVerification() {
    if (!_prefs.containsKey(needRecoveryKeyVerification)) {
      // fetch the status from remote
      unawaited(_refreshRecoveryVerificationFlag());
      return false;
    }
    return _prefs.getBool(needRecoveryKeyVerification)!;
  }

  // markRecoveryVerificationAsDone is used to track if user has verified their
  // recovery key in the past or not. This helps in avoid showing the same
  // prompt to the user on re-install or signing into a different device
  Future<void> markRecoveryVerificationAsDone() async {
    await _setBooleanFlag(recoveryVerificationFlag, true);
    await _prefs.setBool(needRecoveryKeyVerification, false);
  }

  Future<void> _refreshRecoveryVerificationFlag() async {
    final remoteStatusValue = await _getBooleanFlag(recoveryVerificationFlag);
    if (remoteStatusValue) {
      await _prefs.setBool(needRecoveryKeyVerification, false);
    } else {
      // check the session creationTime. If any active session is older than
      // 1 day, set the need to verification as true
      final activeSessions = await UserService.instance.getActiveSessions();
      final int microSecondsInADay = const Duration(minutes: 1).inMicroseconds;
      final bool anyActiveSessionOlderThanADay =
          activeSessions.sessions.firstWhere(
                (e) =>
                    (e.creationTime + microSecondsInADay) <
                    DateTime.now().microsecondsSinceEpoch,
                orElse: () => null,
              ) !=
              null;
      if (anyActiveSessionOlderThanADay) {
        await _prefs.setBool(needRecoveryKeyVerification, true);
      } else {
        // continue defaulting to no verification prompt
        _logger.finest('No active session older than 1 day');
      }
    }
  }

  Future<bool> _getBooleanFlag(String key, {bool defaultVal = false}) async {
    try {
      final response = await _dio.get(
        _config.getHttpEndpoint() + "/users/remote-store/bool/$key",
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw Exception("Unexpected status code");
      }
      return response.data["status"] ?? defaultVal;
    } catch (e) {
      _logger.info(
        "Error while fetching bool status for $key",
      );
      rethrow;
    }
  }

  // _setBooleanFlag sets the corresponding flag on remote
  // to mark recovery as completed
  Future<void> _setBooleanFlag(String key, bool value) async {
    try {
      final response = await _dio.post(
        _config.getHttpEndpoint() + "/users/remote-store/bool/$key/$value",
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw Exception("Unexpected state");
      }
    } catch (e) {
      _logger.warning("Failed to set flag for $key", e);
      rethrow;
    }
  }
}
