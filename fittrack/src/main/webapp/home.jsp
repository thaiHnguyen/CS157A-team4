<%--
    home.jsp -- the dashboard every user lands on after signing in.
    Members see their membership status and upcoming bookings.
    Everyone sees the next few classes with live remaining spots.
--%>
<%@ include file="/WEB-INF/jspf/common.jspf" %>
<%
    if (userId == null) {
        response.sendRedirect(ctx + "/login.jsp");
        return;
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
    <%
        Connection con = null;
        try {
            con = getConnection();

            if (isMember) {
                // - membership status 
                PreparedStatement cur = con.prepareStatement(
                    "SELECT t.TierName, m.EndDate, DATEDIFF(m.EndDate, CURDATE()) AS DaysLeft "
                    + "  FROM Membership m JOIN MembershipTier t ON t.TierId = m.TierId "
                    + " WHERE m.MemberId = ? AND m.Status = 'ACTIVE' "
                    + "   AND CURDATE() BETWEEN m.StartDate AND m.EndDate "
                    + " ORDER BY m.EndDate DESC LIMIT 1");
                cur.setInt(1, userId);
                ResultSet rs = cur.executeQuery();
                if (rs.next()) {
    %>
        <div class="status-card ok">
            <div>
                <div class="muted small">Membership</div>
                <div class="big"><%= esc(rs.getString("TierName")) %></div>
                <div class="muted">Active until <%= day(rs.getObject("EndDate", LocalDate.class)) %>
                    (<%= rs.getInt("DaysLeft") %> days left)</div>
            </div>
            <div class="card-actions">
                <a class="btn" href="<%= ctx %>/schedule.jsp">Book a class</a>
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
                rs.close();
                cur.close();

                // my upcoming bookings 
                PreparedStatement mine = con.prepareStatement(
                    "SELECT c.StartTime, ct.Title, u.Name AS Trainer, c.RoomNumber "
                    + "  FROM Booking b "
                    + "  JOIN `Class` c     ON c.ClassId = b.ClassId "
                    + "  JOIN ClassType ct  ON ct.ClassTypeId = c.ClassTypeId "
                    + "  JOIN UserAccount u ON u.UserId = c.TrainerId "
                    + " WHERE b.MemberId = ? AND b.Status = 'BOOKED' AND c.StartTime >= NOW() "
                    + " ORDER BY c.StartTime");
                mine.setInt(1, userId);
                rs = mine.executeQuery();
    %>
        <h2>Your upcoming classes</h2>
        <table>
            <tr><th>When</th><th>Class</th><th>Trainer</th><th>Room</th></tr>
    <%
                int n = 0;
                while (rs.next()) {
                    n++;
    %>
            <tr>
                <td class="nowrap"><%= when(rs.getObject("StartTime", LocalDateTime.class)) %></td>
                <td><%= esc(rs.getString("Title")) %></td>
                <td><%= esc(rs.getString("Trainer")) %></td>
                <td><%= esc(rs.getString("RoomNumber")) %></td>
            </tr>
    <%
                }
                if (n == 0) {
    %>
            <tr><td colspan="4" class="muted">Nothing booked yet.
                <a href="<%= ctx %>/schedule.jsp">Browse the schedule</a></td></tr>
    <%
                }
    %>
        </table>
    <%
                rs.close();
                mine.close();
            }

            // next classes (everyone) 
            Statement stmt = con.createStatement();
            ResultSet rs = stmt.executeQuery(
                "SELECT c.StartTime, ct.Title, u.Name AS Trainer, c.RoomNumber, c.Capacity, "
                + "       (SELECT COUNT(*) FROM Booking b "
                + "         WHERE b.ClassId = c.ClassId AND b.Status = 'BOOKED') AS Booked "
                + "  FROM `Class` c "
                + "  JOIN ClassType ct  ON ct.ClassTypeId = c.ClassTypeId "
                + "  JOIN UserAccount u ON u.UserId = c.TrainerId "
                + " WHERE c.StartTime >= NOW() "
                + " ORDER BY c.StartTime LIMIT 5");
    %>
        <h2>Coming up next</h2>
        <p class="note">The next five classes. <a href="<%= ctx %>/schedule.jsp">See the full schedule</a></p>
        <table>
            <tr><th>When</th><th>Class</th><th>Trainer</th><th>Room</th><th>Spots left</th></tr>
    <%
            while (rs.next()) {
                int left = rs.getInt("Capacity") - rs.getInt("Booked");
    %>
            <tr>
                <td class="nowrap"><%= when(rs.getObject("StartTime", LocalDateTime.class)) %></td>
                <td><%= esc(rs.getString("Title")) %></td>
                <td><%= esc(rs.getString("Trainer")) %></td>
                <td><%= esc(rs.getString("RoomNumber")) %></td>
                <% if (left <= 0) { %><td class="full">FULL</td><% } else { %><td class="left"><%= left %></td><% } %>
            </tr>
    <%
            }
    %>
        </table>
    <%
            rs.close();
            stmt.close();
        } catch (Exception e) {
            out.println("<p class=\"error\">Could not load gym data: " + esc(e.getMessage()) + "</p>");
        } finally {
            close(con);
        }
    %>
    </main>
    </div>

    <footer>
        <div class="wrap">
            <p>FitTrack - CS157A Fall 2026 Project, Team 4.</p>
        </div>
    </footer>

</body>

</html>
