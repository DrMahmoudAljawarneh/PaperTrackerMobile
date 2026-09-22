import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paper_tracker/config/theme.dart';

class PomodoroTimerWidget extends StatefulWidget {
  final VoidCallback? onSessionCompleted;

  const PomodoroTimerWidget({super.key, this.onSessionCompleted});

  @override
  State<PomodoroTimerWidget> createState() => _PomodoroTimerWidgetState();
}

class _PomodoroTimerWidgetState extends State<PomodoroTimerWidget> {
  static const int _focusDuration = 25 * 60; // 25 minutes
  static const int _breakDuration = 5 * 60;  // 5 minutes

  int _remainingSeconds = _focusDuration;
  bool _isRunning = false;
  bool _isBreak = false;
  int _completedSessions = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    HapticFeedback.mediumImpact();
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _timer?.cancel();
          HapticFeedback.heavyImpact();
          if (!_isBreak) {
            _completedSessions++;
            widget.onSessionCompleted?.call();
          }
          setState(() {
            _isRunning = false;
            _isBreak = !_isBreak;
            _remainingSeconds = _isBreak ? _breakDuration : _focusDuration;
          });
        }
      });
    }
  }

  void _resetTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isBreak = false;
      _remainingSeconds = _focusDuration;
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final total = _isBreak ? _breakDuration : _focusDuration;
    final progress = (_remainingSeconds / total).clamp(0.0, 1.0);
    final accentColor = _isBreak ? AppTheme.accentColor : AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isBreak ? Icons.coffee_rounded : Icons.timer_outlined,
                color: accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isBreak ? 'Short Break' : 'Deep Work Session',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (_completedSessions > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 12, color: AppTheme.successColor),
                      const SizedBox(width: 4),
                      Text(
                        '$_completedSessions done',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successColor),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Timer progress bar + time display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(_remainingSeconds),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  color: _isRunning ? accentColor : null,
                ),
              ),
              Row(
                children: [
                  IconButton.filled(
                    onPressed: _toggleTimer,
                    icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Reset Timer',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: accentColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
