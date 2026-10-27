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
    The Booking row is locked with SELECT ... FOR UPDATE until commit.

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

        // 1-3. find this member's booking for the class and lock it
        PreparedStatement bs = con.prepareStatement(
            "SELECT b.BookingId, b.Status, c.StartTime, ct.Title "
            + "  FROM Booking b "
            + "  JOIN `Class` c    ON c.ClassId = b.ClassId "
            + "  JOIN ClassType ct ON ct.ClassTypeId = c.ClassTypeId "
            + " WHERE b.MemberId = ? AND b.ClassId = ? FOR UPDATE");
        bs.setInt(1, userId);
        bs.setObject(2, classId); 
        ResultSet rs = bs.executeQuery();

        int bookingId = 0;
        String title = null;
        LocalDateTime start = null;
        if (!rs.next()) {
            error = "You don't have a booking for that class.";
        } else {
            bookingId = rs.getInt("BookingId");
            title = rs.getString("Title");
            start = rs.getObject("StartTime", LocalDateTime.class);
            if ("CANCELLED".equals(rs.getString("Status"))) {
                error = "Your booking for " + title + " is already cancelled.";
            } else if (!start.isAfter(LocalDateTime.now())) {
                error = title + " has already started, so it can't be cancelled.";
            }
        }
        rs.close();
        bs.close();

        // all checks passed: mark the booking cancelled (keep the row)
        if (error == null) {
            PreparedStatement up = con.prepareStatement(
                "UPDATE Booking SET Status = 'CANCELLED' WHERE BookingId = ? AND MemberId = ?");
            up.setInt(1, bookingId);
            up.setInt(2, userId);
            up.executeUpdate();
            up.close();
            con.commit();
            cancelled = "Your booking for " + title + " on " + when(start)
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
