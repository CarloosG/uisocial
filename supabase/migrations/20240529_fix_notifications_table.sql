-- Drop existing table if exists
DROP TABLE IF EXISTS notifications;

-- Create notifications table with proper structure
CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type text NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  event_id uuid REFERENCES events(id) ON DELETE CASCADE,
  is_read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Add notification type constraint
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS valid_notification_type;
ALTER TABLE notifications ADD CONSTRAINT valid_notification_type 
  CHECK (type IN ('event_created', 'friend_request', 'friend_accepted')); 