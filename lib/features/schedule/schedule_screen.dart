import 'package:flutter/material.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int selectedDateIndex = 0;
  final List<String> dates = ['Oct 1', 'Oct 2', 'Oct 3', 'Oct 4', 'Oct 5'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SCHEDULE')),
      body: Column(
        children: [
          // Date selector pills
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ChoiceChip(
                    label: Text(dates[index]),
                    selected: selectedDateIndex == index,
                    onSelected: (selected) {
                      setState(() {
                        selectedDateIndex = index;
                      });
                    },
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    labelStyle: TextStyle(
                      color: selectedDateIndex == index
                          ? Colors.white
                          : Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                );
              },
            ),
          ),
          // Vertical Timeline
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 10,
              itemBuilder: (context, index) {
                return IntrinsicHeight(
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: 2,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          child: ListTile(
                            title: Text('Event ${index + 1}'),
                            subtitle: const Text('10:00 AM - 11:30 AM'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
