import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_state.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/widgets/empty_state.dart';
import 'package:paper_tracker/widgets/status_badge.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deadline Calendar'),
      ),
      body: BlocBuilder<PaperBloc, PaperState>(
        builder: (context, state) {
          if (state is! PapersLoaded) {
            return const EmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'No papers loaded',
            );
          }

          final papers = state.papers;
          final deadlines = papers
              .where((p) => p.deadline != null)
              .toList();

          final deadlineDates = deadlines
              .map((p) => DateTime(p.deadline!.year, p.deadline!.month, p.deadline!.day))
              .toSet();

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 730)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) => setState(() => _calendarFormat = format),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                eventLoader: (day) {
                  return deadlineDates.contains(day) ? [day] : [];
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;
                    final dayPapers = deadlines.where((p) =>
                        p.deadline!.year == date.year &&
                        p.deadline!.month == date.month &&
                        p.deadline!.day == date.day);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: dayPapers.map((p) {
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.priorityColor(p.priority),
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    );
                  },
                  todayBuilder: (context, date, _) {
                    return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                  selectedBuilder: (context, date, _) {
                    return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${date.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  markerDecoration: const BoxDecoration(),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.event, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMMM d, yyyy').format(_selectedDay),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildDayPapers(deadlines),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDayPapers(List<Paper> allDeadlines) {
    final dayPapers = allDeadlines.where((p) {
      final d = p.deadline!;
      return d.year == _selectedDay.year &&
          d.month == _selectedDay.month &&
          d.day == _selectedDay.day;
    }).toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));

    if (dayPapers.isEmpty) {
      return const EmptyState(
        icon: Icons.event_busy,
        title: 'No deadlines',
        subtitle: 'No papers have deadlines on this day',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: dayPapers.length,
      itemBuilder: (context, index) {
        final paper = dayPapers[index];
        return _buildPaperDeadlineItem(paper);
      },
    );
  }

  Widget _buildPaperDeadlineItem(Paper paper) {
    final priorityColor = AppTheme.priorityColor(paper.priority);
    final daysUntil = paper.deadline!.difference(DateTime.now()).inDays;

    return GestureDetector(
      onTap: () => context.push('/papers/${paper.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: priorityColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paper.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          paper.priority.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: priorityColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: paper.status),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('MMM d').format(paper.deadline!),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: daysUntil <= 3 ? AppTheme.errorColor : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                if (daysUntil >= 0)
                  Text(
                    daysUntil == 0 ? 'Today' : '${daysUntil}d left',
                    style: TextStyle(
                      fontSize: 10,
                      color: daysUntil <= 3 ? AppTheme.errorColor : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  )
                else
                  Text(
                    '${-daysUntil}d overdue',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
