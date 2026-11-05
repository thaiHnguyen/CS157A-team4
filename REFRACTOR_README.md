# FR 1.1.1: Register and Login (refactor)

## What changed
The SQL moved out of `login.jsp` and `register.jsp` into DAO classes. The validation rules, messages,
session handling, transaction, and HTML are unchanged.

| File | Change |
|---|---|
| `login.jsp` | The `SELECT ... FROM UserAccount WHERE Email = ?` became `new UserAccountDAO(con).findByEmail(email)`. The password check (`checkPassword`) and session setup are unchanged. |
| `register.jsp` | The email check, `INSERT INTO UserAccount`, and `INSERT INTO Member` became `emailExists`, `insert`, and `MemberDAO.insert`. They still run in one transaction (`commit` / `rollback` stay in the JSP). |
| `model/UserAccount.java` | **New.** One UserAccount row (UserId, Email, PasswordHash, Role, Name, Phone, DateOfBirth, CreatedAt). |
| `model/Member.java` | **New.** One Member row (UserId, EmergencyPhoneNumber). |
| `dao/UserAccountDAO.java` | **New.** `findByEmail`, `findById`, `emailExists`, `insert` (returns the new UserId), `updateContact`. |
| `dao/MemberDAO.java` | **New.** `findById`, `insert`, `updateEmergencyPhone`. |

## How it was tested
Run on MySQL 8.0 and Tomcat 10.1 with the seed data:
- Login with a wrong password, and as a member, trainer, and staff.
- Register: a new member is signed in, the emergency phone is saved, a duplicate email is rejected, validation messages appear.

## Notes (not changed by this refactor)
- After registering, the page redirects to `membership.jsp`, which doesn't exist yet (404). Same as on `main`.
- Hari's branch `fix/registration-login-profile` edits these same pages. Its queries use `Member.FullName` /
  `Member.MemberId`, which aren't in the current schema (`Name` is on `UserAccount`; `Member` is keyed by `UserId`).