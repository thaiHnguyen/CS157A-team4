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
    The Class row is locked with SELECT ... FOR UPDATE (ClassDAO.findByIdForUpdate),
    so two members clicking at the same moment cannot both take the last spot.

    The MemberId always comes from the session, never from the form, so a
    member can only book for themselves.
--%>
<%@ include file="/WEB-INF/jspf/common.jspf" %>
<%
    if (userId == null) {
        response.sendRedirect(ctx + "/login.jsp");
        return;
    }

    // send the member back to the schedule with the same filters they had
    // only letters, digits, and URL characters are allowed in it
    String back = param(request, "back");
    String scheduleUrl = ctx + "/schedule.jsp"
        + (back.matches("[A-Za-z0-9=&%._-]+") ? "?" + back : "");

    // only members book, and only through the form (POST), so a link or a
    // page refresh cannot create a booking
    if (!isMember || !"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect(scheduleUrl);
        return;
    }

    Integer classId = toInt(param(request, "classId"));
    String error = null;

    // success message
    String booked = null;                      

    Connection con = null;
    try {
        con = getConnection();
        con.setAutoCommit(false);
        BookingDAO bookings = new BookingDAO(con);

        // 1. active membership
        if (!new MembershipDAO(con).hasActive(userId)) {
            error = "You need an active membership to book a class.";
        }

        // 2. class exists and has not started; lock the row until commit
        GymClass gymClass = null;
        if (error == null) {
            gymClass = classId == null ? null : new ClassDAO(con).findByIdForUpdate(classId);
            if (gymClass == null)            error = "That class could not be found.";
            else if (gymClass.hasStarted())  error = "This class has already started.";
        }

        // 3. not already booked. A CANCELLED row can be reused: the table
        //    allows one row per member and class (uq_member_class)
        Booking existing = null;
        if (error == null) {
            existing = bookings.findByMemberAndClass(userId, classId);
            if (existing != null && existing.isBooked()) error = "You are already booked for this class.";
        }

        // 4. spots left
        //    (locking read, so a booking committed while we waited for the
        //    Class lock is counted; see BookingDAO.countBookedForUpdate)
        if (error == null && bookings.countBookedForUpdate(classId) >= gymClass.getCapacity()) {
            error = "Sorry, this class is full.";
        }

        // all checks passed: save the booking
        if (error == null) {
            if (existing != null) bookings.rebook(existing.getBookingId());
            else                  bookings.insert(userId, classId);
            con.commit();
            booked = "You are booked for " + gymClass.getTitle() + " on " + when(gymClass.getStartTime()) + ".";
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
