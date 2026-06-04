# Requirements Document

## Introduction

The messaging feature in the Skwilti Flutter app crashes when an authenticated user attempts to start a new direct conversation. The root cause is missing Row-Level Security (RLS) policies on the `conversations` and `conversation_members` Supabase tables, which blocks all INSERT operations with a `42501` Forbidden error. This feature addresses three concerns: (1) adding the correct SQL RLS policies as a migration file, (2) improving error handling in `MessagingService` so failures surface as clear French-language messages, and (3) polishing the `MessagesScreen` UI to fix a clipped FAB, add a null-safety guard, animate the empty state, and add a slide/fade transition when opening a conversation.

## Glossary

- **RLS**: Row-Level Security — a Supabase/PostgreSQL feature that restricts which rows a user can read or write based on policies.
- **MessagingService**: The Dart service class at `lib/services/messaging_service.dart` that wraps all Supabase messaging calls.
- **MessagesScreen**: The Flutter screen at `lib/screens/messages_screen.dart` that lists conversations and provides the entry point for new messages.
- **ConversationScreen**: The Flutter screen at `lib/screens/conversation_screen.dart` that shows the message thread for a single conversation.
- **Migration_File**: The SQL file at `supabase/migrations/fix_messaging_rls.sql` that contains the RLS policy definitions.
- **FAB**: Floating Action Button — the "Nouveau message" button rendered by `FloatingActionButton.extended` in `MessagesScreen`.
- **auth.uid()**: The Supabase SQL function that returns the UUID of the currently authenticated user.
- **PostgrestException**: The Dart exception type thrown by `supabase_flutter` when a Supabase query fails, carrying a `code` field.

---

## Requirements

### Requirement 1: RLS Migration — conversations table

**User Story:** As a developer, I want correct RLS policies on the `conversations` table, so that authenticated users can create and read their own conversations without receiving a Forbidden error.

#### Acceptance Criteria

1. THE Migration_File SHALL contain a `CREATE POLICY` statement that allows authenticated users to INSERT rows into `conversations` where `created_by = auth.uid()`.
2. THE Migration_File SHALL contain a `CREATE POLICY` statement that allows authenticated users to SELECT rows from `conversations` where the user is a member of that conversation (i.e., a matching row exists in `conversation_members` with `user_id = auth.uid()`).
3. WHEN the Migration_File is applied to a Supabase project, THE Migration_File SHALL enable RLS on the `conversations` table if it is not already enabled.
4. IF a policy with the same name already exists, THEN THE Migration_File SHALL use `DROP POLICY IF EXISTS` before each `CREATE POLICY` to ensure idempotent application.

---

### Requirement 2: RLS Migration — conversation_members table

**User Story:** As a developer, I want correct RLS policies on the `conversation_members` table, so that authenticated users can add themselves and others to conversations they create, and read membership records for their own conversations.

#### Acceptance Criteria

1. THE Migration_File SHALL contain a `CREATE POLICY` statement that allows authenticated users to INSERT rows into `conversation_members` where `user_id = auth.uid()`.
2. THE Migration_File SHALL contain a `CREATE POLICY` statement that allows authenticated users to INSERT rows into `conversation_members` for any user, provided the conversation was created by `auth.uid()` (i.e., a matching row exists in `conversations` with `created_by = auth.uid()`).
3. THE Migration_File SHALL contain a `CREATE POLICY` statement that allows authenticated users to SELECT rows from `conversation_members` where the conversation belongs to the user (i.e., a matching row exists in `conversation_members` with `user_id = auth.uid()` for the same `conversation_id`).
4. WHEN the Migration_File is applied to a Supabase project, THE Migration_File SHALL enable RLS on the `conversation_members` table if it is not already enabled.
5. IF a policy with the same name already exists, THEN THE Migration_File SHALL use `DROP POLICY IF EXISTS` before each `CREATE POLICY` to ensure idempotent application.

---

### Requirement 3: MessagingService — RLS error handling

**User Story:** As a user, I want to see a clear French error message when a conversation cannot be created due to a permissions issue, so that I understand what went wrong instead of seeing a raw exception.

#### Acceptance Criteria

1. WHEN `getOrCreateDirectConversation` catches a `PostgrestException` with `code == '42501'`, THE MessagingService SHALL throw an `Exception` with the French message `'Permissions insuffisantes pour créer une conversation. Contactez un administrateur.'`.
2. WHEN `getOrCreateDirectConversation` catches any other exception, THE MessagingService SHALL rethrow the original exception unchanged.
3. WHEN `createConversation` is called with a `creatorId` that is an empty string, THE MessagingService SHALL throw an `ArgumentError` with the message `'creatorId ne peut pas être vide'` before making any network call.
4. WHEN `getOrCreateDirectConversation` is called with a `currentUserId` that is an empty string, THE MessagingService SHALL throw an `ArgumentError` with the message `'currentUserId ne peut pas être vide'` before making any network call.

---

### Requirement 4: MessagesScreen — null-safety guard for current user

**User Story:** As a user, I want the messaging screen to display a clear error state instead of crashing when my session is not available, so that the app remains stable.

#### Acceptance Criteria

1. WHEN `_currentUserId` is null at build time, THE MessagesScreen SHALL display an error widget containing the French text `'Session utilisateur introuvable. Veuillez vous reconnecter.'` instead of the normal conversation list.
2. WHEN `_currentUserId` is null, THE MessagesScreen SHALL NOT render the FAB.
3. WHEN `_currentUserId` is null and the user taps the FAB (if somehow visible), THE MessagesScreen SHALL NOT call `_openContactsBottomSheet`.

---

### Requirement 5: MessagesScreen — FAB visibility fix

**User Story:** As a user, I want the "Nouveau message" FAB to be fully visible and not clipped by the bottom navigation bar, so that I can always tap it to start a new conversation.

#### Acceptance Criteria

1. THE MessagesScreen SHALL set `floatingActionButtonLocation` to `FloatingActionButtonLocation.endFloat` on the `Scaffold`.
2. THE MessagesScreen SHALL add bottom padding to the conversation list so that the last item is not obscured by the FAB.
3. WHILE the conversation list is scrolled to the bottom, THE MessagesScreen SHALL ensure the FAB does not overlap the last visible list item.

---

### Requirement 6: MessagesScreen — animated empty state

**User Story:** As a user, I want the empty-state illustration to appear with a subtle fade-in animation, so that the transition feels polished rather than abrupt.

#### Acceptance Criteria

1. WHEN the conversation list is empty and loading has completed, THE MessagesScreen SHALL display the empty-state widget wrapped in an `AnimatedOpacity` that transitions from opacity `0.0` to `1.0`.
2. THE MessagesScreen SHALL use an animation duration of 600 milliseconds for the empty-state fade-in.
3. WHEN the search query changes and the filtered list becomes empty, THE MessagesScreen SHALL re-trigger the fade-in animation.

---

### Requirement 7: MessagesScreen — slide/fade navigation transition

**User Story:** As a user, I want a smooth slide-and-fade transition when I open a conversation, so that the navigation feels fluid and consistent with the app's design language.

#### Acceptance Criteria

1. WHEN a user taps a conversation item, THE MessagesScreen SHALL navigate to `ConversationScreen` using a custom `PageRouteBuilder` that combines a slide transition (from right to left) with a fade transition.
2. THE MessagesScreen SHALL use a transition duration of 300 milliseconds for the slide/fade animation.
3. WHEN the user navigates back from `ConversationScreen`, THE MessagesScreen SHALL silently refresh the conversation list.
