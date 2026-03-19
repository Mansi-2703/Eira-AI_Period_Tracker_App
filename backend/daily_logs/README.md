# Daily Logs API - Setup Instructions

## Backend Setup (Django)

### 1. Run Database Migrations

To create the database table for daily logs, run the following commands from the `backend` directory:

```bash
# Create migration files
python manage.py makemigrations

# Apply migrations
python manage.py migrate
```

### 2. API Endpoints

The following endpoints are now available at `/api/daily-logs/`:

#### Create or Update Daily Log
**POST** `/api/daily-logs/`

Request body:
```json
{
  "date": "2026-03-19T00:00:00Z",
  "mood": "happy",
  "flow": "medium",
  "energy": "high",
  "symptoms": ["Cramps", "Headache"]
}
```

Response (201 Created or 200 OK):
```json
{
  "id": 1,
  "date": "2026-03-19",
  "mood": "happy",
  "flow": "medium",
  "energy": "high",
  "symptoms": ["Cramps", "Headache"],
  "created_at": "2026-03-19T10:30:00Z",
  "updated_at": "2026-03-19T10:30:00Z"
}
```

#### Get All Daily Logs
**GET** `/api/daily-logs/`

Query parameters (optional):
- `start_date`: Filter logs from this date (YYYY-MM-DD)
- `end_date`: Filter logs until this date (YYYY-MM-DD)
- `limit`: Maximum number of logs to return (default: 30)

Example: `/api/daily-logs/?start_date=2026-03-01&limit=10`

#### Get Daily Log by Date
**GET** `/api/daily-logs/date/{date}/`

Example: `/api/daily-logs/date/2026-03-19/`

#### Update Daily Log
**PUT** `/api/daily-logs/{id}/`

Request body (partial update supported):
```json
{
  "mood": "calm",
  "symptoms": ["Bloating"]
}
```

#### Delete Daily Log
**DELETE** `/api/daily-logs/{id}/`

### 3. Authentication

All daily log endpoints require JWT authentication. Include the token in the request headers:

```
Authorization: Bearer {your-jwt-token}
```

### 4. Available Choices

**Mood**: happy, calm, sad, anxious, irritable, tired

**Flow**: light, medium, heavy, none

**Energy**: high, medium, low

**Symptoms**: Any array of strings (e.g., ["Cramps", "Headache", "Bloating"])

### 5. Admin Panel

Daily logs can be viewed and managed in the Django admin panel at:
`http://localhost:8000/admin/daily_logs/dailylog/`

## Frontend Integration (Flutter)

The daily log functionality has been integrated into the Flutter app:

### API Service Methods

Located in `lib/services/api_service.dart`:

- `saveDailyLog(Map<String, dynamic> logData)` - Create/update daily log
- `fetchDailyLogs({String? startDate, String? endDate, int limit})` - Get all logs
- `getDailyLogByDate(String date)` - Get log by specific date
- `deleteDailyLog(int logId)` - Delete a log

### UI Component

The `DailyLogCard` widget is now integrated above the cycle length trend card and automatically saves data to the backend when users complete their daily log.

## Testing

### Backend Testing (using cURL)

```bash
# Login to get token
curl -X POST http://localhost:8000/api/users/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"your_username","password":"your_password"}'

# Create a daily log (replace YOUR_TOKEN)
curl -X POST http://localhost:8000/api/daily-logs/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "date": "2026-03-19T00:00:00Z",
    "mood": "happy",
    "flow": "light",
    "energy": "high",
    "symptoms": ["Cramps"]
  }'

# Get all logs
curl -X GET http://localhost:8000/api/daily-logs/ \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Database Schema

```sql
CREATE TABLE daily_logs_dailylog (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES auth_user(id),
    date DATE NOT NULL,
    mood VARCHAR(20),
    flow VARCHAR(20),
    energy VARCHAR(20),
    symptoms TEXT,  -- JSON array
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    UNIQUE(user_id, date)
);
```

## Notes

- Each user can have only ONE log per day (enforced by unique constraint)
- Updating an existing log for the same date will overwrite the previous values
- Symptoms are stored as JSON array for flexibility
- All fields except `date` are optional, but at least one field must be provided
