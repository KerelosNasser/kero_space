import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/productivity_bloc.dart';
import '../widgets/daily_checklist.dart';
import '../widgets/task_tree_view.dart';
import '../../data/repositories/productivity_repository.dart';

class ProductivityScreen extends StatelessWidget {
  const ProductivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductivityBloc(ProductivityRepository())..add(const ProductivityEvent.loadData()),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Productivity'),
            bottom: const TabBar(
              tabs: [
                Tab(text: "Today"),
                Tab(text: "Projects"),
                Tab(text: "Notes"),
              ],
            ),
          ),
          body: BlocBuilder<ProductivityBloc, ProductivityState>(
            builder: (context, state) {
              return state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (msg) => Center(child: Text("Error: \$msg")),
                loaded: (allTasks, dailyChecklist, allNotes) {
                  return TabBarView(
                    children: [
                      // Tab 1: Today's Checklist
                      DailyChecklist(tasks: dailyChecklist),
                      
                      // Tab 2: Projects Tree View
                      TaskTreeView(allTasks: allTasks),
                      
                      // Tab 3: Notes
                      ListView.builder(
                        itemCount: allNotes.length,
                        itemBuilder: (context, index) {
                          final note = allNotes[index];
                          return ListTile(
                            title: Text(note.title),
                            onTap: () => context.push('/note_editor', extra: note),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // Simple create action depending on current tab context
              // For demo purposes, we will just navigate to note creation for now
              context.push('/note_editor');
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
