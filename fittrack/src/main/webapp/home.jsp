<%--
    home.jsp -- acts as main/home page 
--%>
<%@ page import="java.sql.*" %>
<%
    String ctx = request.getContextPath();
    String fullName = (String) session.getAttribute("fullName");
    String role = (String) session.getAttribute("role");

    if (fullName == null) {
        response.sendRedirect(ctx + "/login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Dashboard -- FitTrack</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>

<body>

    <div class="topbar">
        <div class="wrap">
            <a class="brand" href="<%= ctx %>/index.jsp">FitTrack</a>
            <nav>
                <span class="who">Signed in as <strong><%= fullName %></strong> (<%= role %>)</span>
                <a class="btn-quiet" href="<%= ctx %>/logout.jsp">Log out</a>
            </nav>
        </div>
    </div>

    <div class="wrap">
    <main>
    <%
        Connection con = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            con = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/fittrack"
                + "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Los_Angeles",
                "root", "CHANGE_ME");

            Statement stmt = con.createStatement();
    %>
        <h2>Upcoming sessions</h2>
        <p class="note">Spots left is capacity minus the bookings with status
           BOOKED, counted when this page loads.</p>

        <table>
            <tr>
                <th>Start time</th><th>Session</th><th>Trainer</th>
                <th>Room</th><th>Capacity</th><th>Booked</th><th>Spots left</th>
            </tr>
    <%
            ResultSet rs = stmt.executeQuery(
                "SELECT sc.StartTime, s.Title, t.FullName, sc.RoomNumber, sc.Capacity, "
              + "       (SELECT COUNT(*) FROM SessionBooking b "
              + "         WHERE b.ScheduleId = sc.ScheduleId AND b.Status = 'BOOKED') AS Booked "
              + "  FROM Schedule sc "
              + "  JOIN `Session` s ON s.SessionId = sc.SessionId "
              + "  JOIN Trainer  t ON t.TrainerId = sc.TrainerId "
              + " WHERE sc.StartTime >= NOW() "
              + " ORDER BY sc.StartTime");

            while (rs.next()) {
                int capacity = rs.getInt("Capacity");
                int booked = rs.getInt("Booked");
                int left = capacity - booked;
                out.println(
                    "<tr>" +
                    "<td>" + rs.getTimestamp("StartTime") + "</td>" +
                    "<td>" + rs.getString("Title") + "</td>" +
                    "<td>" + rs.getString("FullName") + "</td>" +
                    "<td>" + rs.getString("RoomNumber") + "</td>" +
                    "<td>" + capacity + "</td>" +
                    "<td>" + booked + "</td>" +
                    (left <= 0
                        ? "<td class=\"full\">FULL</td>"
                        : "<td class=\"left\">" + left + "</td>") +
                    "</tr>");
            }
            rs.close();
    %>
        </table>

        <h2>Membership tiers</h2>
        <table>
            <tr><th>Level</th><th>Tier</th><th>Monthly fee</th><th>Description</th></tr>
    <%
            rs = stmt.executeQuery(
                "SELECT TierLevel, TierName, MonthlyFee, Description "
              + "  FROM MembershipTier ORDER BY TierLevel");

            while (rs.next()) {
                out.println(
                    "<tr>" +
                    "<td>" + rs.getInt("TierLevel") + "</td>" +
                    "<td>" + rs.getString("TierName") + "</td>" +
                    "<td>$" + rs.getBigDecimal("MonthlyFee") + "</td>" +
                    "<td>" + rs.getString("Description") + "</td>" +
                    "</tr>");
            }
            rs.close();
            stmt.close();
    %>
        </table>
    <%
        } catch (Exception e) {
            out.println("<p class=\"error\">Could not load gym data: " + e.getMessage() + "</p>");
        } finally {
            if (con != null) { try { con.close(); } catch (SQLException ignore) { } }
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
