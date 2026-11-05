# FR 1.1.4: Browse Session Schedule (dashboard + DAO refactor)

## What changed
The SQL moved out of `schedule.jsp` and `home.jsp`. Both pages now **load all their data first and close the
connection before writing any HTML**, instead of reading a ResultSet in the middle of the markup.
The HTML they produce is unchanged: it was compared with `main` for 4 users × 11 filter combinations, and all 44 matched.

| File | Change |
|---|---|
| `schedule.jsp` | The trainer and class type dropdowns use `TrainerDAO.findAll()` / `ClassTypeDAO.findAll()`. The class list uses `ClassDAO.search(userId, date, timeOfDay, trainerId, typeId)`. Building the WHERE clause dynamically (one `AND` per filter that is set) moved into `search`. |
| `home.jsp` | The membership card uses `MembershipDAO.findActive`, "Your upcoming classes" uses `ClassDAO.findUpcomingBookedBy`, and "Coming up next" uses `ClassDAO.findUpcoming(5)`. |
| `model/GymClass.java` | **New.** One class plus its title, trainer name, BOOKED count, and the viewer's own booking status. Helpers: `getSpotsLeft()`, `isBookedByMe()`, `hasStarted()`. Named GymClass because `java.lang.Class` already uses the name `Class`. |
| `model/Membership.java`, `model/Trainer.java`, `model/ClassType.java` | **New.** |
| `dao/ClassDAO.java` | **New.** `findUpcoming`, `findUpcomingBookedBy`, `search`, plus `findByIdForUpdate` (used by FR 1.1.5). The "booked spots" subquery that both pages used to copy is now written once here. |
| `dao/MembershipDAO.java` | **New.** `findActive` (tier name, end date, days left), plus `hasActive` (used by FR 1.1.5). |
| `dao/TrainerDAO.java`, `dao/ClassTypeDAO.java` | **New.** `findAll()`. |

If the database is unreachable, both pages show "Could not load gym data: ..." instead of the tables.


## Files changed in this branch
- `fittrack/src/main/webapp/schedule.jsp`
- `fittrack/src/main/webapp/home.jsp`
- `fittrack/src/main/java/fittrack/model/GymClass.java`
- `fittrack/src/main/java/fittrack/model/Membership.java`
- `fittrack/src/main/java/fittrack/model/Trainer.java`
- `fittrack/src/main/java/fittrack/model/ClassType.java`
- `fittrack/src/main/java/fittrack/dao/ClassDAO.java`
- `fittrack/src/main/java/fittrack/dao/MembershipDAO.java`
- `fittrack/src/main/java/fittrack/dao/TrainerDAO.java`
- `fittrack/src/main/java/fittrack/dao/ClassTypeDAO.java`
