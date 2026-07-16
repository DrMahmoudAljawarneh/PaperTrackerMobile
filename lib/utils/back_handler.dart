import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps a screen so the user must tap back twice within [duration] to exit.
/// Shows a [SnackBar] hint on the first tap.
class DoubleBackExit extends StatefulWidget {
  final Widget child;
  final String message;
  final Duration duration;

  const DoubleBackExit({
    super.key,
    required this.child,
    this.message = 'Tap again to exit',
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<DoubleBackExit> createState() => _DoubleBackExitState();
}

class _DoubleBackExitState extends State<DoubleBackExit> {
  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < widget.duration) {
          _lastBackPress = null;
          SystemNavigator.pop();
          return;
        }
        _lastBackPress = now;
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(widget.message),
              duration: widget.duration,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
            ),
          );
      },
      child: widget.child,
    );
  }
}

/// Wraps a screen with a confirm-exit dialog.
/// Useful for forms with unsaved data.
class ConfirmExit extends StatelessWidget {
  final Widget child;
  final bool hasUnsavedChanges;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  const ConfirmExit({
    super.key,
    required this.child,
    this.hasUnsavedChanges = false,
    this.title = 'Discard changes?',
    this.message = 'You have unsaved changes. Are you sure you want to go back?',
    this.confirmLabel = 'Discard',
    this.cancelLabel = 'Stay',
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(cancelLabel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        );
        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}
