# FR 1.1.5: Book a Session (DAO refactor + overbooking fix)

## What changed
The SQL moved out of `book.jsp`. The four checks, their messages, the single transaction, and the
`SELECT ... FOR UPDATE` lock on the Class row are the same as before.

| Check in `book.jsp` | Now calls |
|---|---|
| 1. active membership | `MembershipDAO.hasActive(userId)` |
| 2. class exists, not started (locks the Class row) | `ClassDAO.findByIdForUpdate(classId)` + `GymClass.hasStarted()` |
| 3. not already booked (a CANCELLED row is reused) | `BookingDAO.findByMemberAndClass` |
| 4. spots left | `BookingDAO.countBookedForUpdate(classId)` (see the bug fix below) |
| save | `BookingDAO.rebook(bookingId)` or `BookingDAO.insert(memberId, classId)` |

New files: `model/Booking.java`, `model/GymClass.java`, `model/Membership.java`, `dao/BookingDAO.java`, `dao/ClassDAO.java`, `dao/MembershipDAO.java`.

## Bug fix: two members could book the last spot
**On `main`:** when several members booked a class's last spot at the same moment, the class went over capacity.
In a test with 6 members racing for 1 spot, `main` allowed up to 6 bookings.

**Why:** MySQL's default isolation level, REPEATABLE READ, reads from a snapshot taken at the transaction's first
plain SELECT. Here that's the membership check, which runs *before* the Class row lock. So after a member waited for
the lock, the `COUNT(*)` still read the old snapshot and missed the booking the other member had just committed.

**Fix:** the capacity count is now a locking read, `SELECT COUNT(*) ... FOR SHARE` (`BookingDAO.countBookedForUpdate`).
A locking read always sees the latest committed rows. With the fix, the same race gave exactly 1 booking in 8 out of 8 runs.

## How it was tested
Booking an open class, already booked, booking again after cancelling (still one row because of `uq_member_class`), full class,
class already started, missing or empty classId, no active membership, a trainer trying to book, a GET request (does nothing),
filters kept after the redirect, and the concurrent last-spot race.

## Files changes in this branch
- `fittrack/src/main/webapp/book.jsp`
- `fittrack/src/main/java/fittrack/model/Booking.java`
- `fittrack/src/main/java/fittrack/model/GymClass.java`
- `fittrack/src/main/java/fittrack/model/Membership.java`
- `fittrack/src/main/java/fittrack/dao/BookingDAO.java`
- `fittrack/src/main/java/fittrack/dao/ClassDAO.java`
- `fittrack/src/main/java/fittrack/dao/MembershipDAO.java`
