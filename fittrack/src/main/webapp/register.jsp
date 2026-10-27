
<%--
    register.jsp - FitTrack Member Registration

    Creates a UserAccount and a linked Member record.
    Both inserts run in one transaction.

    Database tables:
    UserAccount(UserId, Email, PasswordHash, Role, CreatedAt)
    Member(MemberId, UserId, FullName, Phone, DateOfBirth)
--%>

<%@ include file="/WEB-INF/jspf/common.jspf" %>

<%
    // Redirect users who are already logged in.
    if (userId != null) {
        response.sendRedirect(ctx + "/home.jsp");
        return;
    }

    // Read registration form values.
    String name = param(request, "name");
    String email = param(request, "email").toLowerCase();
    String phone = param(request, "phone");
    String dobText = param(request, "dob");

    // Kept in the form for compatibility.
    // The current Member table does not have an emergency phone column.
    String emergency = param(request, "emergency");

    List<String> errors = new ArrayList<>();

    if ("POST".equalsIgnoreCase(request.getMethod())) {

        String password = request.getParameter("password");
        String confirm = request.getParameter("confirm");

        LocalDate dob = toDate(dobText);

        // -----------------------------
        // Input validation
        // -----------------------------

        if (name.isEmpty()) {
            errors.add("Enter your full name.");
        } else if (name.length() > 120) {
            errors.add("Name is too long (120 characters max).");
        }

        if (!email.matches("[^@\\s]+@[^@\\s]+\\.[^@\\s]+")
                || email.length() > 120) {
            errors.add("Enter a valid email address.");
        }

        if (password == null || password.length() < 6) {
            errors.add("Password must be at least 6 characters.");
        } else if (!password.equals(confirm)) {
            errors.add("The two passwords do not match.");
        }

        if (!validPhone(phone)) {
            errors.add("Enter a valid phone number, e.g. 408-555-0100.");
        }

        if (dob == null) {
            errors.add("Enter your date of birth.");
        } else if (!dob.isBefore(LocalDate.now())) {
            errors.add("Date of birth must be in the past.");
        }

        // -----------------------------
        // Database registration
        // -----------------------------

        if (errors.isEmpty()) {

            Connection con = null;

            try {
                con = getConnection();
                con.setAutoCommit(false);

                // Check whether email is already registered.
                boolean taken;

                try (PreparedStatement check = con.prepareStatement(
                        "SELECT 1 FROM UserAccount WHERE Email = ?")) {

                    check.setString(1, email);

                    try (ResultSet rs = check.executeQuery()) {
                        taken = rs.next();
                    }
                }

                if (taken) {

                    errors.add(
                        "An account with that email already exists. Try signing in."
                    );

                    con.rollback();

                } else {

                    // -----------------------------
                    // Insert into UserAccount
                    // -----------------------------

                    int newId;

                    String accountSql =
                        "INSERT INTO UserAccount "
                        + "(Email, PasswordHash, Role) "
                        + "VALUES (?, ?, 'MEMBER')";

                    try (PreparedStatement ins = con.prepareStatement(
                            accountSql,
                            Statement.RETURN_GENERATED_KEYS)) {

                        ins.setString(1, email);
                        ins.setString(2, hashPassword(password));

                        ins.executeUpdate();

                        try (ResultSet keys = ins.getGeneratedKeys()) {

                            if (!keys.next()) {
                                throw new java.sql.SQLException(
                                    "Could not retrieve new user ID."
                                );
                            }

                            newId = keys.getInt(1);
                        }
                    }

                    // -----------------------------
                    // Insert into Member
                    // -----------------------------

                    String memberSql =
                        "INSERT INTO Member "
                        + "(UserId, FullName, Phone, DateOfBirth) "
                        + "VALUES (?, ?, ?, ?)";

                    try (PreparedStatement mem =
                            con.prepareStatement(memberSql)) {

                        mem.setInt(1, newId);
                        mem.setString(2, name);
                        mem.setString(3, phone);
                        mem.setDate(
                            4,
                            java.sql.Date.valueOf(dob)
                        );

                        mem.executeUpdate();
                    }

                    // Both inserts succeeded.
                    con.commit();

                    // -----------------------------
                    // Automatically sign in member
                    // -----------------------------

                    request.changeSessionId();

                    session.setAttribute("userId", newId);
                    session.setAttribute("role", "MEMBER");
                    session.setAttribute("fullName", name);

                    session.setAttribute(
                        "flash",
                        "ok:Welcome to FitTrack, " + name
                        + "! Your account has been created successfully."
                    );

                    response.sendRedirect(ctx + "/home.jsp");
                    return;
                }

            } catch (SQLIntegrityConstraintViolationException e) {

                rollback(con);

                errors.add(
                    "Registration could not be completed. "
                    + "The email may already be registered."
                );

            } catch (Exception e) {

                rollback(con);

                // Log detailed errors on the server only.
                application.log("FitTrack registration failed", e);

                errors.add(
                    "Could not create the account. "
                    + "Please check the server log or contact staff."
                );

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

    <title>Join - FitTrack</title>

    <link rel="stylesheet"
          href="<%= ctx %>/css/style.css">
</head>

<body>

<%@ include file="/WEB-INF/jspf/topbar.jspf" %>

<div class="panel wide">

    <h1>Create your account</h1>

    <p class="sub">
        Members sign up here. Trainer and staff accounts
        are created by gym staff.
    </p>

    <%-- Display validation and database errors --%>

    <% if (!errors.isEmpty()) { %>

        <div class="error" role="alert">

            <% for (String err : errors) { %>

                <div><%= esc(err) %></div>

            <% } %>

        </div>

    <% } %>

    <form method="post"
          action="<%= ctx %>/register.jsp">

        <label for="name">Full name</label>

        <input
            type="text"
            id="name"
            name="name"
            value="<%= esc(name) %>"
            maxlength="120"
            required
            autofocus
        >

        <label for="email">Email</label>

        <input
            type="email"
            id="email"
            name="email"
            value="<%= esc(email) %>"
            maxlength="120"
            required
        >

        <div class="row2">

            <div>

                <label for="password">Password</label>

                <input
                    type="password"
                    id="password"
                    name="password"
                    minlength="6"
                    required
                >

            </div>

            <div>

                <label for="confirm">Confirm password</label>

                <input
                    type="password"
                    id="confirm"
                    name="confirm"
                    minlength="6"
                    required
                >

            </div>

        </div>

        <div class="row2">

            <div>

                <label for="phone">Phone</label>

                <input
                    type="tel"
                    id="phone"
                    name="phone"
                    value="<%= esc(phone) %>"
                    placeholder="408-555-0100"
                    required
                >

            </div>

            <div>

                <label for="dob">Date of birth</label>

                <input
                    type="date"
                    id="dob"
                    name="dob"
                    value="<%= esc(dobText) %>"
                    required
                >

            </div>

        </div>

        <%-- Emergency contact is not currently stored.
             Add this field back when the database supports it. --%>

        <button class="btn" type="submit">
            Create account
        </button>

    </form>

    <p class="hint">
        Already a member?
        <a href="<%= ctx %>/login.jsp">Sign in</a>
    </p>

</div>

</body>
</html>
