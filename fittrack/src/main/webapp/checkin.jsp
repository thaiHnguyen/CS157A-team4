<%--
    checkin.jsp - FR 1.1.7 Check In
    A member checks in when they arrive at the gym: either a plain gym visit,
    or for one of today's classes they booked. The forms post back to this page

    Check-in runs in one transaction:
        1. lock the member's row (MemberDAO.lockById), so a double click
            cannot record the same check-in twice
        2. verify an active membership                    MembershipDAO.hasActive
        3. plain visit:  not already checked in today     AttendanceDAO.findGymVisitToday
            class:        booked (BOOKED) for that class,  BookingDAO.findByMemberAndClass
                        not already checked in for it,   AttendanceDAO.findForClass
                        check-in window is open          ClassDAO.findCheckInState
        4. INSERT the Attendance row (CheckInTime = now)  AttendanceDAO.insert
        The MemberId always comes from the session, never from the form

    FR 1.1.8 View Attendance History is the "History check-ins" table at the
    bottom: every check-in, newest first, filtered by the range dropdown
    (?range=week | month | all, default all)  AttendanceDAO.findForMember
    Every time rule uses MySQL's clock (NOW(), CURDATE()), never Java's, so
    the web server and the database can't disagree about what time it is.
--%>
<%@ include file="/WEB-INF/jspf/common.jspf" %>
<%
    if (userId == null) {
        response.sendRedirect(ctx + "/login.jsp");
        return;
    }
    if (!isMember) {                            // only members can check in
        response.sendRedirect(ctx + "/home.jsp");
        return;
    }

    DateTimeFormatter CLOCK = DateTimeFormatter.ofPattern("h:mm a", Locale.US);

    // FR 1.1.8 checkin history filter: value, label. Unknown values fall back to "all".
    String[][] RANGES = { {"week", "Last week"}, {"month", "Last month"}, {"all", "All"} };
    String range = param(request, "range");
    if (!range.equals("week") && !range.equals("month")) range = "all";
    String keepRange = range.equals("all") ? "" : "?range=" + range;   // kept across check-in redirects

    //  check in 
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String classParam = param(request, "classId");
        Integer classId = toInt(classParam);    // empty = plain gym visit
        String error = null;
        String done = null;

        Connection con = null;
        try {
            con = getConnection();
            con.setAutoCommit(false);

            // 1. lock first, so every read below sees the latest committed rows
            new MemberDAO(con).lockById(userId);
            AttendanceDAO attendance = new AttendanceDAO(con);

            // 2. active membership
            if (!new MembershipDAO(con).hasActive(userId)) {
                error = "You need an active membership to check in.";
            }

            // 3. what they are checking in for
            if (error == null && !classParam.isEmpty() && classId == null) {
                error = "That class could not be found.";
            } else if (error == null && classId == null) {
                Attendance today = attendance.findGymVisitToday(userId);
                if (today != null) {
                    error = "You already checked in today at " + today.getCheckInTime().format(CLOCK) + ".";
                }
            } else if (error == null) {
                Booking booking = new BookingDAO(con).findByMemberAndClass(userId, classId);
                if (booking == null || !booking.isBooked()) {
                    error = "You are not booked for that class, so you can't check in for it.";
                } else {
                    GymClass c = new GymClass();
                    c.setStartTime(booking.getClassStart());
                    String state = new ClassDAO(con).findCheckInState(classId);
                    Attendance already = attendance.findForClass(userId, classId);
                    if (already != null) {
                        error = "You already checked in for " + booking.getClassTitle()
                            + " at " + already.getCheckInTime().format(CLOCK) + ".";
                    } else if ("NOT_YET".equals(state)) {
                        error = "Check-in for " + booking.getClassTitle() + " opens at "
                            + c.getCheckInOpens().format(CLOCK) + " (" + GymClass.CHECK_IN_OPENS_MINUTES_BEFORE
                            + " minutes before it starts).";
                    } else if (!"OPEN".equals(state)) {
                        error = "Check-in for " + booking.getClassTitle() + " closed at "
                            + c.getCheckInCloses().format(CLOCK) + ".";
                    } else {
                        done = booking.getClassTitle();
                    }
                }
            }

            // 4. record the check-in
            if (error == null) {
                int attendanceId = attendance.insert(userId, classId);
                String now = attendance.findById(attendanceId).getCheckInTime().format(CLOCK);
                con.commit();
                session.setAttribute("flash", "ok:" + (done == null
                    ? "Checked in at " + now + ". Have a good workout!"
                    : "Checked in for " + done + " at " + now + ". Enjoy the class!"));
            } else {
                con.rollback();
                session.setAttribute("flash", "error:" + error);
            }
        } catch (Exception e) {
            rollback(con);
            session.setAttribute("flash", "error:Could not check in: " + e.getMessage());
        } finally {
            close(con);
        }

        response.sendRedirect(ctx + "/checkin.jsp" + keepRange);
        return;
    }

    //  load the page data 
    boolean activeMember = false;
    Attendance gymToday = null;
    List<GymClass> todays = new ArrayList<>();
    List<Attendance> history = new ArrayList<>();
    String loadError = null;

    Connection con = null;
    try {
        con = getConnection();
        activeMember = new MembershipDAO(con).hasActive(userId);
        AttendanceDAO attendance = new AttendanceDAO(con);
        gymToday = attendance.findGymVisitToday(userId);
        todays = new ClassDAO(con).findBookedTodayBy(userId);
        history = attendance.findForMember(userId, range);
    } catch (Exception e) {
        loadError = "Could not load check-in: " + e.getMessage();
    } finally {
        close(con);
    }
%>
<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Check in - FitTrack</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>

<body>
<%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="wrap">
    <main>
        <h1 class="page-title">Check in</h1>
    <% if (loadError != null) { %>
        <p class="error"><%= esc(loadError) %></p>
    <% } else if (!activeMember) { %>
        <div class="status-card none">
            <div>
                <div class="muted small">Check in</div>
                <div class="big">No active membership</div>
                <div class="muted">You need an active membership to check in.</div>
            </div>
            <div class="card-actions">
                <a class="btn" href="<%= ctx %>/membership.jsp">Get a membership</a>
            </div>
        </div>
    <% } else { %>

        <%-- plain gym visit --%>
        <div class="status-card ok">
            <div>
                <div class="muted small">Gym visit</div>
                <% if (gymToday != null) { %>
                <div class="big">Checked in;</div>
                <div class="muted">Today at <%= gymToday.getCheckInTime().format(CLOCK) %></div>
                <% } else { %>
                <div class="big">Welcome in!</div>
                <div class="muted">Check in when you arrive at the gym.</div>
                <% } %>
            </div>
            <% if (gymToday == null) { %>
            <div class="card-actions">
                <form method="post" action="<%= ctx %>/checkin.jsp">
                    <input type="hidden" name="range" value="<%= range %>">
                    <input type="hidden" name="classId" value="">
                    <button class="btn" type="submit">Check in now</button>
                </form>
            </div>
            <% } %>
        </div>

        <%-- today's booked classes --%>
        <h2>Today's classes</h2>
        <p class="note">Check in for a class you booked from <%= GymClass.CHECK_IN_OPENS_MINUTES_BEFORE %> minutes
            before it starts until <%= GymClass.CHECK_IN_CLOSES_MINUTES_AFTER %> minutes after.</p>
        <table>
            <tr><th>Time</th><th>Class</th><th>Trainer</th><th>Room</th><th></th></tr>
        <%
            for (GymClass c : todays) {
        %>
            <tr>
                <td class="nowrap"><%= c.getStartTime().format(CLOCK) %></td>
                <td><%= esc(c.getTitle()) %></td>
                <td><%= esc(c.getTrainerName()) %></td>
                <td><%= esc(c.getRoomNumber()) %></td>
                <td class="nowrap">
                <% if (c.getCheckedInAt() != null) { %>
                    <span class="muted">Checked in ; <%= c.getCheckedInAt().format(CLOCK) %></span>
                <% } else if (c.isCheckInOpen()) { %>
                    <form method="post" action="<%= ctx %>/checkin.jsp">
                        <input type="hidden" name="range" value="<%= range %>">
                        <input type="hidden" name="classId" value="<%= c.getClassId() %>">
                        <button class="btn btn-sm" type="submit">Check in</button>
                    </form>
                <% } else if ("NOT_YET".equals(c.getCheckInState())) { %>
                    <span class="muted">Opens <%= c.getCheckInOpens().format(CLOCK) %></span>
                <% } else { %>
                    <span class="muted">Check-in closed</span>
                <% } %>
                </td>
            </tr>
        <%
            }
            if (todays.isEmpty()) {
        %>
            <tr><td colspan="5" class="muted">No classes booked for today.
                <a href="<%= ctx %>/schedule.jsp">Browse the schedule</a></td></tr>
        <%
            }
        %>
        </table>
    <% } %>

    <% if (loadError == null) { %>
        <%-- FR 1.1.8: attendance history (also the updated record after a check-in) --%>
        <h2 id="history">History check-ins</h2>
        <form method="get" action="<%= ctx %>/checkin.jsp#history">
            <div class="filters">
                <div>
                    <label for="range">Show</label>
                    <select id="range" name="range" onchange="this.form.submit()">
                    <% for (String[] r : RANGES) { %>
                        <option value="<%= r[0] %>" <%= r[0].equals(range) ? "selected" : "" %>><%= r[1] %></option>
                    <% } %>
                    </select>
                </div>
            </div>
            <noscript><div class="filter-actions"><button class="btn" type="submit">Filter</button></div></noscript>
        </form>
        <p class="note"><%= history.size() %> check-in<%= history.size() == 1 ? "" : "s" %><%=
            range.equals("week") ? " in the last 7 days" : range.equals("month") ? " in the last month" : " in total" %>.</p>
        <table>
            <tr><th>Checked in</th><th>For</th></tr>
        <% for (Attendance a : history) { %>
            <tr>
                <td class="nowrap"><%= when(a.getCheckInTime()) %></td>
                <td><%= a.isGymVisit() ? "Gym visit" : esc(a.getClassTitle()) + " <span class=\"muted\">(class at " + when(a.getClassStart()) + ")</span>" %></td>
            </tr>
        <% } %>
        <% if (history.isEmpty()) { %>
            <tr><td colspan="2" class="muted">No check-ins<%= range.equals("all") ? " yet" : " in this period" %>.</td></tr>
        <% } %>
        </table>
    <% } %>
    </main>
    </div>

</body>

</html>
