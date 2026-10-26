<%--
    login.jsp - FR 1.1.1 Login. All subclasses of UserAccount(Members, trainers, and staff) all use this form. 
    The form posts back to this page.
    SELECT the account by email, compare the salted password hash, and store
    userId, role, and fullName in the HTTP session.
--%>
<%@ include file="/WEB-INF/jspf/common.jspf" %>
<%
    // Check if user is already signed in. if so, redirect to home page.
    if (userId != null) {                       
        response.sendRedirect(ctx + "/home.jsp");
        return;
    }

    String error = null;
    String email = param(request, "email");

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String typedPassword = request.getParameter("password");

        // If either email or password is invalid or empty, show error
        if (email.isEmpty() || typedPassword == null || typedPassword.isEmpty()) {
            error = "Enter both your email and your password.";
        } else {
            Connection con = null;
            try {
                con = getConnection();

                // Look up account by email, then check pwd hash here
                PreparedStatement ps = con.prepareStatement(
                    "SELECT UserId, Role, Name, PasswordHash FROM UserAccount WHERE Email = ?");
                ps.setString(1, email);
                ResultSet rs = ps.executeQuery();
                
                if (rs.next() && checkPassword(typedPassword, rs.getString("PasswordHash"))) {
                    request.changeSessionId();          // new session id after login
                    session.setAttribute("userId",   rs.getInt("UserId"));
                    session.setAttribute("role",     rs.getString("Role"));
                    session.setAttribute("fullName", rs.getString("Name"));
                    rs.close();
                    ps.close();
                    response.sendRedirect(ctx + "/home.jsp");
                    return;
                }

                // Same message whether the email or the password was wrong,
                // so the form does not reveal which emails have accounts.
                error = "That email and password do not match an account.";
                rs.close();
                ps.close();
            } catch (Exception e) {
                error = "Could not reach the database: " + e.getMessage();
            } finally {
                close(con);
            }
        }
    }
%>
<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Sign in - FitTrack</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>

<body>
<%@ include file="/WEB-INF/jspf/topbar.jspf" %>
    <div class="panel">
        <h1>Sign in</h1>
        <p class="sub">Members, trainers, and staff all use this form.</p>

        <% if (error != null) { %>
            <p class="error"><%= esc(error) %></p>
        <% } %>
        
        <form method="post" action="<%= ctx %>/login.jsp">
            <label for="email">Email</label>
            <input type="email" id="email" name="email" value="<%= esc(email) %>" autofocus>

            <label for="password">Password</label>
            <input type="password" id="password" name="password">

            <button class="btn" type="submit">Sign in</button>
        </form>

        <p class="hint">New here? <a href="<%= ctx %>/register.jsp">Create a member account</a></p>
        <p class="hint">Demo accounts: thai.nguyen@example.com (member),
            john.doe@fittrack.test (trainer), nina.alvarez@fittrack.test (staff).
            Password for all: demo123</p>
    </div>

</body>

</html>
