import "dart:io";

import "package:flutter/material.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/utils/dialog_util.dart";

class AutoCastDialog extends StatefulWidget {
  AutoCastDialog({
    Key? key,
  }) : super(key: key) {}

  @override
  State<AutoCastDialog> createState() => _AutoCastDialogState();
}

class _AutoCastDialogState extends State<AutoCastDialog> {
  final bool doesUserExist = true;

  @override
  Widget build(BuildContext context) {
    final textStyle = getEnteTextTheme(context);

    final AlertDialog alert = AlertDialog(
      title: Text(
        "Connect to device",
        style: textStyle.largeBold,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "You'll see available Cast devices here.",
            style: textStyle.bodyMuted,
          ),
          if (Platform.isIOS)
            Text(
              "Make sure Local Network permissions are turned on for the Ente Photos app, in Settings.",
              style: textStyle.bodyMuted,
            ),
          const SizedBox(height: 16),
          FutureBuilder<List<(String, Object)>>(
            future: castService.searchDevices(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error.toString()}',
                  ),
                );
              } else if (!snapshot.hasData) {
                return const EnteLoadingWidget();
              }

              if (snapshot.data!.isEmpty) {
                return const Center(child: Text('No device'));
              }

              return Column(
                children: snapshot.data!.map((result) {
                  final device = result.$2;
                  final name = result.$1;
                  return GestureDetector(
                    onTap: () async {
                      try {
                        await _connectToYourApp(context, device);
                      } catch (e) {
                        showGenericErrorDialog(context: context, error: e)
                            .ignore();
                      }
                    },
                    child: Text(name),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
    return alert;
  }

  Future<void> _connectToYourApp(
    BuildContext context,
    Object castDevice,
  ) async {
    await castService.connectDevice(context, castDevice);
  }
}
