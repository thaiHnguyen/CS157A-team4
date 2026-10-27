<%--
    index.jsp - public landing page. No login required, no database access.
    Tomcat serves this automatically at http://localhost:8080/fittrack/
--%>
<%@ include file="/WEB-INF/jspf/common.jspf" %>
<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>FitTrack - Gym Membership System</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>

<body>

<%@ include file="/WEB-INF/jspf/topbar.jspf" %>
<% if (request.getParameter("loggedOut") != null && userId == null) { %>
    <div class="wrap"><p class="success flash">You have been signed out.</p></div>
<% } %>

    <div class="hero">
        <div class="wrap">
            <h1>Your gym, your schedule, one place.</h1>
            <p>Book sessions, track your membership, and check in without asking
                staff. Trainers see their rosters, staff see everything.</p>
            <% if (userId == null) { %>
                <a class="btn" href="<%= ctx %>/register.jsp">Become a member</a>
                <a class="btn-quiet" href="<%= ctx %>/login.jsp">Sign in</a>
            <% } else { %>
                <a class="btn" href="<%= ctx %>/home.jsp">Go to dashboard</a>
            <% } %>
        </div>
    </div>

    <div class="wrap">
        <div class="features">
            <div class="card">
                <h3>Members</h3>
                <p>See what is on this week, book a class, and view your attendance
                    history and membership status.</p>
            </div>
            <div class="card">
                <h3>Trainers</h3>
                <p>Check the roster for each class you lead and record attendance
                    digitally.</p>
            </div>
            <div class="card">
                <h3>Staff</h3>
                <p>Manage members, membership tiers, trainers, and the session
                    schedule from a single dashboard.</p>
            </div>
        </div>
    </div>

    <footer>
        <div class="wrap">
            <p>FitTrack - CS157A Fall 2026 Project, Team 4.
                Wesley Kieu, Thai Nguyen, Hari Sowmith Reddy Vedanaparthi.</p>
        </div>
    </footer>

</body>

</html>
