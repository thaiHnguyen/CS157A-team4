<%--
    home.jsp - the dashboard every user lands on after signing in.
    Members see their membership status and upcoming bookings.
    Everyone sees the next few classes with live remaining spots.
    Data comes from MembershipDAO.findActive, ClassDAO.findUpcomingBookedBy,
    and ClassDAO.findUpcoming.
--%>
<%@ include file="/WEB-INF/jspf/common.jspf" %>
<%
    if (userId == null) {
        response.sendRedirect(ctx + "/login.jsp");
        return;
    }

    // Load everything first, then render. The connection is closed before
    // any HTML is written.
    Membership active = null;
    List<GymClass> myClasses = new ArrayList<>();
    List<GymClass> nextClasses = new ArrayList<>();
    String loadError = null;

    Connection con = null;
    try {
        con = getConnection();
        if (isMember) {
            active = new MembershipDAO(con).findActive(userId);
            myClasses = new ClassDAO(con).findUpcomingBookedBy(userId);
        }
        nextClasses = new ClassDAO(con).findUpcoming(5);
    } catch (Exception e) {
        loadError = "Could not load gym data: " + e.getMessage();
    } finally {
        close(con);
    }
%>
<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Dashboard - FitTrack</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>

<body>
<%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="wrap">
    <main>
        <h1 class="page-title">Hi, <%= esc(fullName) %></h1>
    <% if (loadError != null) { %>
        <p class="error"><%= esc(loadError) %></p>
    <% } else { %>
    <%
            if (isMember) {
                // - membership status 
                if (active != null) {
    %>
        <div class="status-card ok">
            <div>
                <div class="muted small">Membership</div>
                <div class="big"><%= esc(active.getTierName()) %></div>
                <div class="muted">Active until <%= day(active.getEndDate()) %>
                    (<%= active.getDaysLeft() %> days left)</div>
            </div>
            <div class="card-actions">
                <a class="btn" href="<%= ctx %>/checkin.jsp">Check in</a>
                <a class="btn-quiet" href="<%= ctx %>/schedule.jsp">Book a class</a>
                <a class="btn-quiet" href="<%= ctx %>/membership.jsp">Renew</a>
            </div>
        </div>
    <%
                } else {
    %>
        <div class="status-card none">
            <div>
                <div class="muted small">Membership</div>
                <div class="big">No active membership</div>
                <div class="muted">You need one to book classes.</div>
            </div>
            <div class="card-actions">
                <a class="btn" href="<%= ctx %>/membership.jsp">Get a membership</a>
            </div>
        </div>
    <%
                }

                // my upcoming bookings 
    %>
        <h2>Your upcoming classes</h2>
        <table>
            <tr><th>When</th><th>Class</th><th>Trainer</th><th>Room</th><th></th></tr>
    <%
                for (GymClass c : myClasses) {
    %>
            <tr>
                <td class="nowrap"><%= when(c.getStartTime()) %></td>
                <td><%= esc(c.getTitle()) %></td>
                <td><%= esc(c.getTrainerName()) %></td>
                <td><%= esc(c.getRoomNumber()) %></td>
                <td class="nowrap">
                    <%-- FR 1.1.6: cancel this booking (cancel.jsp) --%>
                    <form method="post" action="<%= ctx %>/cancel.jsp"
                        onsubmit="return confirm('Cancel your booking for this class?');">
                        <input type="hidden" name="classId" value="<%= c.getClassId() %>">
                        <input type="hidden" name="from" value="home">
                        <button class="btn-quiet btn-sm" type="submit">Cancel</button>
                    </form>
                </td>
            </tr>
    <%
                }
                if (myClasses.isEmpty()) {
    %>
            <tr><td colspan="5" class="muted">Nothing booked yet.
                <a href="<%= ctx %>/schedule.jsp">Browse the schedule</a></td></tr>
    <%
                }
    %>
        </table>
    <%
            }

            // next classes (everyone) 
    %>
        <h2>Coming up next</h2>
        <p class="note">The next five classes. <a href="<%= ctx %>/schedule.jsp">See the full schedule</a></p>
        <table>
            <tr><th>When</th><th>Class</th><th>Trainer</th><th>Room</th><th>Spots left</th></tr>
    <%
            for (GymClass c : nextClasses) {
                int left = c.getSpotsLeft();
    %>
            <tr>
                <td class="nowrap"><%= when(c.getStartTime()) %></td>
                <td><%= esc(c.getTitle()) %></td>
                <td><%= esc(c.getTrainerName()) %></td>
                <td><%= esc(c.getRoomNumber()) %></td>
                <% if (left <= 0) { %><td class="full">FULL</td><% } else { %><td class="left"><%= left %></td><% } %>
            </tr>
    <%
            }
    %>
        </table>
    <% } %>
    </main>
    </div>

    <footer>
        <div class="wrap">
            <p>FitTrack - CS157A Fall 2026 Project, Team 4.</p>
        </div>
    </footer>

</body>

</html>
