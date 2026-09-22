<%--
  index.jsp -- public landing page. No login required, no database access.
  Tomcat serves this automatically at http://localhost:8080/fittrack/
--%>
<%
    String fullName = (String) session.getAttribute("fullName");
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>FitTrack - Gym Membership System</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>

<body>

    <div class="topbar">
        <div class="wrap">
            <a class="brand" href="<%= ctx %>/index.jsp">FitTrack</a>
            <nav>
                <% if (fullName == null) { %>
                    <a href="<%= ctx %>/login.jsp">Sign in</a>
                <% } else { %>
                    <span class="who">Signed in as <strong><%= fullName %></strong></span>
                    <a href="<%= ctx %>/home.jsp">Dashboard</a>
                    <a class="btn-quiet" href="<%= ctx %>/logout.jsp">Log out</a>
                <% } %>
            </nav>
        </div>
    </div>

    <div class="hero">
        <div class="wrap">
            <h1>Your gym, your schedule, one place.</h1>
            <p>Book sessions, track your membership, and check in without asking
               staff. Trainers see their rosters, staff see everything.</p>
            <% if (fullName == null) { %>
                <a class="btn" href="<%= ctx %>/login.jsp">Sign in</a>
            <% } else { %>
                <a class="btn" href="<%= ctx %>/home.jsp">Go to dashboard</a>
            <% } %>
        </div>
    </div>

    <div class="wrap">
        <div class="features">
            <div class="card">
                <h3>Members</h3>
                <p>See what is on this week, book a spot, and view your attendance
                   history and membership status.</p>
            </div>
            <div class="card">
                <h3>Trainers</h3>
                <p>Check the roster for each session you lead and record attendance
                   without paper sign-in sheets.</p>
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
