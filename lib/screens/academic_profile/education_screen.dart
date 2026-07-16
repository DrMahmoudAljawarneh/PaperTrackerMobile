import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_state.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_bloc.dart';
import 'package:paper_tracker/widgets/academic/timeline_widget.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Education')),
      body: BlocBuilder<AcademicProfileBloc, AcademicProfileState>(
        builder: (context, state) {
          if (state is! AcademicProfileLoaded) {
            return const Center(child: Text('No data'));
          }

          final entries = state.record.educations.map((e) {
            final parts = [
              if (e.city.isNotEmpty) e.city,
              if (e.country.isNotEmpty) e.country,
            ];
            return TimelineEntry(
              title: e.organizationName,
              subtitle: e.roleTitle,
              description: e.departmentName.isNotEmpty
                  ? '${e.departmentName}\n${parts.join(', ')}'
                  : parts.join(', '),
              startDate: e.startDate,
              endDate: e.endDate,
              icon: Icons.school,
              color: const Color(0xFFE65100),
            );
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TimelineWidget(entries: entries),
            ],
          );
        },
      ),
    );
  }
}
