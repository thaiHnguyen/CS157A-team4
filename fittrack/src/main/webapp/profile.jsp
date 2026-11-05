<%--
    profile.jsp: FR 1.1.2 Update Profile.
    Load the signed-in user's record to pre-fill the form (UserAccountDAO and
    MemberDAO), then update it.
    The UserId always comes from the session, never from the form, so a user
    can only change their own profile. Members also have an emergency phone,
    which lives in the Member table (look at ERD for this detail).
--%>
<%@ include file="/WEB-INF/jspf/common.jspf" %>
<%
    if (userId == null) {
        response.sendRedirect(ctx + "/login.jsp");
        return;
    }

    List<String> errors = new ArrayList<>();
    String name = param(request, "name");
    String phone = param(request, "phone");
    String emergency = param(request, "emergency");
    String email = "";
    LocalDate dob = null;
    LocalDateTime joined = null;

    Connection con = null;
    try {
        con = getConnection();

        if ("POST".equalsIgnoreCase(request.getMethod())) {
            if (name.isEmpty())                errors.add("Name cannot be empty.");
            else if (name.length() > 120)      errors.add("Name is too long (120 characters max).");
            if (!validPhone(phone))            errors.add("Enter a valid phone number, e.g. 408-555-0100.");
            if (isMember && !emergency.isEmpty() && !validPhone(emergency))
                                                errors.add("Emergency phone is not a valid phone number.");

            if (errors.isEmpty()) {
                con.setAutoCommit(false);

                new UserAccountDAO(con).updateContact(userId, name, phone);
                if (isMember) {
                    new MemberDAO(con).updateEmergencyPhone(userId, emergency.isEmpty() ? null : emergency);
                }

                con.commit();
                session.setAttribute("fullName", name);
                session.setAttribute("flash", "ok:Your profile was updated.");
                response.sendRedirect(ctx + "/profile.jsp");
                return;
            }
        }

        // Load the current values. Every user has a UserAccount row; only
        // members have a Member row (trainers and staff get null).
        UserAccount account = new UserAccountDAO(con).findById(userId);
        Member member = isMember ? new MemberDAO(con).findById(userId) : null;
        if (account != null) {
            email = account.getEmail();
            dob = account.getDateOfBirth();
            joined = account.getCreatedAt();
            if (errors.isEmpty()) {              // keep what the user typed if there were errors
                name = account.getName();
                phone = account.getPhone() == null ? "" : account.getPhone();
                emergency = (member == null || member.getEmergencyPhone() == null) ? "" : member.getEmergencyPhone();
            }
        }
    } catch (Exception e) {
        rollback(con);
        errors.add("Could not load or save your profile: " + e.getMessage());
    } finally {
        close(con);
    }
%>
<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Profile - FitTrack</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>

<body>
<%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="panel wide">
        <h1>Your profile</h1>
        <p class="sub">Keep your contact details up to date.</p>

        <% if (!errors.isEmpty()) { %>
            <div class="error">
                <% for (String err : errors) { %><div><%= esc(err) %></div><% } %>
            </div>
        <% } %>

        <dl class="facts">
            <dt>Email</dt>          <dd><%= esc(email) %></dd>
            <dt>Date of birth</dt>  <dd><%= esc(day(dob)) %></dd>
            <dt>Member since</dt>   <dd><%= joined == null ? "" : esc(day(joined.toLocalDate())) %></dd>
        </dl>

        <form method="post" action="<%= ctx %>/profile.jsp" novalidate>
            <label for="name">Full name</label>
            <input type="text" id="name" name="name" value="<%= esc(name) %>" maxlength="120" required>

            <label for="phone">Phone</label>
            <input type="tel" id="phone" name="phone" value="<%= esc(phone) %>" required>

            <% if (isMember) { %>
            <label for="emergency">Emergency contact phone <span class="opt">(optional)</span></label>
            <input type="tel" id="emergency" name="emergency" value="<%= esc(emergency) %>">
            <% } %>

            <button class="btn" type="submit">Save changes</button>
        </form>
    </div>

</body>

</html>
