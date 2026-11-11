# Candle comments

Every candle has its own comment thread. Anyone can read it; signed-in users can
comment, reply to any comment and delete their own comments. Replies form a tree.

## Model

`CandleComment` (`backend/api/Models/CandleComment.cs`):

| Field | Meaning |
| --- | --- |
| `CandleId`, `UserId` | Thread and author |
| `ParentCommentId` | The comment answered; null for a top-level comment |
| `RootCommentId` | Top-level comment of the branch; null for a top-level comment |
| `Path` | Ancestor ids, `/` for a top-level comment, `/12/45/` for a reply to 45 under 12 |
| `Depth` | 0 for a top-level comment, 1 for a reply to it, and so on (max 100) |
| `Text` | Trimmed, 1–1000 characters |
| `CreatedAt`, `DeletedAt` | `DeletedAt` is the soft delete; the text stays in the database |

`Path` makes "everything below a comment" a single prefix match within the candle,
which is how reply counts and placeholder visibility are computed. Indexes cover
listing by `(CandleId, ParentCommentId, CreatedAt, Id)` and subtree lookups by
`(CandleId, Path)`.

A comment is **live** when it is not deleted and its author still has an account.

- Counters only count live comments: `CommentsCount` on candle responses and
  `RepliesCount` on comments (live comments anywhere below, not just direct replies).
- A deleted comment with live comments below it is listed as a placeholder:
  `isDeleted: true`, `author` and `text` null. Without live comments below it, it
  is not listed at all. Placeholders cannot be answered.

## API

All routes are under `/api`, errors are plain codes as elsewhere in the API.
Pagination uses opaque cursors bound to one list; `limit` is 1–50, default 20.
A cursor from another list, an altered cursor or a cursor issued before the Data
Protection keys changed returns `400 invalid_cursor`.

| Method and path | Access | Result |
| --- | --- | --- |
| `GET /candles/{id}/comments?cursor=&limit=` | anyone | Top-level comments, newest first |
| `GET /candles/{id}/comments/{commentId}/replies?cursor=&limit=` | anyone | Direct replies, oldest first |
| `POST /candles/{id}/comments` `{ text, parentCommentId? }` | signed in | 201 with the comment |
| `DELETE /candles/{id}/comments/{commentId}` | comment author | 204 |

```json
{
  "items": [
    {
      "id": 23, "candleId": 8, "parentCommentId": null, "rootCommentId": null,
      "depth": 0, "author": { "id": 4, "username": "anna" },
      "text": "Light and peace to your family.", "isDeleted": false,
      "createdAt": "2026-11-11T11:17:42.12Z", "repliesCount": 1
    }
  ],
  "nextCursor": null
}
```

Errors:

| Code | When |
| --- | --- |
| `400 invalid_comment_text` | Text empty after trimming or longer than 1000 characters |
| `400 parent_not_in_candle` | `parentCommentId` belongs to another candle |
| `400 thread_too_deep` | The parent is already at depth 100 |
| `400 invalid_cursor`, `400 invalid_limit` | Pagination parameters |
| `404 candle_not_found` | No such candle, or its author is blocked by the caller |
| `404 comment_not_found` | No such comment in this candle, or it is deleted (delete, reply) |
| `403 forbidden` | Deleting someone else's comment |

Comments of candles hidden by a user block are hidden with the candle. Blocks are
not applied to individual comments yet.

## Reports

`POST /reports` accepts `commentId` as a third target next to `candleId` and
`userId`; exactly one must be set (`400 report_target_required`). Reporting your
own comment returns `400 cannot_report_yourself`, a deleted comment `404`.
The report stores `CommentId` and the comment author as `ReportedUserId`.

## Client

`frontend/app/lib/features/comments`. The comments button on the candle screen
opens a bottom sheet at two thirds of the screen; dragging its header expands it
to full height or closes it. Top-level comments load on opening and on
pull-to-refresh; replies load per branch behind "Show N replies". Two reply levels
are indented inline (`CommentLayout.maxInlineDepth`); deeper branches open as a
focused view with a back action.

## Not included yet

Likes and popularity sorting, reply notifications, realtime updates, blocks applied
to comments, rate limiting, moderation by candle authors and editing.
