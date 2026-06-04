-- ══════════════════════════════════════════════════════════════
-- FIX MESSAGING SYSTEM - Complete Migration
-- ══════════════════════════════════════════════════════════════
-- This migration fixes all RLS policies and ensures proper data flow
-- ══════════════════════════════════════════════════════════════

-- 1. Drop all existing policies to start fresh
-- ══════════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "conv_select" ON conversations;
DROP POLICY IF EXISTS "conv_insert" ON conversations;
DROP POLICY IF EXISTS "conv_update" ON conversations;
DROP POLICY IF EXISTS "conversations_select" ON conversations;
DROP POLICY IF EXISTS "conversations_insert" ON conversations;
DROP POLICY IF EXISTS "conversations_update" ON conversations;
DROP POLICY IF EXISTS "allow_insert_conversations" ON conversations;

DROP POLICY IF EXISTS "cm_select" ON conversation_members;
DROP POLICY IF EXISTS "cm_insert" ON conversation_members;
DROP POLICY IF EXISTS "conv_members_select" ON conversation_members;
DROP POLICY IF EXISTS "conv_members_insert" ON conversation_members;
DROP POLICY IF EXISTS "allow_insert_conversation_members_by_creator" ON conversation_members;

DROP POLICY IF EXISTS "msg_select" ON messages;
DROP POLICY IF EXISTS "msg_insert" ON messages;
DROP POLICY IF EXISTS "msg_update" ON messages;
DROP POLICY IF EXISTS "messages_select" ON messages;
DROP POLICY IF EXISTS "messages_insert" ON messages;
DROP POLICY IF EXISTS "messages_update" ON messages;

-- 2. Ensure RLS is enabled
-- ══════════════════════════════════════════════════════════════
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- 3. CONVERSATIONS policies
-- ══════════════════════════════════════════════════════════════

-- SELECT: User can see conversations they are a member of
CREATE POLICY "conversations_select_policy"
ON conversations FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM conversation_members cm
    WHERE cm.conversation_id = conversations.id
    AND cm.user_id = auth.uid()
  )
);

-- INSERT: Any authenticated user can create a conversation
-- The created_by field will be set to their user ID
CREATE POLICY "conversations_insert_policy"
ON conversations FOR INSERT
TO authenticated
WITH CHECK (
  created_by = auth.uid()
);

-- UPDATE: Only the creator can update conversation metadata
CREATE POLICY "conversations_update_policy"
ON conversations FOR UPDATE
TO authenticated
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

-- 4. CONVERSATION_MEMBERS policies
-- ══════════════════════════════════════════════════════════════

-- SELECT: Users can see all members of conversations they belong to
CREATE POLICY "conversation_members_select_policy"
ON conversation_members FOR SELECT
TO authenticated
USING (
  -- Can see members of conversations where user is also a member
  conversation_id IN (
    SELECT conversation_id 
    FROM conversation_members 
    WHERE user_id = auth.uid()
  )
);

-- INSERT: Conversation creator can add members
CREATE POLICY "conversation_members_insert_policy"
ON conversation_members FOR INSERT
TO authenticated
WITH CHECK (
  -- Either the user is adding themselves, or they are the conversation creator
  user_id = auth.uid()
  OR
  EXISTS (
    SELECT 1 FROM conversations c
    WHERE c.id = conversation_id
    AND c.created_by = auth.uid()
  )
);

-- UPDATE: Users can update their own membership settings (like unread_count, is_muted)
CREATE POLICY "conversation_members_update_policy"
ON conversation_members FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 5. MESSAGES policies
-- ══════════════════════════════════════════════════════════════

-- SELECT: Users can see messages in conversations they are members of
CREATE POLICY "messages_select_policy"
ON messages FOR SELECT
TO authenticated
USING (
  conversation_id IN (
    SELECT conversation_id 
    FROM conversation_members 
    WHERE user_id = auth.uid()
  )
);

-- INSERT: Users can send messages to conversations they are members of
CREATE POLICY "messages_insert_policy"
ON messages FOR INSERT
TO authenticated
WITH CHECK (
  sender_id = auth.uid()
  AND
  conversation_id IN (
    SELECT conversation_id 
    FROM conversation_members 
    WHERE user_id = auth.uid()
  )
);

-- UPDATE: Users can update messages in their conversations (for read receipts)
CREATE POLICY "messages_update_policy"
ON messages FOR UPDATE
TO authenticated
USING (
  conversation_id IN (
    SELECT conversation_id 
    FROM conversation_members 
    WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  conversation_id IN (
    SELECT conversation_id 
    FROM conversation_members 
    WHERE user_id = auth.uid()
  )
);

-- 6. Ensure created_by has a default value
-- ══════════════════════════════════════════════════════════════
ALTER TABLE conversations 
ALTER COLUMN created_by SET DEFAULT auth.uid();

-- 7. Recreate the view with proper structure
-- ══════════════════════════════════════════════════════════════
DROP VIEW IF EXISTS v_conversations_for_user;

CREATE VIEW v_conversations_for_user AS
SELECT
  c.id,
  c.name,
  c.avatar_url,
  c.is_group,
  c.last_message,
  c.updated_at,
  c.created_at,
  cm.user_id,
  cm.unread_count,
  cm.role AS member_role,
  cm.is_muted
FROM conversations c
INNER JOIN conversation_members cm ON cm.conversation_id = c.id;

-- 8. Ensure the trigger function exists and is correct
-- ══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION update_conversation_on_message()
RETURNS TRIGGER AS $$
BEGIN
  -- Update conversation's last_message and updated_at
  UPDATE conversations
  SET 
    last_message = NEW.content,
    updated_at = NOW()
  WHERE id = NEW.conversation_id;

  -- Increment unread_count for all members except the sender
  UPDATE conversation_members
  SET unread_count = unread_count + 1
  WHERE conversation_id = NEW.conversation_id
    AND user_id != NEW.sender_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
DROP TRIGGER IF EXISTS trg_update_conversation ON messages;
CREATE TRIGGER trg_update_conversation
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_on_message();

-- 9. Ensure mark_conversation_read function exists
-- ══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION mark_conversation_read(
  p_conversation_id UUID,
  p_user_id UUID
) 
RETURNS void AS $$
BEGIN
  -- Reset unread count for the user
  UPDATE conversation_members
  SET unread_count = 0
  WHERE conversation_id = p_conversation_id
    AND user_id = p_user_id;

  -- Mark messages as read
  UPDATE messages
  SET is_read = true
  WHERE conversation_id = p_conversation_id
    AND sender_id != p_user_id
    AND is_read = false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Grant necessary permissions
-- ══════════════════════════════════════════════════════════════
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON conversations TO authenticated;
GRANT ALL ON conversation_members TO authenticated;
GRANT ALL ON messages TO authenticated;
GRANT SELECT ON v_conversations_for_user TO authenticated;

-- 11. Create indexes for better performance (if not exists)
-- ══════════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_conv_members_user_id ON conversation_members(user_id);
CREATE INDEX IF NOT EXISTS idx_conv_members_conversation_id ON conversation_members(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversations_created_by ON conversations(created_by);
CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON conversations(updated_at DESC);

-- ══════════════════════════════════════════════════════════════
-- VERIFICATION QUERIES (Run these to test)
-- ══════════════════════════════════════════════════════════════

-- Test 1: Check if policies are created
-- SELECT schemaname, tablename, policyname, cmd 
-- FROM pg_policies 
-- WHERE tablename IN ('conversations', 'conversation_members', 'messages')
-- ORDER BY tablename, policyname;

-- Test 2: Check if view works
-- SELECT * FROM v_conversations_for_user WHERE user_id = auth.uid();

-- Test 3: Check if trigger exists
-- SELECT tgname, tgtype, tgenabled 
-- FROM pg_trigger 
-- WHERE tgname = 'trg_update_conversation';

-- ══════════════════════════════════════════════════════════════
-- END OF MIGRATION
-- ══════════════════════════════════════════════════════════════
