# Kairos Flutter Web/PWA

Flutter-first frontend for Kairos, the AI Manager MVP described in `Kairos.docx`.

## What Is Included

- Flutter web/PWA shell with manifest and install metadata
- Riverpod state management
- go_router routes for auth, home, inbox, memories, workflows, notifications, profile, and settings
- API-backed repository boundaries for REST integration
- Design tokens based on the Kairos UI design system

## Run Locally

Install Flutter, then run:

```bash
flutter pub get
flutter run -d chrome --dart-define=Kairos_API_BASE_URL=http://localhost:8080/api/v1
```

Build the PWA:

```bash
flutter build web --release --dart-define=Kairos_API_BASE_URL=https://api.Kairos.ai/api/v1
```

## Backend API Contract

The frontend base URL defaults to `http://localhost:8080/api/v1`. Every protected route should accept `Authorization: Bearer <accessToken>`.

Auth endpoints already used by the Flutter app:

| Method | Path | Request | Response |
| --- | --- | --- | --- |
| `POST` | `/auth/register` | `{ "fullName": "Shivansh", "email": "you@example.com", "password": "secret" }` | `{ "accessToken": "...", "refreshToken": "...", "tokenType": "Bearer" }` |
| `POST` | `/auth/login` | `{ "email": "you@example.com", "password": "secret" }` | `{ "accessToken": "...", "refreshToken": "...", "tokenType": "Bearer" }` |

Main snapshot endpoint used to hydrate Today, Inbox, Notifications, Memories, Workflows, and Profile:

| Method | Path | Response |
| --- | --- | --- |
| `GET` | `/kairos/snapshot` | A `KairosSnapshot` object, either directly or wrapped as `{ "data": KairosSnapshot }`. |

`KairosSnapshot` shape:

```json
{
  "dashboard": {
    "nextMove": {
      "id": "task_1",
      "title": "Submit assignment",
      "type": "assignment",
      "dueLabel": "2:00 PM",
      "estimatedMinutes": 45,
      "reasons": ["Due today"],
      "workflowId": "workflow_1",
      "isAiGenerated": true
    },
    "everythingElse": [],
    "risks": [
      {
        "id": "risk_1",
        "title": "Payment deadline",
        "description": "Due soon",
        "severity": "medium",
        "dueLabel": "Tomorrow"
      }
    ],
    "insights": []
  },
  "memories": [
    {
      "id": "memory_1",
      "title": "Figma invoice",
      "type": "bill",
      "source": "Gmail",
      "confidence": 0.82,
      "status": "needs_review",
      "updatedLabel": "Today",
      "metadata": { "amount": "2880" },
      "workflowId": "workflow_1",
      "confirmed": false
    }
  ],
  "workflows": [
    {
      "id": "workflow_1",
      "memoryId": "memory_1",
      "title": "Pay Figma invoice",
      "typeLabel": "Bill",
      "state": "detected",
      "snoozesUsed": 0,
      "steps": [
        { "label": "Review", "description": "Confirm details", "complete": false }
      ]
    }
  ],
  "notifications": [
    {
      "id": "notification_1",
      "title": "Review invoice",
      "body": "Kai found a bill that needs confirmation.",
      "type": "review",
      "createdLabel": "Now",
      "deepLink": "/inbox",
      "read": false
    }
  ],
  "needsReview": [
    {
      "id": "review_1",
      "title": "Invoice from Figma",
      "confidence": 0.74,
      "source": "Gmail",
      "extractedFields": { "amount": "2880", "dueDate": "2026-07-27" }
    }
  ],
  "profile": {
    "fullName": "Shivansh",
    "email": "you@example.com",
    "occupation": "Student",
    "kairosInboxAddress": "shivansh@kairos.app",
    "dailyBriefingTime": "08:00",
    "timezone": "Asia/Kolkata",
    "currency": "INR",
    "notificationIntensity": 0.5,
    "pushEnabled": true,
    "emailEnabled": false
  },
  "rawNotes": []
}
```

Mutation endpoints the frontend calls:

| Method | Path | Request |
| --- | --- | --- |
| `POST` | `/chat/messages` | `{ "text": "Draft an email..." }` |
| `POST` | `/chat/attachments` | `multipart/form-data` with `files` |
| `POST` | `/inbox/text` | `{ "text": "Raw note or pasted content" }` |
| `POST` | `/needs-review/{id}/confirm` | none |
| `DELETE` | `/needs-review/{id}` | none |
| `POST` | `/dashboard/next-move/complete` | none |
| `POST` | `/dashboard/next-move/snooze` | none |
| `PATCH` | `/notifications/{id}` | `{ "read": true }` |
| `POST` | `/notifications/mark-all-read` | none |
| `POST` | `/memories/{id}/confirm` | none |
| `POST` | `/workflows/{id}/snooze` | none |
| `POST` | `/workflows/{id}/resolve` | none |
| `PATCH` | `/profile` | Any subset of `{ "dailyBriefingTime": "09:00", "notificationIntensity": 0.8, "pushEnabled": true, "emailEnabled": false }` |

Mutation responses can return the full `KairosSnapshot`, `{ "data": KairosSnapshot }`, `{ "data": { "snapshot": KairosSnapshot, "reply": "..." } }`, or no body. If no snapshot is returned, the frontend refetches `GET /kairos/snapshot`. Chat endpoints may also return `{ "reply": "Kai response" }` or `{ "message": "Kai response" }`.

Accepted enum strings:

- `type`: `bill`, `exam`, `assignment`, `meeting`, `subscription`, `travel`, `goal`, `note`
- `severity`: `high`, `medium`, `low`
- `state`: `detected`, `approaching`, `critical`, `overdue`, `resolved`

## Project Shape

```text
lib/
|-- app/
|-- core/
|-- features/
|   |-- auth/
|   |-- dashboard/
|   |-- inbox/
|   |-- memories/
|   |-- notifications/
|   |-- profile/
|   `-- workflows/
|-- shared/
`-- main.dart
```

Run `flutter analyze` before committing UI or API contract changes.
