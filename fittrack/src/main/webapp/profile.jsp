
<%--
    profile.jsp - FitTrack User Profile

    Members can view and update their personal information.

    UserAccount:
        UserId, Email, PasswordHash, Role, CreatedAt

    Member:
        MemberId, UserId, FullName, Phone, DateOfBirth

    The UserId is retrieved from the session, not the form.
--%>

<%@ include file="/WEB-INF/jspf/common.jspf" %>

<%
    // Require authentication.
    if (userId == null) {
        response.sendRedirect(ctx + "/login.jsp");
        return;
    }

    List<String> errors = new ArrayList<>();

    String name = param(request, "name");
    String phone = param(request, "phone");

    String email = "";
    LocalDate dob = null;
    LocalDateTime joined = null;

    boolean profileFound = false;
    boolean isPost = "POST".equalsIgnoreCase(request.getMethod());

    // The current database stores editable profile fields
    // in Member, not UserAccount.
    boolean canEdit = isMember;

    Connection con = null;

    try {
        con = getConnection();

        // ---------------------------------------
        // Update member profile
        // ---------------------------------------

        if (isPost) {

            if (!canEdit) {
                errors.add(
                    "Profile editing is currently available for members only."
                );
            } else {

                if (name.isEmpty()) {
                    errors.add("Name cannot be empty.");
                } else if (name.length() > 120) {
                    errors.add(
                        "Name is too long (120 characters max)."
                    );
                }

                if (!validPhone(phone)) {
                    errors.add(
                        "Enter a valid phone number, e.g. 408-555-0100."
                    );
                }

                if (errors.isEmpty()) {

                    String updateSql =
                        "UPDATE Member "
                        + "SET FullName = ?, Phone = ? "
                        + "WHERE UserId = ?";

                    try (PreparedStatement up =
                            con.prepareStatement(updateSql)) {

                        up.setString(1, name);
                        up.setString(2, phone);
                        up.setInt(3, userId);

                        int updated = up.executeUpdate();

                        if (updated == 0) {
                            errors.add(
                                "Member profile not found. "
                                + "No changes were saved."
                            );
                        } else {

                            // Update name stored in session.
                            session.setAttribute("fullName", name);

                            session.setAttribute(
                                "flash",
                                "ok:Your profile was updated successfully."
                            );

                            response.sendRedirect(
                                ctx + "/profile.jsp"
                            );
                            return;
                        }
                    }
                }
            }
        }

        // ---------------------------------------
        // Load the current profile information
        // ---------------------------------------

        String selectSql =
            "SELECT "
            + "u.Email, "
            + "u.CreatedAt, "
            + "m.FullName, "
            + "m.Phone, "
            + "m.DateOfBirth "
            + "FROM UserAccount u "
            + "LEFT JOIN Member m "
            + "ON m.UserId = u.UserId "
            + "WHERE u.UserId = ?";

        try (PreparedStatement ps =
                con.prepareStatement(selectSql)) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    profileFound = true;

                    email = rs.getString("Email");

                    java.sql.Date dbDob =
                        rs.getDate("DateOfBirth");

                    if (dbDob != null) {
                        dob = dbDob.toLocalDate();
                    }

                    java.sql.Timestamp dbJoined =
                        rs.getTimestamp("CreatedAt");

                    if (dbJoined != null) {
                        joined = dbJoined.toLocalDateTime();
                    }

                    // Preserve submitted values after
                    // a validation error.
                    if (!isPost) {

                        String dbName =
                            rs.getString("FullName");

                        String dbPhone =
                            rs.getString("Phone");

                        name = dbName == null ? "" : dbName;
                        phone = dbPhone == null ? "" : dbPhone;
                    }

                } else {

                    errors.add(
                        "Your account could not be found."
                    );
                }
            }
        }

    } catch (Exception e) {

        application.log("FitTrack profile error", e);

        errors.add(
            "Could not load or save your profile. "
            + "Please check the server log."
        );

    } finally {

        close(con);
    }
%>

<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">

    <meta name="viewport"
          content="width=device-width, initial-scale=1">

    <title>Profile - FitTrack</title>

    <link rel="stylesheet"
          href="<%= ctx %>/css/style.css">

</head>

<body>

<%@ include file="/WEB-INF/jspf/topbar.jspf" %>

<div class="panel wide">

    <h1>Your profile</h1>

    <p class="sub">
        Keep your contact details up to date.
    </p>

    <%-- Error messages --%>

    <% if (!errors.isEmpty()) { %>

        <div class="error" role="alert">

            <% for (String err : errors) { %>

                <div><%= esc(err) %></div>

            <% } %>

        </div>

    <% } %>

    <%-- Profile information --%>

    <% if (profileFound) { %>

        <dl class="facts">

            <dt>Email</dt>

            <dd><%= esc(email) %></dd>

            <% if (isMember) { %>

                <dt>Date of birth</dt>

                <dd><%= esc(day(dob)) %></dd>

            <% } %>

            <dt>Member since</dt>

            <dd>
                <%= joined == null
                    ? ""
                    : esc(day(joined.toLocalDate())) %>
            </dd>

        </dl>

        <%-- Member profile editing --%>

        <% if (canEdit) { %>

            <form method="post"
                  action="<%= ctx %>/profile.jsp"
                  novalidate>

                <label for="name">
                    Full name
                </label>

                <input
                    type="text"
                    id="name"
                    name="name"
                    value="<%= esc(name) %>"
                    maxlength="120"
                    required
                >

                <label for="phone">
                    Phone
                </label>

                <input
                    type="tel"
                    id="phone"
                    name="phone"
                    value="<%= esc(phone) %>"
                    placeholder="408-555-0100"
                    required
                >

                <button class="btn" type="submit">
                    Save changes
                </button>

            </form>

        <% } else { %>

            <p class="hint">
                Profile editing for trainer and staff
                accounts is not yet available.
            </p>

        <% } %>

    <% } %>

</div>

</body>
</html>
