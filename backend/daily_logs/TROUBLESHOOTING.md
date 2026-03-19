# Daily Logs - Troubleshooting Authentication

## Issue: 401 Unauthorized Error

The 401 error indicates that the JWT authentication token is either:
- Missing
- Invalid
- Expired

## Quick Fixes

### 1. Ensure You're Logged In

Make sure you're logged into the app before trying to save a daily log. The JWT token is obtained during login.

### 2. Check Token in Secure Storage

The token should be stored in Flutter Secure Storage with key `"access"`.

### 3. Test Authentication with cURL

```bash
# Step 1: Login to get a fresh token
curl -X POST http://10.0.2.2:8000/api/users/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "your_username",
    "password": "your_password"
  }'

# Copy the "access" token from the response

# Step 2: Test the daily logs endpoint with the token
curl -X POST http://10.0.2.2:8000/api/daily-logs/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN_HERE" \
  -d '{
    "date": "2026-03-19T00:00:00Z",
    "mood": "happy",
    "flow": "light",
    "energy": "high",
    "symptoms": ["Cramps"]
  }'
```

### 4. Check Token Expiration

JWT tokens from Simple JWT have a default expiration time. Check your Django settings:

```python
# backend/config/settings.py
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),  # Default: 5 minutes
    'REFRESH_TOKEN_LIFETIME': timedelta(days=1),
    ...
}
```

If not configured, tokens expire in 5 minutes by default!

### 5. Check the Flutter App Logs

When you try to save a daily log, check the debug console for:

```
Save daily log error: 401 - {"detail":"Authentication credentials were not provided."}
```

or

```
Save daily log error: 401 - {"detail":"Given token not valid for any token type"}
```

## Solutions

### Solution 1: Re-login
Simply logout and login again to get a fresh token.

### Solution 2: Extend Token Lifetime (backend/config/settings.py)

Add or update the SIMPLE_JWT settings:

```python
from datetime import timedelta

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=24),  # Token lasts 24 hours
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': False,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': False,

    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'VERIFYING_KEY': None,
    'AUDIENCE': None,
    'ISSUER': None,

    'AUTH_HEADER_TYPES': ('Bearer',),
    'AUTH_HEADER_NAME': 'HTTP_AUTHORIZATION',
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
}
```

### Solution 3: Add Refresh Token Logic (Advanced)

Implement token refresh in the Flutter app to automatically get new tokens when they expire.

## Test the Fix

After applying a solution:

1. **Restart Django server**: `python manage.py runserver`
2. **Clear app data** or logout/login in the Flutter app
3. **Try saving a daily log** again

## Expected Success Response

When it works, you should see:

**Console Log**:
```
Daily log saved successfully: {date: 2026-03-19T00:00:00.000Z, mood: happy, flow: light, energy: high, symptoms: [Cramps]}
```

**Snackbar**:
```
Daily log saved successfully! 🎉
```

**Server Log** (backend):
```
[19/Mar/2026 03:XX:XX] "POST /api/daily-logs/ HTTP/1.1" 201 XXX
```

## Still Having Issues?

Check:
1. Is the Django server running? `python manage.py runserver`
2. Is the database migrated? `python manage.py migrate`
3. Does the user exist in the database?
4. Is the Flutter app pointing to the correct backend URL? (Check `baseUrl` in `api_service.dart`)

For Android Emulator:
```dart
static const String baseUrl = "http://10.0.2.2:8000/api";
```

For iOS Simulator:
```dart
static const String baseUrl = "http://localhost:8000/api";
```

For Physical Device:
```dart
static const String baseUrl = "http://YOUR_COMPUTER_IP:8000/api";
```
