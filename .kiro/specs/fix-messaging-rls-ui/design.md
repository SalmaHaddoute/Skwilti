# Design Document

## Overview

This design addresses a critical bug in the Skwilti messaging feature where authenticated users cannot create conversations due to missing Row-Level Security (RLS) policies on the `conversations` and `conversation_members` tables. The solution involves three components:

1. **SQL Migration**: Add RLS policies to allow authenticated users to create and read conversations
2. **Error Handling**: Improve `MessagingService` to catch RLS errors and display French error messages
3. **UI Polish**: Fix FAB clipping, add null-safety guards, animate empty state, and add navigation transitions

The design follows Flutter best practices for error handling and UI animations, and uses PostgreSQL RLS patterns for secure multi-tenant data access.

---

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     MessagesScreen (UI)                      │
│  - Displays conversation list                                │
│  - FAB for new conversations                                 │
│  - Null-safety guard for _currentUserId                      │
│  - Animated empty state                                      │
│  - Custom navigation transitions                             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              MessagingService (Business Logic)               │
│  - getOrCreateDirectConversation()                           │
│  - createConversation()                                      │
│  - Error handling for PostgrestException 42501               │
│  - Input validation for empty IDs                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Supabase Database (PostgreSQL)                  │
│  - conversations table with RLS policies                     │
│  - conversation_members table with RLS policies              │
│  - messages table (existing)                                 │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **User initiates conversation**: User taps FAB → opens contacts sheet → selects contact
2. **Service layer**: `MessagingService.getOrCreateDirectConversation()` is called
3. **Database check**: Query existing conversations between users
4. **Create if needed**: If no conversation exists, call `createConversation()`
5. **RLS enforcement**: PostgreSQL checks RLS policies before INSERT
6. **Error handling**: If 42501 error, catch and display French message
7. **Navigation**: On success, navigate to `ConversationScreen` with slide/fade transition

---

## Components and Interfaces

### 1. SQL Migration File

**File**: `database_migrations/fix_messaging_rls.sql`

**Purpose**: Add RLS policies to `conversations` and `conversation_members` tables

**Structure**:
```sql
-- Enable RLS on tables
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_members ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (idempotent)
DROP POLICY IF EXISTS "conversations_insert_policy" ON conversations;
DROP POLICY IF EXISTS "conversations_select_policy" ON conversations;
DROP POLICY IF EXISTS "conversation_members_insert_self_policy" ON conversation_members;
DROP POLICY IF EXISTS "conversation_members_insert_creator_policy" ON conversation_members;
DROP POLICY IF EXISTS "conversation_members_select_policy" ON conversation_members;

-- Create new policies
CREATE POLICY "conversations_insert_policy" ON conversations
  FOR INSERT TO authenticated
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "conversations_select_policy" ON conversations
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM conversation_members
      WHERE conversation_members.conversation_id = conversations.id
        AND conversation_members.user_id = auth.uid()
    )
  );

CREATE POLICY "conversation_members_insert_self_policy" ON conversation_members
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "conversation_members_insert_creator_policy" ON conversation_members
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM conversations
      WHERE conversations.id = conversation_members.conversation_id
        AND conversations.created_by = auth.uid()
    )
  );

CREATE POLICY "conversation_members_select_policy" ON conversation_members
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM conversation_members cm
      WHERE cm.conversation_id = conversation_members.conversation_id
        AND cm.user_id = auth.uid()
    )
  );
```

**Policy Explanation**:
- `conversations_insert_policy`: Users can only insert conversations where they are the creator
- `conversations_select_policy`: Users can only select conversations where they are a member
- `conversation_members_insert_self_policy`: Users can always add themselves to conversations
- `conversation_members_insert_creator_policy`: Conversation creators can add any user to their conversations
- `conversation_members_select_policy`: Users can only see membership records for conversations they belong to

### 2. MessagingService Error Handling

**File**: `lib/services/messaging_service.dart`

**Changes**:

#### Input Validation
```dart
Future<String> createConversation({
  String? name,
  bool isGroup = false,
  String? avatarUrl,
  required List<String> memberIds,
  required String creatorId,
}) async {
  // Validate creatorId is not empty
  if (creatorId.isEmpty) {
    throw ArgumentError('creatorId ne peut pas être vide');
  }
  
  // Existing implementation...
}

Future<String> getOrCreateDirectConversation(
  String currentUserId,
  String otherUserId,
) async {
  // Validate currentUserId is not empty
  if (currentUserId.isEmpty) {
    throw ArgumentError('currentUserId ne peut pas être vide');
  }
  
  try {
    // Existing implementation...
  } on PostgrestException catch (e) {
    // Handle RLS permission error
    if (e.code == '42501') {
      throw Exception(
        'Permissions insuffisantes pour créer une conversation. Contactez un administrateur.'
      );
    }
    rethrow;
  } catch (e) {
    print('[MessagingService] getOrCreateDirectConversation error: $e');
    rethrow;
  }
}
```

**Error Handling Strategy**:
- Validate inputs before making network calls (fail fast)
- Catch `PostgrestException` specifically for RLS errors
- Transform 42501 error code into user-friendly French message
- Rethrow all other exceptions unchanged
- Preserve existing debug logging

### 3. MessagesScreen UI Improvements

**File**: `lib/screens/messages_screen.dart`

#### 3.1 Null-Safety Guard

**Current Issue**: If `_currentUserId` is null, the app may crash when trying to load conversations or open contacts sheet.

**Solution**: Add early return with error widget when `_currentUserId` is null.

```dart
@override
Widget build(BuildContext context) {
  // Null-safety guard
  if (_currentUserId == null) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Messagerie',
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.alertCircle,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Session utilisateur introuvable. Veuillez vous reconnecter.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Normal build continues...
}
```

#### 3.2 FAB Visibility Fix

**Current Issue**: FAB may be clipped by bottom navigation bar or overlap last list item.

**Solution**:
1. Set `floatingActionButtonLocation` to `FloatingActionButtonLocation.endFloat`
2. Add bottom padding to conversation list

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(/* ... */),
    body: Column(/* ... */),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _openContactsBottomSheet,
      icon: const Icon(LucideIcons.messageSquare, size: 18),
      label: Text(
        'Nouveau message',
        style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
      ),
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
  );
}

Widget _buildConversationList(List<ConversationUIModel> list) {
  // Add bottom padding to prevent FAB overlap
  return RefreshIndicator(
    onRefresh: () => _loadConversations(silent: true),
    color: AppColors.primary,
    child: ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 80), // Bottom padding for FAB
      itemCount: list.length,
      // ...
    ),
  );
}
```

#### 3.3 Animated Empty State

**Current Issue**: Empty state appears abruptly without animation.

**Solution**: Wrap empty state in `AnimatedOpacity` with 600ms fade-in.

```dart
class _MessagesScreenState extends State<MessagesScreen> 
    with SingleTickerProviderStateMixin {
  // Add animation state
  bool _showEmptyState = false;
  
  @override
  void initState() {
    super.initState();
    // Existing initialization...
  }
  
  Future<void> _loadConversations({bool silent = false}) async {
    // Reset animation state
    setState(() => _showEmptyState = false);
    
    // Existing loading logic...
    
    if (mounted) {
      setState(() {
        _conversations = resolved;
        _filterConversations();
        _isLoading = false;
        // Trigger animation after data is loaded
        _showEmptyState = true;
      });
    }
  }
  
  void _filterConversations() {
    // Reset animation when filter changes
    setState(() => _showEmptyState = false);
    
    // Existing filter logic...
    
    // Trigger animation after filtering
    Future.microtask(() {
      if (mounted) {
        setState(() => _showEmptyState = true);
      }
    });
  }
  
  Widget _buildConversationList(List<ConversationUIModel> list) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadConversations(silent: true),
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            AnimatedOpacity(
              opacity: _showEmptyState ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Existing empty state content...
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Existing list rendering...
  }
}
```

#### 3.4 Slide/Fade Navigation Transition

**Current Issue**: Navigation to `ConversationScreen` uses default transition.

**Solution**: Use `PageRouteBuilder` with custom slide and fade transitions.

```dart
void _navigateToConversation(ConversationUIModel uiModel) {
  final resolvedConversation = Conversation(
    id: uiModel.conversation.id,
    name: uiModel.displayName,
    avatarUrl: uiModel.displayAvatar,
    isGroup: uiModel.conversation.isGroup,
    lastMessage: uiModel.conversation.lastMessage,
    updatedAt: uiModel.conversation.updatedAt,
    unreadCount: 0,
    memberRole: uiModel.conversation.memberRole,
    isOnline: uiModel.conversation.isOnline,
    createdAt: uiModel.conversation.createdAt,
  );

  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ConversationScreen(conversation: resolvedConversation),
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide from right to left
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        
        var slideTween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: curve));
        var slideAnimation = animation.drive(slideTween);
        
        // Fade in
        var fadeTween = Tween(begin: 0.0, end: 1.0);
        var fadeAnimation = animation.drive(fadeTween);
        
        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    ),
  ).then((_) => _loadConversations(silent: true));
}
```

---

## Data Models

### Existing Models (No Changes)

**Conversation Model** (`lib/models/conversation.dart`):
```dart
class Conversation {
  final String id;
  final String? name;
  final String? avatarUrl;
  final bool isGroup;
  final String? lastMessage;
  final DateTime? updatedAt;
  final int? unreadCount;
  final String? memberRole;
  final bool? isOnline;
  final DateTime createdAt;
  
  // Constructor and fromJson...
}
```

**MessageModel** (`lib/models/message.dart`):
```dart
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime createdAt;
  
  // Constructor and fromJson...
}
```

No changes to data models are required. The fix is purely at the database policy level and error handling level.

---

## Error Handling

### Error Categories

1. **RLS Permission Error (42501)**
   - **Cause**: Missing or incorrect RLS policies
   - **Handling**: Catch `PostgrestException` with code `42501`
   - **User Message**: "Permissions insuffisantes pour créer une conversation. Contactez un administrateur."
   - **Recovery**: User should contact administrator to fix RLS policies

2. **Empty Input Error**
   - **Cause**: `creatorId` or `currentUserId` is empty string
   - **Handling**: Throw `ArgumentError` before network call
   - **User Message**: "creatorId ne peut pas être vide" or "currentUserId ne peut pas être vide"
   - **Recovery**: This is a programming error, should not happen in production

3. **Null User Session Error**
   - **Cause**: User session expired or not initialized
   - **Handling**: Display error widget in UI
   - **User Message**: "Session utilisateur introuvable. Veuillez vous reconnecter."
   - **Recovery**: User should log out and log back in

4. **Network/Database Errors**
   - **Cause**: Network timeout, database unavailable, etc.
   - **Handling**: Rethrow original exception, display generic error in UI
   - **User Message**: "Impossible d'ouvrir la conversation: [error]"
   - **Recovery**: User can retry

### Error Flow Diagram

```
User Action (Create Conversation)
        │
        ▼
Input Validation
        │
        ├─ Empty ID? ──► ArgumentError ──► Developer Fix
        │
        ▼
Database Query
        │
        ├─ 42501 Error? ──► French Message ──► Contact Admin
        │
        ├─ Network Error? ──► Generic Error ──► Retry
        │
        ▼
Success ──► Navigate to Conversation
```

---

## Testing Strategy

This is a bug fix with UI improvements. Testing will focus on:

### Unit Tests

1. **MessagingService Input Validation**
   - Test `createConversation` throws `ArgumentError` when `creatorId` is empty
   - Test `getOrCreateDirectConversation` throws `ArgumentError` when `currentUserId` is empty

2. **MessagingService Error Handling**
   - Test `getOrCreateDirectConversation` catches `PostgrestException` with code `42501`
   - Test French error message is thrown for 42501 errors
   - Test other exceptions are rethrown unchanged

### Integration Tests

1. **RLS Policy Verification**
   - Test authenticated user can create conversation where `created_by = auth.uid()`
   - Test authenticated user can read conversations where they are a member
   - Test authenticated user can add themselves to conversations
   - Test conversation creator can add other users to their conversations
   - Test user cannot create conversation with `created_by != auth.uid()` (should fail with 42501)
   - Test user cannot read conversations where they are not a member

2. **End-to-End Conversation Creation**
   - Test user can select contact and create new conversation
   - Test existing conversation is returned when it already exists
   - Test error message is displayed when RLS fails

### UI Tests

1. **Null-Safety Guard**
   - Test error widget is displayed when `_currentUserId` is null
   - Test FAB is not rendered when `_currentUserId` is null

2. **FAB Visibility**
   - Test FAB is positioned at `FloatingActionButtonLocation.endFloat`
   - Test conversation list has bottom padding of 80px
   - Test last list item is not obscured by FAB

3. **Animated Empty State**
   - Test empty state fades in with 600ms duration
   - Test animation resets when search query changes

4. **Navigation Transition**
   - Test slide transition moves from right to left
   - Test fade transition occurs simultaneously
   - Test transition duration is 300ms

### Manual Testing Checklist

- [ ] Apply SQL migration to Supabase project
- [ ] Verify RLS is enabled on both tables
- [ ] Create new conversation as authenticated user
- [ ] Verify conversation appears in list
- [ ] Test with expired session (null user ID)
- [ ] Test FAB visibility on different screen sizes
- [ ] Test empty state animation
- [ ] Test navigation transition smoothness
- [ ] Test error message when RLS fails (temporarily disable policies)

---

## Deployment Notes

### Migration Application

1. **Backup Database**: Always backup before applying migrations
2. **Apply Migration**: Run `fix_messaging_rls.sql` against Supabase project
3. **Verify Policies**: Check that all 5 policies are created
4. **Test in Staging**: Test conversation creation in staging environment first
5. **Monitor Logs**: Watch for 42501 errors after deployment

### Rollback Plan

If issues occur after deployment:

1. **Disable RLS**: `ALTER TABLE conversations DISABLE ROW LEVEL SECURITY;`
2. **Disable RLS**: `ALTER TABLE conversation_members DISABLE ROW LEVEL SECURITY;`
3. **Investigate**: Check logs for specific policy failures
4. **Fix Policies**: Adjust policies as needed
5. **Re-enable RLS**: Re-enable after fixes are verified

### Performance Considerations

- RLS policies add overhead to every query
- The `EXISTS` subqueries in SELECT policies may impact performance on large datasets
- Consider adding indexes on `conversation_members(conversation_id, user_id)` if not already present
- Monitor query performance after deployment

---

## Future Improvements

1. **Policy Optimization**: Consider materialized views for conversation membership to reduce subquery overhead
2. **Caching**: Cache conversation list in local storage to reduce database queries
3. **Offline Support**: Add offline queue for conversation creation when network is unavailable
4. **Error Telemetry**: Add error tracking (e.g., Sentry) to monitor RLS failures in production
5. **Admin Dashboard**: Build admin interface to manage RLS policies without SQL
6. **Batch Operations**: Optimize `getOrCreateDirectConversation` to reduce round trips
