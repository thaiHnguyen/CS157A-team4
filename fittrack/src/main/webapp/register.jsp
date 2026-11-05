<%--
    register.jsp - FR 1.1.1 Register. A new member creates an account.
    The form posts back to this page.

    On success: UserAccountDAO.insert (Role = MEMBER) and a linked
    MemberDAO.insert, inside a single transaction so we never end up with
    an account that has no Member row. The new member is then signed in.
--%>
<%@ include file="/WEB-INF/jspf/common.jspf" %>
<%
    if (userId != null) {                       // already signed in
        response.sendRedirect(ctx + "/home.jsp");
        return;
    }

    String name = param(request, "name");
    String email = param(request, "email").toLowerCase();
    String phone = param(request, "phone");
    String dobText = param(request, "dob");
    String emergency = param(request, "emergency");
    List<String> errors = new ArrayList<>();

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String password = request.getParameter("password");
        String confirm  = request.getParameter("confirm");
        LocalDate dob = toDate(dobText);

        // ---- validation ----
        if (name.isEmpty())                      errors.add("Enter your full name.");
        else if (name.length() > 120)            errors.add("Name is too long (120 characters max).");
        if (!email.matches("[^@\\s]+@[^@\\s]+\\.[^@\\s]+") || email.length() > 120)
                                                errors.add("Enter a valid email address.");
        if (password == null || password.length() < 6)
                                                    errors.add("Password must be at least 6 characters.");
        else if (!password.equals(confirm))      errors.add("The two passwords do not match.");
        if (!validPhone(phone))                  errors.add("Enter a valid phone number, e.g. 408-555-0100.");
        if (dob == null)                         errors.add("Enter your date of birth.");
        else if (!dob.isBefore(LocalDate.now())) errors.add("Date of birth must be in the past.");
        if (!emergency.isEmpty() && !validPhone(emergency))
                                                    errors.add("Emergency phone is not a valid phone number.");

        if (errors.isEmpty()) {
            Connection con = null;
            try {
                con = getConnection();
                con.setAutoCommit(false);

                UserAccountDAO accounts = new UserAccountDAO(con);

                // Email must be unique. The UNIQUE constraint also guards this;
                // checking first lets us show a friendly message.
                if (accounts.emailExists(email)) {
                    errors.add("An account with that email already exists. Try signing in.");
                    con.rollback();
                } else {
                    UserAccount account = new UserAccount();
                    account.setEmail(email);
                    account.setPasswordHash(hashPassword(password));
                    account.setRole("MEMBER");
                    account.setName(name);
                    account.setPhone(phone);
                    account.setDateOfBirth(dob);
                    int newId = accounts.insert(account);

                    new MemberDAO(con).insert(new Member(newId, emergency.isEmpty() ? null : emergency));

                    con.commit();

                    // sign the new member in
                    request.changeSessionId();
                    session.setAttribute("userId", newId);
                    session.setAttribute("role", "MEMBER");
                    session.setAttribute("fullName", name);
                    session.setAttribute("flash",
                        "ok:Welcome to FitTrack, " + name + "! Choose a membership below to start booking classes.");
                    response.sendRedirect(ctx + "/membership.jsp");
                    return;
                }
            } catch (SQLIntegrityConstraintViolationException e) {
                rollback(con);
                errors.add("An account with that email already exists. Try signing in.");
            } catch (Exception e) {
                rollback(con);
                errors.add("Could not create the account: " + e.getMessage());
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
    <title>Join - FitTrack</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>

<body>
<%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="panel wide">
        <h1>Create your account</h1>
        <p class="sub">Members sign up here. Trainer and staff accounts are created by gym staff.</p>

        <% if (!errors.isEmpty()) { %>
            <div class="error">
                <% for (String err : errors) { %><div><%= esc(err) %></div><% } %>
            </div>
        <% } %>

        <form method="post" action="<%= ctx %>/register.jsp" novalidate>
            <label for="name">Full name</label>
            <input type="text" id="name" name="name" value="<%= esc(name) %>" maxlength="120" required autofocus>

            <label for="email">Email</label>
            <input type="email" id="email" name="email" value="<%= esc(email) %>" maxlength="120" required>

            <div class="row2">
                <div>
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password" minlength="6" required>
                </div>
                <div>
                    <label for="confirm">Confirm password</label>
                    <input type="password" id="confirm" name="confirm" minlength="6" required>
                </div>
            </div>

            <div class="row2">
                <div>
                    <label for="phone">Phone</label>
                    <input type="tel" id="phone" name="phone" value="<%= esc(phone) %>" placeholder="408-555-0100" required>
                </div>
                <div>
                    <label for="dob">Date of birth</label>
                    <input type="date" id="dob" name="dob" value="<%= esc(dobText) %>" required>
                </div>
            </div>

            <label for="emergency">Emergency contact phone <span class="opt">(optional)</span></label>
            <input type="tel" id="emergency" name="emergency" value="<%= esc(emergency) %>">

            <button class="btn" type="submit">Create account</button>
        </form>

        <p class="hint">Already a member? <a href="<%= ctx %>/login.jsp">Sign in</a></p>
    </div>

</body>

</html>
