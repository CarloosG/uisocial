-- Add visibility field to notifications table
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS visibility text;

-- Update the visibility field for existing event notifications
UPDATE notifications 
SET visibility = (
  SELECT visibility 
  FROM events 
  WHERE events.id = notifications.event_id
)
WHERE type = 'event_created' AND event_id IS NOT NULL; 