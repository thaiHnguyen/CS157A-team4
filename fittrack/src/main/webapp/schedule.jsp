<%--
    schedule.jsp - FR 1.1.4 Browse Available Session Schedule.
    Lists every upcoming class with its trainer, room, and live remaining spots.
    Optional filters for date, time of day, trainer, and class type are read
    from the URL (GET) and passed to ClassDAO.search, which adds an AND to the
    WHERE for each one that is set.
    FR 1.1.5: members also get a Book button on each open class, which posts
    to book.jsp.
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

    // Load the dropdown options and the matching classes, then render.
    // ClassDAO.search adds one AND to the WHERE for each filter that is set.
    List<Trainer>   trainers = new ArrayList<>();
    List<ClassType> types    = new ArrayList<>();
    List<GymClass>  classes  = new ArrayList<>();
    String loadError = null;

    Connection con = null;
    try {
        con = getConnection();
        trainers = new TrainerDAO(con).findAll();
        types    = new ClassTypeDAO(con).findAll();
        classes  = new ClassDAO(con).search(userId, onDate, timeOfDay, trainerId, typeId);
    } catch (Exception e) {
        loadError = "Could not load gym data: " + e.getMessage();
    } finally {
        close(con);
    }

    // book.jsp and cancel.jsp send the member back here with the same filters
    String back = request.getQueryString() == null ? "" : request.getQueryString();
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
    <% if (loadError != null) { %>
        <p class="error"><%= esc(loadError) %></p>
    <% } else { %>
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
            for (Trainer t : trainers) {
                int id = t.getUserId();
    %>
                        <option value="<%= id %>" <%= Integer.valueOf(id).equals(trainerId) ? "selected" : "" %>><%= esc(t.getName()) %></option>
    <%
            }
    %>
                    </select>
                </div>
                <div>
                    <label for="type">Class type</label>
                    <select id="type" name="type">
                        <option value="">Any class</option>
    <%
            for (ClassType t : types) {
                int id = t.getClassTypeId();
    %>
                        <option value="<%= id %>" <%= Integer.valueOf(id).equals(typeId) ? "selected" : "" %>><%= esc(t.getTitle()) %></option>
    <%
            }
    %>
                    </select>
                </div>
            </div>
            <div class="filter-actions">
                <button class="btn" type="submit">Filter</button>
                <a href="<%= ctx %>/schedule.jsp">Clear</a>
            </div>
        </form>
        <table>
            <tr><th>When</th><th>Class</th><th>Trainer</th><th>Room</th><th>Spots left</th>
                <% if (isMember) { %><th></th><% } %></tr>
    <%
            for (GymClass c : classes) {
                int left = c.getSpotsLeft();
                boolean mine = c.isBookedByMe();
    %>
            <tr>
                <td class="nowrap"><%= when(c.getStartTime()) %></td>
                <td><%= esc(c.getTitle()) %></td>
                <td><%= esc(c.getTrainerName()) %></td>
                <td><%= esc(c.getRoomNumber()) %></td>
                <% if (left <= 0) { %><td class="full">FULL</td><% } else { %><td class="left"><%= left %></td><% } %>
                <% if (isMember) { %>
                <td class="nowrap">
                    <% if (mine) { %>
                    <span class="muted">Booked &#10003;</span>
                    <%-- FR 1.1.6: cancel this booking (cancel.jsp) --%>
                    <form method="post" action="<%= ctx %>/cancel.jsp" class="inline"
                        onsubmit="return confirm('Cancel your booking for this class?');">
                        <input type="hidden" name="classId" value="<%= c.getClassId() %>">
                        <input type="hidden" name="back" value="<%= esc(back) %>">
                        <button class="btn-quiet btn-sm" type="submit">Cancel</button>
                    </form>
                    <% } else if (left > 0) { %>
                    <form method="post" action="<%= ctx %>/book.jsp">
                        <input type="hidden" name="classId" value="<%= c.getClassId() %>">
                        <input type="hidden" name="back" value="<%= esc(back) %>">
                        <button class="btn btn-sm" type="submit">Book</button>
                    </form>
                    <% } %>
                </td>
                <% } %>
            </tr>
    <%
            }
            if (classes.isEmpty()) {
    %>
            <tr><td colspan="<%= isMember ? 6 : 5 %>" class="muted">No upcoming classes match these filters.
                <a href="<%= ctx %>/schedule.jsp">Clear filters</a></td></tr>
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
