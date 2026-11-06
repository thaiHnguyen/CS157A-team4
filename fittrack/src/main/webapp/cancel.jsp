<%--
    cancel.jsp: FR 1.1.6 Cancel a Booking.
    The Cancel buttons on home.jsp ("Your upcoming classes") and on
    schedule.jsp (next to "Booked") post here.
    The file checks the booking, marks it CANCELLED, and redirects back to
    the page the member came from with a flash message.

    Checks, in one transaction:
        1. the member has a booking for this class
        2. that booking is still BOOKED (not already cancelled)
        3. the class has not started yet
    The Booking row is locked with SELECT ... FOR UPDATE until commit
    (BookingDAO.findByMemberAndClassForUpdate).

    The row is NOT deleted. Its Status changes to CANCELLED so the history
    is kept, and the spot opens up again because the schedule only counts
    BOOKED rows. If the member books the same class again later, book.jsp
    reuses this row (uq_member_class allows one row per member and class).

    The MemberId always comes from the session, never from the form, so a
    member can only cancel their own bookings. The booking is found by
    (MemberId, ClassId), which is unique because of uq_member_class.
--%>
<%@ include file="/WEB-INF/jspf/common.jspf" %>
<%
    if (userId == null) {
        response.sendRedirect(ctx + "/login.jsp");
        return;
    }

    // Where to go afterwards: back to the dashboard, or back to the schedule
    // with the same filters. Only letters, digits, and URL characters are
    // allowed in the filters.
    String from = param(request, "from");
    String back = param(request, "back");
    String returnUrl = "home".equals(from)
        ? ctx + "/home.jsp"
        : ctx + "/schedule.jsp" + (back.matches("[A-Za-z0-9=&%._-]+") ? "?" + back : "");

    // only members cancel, and only through the form (POST), so a link or a
    // page refresh cannot cancel anything.
    if (!isMember || !"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect(returnUrl);
        return;
    }

    Integer classId = toInt(param(request, "classId"));
    String error = null;
    String cancelled = null;

    Connection con = null;
    try {
        con = getConnection();
        con.setAutoCommit(false);
        BookingDAO bookings = new BookingDAO(con);

        // 1-3. find this member's booking for the class and lock it
        Booking booking = classId == null ? null : bookings.findByMemberAndClassForUpdate(userId, classId);
        if (booking == null) {
            error = "You don't have a booking for that class.";
        } else if (booking.isCancelled()) {
            error = "Your booking for " + booking.getClassTitle() + " is already cancelled.";
        } else if (!booking.getClassStart().isAfter(LocalDateTime.now())) {
            error = booking.getClassTitle() + " has already started, so it can't be cancelled.";
        }

        // all checks passed: mark the booking cancelled (keep the row)
        if (error == null) {
            bookings.cancel(booking.getBookingId(), userId);
            con.commit();
            cancelled = "Your booking for " + booking.getClassTitle() + " on " + when(booking.getClassStart())
                + " is cancelled. The spot is open for other members.";
        } else {
            con.rollback();
        }
    } catch (Exception e) {
        rollback(con);
        error = "Could not cancel the booking: " + e.getMessage();
    } finally {
        close(con);
    }

    session.setAttribute("flash", error == null ? "ok:" + cancelled : "err:" + error);
    response.sendRedirect(returnUrl);
%>
