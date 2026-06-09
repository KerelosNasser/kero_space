# Phase 3A: Tasks, Notes, and ProductivityBloc Design Spec

## Overview
This specification covers Sub-Phase 3A of the Kero Space project. It implements the core productivity module, including a 3-level hierarchical task tree, daily carry-forward checklist logic, and standalone/linked rich-text notes.

## Architecture

### Isar Data Schema

We use a flat collection architecture to ensure maximum query performance for daily aggregates.

#### Task Collection
```dart
@Collection()
class Task {
  Id id = Isar.autoIncrement;
  late String title;
  String? description;
  DateTime? dueDate;
  bool isCompleted = false;
  
  @Enumerated(EnumType.name)
  late TaskType type; // PROJECT, TASK, SUBTASK
  
  int? parentId; // Links to another Task ID (null for Projects)
  int? linkedNoteId; // Links to a Note ID
  
  @Index()
  late DateTime updatedAt;
}
```

#### Note Collection
```dart
@Collection()
class Note {
  Id id = Isar.autoIncrement;
  late String title;
  late String quillDelta; // JSON string of flutter_quill state
  
  @Index()
  late DateTime updatedAt;
  late DateTime createdAt;
}
```

## State Management (`ProductivityBloc`)

The `ProductivityBloc` manages the entire productivity state by listening to Isar streams.

- **States:** 
  - `ProductivityLoading`
  - `ProductivityLoaded(List<Task> tree, List<Task> dailyChecklist, List<Note> standaloneNotes)`
  - `ProductivityError`
  
- **Events:** 
  - `LoadProductivityData`
  - `CreateTask(Task)`
  - `UpdateTask(Task)`
  - `CompleteTask(int id)` (Recursively completes sub-entities if completing a Project/Task)
  - `CreateNote(Note, {int? linkedTaskId})`
  - `UpdateNote(Note)`

- **Carry-Forward Logic:** 
  Upon initialization, the BLoC queries for tasks where `isCompleted == false` and `dueDate < DateTime.now().startOfDay`. It executes a transaction to update these tasks to `dueDate = DateTime.now()`.

## UI Components

1. **Task Tree View:**
   Uses `flutter_fancy_tree_view` to render the 3-level depth (Project -> Task -> Subtask). Displays hierarchical lines and allows collapsing/expanding of nodes.
2. **Daily Checklist:**
   A focused list view rendering only items due today. Incorporates visual cues (ADHD focus features to be added in Phase 3C).
3. **Rich Text Note Editor:**
   Uses `flutter_quill` to provide standard rich-text formatting (bold, italic, headers, lists). Provides a link button to optionally attach the note to an existing Task.

## Error Handling & Edge Cases
- **Database Exceptions:** Caught within the repository and emitted as `ProductivityError` state. Handled globally by the error snackbar mechanism.
- **Recursive Deletion/Completion:** Deleting or completing a `Project` must recursively query and update all child `Tasks` and `Subtasks` to prevent orphaned nodes.
- **Depth Constraints:** The UI will prevent assigning a `Subtask` as the parent of a new task to enforce the strict 3-level depth constraint.

## Testing Strategy
- **Unit Tests:** Mock Isar storage to verify the carry-forward query logic accurately mutates dates without altering completed tasks.
- **BLoC Tests:** Verify `CompleteTask` event propagates downward through the tree.
- **Widget Tests:** Verify `flutter_fancy_tree_view` expands properly and `flutter_quill` editor saves content back to the BLoC.
