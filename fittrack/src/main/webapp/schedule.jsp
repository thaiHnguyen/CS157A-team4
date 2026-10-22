<%--
    schedule.jsp - FR 1.1.4 Browse Available Session Schedule.
    Lists every upcoming class with its trainer, room, and live remaining spots.
    Optional filters for date, time of day, trainer, and class type are read
    from the URL (GET), and each one that is set adds an AND to the WHERE.
--%>
<%@ include file="/WEB-INF/jspf/common.jspf" %>
<%
    if (userId == null) {
        response.sendRedirect(ctx + "/login.jsp");
        return;
    }

    // Filters: Empty or invalid values come back as null and are skipped.
    LocalDate onDate    = toDate(param(request, "date"));
    String    timeOfDay = param(request, "time");          // morning | afternoon | evening
    Integer   trainerId = toInt(param(request, "trainer"));
    Integer   typeId    = toInt(param(request, "type"));
%>
<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Schedule - FitTrack</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>

<body>
<%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="wrap">
    <main>
        <h1 class="page-title">Class schedule</h1>
    <%
        Connection con = null;
        try {
            con = getConnection();

            // dropdown options come from the database
            Statement opts = con.createStatement();
    %>
        <form method="get" action="<%= ctx %>/schedule.jsp">
            <div class="filters">
                <div>
                    <label for="date">Date</label>
                    <input type="date" id="date" name="date" value="<%= onDate == null ? "" : onDate %>">
                </div>
                <div>
                    <label for="time">Time</label>
                    <select id="time" name="time">
                        <option value="">Any time</option>
                        <option value="morning"   <%= "morning".equals(timeOfDay)   ? "selected" : "" %>>Morning (before 12pm)</option>
                        <option value="afternoon" <%= "afternoon".equals(timeOfDay) ? "selected" : "" %>>Afternoon (12-5pm)</option>
                        <option value="evening"   <%= "evening".equals(timeOfDay)   ? "selected" : "" %>>Evening (after 5pm)</option>
                    </select>
                </div>
                <div>
                    <label for="trainer">Trainer</label>
                    <select id="trainer" name="trainer">
                        <option value="">Any trainer</option>
    <%
            ResultSet rs = opts.executeQuery(
                "SELECT t.UserId, u.Name FROM Trainer t "
                + "  JOIN UserAccount u ON u.UserId = t.UserId ORDER BY u.Name");
            while (rs.next()) {
                int id = rs.getInt("UserId");
    %>
                        <option value="<%= id %>" <%= Integer.valueOf(id).equals(trainerId) ? "selected" : "" %>><%= esc(rs.getString("Name")) %></option>
    <%
            }
            rs.close();
    %>
                    </select>
                </div>
                <div>
                    <label for="type">Class type</label>
                    <select id="type" name="type">
                        <option value="">Any class</option>
    <%
            rs = opts.executeQuery("SELECT ClassTypeId, Title FROM ClassType ORDER BY Title");
            while (rs.next()) {
                int id = rs.getInt("ClassTypeId");
    %>
                        <option value="<%= id %>" <%= Integer.valueOf(id).equals(typeId) ? "selected" : "" %>><%= esc(rs.getString("Title")) %></option>
    <%
            }
            rs.close();
            opts.close();
    %>
                    </select>
                </div>
            </div>
            <div class="filter-actions">
                <button class="btn" type="submit">Filter</button>
                <a href="<%= ctx %>/schedule.jsp">Clear</a>
            </div>
        </form>
    <%
            // upcoming classes: start with the fixed part, then add filters
            StringBuilder sql = new StringBuilder(
                "SELECT c.ClassId, c.StartTime, ct.Title, u.Name AS Trainer, c.RoomNumber, c.Capacity, "
                + "       (SELECT COUNT(*) FROM Booking b "
                + "         WHERE b.ClassId = c.ClassId AND b.Status = 'BOOKED') AS Booked "
                + "  FROM `Class` c "
                + "  JOIN ClassType ct  ON ct.ClassTypeId = c.ClassTypeId "
                + "  JOIN UserAccount u ON u.UserId = c.TrainerId "
                + " WHERE c.StartTime >= NOW() ");
            List<Object> params = new ArrayList<>();

            if (onDate != null) {
                sql.append(" AND DATE(c.StartTime) = ? ");
                params.add(onDate);
            }
            // time logic of day is one of three fixed choices, so no ? is needed
            if ("morning".equals(timeOfDay)) {
                sql.append(" AND HOUR(c.StartTime) < 12 ");
            } else if ("afternoon".equals(timeOfDay)) {
                sql.append(" AND HOUR(c.StartTime) BETWEEN 12 AND 16 ");
            } else if ("evening".equals(timeOfDay)) {
                sql.append(" AND HOUR(c.StartTime) >= 17 ");
            }
            if (trainerId != null) {
                sql.append(" AND c.TrainerId = ? ");
                params.add(trainerId);
            }
            if (typeId != null) {
                sql.append(" AND c.ClassTypeId = ? ");
                params.add(typeId);
            }
            sql.append(" ORDER BY c.StartTime");

            PreparedStatement ps = con.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            rs = ps.executeQuery();
    %>
        <table>
            <tr><th>When</th><th>Class</th><th>Trainer</th><th>Room</th><th>Spots left</th></tr>
    <%
            int n = 0;
            while (rs.next()) {
                n++;
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
            if (n == 0) {
    %>
            <tr><td colspan="5" class="muted">No upcoming classes match these filters.
                <a href="<%= ctx %>/schedule.jsp">Clear filters</a></td></tr>
    <%
            }
    %>
        </table>
    <%
            rs.close();
            ps.close();
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
