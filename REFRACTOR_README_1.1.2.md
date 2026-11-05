# FR 1.1.2: Update Profile (refactor)

## What changed
The SQL moved out of `profile.jsp`. The validation, messages, "keep what the user typed on error" behavior, and HTML are unchanged.

| File | Change |
|---|---|
| `profile.jsp` | Save: `UPDATE UserAccount` became `UserAccountDAO.updateContact`; for members, `UPDATE Member` became `MemberDAO.updateEmergencyPhone`. Both run in one transaction, same as before. Load: the `UserAccount LEFT JOIN Member` query became `UserAccountDAO.findById` + `MemberDAO.findById` (members only; trainers and staff have no Member row). |
| `model/UserAccount.java`, `model/Member.java` | **New** (same files as FR 1.1.1). |
| `dao/UserAccountDAO.java`, `dao/MemberDAO.java` | **New** (same files as FR 1.1.1). Used here: `findById`, `updateContact`, `updateEmergencyPhone`. |

The UserId still comes only from the session, so a user can only edit their own profile.

## How it was tested
Run on MySQL 8.0 and Tomcat 10.1 with the seed data: a member updates their name, phone, and emergency phone
(including clearing it), the new name shows in the top bar, a trainer views and updates their profile (no emergency field),
and an invalid phone keeps the typed values on the form.

