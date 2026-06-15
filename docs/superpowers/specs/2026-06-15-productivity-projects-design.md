# Projects Hub Redesign & Conversational AI - Design Spec

## UX Audit (StyleSeed Toss Guidelines)
1. **System Status**: Current AI generation shows a tiny spinner in the text field. It lacks personality and clear state communication.
2. **User Control**: Users cannot edit generated tasks, only delete or complete them. Missing inline editing.
3. **Aesthetics**: The bottom sheet and grid cards are generic. They lack the premium Toss-like glassmorphism, micro-animations, and typographic hierarchy.

## Multi-Agent Brainstorming Log
- **Primary Designer**: Propose a chat-like interface for the AI project generation and a Toss-style bottom sheet with inline editing.
- **Skeptic**: Building a stateful chat UI inside a text field is over-engineered. What if the user navigates away?
- **Constraint Guardian**: Keep the AI interaction stateless to avoid complex database changes for chat history. Pass context in a single payload.
- **User Advocate**: Users want speed. The AI should only ask clarifying questions if the prompt is extremely vague (e.g., "Build an app"). If it's "Plan a trip to Japan", it should just work. Inline editing must have clear visual cues.
- **Arbiter Decision**: We will use a stateless popup dialog for AI clarifications. The AI prompt will be strictly instructed to default to generation unless the task is completely ambiguous.

## Proposed Architecture
### 1. Conversational AI Flow
- User types prompt in the Project creation field.
- `AIService` sends prompt. AI returns either `{"type": "clarification", "question": "..."}` or `{"type": "plan", ...}`.
- If clarification: UI shows a beautifully animated Toss-style modal dialog with the question and a text input. User answers, UI sends `Original Prompt + Question + Answer` back to AI.
- If plan: Project is created with a specific Icon/Emoji returned by the AI.

### 2. UI/UX Upgrades (Toss-Style)
- **Project Cards**: Add smooth scale-on-tap animations, use the AI-generated emoji as a prominent header icon, use AppTheme tokens for subtle gradients.
- **Bottom Sheet**: Implement a drag-handle, large bold typography for the title, and a glassmorphic background.
- **Task CRUD**: Tapping a task text in the bottom sheet morphs it into a `TextField` for inline editing (auto-saves on focus lost or submit).

## Data Schema Changes
- `Task` model: Add `String? icon;` (requires `build_runner` migration).
