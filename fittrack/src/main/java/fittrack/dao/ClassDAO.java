
package fittrack.dao;

import fittrack.model.GymClass;

import java.sql.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class ClassDAO {

    /**
     * Shared by every class listing: the class, its type title,
     * the trainer's name, and the live count of BOOKED rows.
     */
    private static final String LISTING_COLUMNS =
        "SELECT c.ClassId, c.StartTime, ct.Title, "
        + "u.Name AS Trainer, c.RoomNumber, c.Capacity, "
        + "(SELECT COUNT(*) FROM Booking b "
        + " WHERE b.ClassId = c.ClassId "
        + " AND b.Status = 'BOOKED') AS Booked ";

    private static final String LISTING_FROM =
        " FROM `Class` c "
        + " JOIN ClassType ct "
        + " ON ct.ClassTypeId = c.ClassTypeId "
        + " JOIN UserAccount u "
        + " ON u.UserId = c.TrainerId ";

    private final Connection con;

    public ClassDAO(Connection con) {
        this.con = con;
    }

    /**
     * Lock a class row during booking.
     */
    public GymClass findByIdForUpdate(int classId)
            throws SQLException {

        String sql =
            "SELECT c.ClassId, c.StartTime, "
            + "c.Capacity, c.RoomNumber, ct.Title "
            + "FROM `Class` c "
            + "JOIN ClassType ct "
            + "ON ct.ClassTypeId = c.ClassTypeId "
            + "WHERE c.ClassId = ? FOR UPDATE";

        try (PreparedStatement ps =
                con.prepareStatement(sql)) {

            ps.setInt(1, classId);

            try (ResultSet rs = ps.executeQuery()) {

                if (!rs.next()) {
                    return null;
                }

                GymClass c = new GymClass();

                c.setClassId(rs.getInt("ClassId"));
                c.setStartTime(
                    rs.getObject(
                        "StartTime",
                        LocalDateTime.class
                    )
                );
                c.setCapacity(rs.getInt("Capacity"));
                c.setRoomNumber(
                    rs.getString("RoomNumber")
                );
                c.setTitle(rs.getString("Title"));

                return c;
            }
        }
    }

    /**
     * Upcoming classes for the member dashboard.
     */
    public List<GymClass> findUpcoming(int limit)
            throws SQLException {

        String sql =
            LISTING_COLUMNS + LISTING_FROM
            + "WHERE c.StartTime >= NOW() "
            + "ORDER BY c.StartTime LIMIT ?";

        try (PreparedStatement ps =
                con.prepareStatement(sql)) {

            ps.setInt(1, limit);

            return list(ps, false);
        }
    }

    /**
     * Upcoming classes booked by a member.
     */
    public List<GymClass> findUpcomingBookedBy(
            int memberId) throws SQLException {

        String sql =
            LISTING_COLUMNS + LISTING_FROM
            + "JOIN Booking mine "
            + "ON mine.ClassId = c.ClassId "
            + "WHERE mine.MemberId = ? "
            + "AND mine.Status = 'BOOKED' "
            + "AND c.StartTime >= NOW() "
            + "ORDER BY c.StartTime";

        try (PreparedStatement ps =
                con.prepareStatement(sql)) {

            ps.setInt(1, memberId);

            return list(ps, false);
        }
    }

    /**
     * Classes assigned to a trainer.
     * FR 1.2.1
     */
    public List<GymClass> findLedBy(int trainerId)
            throws SQLException {

        String sql =
            LISTING_COLUMNS + LISTING_FROM
            + "WHERE c.TrainerId = ? "
            + "AND c.StartTime >= CURDATE() "
            + "ORDER BY c.StartTime";

        try (PreparedStatement ps =
                con.prepareStatement(sql)) {

            ps.setInt(1, trainerId);

            return list(ps, false);
        }
    }

    /**
     * Search the schedule using optional filters.
     */
    public List<GymClass> search(
            int viewerId,
            LocalDate onDate,
            String timeOfDay,
            Integer trainerId,
            Integer classTypeId) throws SQLException {

        StringBuilder sql = new StringBuilder(
            LISTING_COLUMNS
            + ", (SELECT mb.Status FROM Booking mb "
            + "WHERE mb.ClassId = c.ClassId "
            + "AND mb.MemberId = ?) AS MyStatus "
            + LISTING_FROM
            + "WHERE c.StartTime >= NOW() "
        );

        List<Object> params = new ArrayList<>();
        params.add(viewerId);

        if (onDate != null) {
            sql.append(
                "AND DATE(c.StartTime) = ? "
            );
            params.add(onDate);
        }

        if ("morning".equals(timeOfDay)) {
            sql.append(
                "AND HOUR(c.StartTime) < 12 "
            );
        } else if ("afternoon".equals(timeOfDay)) {
            sql.append(
                "AND HOUR(c.StartTime) BETWEEN 12 AND 16 "
            );
        } else if ("evening".equals(timeOfDay)) {
            sql.append(
                "AND HOUR(c.StartTime) >= 17 "
            );
        }

        if (trainerId != null) {
            sql.append("AND c.TrainerId = ? ");
            params.add(trainerId);
        }

        if (classTypeId != null) {
            sql.append("AND c.ClassTypeId = ? ");
            params.add(classTypeId);
        }

        sql.append("ORDER BY c.StartTime");

        try (PreparedStatement ps =
                con.prepareStatement(sql.toString())) {

            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }

            return list(ps, true);
        }
    }

    /**
     * FR 1.1.7: Check-in window state.
     */
    private static final String CHECK_IN_STATE =
        "CASE WHEN NOW() < c.StartTime - INTERVAL "
        + GymClass.CHECK_IN_OPENS_MINUTES_BEFORE
        + " MINUTE THEN 'NOT_YET' "
        + "WHEN NOW() > c.StartTime + INTERVAL "
        + GymClass.CHECK_IN_CLOSES_MINUTES_AFTER
        + " MINUTE THEN 'CLOSED' "
        + "ELSE 'OPEN' END";

    public String findCheckInState(int classId)
            throws SQLException {

        String sql =
            "SELECT " + CHECK_IN_STATE
            + " FROM `Class` c "
            + "WHERE c.ClassId = ?";

        try (PreparedStatement ps =
                con.prepareStatement(sql)) {

            ps.setInt(1, classId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next()
                    ? rs.getString(1)
                    : null;
            }
        }
    }

    /**
     * Today's booked classes with check-in details.
     */
    public List<GymClass> findBookedTodayBy(
            int memberId) throws SQLException {

        String sql =
            LISTING_COLUMNS
            + ", (SELECT MIN(a.CheckInTime) "
            + "FROM Attendance a "
            + "WHERE a.ClassId = c.ClassId "
            + "AND a.MemberId = mine.MemberId) "
            + "AS CheckedInAt, "
            + CHECK_IN_STATE + " AS CheckInState "
            + LISTING_FROM
            + "JOIN Booking mine "
            + "ON mine.ClassId = c.ClassId "
            + "WHERE mine.MemberId = ? "
            + "AND mine.Status = 'BOOKED' "
            + "AND c.StartTime >= CURDATE() "
            + "AND c.StartTime < CURDATE() "
            + "+ INTERVAL 1 DAY "
            + "ORDER BY c.StartTime";

        try (PreparedStatement ps =
                con.prepareStatement(sql)) {

            ps.setInt(1, memberId);

            return list(ps, false, true);
        }
    }

    // ========================================
    // FR 1.3.4: STAFF SCHEDULE MANAGEMENT
    // ========================================

    /**
     * Retrieve all scheduled classes for staff.
     * Includes past and upcoming classes.
     */
    public List<GymClass> findAllForStaff()
            throws SQLException {

        String sql =
            LISTING_COLUMNS + LISTING_FROM
            + "ORDER BY c.StartTime DESC";

        try (PreparedStatement ps =
                con.prepareStatement(sql)) {

            return list(ps, false);
        }
    }

    /**
     * Schedule details for an edit form.
     * Kept separate from GymClass to preserve
     * compatibility with existing functionality.
     */
    public static class ScheduleDetails {

        private final int classId;
        private final int classTypeId;
        private final int trainerId;
        private final String roomNumber;
        private final LocalDateTime startTime;
        private final int capacity;

        public ScheduleDetails(
                int classId,
                int classTypeId,
                int trainerId,
                String roomNumber,
                LocalDateTime startTime,
                int capacity) {

            this.classId = classId;
            this.classTypeId = classTypeId;
            this.trainerId = trainerId;
            this.roomNumber = roomNumber;
            this.startTime = startTime;
            this.capacity = capacity;
        }

        public int getClassId() {
            return classId;
        }

        public int getClassTypeId() {
            return classTypeId;
        }

        public int getTrainerId() {
            return trainerId;
        }

        public String getRoomNumber() {
            return roomNumber;
        }

        public LocalDateTime getStartTime() {
            return startTime;
        }

        public int getCapacity() {
            return capacity;
        }
    }

    /**
     * Retrieve one scheduled class for editing.
     */
    public ScheduleDetails findScheduleById(
            int classId) throws SQLException {

        String sql =
            "SELECT ClassId, ClassTypeId, "
            + "TrainerId, RoomNumber, "
            + "StartTime, Capacity "
            + "FROM `Class` WHERE ClassId = ?";

        try (PreparedStatement ps =
                con.prepareStatement(sql)) {

            ps.setInt(1, classId);

            try (ResultSet rs = ps.executeQuery()) {

                if (!rs.next()) {
                    return null;
                }

                return new ScheduleDetails(
                    rs.getInt("ClassId"),
                    rs.getInt("ClassTypeId"),
                    rs.getInt("TrainerId"),
                    rs.getString("RoomNumber"),
                    rs.getObject(
                        "StartTime",
                        LocalDateTime.class
                    ),
                    rs.getInt("Capacity")
                );
            }
        }
    }

    /**
     * FR 1.3.4
     * Create a new scheduled class.
     *
     * Returns the generated ClassId.
     */
    public int addScheduledClass(
            int classTypeId,
            int trainerId,
            String roomNumber,
            LocalDateTime startTime,
            int capacity) throws SQLException {

        validateSchedule(
            classTypeId,
            trainerId,
            roomNumber,
            startTime,
            capacity
        );

        String sql =
            "INSERT INTO `Class` "
            + "(ClassTypeId, TrainerId, "
            + "RoomNumber, StartTime, Capacity) "
            + "VALUES (?, ?, ?, ?, ?)";

        try (PreparedStatement ps =
                con.prepareStatement(
                    sql,
                    Statement.RETURN_GENERATED_KEYS
                )) {

            ps.setInt(1, classTypeId);
            ps.setInt(2, trainerId);
            ps.setString(3, roomNumber.trim());
            ps.setTimestamp(
                4,
                Timestamp.valueOf(startTime)
            );
            ps.setInt(5, capacity);

            ps.executeUpdate();

            try (ResultSet keys =
                    ps.getGeneratedKeys()) {

                if (keys.next()) {
                    return keys.getInt(1);
                }
            }
        }

        throw new SQLException(
            "Class created, but no generated ID returned."
        );
    }

    /**
     * FR 1.3.4
     * Update an existing scheduled class.
     *
     * Capacity cannot be reduced below the
     * number of currently BOOKED members.
     */
    public boolean updateScheduledClass(
            int classId,
            int classTypeId,
            int trainerId,
            String roomNumber,
            LocalDateTime startTime,
            int capacity) throws SQLException {

        if (classId <= 0) {
            throw new IllegalArgumentException(
                "Invalid class ID."
            );
        }

        validateSchedule(
            classTypeId,
            trainerId,
            roomNumber,
            startTime,
            capacity
        );

        String sql =
            "UPDATE `Class` c "
            + "SET c.ClassTypeId = ?, "
            + "c.TrainerId = ?, "
            + "c.RoomNumber = ?, "
            + "c.StartTime = ?, "
            + "c.Capacity = ? "
            + "WHERE c.ClassId = ? "
            + "AND ? >= ("
            + " SELECT COUNT(*) FROM Booking b "
            + " WHERE b.ClassId = c.ClassId "
            + " AND b.Status = 'BOOKED'"
            + ")";

        try (PreparedStatement ps =
                con.prepareStatement(sql)) {

            ps.setInt(1, classTypeId);
            ps.setInt(2, trainerId);
            ps.setString(3, roomNumber.trim());
            ps.setTimestamp(
                4,
                Timestamp.valueOf(startTime)
            );
            ps.setInt(5, capacity);
            ps.setInt(6, classId);
            ps.setInt(7, capacity);

            return ps.executeUpdate() > 0;
        }
    }

    /**
     * Validate schedule information before
     * inserting or updating database records.
     */
    private static void validateSchedule(
            int classTypeId,
            int trainerId,
            String roomNumber,
            LocalDateTime startTime,
            int capacity) {

        if (classTypeId <= 0) {
            throw new IllegalArgumentException(
                "Please select a class type."
            );
        }

        if (trainerId <= 0) {
            throw new IllegalArgumentException(
                "Please select a trainer."
            );
        }

        if (roomNumber == null
                || roomNumber.trim().isEmpty()
                || roomNumber.trim().length() > 20) {

            throw new IllegalArgumentException(
                "Room number must contain 1 to 20 characters."
            );
        }

        if (startTime == null) {
            throw new IllegalArgumentException(
                "Please select a start date and time."
            );
        }

        if (capacity <= 0) {
            throw new IllegalArgumentException(
                "Capacity must be greater than zero."
            );
        }
    }

    // ========================================
    // EXISTING RESULT MAPPING
    // ========================================

    private static List<GymClass> list(
            PreparedStatement ps,
            boolean withMyStatus) throws SQLException {

        return list(ps, withMyStatus, false);
    }

    private static List<GymClass> list(
            PreparedStatement ps,
            boolean withMyStatus,
            boolean withCheckIn) throws SQLException {

        List<GymClass> list = new ArrayList<>();

        try (ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {

                GymClass c = new GymClass();

                c.setClassId(rs.getInt("ClassId"));

                c.setStartTime(
                    rs.getObject(
                        "StartTime",
                        LocalDateTime.class
                    )
                );

                c.setTitle(rs.getString("Title"));
                c.setTrainerName(
                    rs.getString("Trainer")
                );
                c.setRoomNumber(
                    rs.getString("RoomNumber")
                );
                c.setCapacity(
                    rs.getInt("Capacity")
                );
                c.setBooked(
                    rs.getInt("Booked")
                );

                if (withMyStatus) {
                    c.setMyStatus(
                        rs.getString("MyStatus")
                    );
                }

                if (withCheckIn) {
                    c.setCheckedInAt(
                        rs.getObject(
                            "CheckedInAt",
                            LocalDateTime.class
                        )
                    );

                    c.setCheckInState(
                        rs.getString("CheckInState")
                    );
                }

                list.add(c);
            }
        }

        return list;
    }
}
