<%--
  login.jsp - the form posts back to this page
--%>
<%@ page import="java.sql.*" %>
<%
    String ctx = request.getContextPath();
    String error = null;
    String email = "";

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        email = request.getParameter("email");
        String typedPassword = request.getParameter("password");

        if (email == null || email.trim().isEmpty()
                || typedPassword == null || typedPassword.isEmpty()) {
            error = "Enter both your email and your password.";
        } else {
            Connection con = null;
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                con = DriverManager.getConnection(
                    "jdbc:mysql://localhost:3306/fittrack"
                    + "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Los_Angeles",
                    "root", "CHANGE_ME");

                PreparedStatement ps = con.prepareStatement(
                    "SELECT u.UserId, u.Role, u.PasswordHash, "
                  + "       COALESCE(m.FullName, t.FullName, 'Staff') AS FullName "
                  + "  FROM UserAccount u "
                  + "  LEFT JOIN Member  m ON m.UserId = u.UserId "
                  + "  LEFT JOIN Trainer t ON t.UserId = u.UserId "
                  + " WHERE u.Email = ?");
                ps.setString(1, email.trim());

                ResultSet rs = ps.executeQuery();
                if (rs.next() && rs.getString("PasswordHash").equals(typedPassword)) {
                    session.setAttribute("userId",   rs.getInt("UserId"));
                    session.setAttribute("role",     rs.getString("Role"));
                    session.setAttribute("fullName", rs.getString("FullName"));
                    rs.close();
                    ps.close();
                    con.close();
                    response.sendRedirect(ctx + "/home.jsp");
                    return;
                }
                error = "That email and password do not match an account.";
                rs.close();
                ps.close();
            } catch (Exception e) {
                error = "Could not reach the database: " + e.getMessage();
            } finally {
                if (con != null) { try { con.close(); } catch (SQLException ignore) { } }
            }
        }
    }
%>
<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Sign in -- FitTrack</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>

<body>

    <div class="topbar">
        <div class="wrap">
            <a class="brand" href="<%= ctx %>/index.jsp">FitTrack</a>
            <nav><a href="<%= ctx %>/index.jsp">Back to home</a></nav>
        </div>
    </div>

    <div class="panel">
        <h1>Sign in</h1>
        <p class="sub">Members, trainers, and staff all use this form.</p>

        <% if (error != null) { %>
            <p class="error"><%= error %></p>
        <% } %>

        <form method="post" action="<%= ctx %>/login.jsp">
            <label for="email">Email</label>
            <input type="text" id="email" name="email" value="<%= email == null ? "" : email %>" autofocus>

            <label for="password">Password</label>
            <input type="password" id="password" name="password">

            <button class="btn" type="submit">Sign in</button>
        </form>

        <p class="hint">Demo accounts: thai.nguyen@example.com (member),
           john.doe@fittrack.test (trainer), staff@fittrack.test (staff).
           Password for all three: demo123</p>
    </div>

</body>

</html>
