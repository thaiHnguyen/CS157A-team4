<%@ page import="java.sql.*" %>
<html>

<head>
    <title>FitTrack Home</title>
</head>

<body>
    <h1>FitTrack - Gym Membership System</h1>
    <p>CS157A Fall 2026, Team 4</p>

    <%
        // Same from homework 1, but using fittrack as database name
        String db = "fittrack";
        String user = "root";
        String password = "CHANGE_ME";   // your MySQL workbench password

        Connection con = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            con = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/" + db
                + "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Los_Angeles",
                user, password);
            out.println(db + " database successfully opened.<br/><br/>");

            Statement stmt = con.createStatement();

            //  Upcoming sessions with live remaining spots 
    %>
    <h2>Upcoming sessions</h2>
    <table border="1" cellpadding="5">
        <tr>
            <td>Start time</td>
            <td>Session</td>
            <td>Trainer</td>
            <td>Room</td>
            <td>Capacity</td>
            <td>Booked</td>
            <td>Spots left</td>
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
                    "<td>" + (left <= 0 ? "FULL" : String.valueOf(left)) + "</td>" +
                    "</tr>"
                );
            }
            rs.close();
    %>
    </table>
    <h2>Membership tiers</h2>
    <table border="1" cellpadding="5">
        <tr>
            <td>Level</td>
            <td>Tier</td>
            <td>Monthly fee</td>
            <td>Description</td>
        </tr>
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
                    "</tr>"
                );
            }
            rs.close();
            stmt.close();
    %>
    </table>
    <%
        } catch (SQLException e) {
            out.println("SQLException caught: " + e.getMessage());
        } finally {
            if (con != null) {
                try { con.close(); } catch (SQLException ignore) { }
            }
        }
    %>
</body>

</html>
