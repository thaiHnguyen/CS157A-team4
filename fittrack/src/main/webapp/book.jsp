<%--
    book.jsp: FR 1.1.5 Book a Session.
    The Book button on schedule.jsp posts here. 
    The file checks the booking, saves it, and redirects back to the
    schedule with a flash message.

    Checks, in one transaction:
      1. the member has an active membership
      2. the class exists and has not started
      3. the member is not already booked for it
      4. BOOKED rows for the class are fewer than its Capacity
    The Class row is locked with SELECT ... FOR UPDATE, so two members
    clicking at the same moment cannot both take the last spot.

    The MemberId always comes from the session, never from the form, so a
    member can only book for themselves.
--%>
<%@ include file="/WEB-INF/jspf/common.jspf" %>
<%
    if (userId == null) {
        response.sendRedirect(ctx + "/login.jsp");
        return;
    }

    // send the member back to the schedule with the same filters they had.
    // only letters, digits, and URL characters are allowed in it.
    String back = param(request, "back");
    String scheduleUrl = ctx + "/schedule.jsp"
        + (back.matches("[A-Za-z0-9=&%._-]+") ? "?" + back : "");

    // only members book, and only through the form (POST), so a link or a
    // page refresh cannot create a booking.
    if (!isMember || !"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect(scheduleUrl);
        return;
    }

    Integer classId = toInt(param(request, "classId"));
    String error = null;
    String booked = null;                       // success message

    Connection con = null;
    try {
        con = getConnection();
        con.setAutoCommit(false);

        // 1. active membership
        PreparedStatement ms = con.prepareStatement(
            "SELECT 1 FROM Membership "
            + " WHERE MemberId = ? AND Status = 'ACTIVE' "
            + "   AND CURDATE() BETWEEN StartDate AND EndDate");
        ms.setInt(1, userId);
        ResultSet rs = ms.executeQuery();
        if (!rs.next()) error = "You need an active membership to book a class.";
        rs.close();
        ms.close();

        // 2. class exists and has not started; lock the row until commit
        String title = null;
        LocalDateTime start = null;
        int capacity = 0;
        if (error == null) {
            PreparedStatement cs = con.prepareStatement(
                "SELECT c.StartTime, c.Capacity, ct.Title "
                + "  FROM `Class` c JOIN ClassType ct ON ct.ClassTypeId = c.ClassTypeId "
                + " WHERE c.ClassId = ? FOR UPDATE");
            cs.setObject(1, classId);           // null classId simply finds nothing
            rs = cs.executeQuery();
            if (!rs.next()) {
                error = "That class could not be found.";
            } else {
                title = rs.getString("Title");
                start = rs.getObject("StartTime", LocalDateTime.class);
                capacity = rs.getInt("Capacity");
                if (!start.isAfter(LocalDateTime.now())) error = "This class has already started.";
            }
            rs.close();
            cs.close();
        }

        // 3. not already booked. A CANCELLED row can be reused: the table
        //    allows one row per member and class (uq_member_class).
        Integer cancelledId = null;
        if (error == null) {
            PreparedStatement bs = con.prepareStatement(
                "SELECT BookingId, Status FROM Booking WHERE MemberId = ? AND ClassId = ?");
            bs.setInt(1, userId);
            bs.setInt(2, classId);
            rs = bs.executeQuery();
            if (rs.next()) {
                if ("BOOKED".equals(rs.getString("Status"))) error = "You are already booked for this class.";
                else cancelledId = rs.getInt("BookingId");
            }
            rs.close();
            bs.close();
        }

        // 4. spots left
        if (error == null) {
            PreparedStatement cnt = con.prepareStatement(
                "SELECT COUNT(*) FROM Booking WHERE ClassId = ? AND Status = 'BOOKED'");
            cnt.setInt(1, classId);
            rs = cnt.executeQuery();
            rs.next();
            if (rs.getInt(1) >= capacity) error = "Sorry, this class is full.";
            rs.close();
            cnt.close();
        }

        // all checks passed: save the booking
        if (error == null) {
            PreparedStatement save;
            if (cancelledId != null) {
                save = con.prepareStatement(
                    "UPDATE Booking SET Status = 'BOOKED', BookedAt = NOW() WHERE BookingId = ?");
                save.setInt(1, cancelledId);
            } else {
                save = con.prepareStatement(
                    "INSERT INTO Booking (MemberId, ClassId, Status) VALUES (?, ?, 'BOOKED')");
                save.setInt(1, userId);
                save.setInt(2, classId);
            }
            save.executeUpdate();
            save.close();
            con.commit();
            booked = "You are booked for " + title + " on " + when(start) + ".";
        } else {
            con.rollback();
        }
    } catch (Exception e) {
        rollback(con);
        error = "Could not book the class: " + e.getMessage();
    } finally {
        close(con);
    }

    session.setAttribute("flash", error == null ? "ok:" + booked : "err:" + error);
    response.sendRedirect(scheduleUrl);
%>
