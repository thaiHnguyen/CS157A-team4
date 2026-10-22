<%--
    profile.jsp: FR 1.1.2 Update Profile.
    SELECT the signed-in user's record to pre-fill the form, then UPDATE it.
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

                PreparedStatement up = con.prepareStatement(
                    "UPDATE UserAccount SET Name = ?, Phone = ? WHERE UserId = ?");
                up.setString(1, name);
                up.setString(2, phone);
                up.setInt(3, userId);
                up.executeUpdate();
                up.close();

                if (isMember) {
                    PreparedStatement em = con.prepareStatement(
                        "UPDATE Member SET EmergencyPhoneNumber = ? WHERE UserId = ?");
                    em.setString(1, emergency.isEmpty() ? null : emergency);
                    em.setInt(2, userId);
                    em.executeUpdate();
                    em.close();
                }

                con.commit();
                session.setAttribute("fullName", name);
                session.setAttribute("flash", "ok:Your profile was updated.");
                response.sendRedirect(ctx + "/profile.jsp");
                return;
            }
        }

        // Load the current values,, use LEFT JOIN to you always get the UserAccount row, 
        // whether or not there is a matching Member row
        PreparedStatement ps = con.prepareStatement(
            "SELECT u.Email, u.Name, u.Phone, u.DateOfBirth, u.CreatedAt, m.EmergencyPhoneNumber "
            + "  FROM UserAccount u "
            + "  LEFT JOIN Member m ON m.UserId = u.UserId "        
            + " WHERE u.UserId = ?");
        ps.setInt(1, userId);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            email = rs.getString("Email");
            dob = rs.getObject("DateOfBirth", LocalDate.class);
            joined = rs.getObject("CreatedAt", LocalDateTime.class);
            if (errors.isEmpty()) {              // keep what the user typed if there were errors
                name = rs.getString("Name");
                phone = rs.getString("Phone") == null ? "" : rs.getString("Phone");
                emergency = rs.getString("EmergencyPhoneNumber") == null ? "" : rs.getString("EmergencyPhoneNumber");
            }
        }
        rs.close();
        ps.close();
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
