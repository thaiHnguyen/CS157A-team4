<%--
    trainer.jsp - FR 1.2.1 View Assigned Members and Classes
    A trainer sees the classes they lead (from today on) with how many spots
    are booked. ?classId=N also lists the members with a BOOKED spot in it.
    Data comes from ClassDAO.findLedBy and BookingDAO.findRoster.
    The TrainerId always comes from the session, and findRoster checks that
    this trainer leads the class, so another trainer's ClassId shows nothing.
--%>
<%@ include file="/WEB-INF/jspf/common.jspf" %>
<%
    if (userId == null) {
        response.sendRedirect(ctx + "/login.jsp");
        return;
    }
    if (!"TRAINER".equals(role)) {              // only trainers have assigned classes
        response.sendRedirect(ctx + "/home.jsp");
        return;
    }

    Integer classId = toInt(param(request, "classId"));   // null = no class picked yet

    List<GymClass> myClasses = new ArrayList<>();
    List<RosterEntry> roster = new ArrayList<>();
    GymClass picked = null;
    String loadError = null;

    Connection con = null;
    try {
        con = getConnection();
        myClasses = new ClassDAO(con).findLedBy(userId);
        if (classId != null) {
            for (GymClass c : myClasses) {
                if (c.getClassId() == classId) picked = c;
            }
            if (picked != null) {
                roster = new BookingDAO(con).findRoster(userId, classId);
            }
        }
    } catch (Exception e) {
        loadError = "Could not load your classes: " + e.getMessage();
    } finally {
        close(con);
    }
%>
<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>My classes - FitTrack</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>

<body>
<%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="wrap">
    <main>
        <h1 class="page-title">My classes</h1>
    <% if (loadError != null) { %>
        <p class="error"><%= esc(loadError) %></p>
    <% } else { %>
        <p class="note">Classes you lead, from today on. Pick one to see who is booked.</p>
        <table>
            <tr><th>When</th><th>Class</th><th>Room</th><th>Booked</th><th></th></tr>
    <%
            for (GymClass c : myClasses) {
    %>
            <tr>
                <td class="nowrap"><%= when(c.getStartTime()) %></td>
                <td><%= esc(c.getTitle()) %></td>
                <td><%= esc(c.getRoomNumber()) %></td>
                <td><%= c.getBooked() %> / <%= c.getCapacity() %></td>
                <td class="nowrap">
                    <a class="btn-quiet btn-sm" href="<%= ctx %>/trainer.jsp?classId=<%= c.getClassId() %>">Roster</a>
                </td>
            </tr>
    <%
            }
            if (myClasses.isEmpty()) {
    %>
            <tr><td colspan="5" class="muted">You have no upcoming classes.</td></tr>
    <%
            }
    %>
        </table>

    <%
            if (classId != null) {
                if (picked == null) {
    %>
        <p class="error">That class is not one of yours.</p>
    <%
                } else {
    %>
        <h2>Booked members: <%= esc(picked.getTitle()) %>, <%= when(picked.getStartTime()) %></h2>
        <table>
            <tr><th>Name</th><th>Email</th><th>Phone</th><th>Booked at</th></tr>
    <%
                    for (RosterEntry r : roster) {
    %>
            <tr>
                <td><%= esc(r.getName()) %></td>
                <td><%= esc(r.getEmail()) %></td>
                <td><%= esc(r.getPhone()) %></td>
                <td class="nowrap"><%= when(r.getBookedAt()) %></td>
            </tr>
    <%
                    }
                    if (roster.isEmpty()) {
    %>
            <tr><td colspan="4" class="muted">No one has booked this class yet.</td></tr>
    <%
                    }
    %>
        </table>
    <%
                }
            }
    %>
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