# Username/password authentication

- `POST /auth/password` accepts `{ "username": "name", "password": "..." }` and returns the existing `{ access, refresh, userId }` session contract. An unused username creates an account; an existing username requires its existing password credential. Google-only accounts must sign in through Google before setting a password.
- `PUT /users/me/password` requires authentication and accepts `{ "currentPassword": "...", "newPassword": "..." }`. Omit `currentPassword` only when adding the first password. Returns 204.
- `GET /users/me` and `PATCH /users/me` include `hasPassword`.

Usernames are case-sensitive, 1–128 UTF-16 code units, with no surrounding whitespace or control characters. Email-shaped usernames are literal usernames; no email identity/linking is inferred. Renaming changes the username used for subsequent sign-ins. Because registration and login are combined, entering an unused name creates a separate account.

Passwords must contain at least 6 UTF-16 code units, with no upper length limit or character-composition requirements. Passwords are not trimmed. `UserLogin.PasswordHash` contains the ASP.NET IdentityV3 encoded PBKDF2 hash, including salt and parameters (210,000 iterations). `UsernamePassword = 3`, `ProviderId = null`; provider JSON does not contain credentials. Database constraints prevent duplicate local credentials and invalid provider/hash combinations.

Password endpoints allow 10 requests/minute: login by remote IP, password changes by authenticated user ID. Forwarded IP headers are not trusted; behind a proxy the login bucket is shared by clients with the same observed proxy IP. Password changes do not revoke existing sessions in this version.

The migration applies on backend startup. Rollback refuses to erase existing password credentials. No Firebase password authentication, email verification/recovery, or Telegram linking is introduced.
