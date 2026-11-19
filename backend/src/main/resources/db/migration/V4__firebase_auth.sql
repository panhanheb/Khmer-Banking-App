-- Authentication moves to Firebase Authentication.
-- The API now trusts Firebase ID tokens; users are provisioned on their first
-- authenticated request and keyed by the Firebase UID.

ALTER TABLE users ADD COLUMN firebase_uid VARCHAR(128) UNIQUE;

-- Passwords, login lockout and SMS codes are handled by Firebase.
ALTER TABLE users DROP COLUMN password_hash;
ALTER TABLE users DROP COLUMN failed_login_attempts;
ALTER TABLE users DROP COLUMN locked_until;
ALTER TABLE users DROP COLUMN password_changed_at;

-- A Firebase user may not have linked a phone number yet.
ALTER TABLE users ALTER COLUMN phone DROP NOT NULL;

DROP TABLE refresh_tokens;
DROP TABLE otp_challenges;
