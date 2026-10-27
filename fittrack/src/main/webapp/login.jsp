
<%--
    login.jsp - FR 1.1.1 Login

    Members, trainers, and staff use this form.

    Database structure:

    UserAccount:
        UserId
        Email
        PasswordHash
        Role
        CreatedAt

    Member:
        MemberId
        UserId
        FullName
        Phone
        DateOfBirth

    Login process:
    1. Find the account by email.
    2. Verify the password hash.
    3. Store userId, role, and fullName in session.
    4. Redirect to the dashboard.
--%>

<%@ include file="/WEB-INF/jspf/common.jspf" %>

<%
    // Redirect users who are already signed in.
    if (userId != null) {
        response.sendRedirect(ctx + "/home.jsp");
        return;
    }

    String error = null;
    String email = param(request, "email");

    if ("POST".equalsIgnoreCase(request.getMethod())) {

        String typedPassword =
            request.getParameter("password");

        // -----------------------------
        // Input validation
        // -----------------------------

        if (email.isEmpty()
                || typedPassword == null
                || typedPassword.isEmpty()) {

            error = "Enter both your email and your password.";

        } else {

            Connection con = null;

            try {

                con = getConnection();

                // -----------------------------
                // Retrieve account information
                // -----------------------------

                // Member names are stored in Member.FullName.
                // LEFT JOIN also allows trainer and staff
                // accounts to authenticate successfully.

                String sql =
                    "SELECT "
                    + "u.UserId, "
                    + "u.Email, "
                    + "u.Role, "
                    + "u.PasswordHash, "
                    + "m.FullName "
                    + "FROM UserAccount u "
                    + "LEFT JOIN Member m "
                    + "ON m.UserId = u.UserId "
                    + "WHERE u.Email = ?";

                try (PreparedStatement ps =
                        con.prepareStatement(sql)) {

                    ps.setString(1, email);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (rs.next()) {

                            String storedHash =
                                rs.getString("PasswordHash");

                            // Verify password using existing
                            // password hashing utility.
                            if (checkPassword(
                                    typedPassword,
                                    storedHash)) {

                                int loginUserId =
                                    rs.getInt("UserId");

                                String loginRole =
                                    rs.getString("Role");

                                String loginName =
                                    rs.getString("FullName");

                                // Trainer and staff names may
                                // be stored in separate tables.
                                // Use a fallback until their
                                // structures are verified.
                                if (loginName == null
                                        || loginName.trim().isEmpty()) {

                                    String accountEmail =
                                        rs.getString("Email");

                                    loginName =
                                        accountEmail.substring(
                                            0,
                                            accountEmail.indexOf("@")
                                        );
                                }

                                // -----------------------------
                                // Create authenticated session
                                // -----------------------------

                                request.changeSessionId();

                                session.setAttribute(
                                    "userId",
                                    loginUserId
                                );

                                session.setAttribute(
                                    "role",
                                    loginRole
                                );

                                session.setAttribute(
                                    "fullName",
                                    loginName
                                );

                                // Redirect to dashboard.
                                response.sendRedirect(
                                    ctx + "/home.jsp"
                                );

                                return;
                            }
                        }
                    }
                }

                // Use the same message for invalid emails
                // and incorrect passwords.
                error =
                    "That email and password do not match an account.";

            } catch (Exception e) {

                application.log("FitTrack login error", e);

                error =
                    "Unable to sign in right now. "
                    + "Please try again or contact staff.";

            } finally {

                close(con);
            }
        }
    }
%>

<!DOCTYPE html>
<html lang="en">

<head>

    <meta charset="UTF-8">

    <meta name="viewport"
          content="width=device-width, initial-scale=1">

    <title>Sign in - FitTrack</title>

    <link rel="stylesheet"
          href="<%= ctx %>/css/style.css">

</head>

<body>

<%@ include file="/WEB-INF/jspf/topbar.jspf" %>

<div class="panel">

    <h1>Sign in</h1>

    <p class="sub">
        Members, trainers, and staff all use this form.
    </p>

    <%-- Display login errors --%>

    <% if (error != null) { %>

        <p class="error" role="alert">
            <%= esc(error) %>
        </p>

    <% } %>

    <%-- Login form --%>

    <form method="post"
          action="<%= ctx %>/login.jsp">

        <label for="email">
            Email
        </label>

        <input
            type="email"
            id="email"
            name="email"
            value="<%= esc(email) %>"
            autocomplete="username"
            required
            autofocus
        >

        <label for="password">
            Password
        </label>

        <input
            type="password"
            id="password"
            name="password"
            autocomplete="current-password"
            required
        >

        <button class="btn" type="submit">
            Sign in
        </button>

    </form>

    <p class="hint">
        New here?
        <a href="<%= ctx %>/register.jsp">
            Create a member account
        </a>
    </p>

    <p class="hint">
        Demo accounts:
        thai.nguyen@example.com (member),
        john.doe@fittrack.test (trainer),
        nina.alvarez@fittrack.test (staff).
        Password for all: demo123
    </p>

</div>

</body>
</html>
