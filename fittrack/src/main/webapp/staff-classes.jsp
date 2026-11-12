
<%--
    staff-classes.jsp
    FR 1.3.4 - Manage Class Types and Schedule

    STAFF users can:
    - Create and update class types
    - Create and update scheduled classes
    - View class types and schedules

    Uses the existing DAO layer and common.jspf.
--%>
<%@ include file="/WEB-INF/jspf/common.jspf" %>

<%
    // Only authenticated STAFF users may access this page.
    if (userId == null) {
        response.sendRedirect(ctx + "/login.jsp");
        return;
    }

    if (!"STAFF".equals(role)) {
        response.sendError(
            HttpServletResponse.SC_FORBIDDEN,
            "Only staff can manage classes."
        );
        return;
    }

    // CSRF protection for database-changing requests.
    String csrfToken = (String) session.getAttribute("staffClassCsrf");

    if (csrfToken == null) {
        csrfToken = UUID.randomUUID().toString();
        session.setAttribute("staffClassCsrf", csrfToken);
    }

    String error = null;
    String success = null;

    // Handle submitted management forms.
    if ("POST".equalsIgnoreCase(request.getMethod())) {

        String submittedToken =
            request.getParameter("csrfToken");

        if (!csrfToken.equals(submittedToken)) {
            response.sendError(
                HttpServletResponse.SC_FORBIDDEN,
                "Invalid form token."
            );
            return;
        }

        String action = param(request, "action");

        try (Connection con = getConnection()) {

            ClassTypeDAO typeDAO = new ClassTypeDAO(con);
            ClassDAO classDAO = new ClassDAO(con);

            if ("addType".equals(action)
                    || "updateType".equals(action)) {

                String title = param(request, "title");
                String description =
                    param(request, "description");

                if (title.isEmpty() || title.length() > 80) {
                    throw new IllegalArgumentException(
                        "Title must contain 1 to 80 characters."
                    );
                }

                if (description.length() > 255) {
                    throw new IllegalArgumentException(
                        "Description cannot exceed 255 characters."
                    );
                }

                if ("addType".equals(action)) {
                    if (!typeDAO.addClassType(
                            title, description)) {
                        throw new IllegalStateException(
                            "Could not add the class type."
                        );
                    }

                    success = "Class type added successfully.";

                } else {
                    Integer typeId =
                        toInt(param(request, "classTypeId"));

                    if (typeId == null || typeId <= 0) {
                        throw new IllegalArgumentException(
                            "Invalid class type."
                        );
                    }

                    if (!typeDAO.updateClassType(
                            typeId, title, description)) {
                        throw new IllegalArgumentException(
                            "Class type not found."
                        );
                    }

                    success = "Class type updated successfully.";
                }

            } else if ("addClass".equals(action)
                    || "updateClass".equals(action)) {

                Integer typeId =
                    toInt(param(request, "classTypeId"));
                Integer trainerId =
                    toInt(param(request, "trainerId"));
                Integer capacity =
                    toInt(param(request, "capacity"));

                String room = param(request, "roomNumber");
                String dateTime = param(request, "startTime");

                if (typeId == null || trainerId == null
                        || capacity == null) {
                    throw new IllegalArgumentException(
                        "Select a class type, trainer, and capacity."
                    );
                }

                LocalDateTime start;

                try {
                    start = LocalDateTime.parse(dateTime);
                } catch (Exception ex) {
                    throw new IllegalArgumentException(
                        "Enter a valid start date and time."
                    );
                }

                if ("addClass".equals(action)) {

                    classDAO.addScheduledClass(
                        typeId,
                        trainerId,
                        room,
                        start,
                        capacity
                    );

                    success = "Class scheduled successfully.";

                } else {

                    Integer classId =
                        toInt(param(request, "classId"));

                    if (classId == null || classId <= 0) {
                        throw new IllegalArgumentException(
                            "Invalid class ID."
                        );
                    }

                    boolean updated =
                        classDAO.updateScheduledClass(
                            classId,
                            typeId,
                            trainerId,
                            room,
                            start,
                            capacity
                        );

                    if (!updated) {
                        throw new IllegalArgumentException(
                            "Class could not be updated. "
                            + "Check that it exists and that capacity "
                            + "is not below current bookings."
                        );
                    }

                    success = "Class schedule updated successfully.";
                }

            } else {
                throw new IllegalArgumentException(
                    "Unknown management action."
                );
            }

            session.setAttribute("flash", "ok:" + success);

            response.sendRedirect(
                ctx + "/staff-classes.jsp"
            );
            return;

        } catch (IllegalArgumentException ex) {
            error = ex.getMessage();

        } catch (SQLException ex) {

            // MySQL duplicate key error.
            if (ex.getErrorCode() == 1062) {
                error = "A class type with this title already exists.";
            } else if (ex.getErrorCode() == 1452) {
                error = "The selected class type or trainer "
                      + "does not exist.";
            } else {
                log("Staff class management SQL error", ex);
                error = "Database operation failed. "
                      + "Please check the submitted details.";
            }

        } catch (Exception ex) {
            log("Staff class management error", ex);
            error = "Unable to save your changes.";
        }
    }

    List<ClassType> classTypes = new ArrayList<>();
    List<Trainer> trainers = new ArrayList<>();
    List<GymClass> classes = new ArrayList<>();

    ClassType editingType = null;
    ClassDAO.ScheduleDetails editingClass = null;

    try (Connection con = getConnection()) {

        ClassTypeDAO typeDAO = new ClassTypeDAO(con);
        TrainerDAO trainerDAO = new TrainerDAO(con);
        ClassDAO classDAO = new ClassDAO(con);

        classTypes = typeDAO.findAll();
        trainers = trainerDAO.findAll();
        classes = classDAO.findAllForStaff();

        Integer editTypeId =
            toInt(param(request, "editType"));

        Integer editClassId =
            toInt(param(request, "editClass"));

        if (editTypeId != null) {
            editingType = typeDAO.findById(editTypeId);
        }

        if (editClassId != null) {
            editingClass =
                classDAO.findScheduleById(editClassId);
        }

    } catch (Exception ex) {
        log("Could not load staff class page", ex);

        error = "Could not load management data. "
              + "Check the database connection.";
    }

    DateTimeFormatter inputDateTime =
        DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, initial-scale=1">

    <title>Manage Classes - FitTrack</title>

    <link rel="stylesheet"
          href="<%= ctx %>/css/style.css">

    <style>
        .staff-container {
            max-width: 1100px;
            margin: 30px auto;
            padding: 0 20px 50px;
        }

        .staff-heading {
            margin-bottom: 25px;
        }

        .staff-heading h1 {
            margin-bottom: 8px;
        }

        .staff-card {
            background: #fff;
            border: 1px solid #e5e7eb;
            border-radius: 12px;
            padding: 24px;
            margin-bottom: 25px;
        }

        .staff-card h2 {
            margin-top: 0;
        }

        .staff-form {
            display: grid;
            grid-template-columns:
                repeat(2, minmax(0, 1fr));
            gap: 16px;
        }

        .staff-field {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .staff-field.full {
            grid-column: 1 / -1;
        }

        .staff-field input,
        .staff-field select,
        .staff-field textarea {
            box-sizing: border-box;
            width: 100%;
            padding: 10px;
            border: 1px solid #d1d5db;
            border-radius: 6px;
            font: inherit;
        }

        .staff-field textarea {
            min-height: 80px;
        }

        .staff-actions {
            grid-column: 1 / -1;
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .staff-table-wrap {
            overflow-x: auto;
        }

        .staff-table {
            width: 100%;
            border-collapse: collapse;
        }

        .staff-table th,
        .staff-table td {
            padding: 12px;
            border-bottom: 1px solid #e5e7eb;
            text-align: left;
            vertical-align: middle;
        }

        .staff-table th {
            background: #f9fafb;
        }

        .staff-table td a {
            font-weight: 600;
        }

        .staff-message {
            padding: 12px 15px;
            border-radius: 6px;
            margin-bottom: 20px;
        }

        .staff-success {
            background: #ecfdf5;
            color: #065f46;
        }

        .staff-error {
            background: #fef2f2;
            color: #991b1b;
        }

        @media (max-width: 650px) {
            .staff-form {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>

<body>

<%@ include file="/WEB-INF/jspf/topbar.jspf" %>

<main class="staff-container">

    <div class="staff-heading">
        <h1>Manage Classes &amp; Schedule</h1>
    </div>

    <% if (flashText != null) { %>
        <div class="staff-message <%= flashOk
                ? "staff-success" : "staff-error" %>"
             role="status">
            <%= esc(flashText) %>
        </div>
    <% } %>

    <% if (error != null) { %>
        <div class="staff-message staff-error"
             role="alert">
            <%= esc(error) %>
        </div>
    <% } %>

    <!-- ===================================== -->
    <!-- CLASS TYPE MANAGEMENT                 -->
    <!-- ===================================== -->

    <section class="staff-card">

        <h2>
            <%= editingType == null
                ? "Add Class Type"
                : "Edit Class Type" %>
        </h2>

        <form method="post"
              action="<%= ctx %>/staff-classes.jsp"
              class="staff-form">

            <input type="hidden"
                   name="csrfToken"
                   value="<%= esc(csrfToken) %>">

            <input type="hidden"
                   name="action"
                   value="<%= editingType == null
                       ? "addType" : "updateType" %>">

            <% if (editingType != null) { %>
                <input type="hidden"
                       name="classTypeId"
                       value="<%= editingType.getClassTypeId() %>">
            <% } %>

            <div class="staff-field full">
                <label for="title">
                    Class Type Title
                </label>

                <input type="text"
                       id="title"
                       name="title"
                       maxlength="80"
                       required
                       value="<%= editingType == null
                           ? ""
                           : esc(editingType.getTitle()) %>">
            </div>

            <div class="staff-field full">
                <label for="description">
                    Description
                </label>

                <textarea id="description"
                          name="description"
                          maxlength="255"><%= editingType == null
                          ? ""
                          : esc(editingType.getDescription()) %></textarea>
            </div>

            <div class="staff-actions">

                <button type="submit" class="btn">
                    <%= editingType == null
                        ? "Add Class Type"
                        : "Save Class Type" %>
                </button>

                <% if (editingType != null) { %>
                    <a href="<%= ctx %>/staff-classes.jsp">
                        Cancel Edit
                    </a>
                <% } %>

            </div>

        </form>

    </section>

    <section class="staff-card">

        <h2>Existing Class Types</h2>

        <div class="staff-table-wrap">
            <table class="staff-table">

                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Title</th>
                        <th>Description</th>
                        <th>Action</th>
                    </tr>
                </thead>

                <tbody>
                <% for (ClassType type : classTypes) { %>

                    <tr>
                        <td><%= type.getClassTypeId() %></td>

                        <td><%= esc(type.getTitle()) %></td>

                        <td>
                            <%= esc(type.getDescription()) %>
                        </td>

                        <td>
                            <a href="<%= ctx
                                %>/staff-classes.jsp?editType=<%=
                                type.getClassTypeId() %>">
                                Edit
                            </a>
                        </td>
                    </tr>

                <% } %>

                <% if (classTypes.isEmpty()) { %>
                    <tr>
                        <td colspan="4">
                            No class types available.
                        </td>
                    </tr>
                <% } %>
                </tbody>

            </table>
        </div>

    </section>

    <!-- ===================================== -->
    <!-- SCHEDULE MANAGEMENT                   -->
    <!-- ===================================== -->

    <section class="staff-card">

        <h2>
            <%= editingClass == null
                ? "Schedule New Class"
                : "Edit Scheduled Class" %>
        </h2>

        <form method="post"
              action="<%= ctx %>/staff-classes.jsp"
              class="staff-form">

            <input type="hidden"
                   name="csrfToken"
                   value="<%= esc(csrfToken) %>">

            <input type="hidden"
                   name="action"
                   value="<%= editingClass == null
                       ? "addClass" : "updateClass" %>">

            <% if (editingClass != null) { %>
                <input type="hidden"
                       name="classId"
                       value="<%= editingClass.getClassId() %>">
            <% } %>

            <div class="staff-field">
                <label for="classTypeId">
                    Class Type
                </label>

                <select id="classTypeId"
                        name="classTypeId"
                        required>

                    <option value="">
                        Select Class Type
                    </option>

                    <% for (ClassType type : classTypes) { %>
                        <option value="<%= type.getClassTypeId() %>"
                            <%= editingClass != null
                                && editingClass.getClassTypeId()
                                == type.getClassTypeId()
                                ? "selected" : "" %>>
                            <%= esc(type.getTitle()) %>
                        </option>
                    <% } %>

                </select>
            </div>

            <div class="staff-field">
                <label for="trainerId">
                    Trainer
                </label>

                <select id="trainerId"
                        name="trainerId"
                        required>

                    <option value="">
                        Select Trainer
                    </option>

                    <% for (Trainer trainer : trainers) { %>
                        <option value="<%= trainer.getUserId() %>"
                            <%= editingClass != null
                                && editingClass.getTrainerId()
                                == trainer.getUserId()
                                ? "selected" : "" %>>
                            <%= esc(trainer.getName()) %>
                        </option>
                    <% } %>

                </select>
            </div>

            <div class="staff-field">
                <label for="roomNumber">
                    Room Number
                </label>

                <input type="text"
                       id="roomNumber"
                       name="roomNumber"
                       maxlength="20"
                       required
                       value="<%= editingClass == null
                           ? ""
                           : esc(editingClass.getRoomNumber()) %>">
            </div>

            <div class="staff-field">
                <label for="startTime">
                    Start Date &amp; Time
                </label>

                <input type="datetime-local"
                       id="startTime"
                       name="startTime"
                       required
                       value="<%= editingClass == null
                           ? ""
                           : esc(editingClass.getStartTime()
                               .format(inputDateTime)) %>">
            </div>

            <div class="staff-field">
                <label for="capacity">
                    Capacity
                </label>

                <input type="number"
                       id="capacity"
                       name="capacity"
                       min="1"
                       required
                       value="<%= editingClass == null
                           ? ""
                           : editingClass.getCapacity() %>">
            </div>

            <div class="staff-actions">

                <button type="submit" class="btn">
                    <%= editingClass == null
                        ? "Schedule Class"
                        : "Update Schedule" %>
                </button>

                <% if (editingClass != null) { %>
                    <a href="<%= ctx %>/staff-classes.jsp">
                        Cancel Edit
                    </a>
                <% } %>

            </div>

        </form>

    </section>

    <!-- ===================================== -->
    <!-- EXISTING SCHEDULE                     -->
    <!-- ===================================== -->

    <section class="staff-card">

        <h2>Scheduled Classes</h2>

        <div class="staff-table-wrap">

            <table class="staff-table">

                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Class</th>
                        <th>Trainer</th>
                        <th>Room</th>
                        <th>Start Time</th>
                        <th>Booked</th>
                        <th>Capacity</th>
                        <th>Action</th>
                    </tr>
                </thead>

                <tbody>

                <% for (GymClass gymClass : classes) { %>

                    <tr>
                        <td>
                            <%= gymClass.getClassId() %>
                        </td>

                        <td>
                            <%= esc(gymClass.getTitle()) %>
                        </td>

                        <td>
                            <%= esc(gymClass.getTrainerName()) %>
                        </td>

                        <td>
                            <%= esc(gymClass.getRoomNumber()) %>
                        </td>

                        <td>
                            <%= esc(when(gymClass.getStartTime())) %>
                        </td>

                        <td>
                            <%= gymClass.getBooked() %>
                        </td>

                        <td>
                            <%= gymClass.getCapacity() %>
                        </td>

                        <td>
                            <a href="<%= ctx
                                %>/staff-classes.jsp?editClass=<%=
                                gymClass.getClassId() %>">
                                Edit
                            </a>
                        </td>
                    </tr>

                <% } %>

                <% if (classes.isEmpty()) { %>
                    <tr>
                        <td colspan="8">
                            No scheduled classes available.
                        </td>
                    </tr>
                <% } %>

                </tbody>

            </table>

        </div>

    </section>

</main>

</body>
</html>
