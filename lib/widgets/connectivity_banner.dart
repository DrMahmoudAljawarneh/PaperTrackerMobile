import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> with SingleTickerProviderStateMixin {
  static Stream<DatabaseEvent>? _sharedStream;
  Stream<DatabaseEvent> get _connectivityStream {
    _sharedStream ??= FirebaseDatabase.instance.ref('.info/connected').onValue;
    return _sharedStream!;
  }
  late AnimationController _animController;
  late Animation<double> _heightFactor;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heightFactor = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: _connectivityStream,
      builder: (context, snapshot) {
        final connected = snapshot.data?.snapshot.value as bool? ?? true;
        final offline = !connected;

        if (offline != _isOffline) {
          _isOffline = offline;
          if (_isOffline) {
            _animController.forward();
          } else {
            _animController.reverse();
          }
        }

        return SizeTransition(
          sizeFactor: _heightFactor,
          alignment: Alignment.topCenter,
          child: Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "You're offline — changes will sync when reconnected.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
