-- ══════════════════════════════════════════════════════════════
-- TEST MESSAGING SYSTEM
-- ══════════════════════════════════════════════════════════════
-- Run these queries one by one to verify your messaging system
-- Replace <USER_ID> and <OTHER_USER_ID> with actual UUIDs
-- ══════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════════════════════
-- STEP 1: Verify Current User
-- ══════════════════════════════════════════════════════════════
SELECT 
  auth.uid() as current_user_id,
  auth.email() as current_user_email;

-- Expected: Should return your user ID and email
-- If NULL, you're not authenticated

-- ══════════════════════════════════════════════════════════════
-- STEP 2: Check Existing Policies
-- ══════════════════════════════════════════════════════════════
SELECT 
  tablename,
  policyname,
  cmd,
  CASE 
    WHEN cmd = 'SELECT' THEN 'Read'
    WHEN cmd = 'INSERT' THEN 'Create'
    WHEN cmd = 'UPDATE' THEN 'Update'
    WHEN cmd = 'DELETE' THEN 'Delete'
  END as operation
FROM pg_policies 
WHERE tablename IN ('conversations', 'conversation_members', 'messages')
ORDER BY tablename, cmd;

-- Expected: Should show 3 policies per table (SELECT, INSERT, UPDATE)
-- conversations: 3 policies
-- conversation_members: 3 policies  
-- messages: 3 policies

-- ══════════════════════════════════════════════════════════════
-- STEP 3: Check if View Exists
-- ══════════════════════════════════════════════════════════════
SELECT 
  schemaname,
  viewname,
  viewowner
FROM pg_views 
WHERE viewname = 'v_conversations_for_user';

-- Expected: Should return 1 row showing the view exists

-- ══════════════════════════════════════════════════════════════
-- STEP 4: Check if Trigger Exists
-- ══════════════════════════════════════════════════════════════
SELECT 
  tgname as trigger_name,
  tgtype,
  tgenabled as is_enabled,
  proname as function_name
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgname = 'trg_update_conversation';

-- Expected: Should show trigger is enabled (tgenabled = 'O')

-- ══════════════════════════════════════════════════════════════
-- STEP 5: Check if Functions Exist
-- ══════════════════════════════════════════════════════════════
SELECT 
  proname as function_name,
  pronargs as num_arguments,
  prorettype::regtype as return_type
FROM pg_proc
WHERE proname IN ('update_conversation_on_message', 'mark_conversation_read');

-- Expected: Should return 2 functions

-- ══════════════════════════════════════════════════════════════
-- STEP 6: List Your Existing Conversations
-- ══════════════════════════════════════════════════════════════
SELECT 
  c.id,
  c.name,
  c.is_group,
  c.last_message,
  c.created_at,
  c.updated_at,
  cm.unread_count,
  cm.role as my_role
FROM conversations c
JOIN conversation_members cm ON cm.conversation_id = c.id
WHERE cm.user_id = auth.uid()
ORDER BY c.updated_at DESC NULLS LAST;

-- Expected: List of all your conversations with metadata

-- ══════════════════════════════════════════════════════════════
-- STEP 7: Test View Query
-- ══════════════════════════════════════════════════════════════
SELECT * 
FROM v_conversations_for_user 
WHERE user_id = auth.uid()
ORDER BY updated_at DESC NULLS LAST;

-- Expected: Same as STEP 6 but using the view

-- ══════════════════════════════════════════════════════════════
-- STEP 8: Count Messages by Conversation
-- ══════════════════════════════════════════════════════════════
SELECT 
  c.name as conversation_name,
  COUNT(m.id) as message_count,
  MAX(m.created_at) as last_message_time
FROM conversations c
JOIN conversation_members cm ON cm.conversation_id = c.id
LEFT JOIN messages m ON m.conversation_id = c.id
WHERE cm.user_id = auth.uid()
GROUP BY c.id, c.name
ORDER BY last_message_time DESC NULLS LAST;

-- Expected: Message counts for each conversation

-- ══════════════════════════════════════════════════════════════
-- STEP 9: Check Unread Messages
-- ══════════════════════════════════════════════════════════════
SELECT 
  c.name as conversation_name,
  cm.unread_count,
  COUNT(CASE WHEN m.is_read = false AND m.sender_id != auth.uid() THEN 1 END) as actual_unread
FROM conversations c
JOIN conversation_members cm ON cm.conversation_id = c.id
LEFT JOIN messages m ON m.conversation_id = c.id
WHERE cm.user_id = auth.uid()
GROUP BY c.id, c.name, cm.unread_count
HAVING cm.unread_count > 0 OR COUNT(CASE WHEN m.is_read = false AND m.sender_id != auth.uid() THEN 1 END) > 0;

-- Expected: Conversations with unread messages

-- ══════════════════════════════════════════════════════════════
-- STEP 10: Test Creating a Conversation (OPTIONAL - MODIFY FIRST)
-- ══════════════════════════════════════════════════════════════
-- IMPORTANT: Replace <OTHER_USER_ID> with an actual user ID from your profiles table
-- Uncomment the lines below to test

/*
-- Get available users to message
SELECT id, first_name, last_name, email, role 
FROM profiles 
WHERE id != auth.uid()
LIMIT 10;

-- Create a test conversation (replace <OTHER_USER_ID>)
DO $$
DECLARE
  v_conversation_id UUID;
  v_other_user_id UUID := '<OTHER_USER_ID>'; -- REPLACE THIS
BEGIN
  -- Create conversation
  INSERT INTO conversations (name, is_group, created_by)
  VALUES ('Test Conversation', false, auth.uid())
  RETURNING id INTO v_conversation_id;
  
  -- Add members
  INSERT INTO conversation_members (conversation_id, user_id, role)
  VALUES 
    (v_conversation_id, auth.uid(), 'creator'),
    (v_conversation_id, v_other_user_id, 'member');
  
  -- Send a test message
  INSERT INTO messages (conversation_id, sender_id, content)
  VALUES (v_conversation_id, auth.uid(), 'Hello! This is a test message.');
  
  RAISE NOTICE 'Test conversation created with ID: %', v_conversation_id;
END $$;
*/

-- ══════════════════════════════════════════════════════════════
-- STEP 11: Test mark_conversation_read Function (OPTIONAL)
-- ══════════════════════════════════════════════════════════════
-- IMPORTANT: Replace <CONVERSATION_ID> with an actual conversation ID
-- Uncomment to test

/*
-- First, check current unread count
SELECT 
  c.name,
  cm.unread_count
FROM conversations c
JOIN conversation_members cm ON cm.conversation_id = c.id
WHERE cm.user_id = auth.uid()
  AND c.id = '<CONVERSATION_ID>'; -- REPLACE THIS

-- Mark as read
SELECT mark_conversation_read('<CONVERSATION_ID>', auth.uid()); -- REPLACE THIS

-- Check again - should be 0
SELECT 
  c.name,
  cm.unread_count
FROM conversations c
JOIN conversation_members cm ON cm.conversation_id = c.id
WHERE cm.user_id = auth.uid()
  AND c.id = '<CONVERSATION_ID>'; -- REPLACE THIS
*/

-- ══════════════════════════════════════════════════════════════
-- STEP 12: Check for Errors in Recent Operations
-- ══════════════════════════════════════════════════════════════
-- This requires log access - check your Supabase Dashboard → Logs

-- ══════════════════════════════════════════════════════════════
-- DIAGNOSTIC SUMMARY
-- ══════════════════════════════════════════════════════════════
SELECT 
  'Conversations' as table_name,
  COUNT(*) as total_rows,
  COUNT(DISTINCT created_by) as unique_creators
FROM conversations
UNION ALL
SELECT 
  'Conversation Members',
  COUNT(*),
  COUNT(DISTINCT user_id)
FROM conversation_members
UNION ALL
SELECT 
  'Messages',
  COUNT(*),
  COUNT(DISTINCT sender_id)
FROM messages;

-- Expected: Summary of your messaging data

-- ══════════════════════════════════════════════════════════════
-- END OF TESTS
-- ══════════════════════════════════════════════════════════════
-- If all tests pass, your messaging system is properly configured!
-- ══════════════════════════════════════════════════════════════
