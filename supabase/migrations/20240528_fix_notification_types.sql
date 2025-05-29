-- Fix notification types constraint
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS valid_notification_type;
ALTER TABLE notifications ADD CONSTRAINT valid_notification_type CHECK (type IN ('event_created', 'friend_request', 'friend_accepted')); 