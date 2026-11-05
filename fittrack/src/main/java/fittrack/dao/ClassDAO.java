package fittrack.dao;

import fittrack.model.GymClass;

import java.sql.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

// All SQL for the `Class` table. Runs on the caller's Connection.
public class ClassDAO {
    /**
     * Shared by every class listing: the class, its type title, the trainer's
     * name, and the live count of BOOKED rows. A spot opens again as soon as
     * a booking is CANCELLED, because only BOOKED rows are counted.
     */
    private static final String LISTING_COLUMNS =
        "SELECT c.ClassId, c.StartTime, ct.Title, u.Name AS Trainer, c.RoomNumber, c.Capacity, "
        + "       (SELECT COUNT(*) FROM Booking b "
        + "         WHERE b.ClassId = c.ClassId AND b.Status = 'BOOKED') AS Booked ";

    private static final String LISTING_FROM =
        "  FROM `Class` c "
        + "  JOIN ClassType ct  ON ct.ClassTypeId = c.ClassTypeId "
        + "  JOIN UserAccount u ON u.UserId = c.TrainerId ";

    private final Connection con;

    public ClassDAO(Connection con) {
        this.con = con;
    }

    /**
     * The class with its title and capacity, locked (SELECT ... FOR UPDATE)
     * until the caller commits, so two members cannot both take the last
     * spot. Returns null if there is no such class. Needs autocommit off
     */
    public GymClass findByIdForUpdate(int classId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT c.ClassId, c.StartTime, c.Capacity, c.RoomNumber, ct.Title "
                + "  FROM `Class` c JOIN ClassType ct ON ct.ClassTypeId = c.ClassTypeId "
                + " WHERE c.ClassId = ? FOR UPDATE")) {
            ps.setInt(1, classId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                GymClass c = new GymClass();
                c.setClassId(rs.getInt("ClassId"));
                c.setStartTime(rs.getObject("StartTime", LocalDateTime.class));
                c.setCapacity(rs.getInt("Capacity"));
                c.setRoomNumber(rs.getString("RoomNumber"));
                c.setTitle(rs.getString("Title"));
                return c;
            }
        }
    }

    // The next few upcoming classes (dashboard "Coming up next")
    public List<GymClass> findUpcoming(int limit) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                LISTING_COLUMNS + LISTING_FROM
                + " WHERE c.StartTime >= NOW() ORDER BY c.StartTime LIMIT ?")) {
            ps.setInt(1, limit);
            return list(ps, false);
        }
    }

    // Upcoming classes this member holds a BOOKED spot in (dashboard "Your upcoming classes")
    public List<GymClass> findUpcomingBookedBy(int memberId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                LISTING_COLUMNS + LISTING_FROM
                + "  JOIN Booking mine ON mine.ClassId = c.ClassId "
                + " WHERE mine.MemberId = ? AND mine.Status = 'BOOKED' AND c.StartTime >= NOW() "
                + " ORDER BY c.StartTime")) {
            ps.setInt(1, memberId);
            return list(ps, false);
        }
    }

    /**
     * Upcoming classes for the schedule page. Every filter is optional: null
     * (or an unknown timeOfDay) means "any", and each one that is set adds an
     * AND to the WHERE. Each class also carries viewerId's own booking status
     * (GymClass.getMyStatus: BOOKED, CANCELLED, or null).
     *
     * @param timeOfDay "morning" (before 12), "afternoon" (12-5pm), "evening" (after 5pm), or null
     */
    public List<GymClass> search(int viewerId, LocalDate onDate, String timeOfDay,
                                 Integer trainerId, Integer classTypeId) throws SQLException {
        StringBuilder sql = new StringBuilder(LISTING_COLUMNS
            + "     , (SELECT mb.Status FROM Booking mb "
            + "         WHERE mb.ClassId = c.ClassId AND mb.MemberId = ?) AS MyStatus "
            + LISTING_FROM
            + " WHERE c.StartTime >= NOW() ");
        List<Object> params = new ArrayList<>();
        params.add(viewerId);                   // for MyStatus above

        if (onDate != null) {
            sql.append(" AND DATE(c.StartTime) = ? ");
            params.add(onDate);
        }
        // time of day is one of three fixed choices, so no ? is needed
        if ("morning".equals(timeOfDay)) {
            sql.append(" AND HOUR(c.StartTime) < 12 ");
        } else if ("afternoon".equals(timeOfDay)) {
            sql.append(" AND HOUR(c.StartTime) BETWEEN 12 AND 16 ");
        } else if ("evening".equals(timeOfDay)) {
            sql.append(" AND HOUR(c.StartTime) >= 17 ");
        }
        if (trainerId != null) {
            sql.append(" AND c.TrainerId = ? ");
            params.add(trainerId);
        }
        if (classTypeId != null) {
            sql.append(" AND c.ClassTypeId = ? ");
            params.add(classTypeId);
        }
        sql.append(" ORDER BY c.StartTime");

        try (PreparedStatement ps = con.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            return list(ps, true);
        }
    }

    private static List<GymClass> list(PreparedStatement ps, boolean withMyStatus) throws SQLException {
        List<GymClass> list = new ArrayList<>();
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                GymClass c = new GymClass();
                c.setClassId(rs.getInt("ClassId"));
                c.setStartTime(rs.getObject("StartTime", LocalDateTime.class));
                c.setTitle(rs.getString("Title"));
                c.setTrainerName(rs.getString("Trainer"));
                c.setRoomNumber(rs.getString("RoomNumber"));
                c.setCapacity(rs.getInt("Capacity"));
                c.setBooked(rs.getInt("Booked"));
                if (withMyStatus) c.setMyStatus(rs.getString("MyStatus"));
                list.add(c);
            }
        }
        return list;
    }
}
