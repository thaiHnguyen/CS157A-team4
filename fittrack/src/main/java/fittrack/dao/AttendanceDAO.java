package fittrack.dao;

import fittrack.model.Attendance;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

// All SQL for the Attendance table. Runs on the caller's Connection
public class AttendanceDAO {
    
    // Attendance plus the class title and start time (NULL for a plain gym visit)
    private static final String SELECT_WITH_CLASS =
        "SELECT a.AttendanceId, a.MemberId, a.ClassId, a.CheckInTime, ct.Title, c.StartTime "
        + "  FROM Attendance a "
        + "  LEFT JOIN `Class` c    ON c.ClassId = a.ClassId "
        + "  LEFT JOIN ClassType ct ON ct.ClassTypeId = c.ClassTypeId ";

    private final Connection con;

    public AttendanceDAO(Connection con) {
        this.con = con;
    }

    // Records a check-in at the current time (CheckInTime defaults to NOW())
    // classId null = plain gym visit. Returns the new AttendanceId
    public int insert(int memberId, Integer classId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO Attendance (MemberId, ClassId) VALUES (?, ?)",
                Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, memberId);
            if (classId == null) ps.setNull(2, Types.INTEGER);
            else                 ps.setInt(2, classId);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                return keys.getInt(1);
            }
        }
    }

    // The member's check-in for this class, or null if they have not checked in
    public Attendance findForClass(int memberId, int classId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                SELECT_WITH_CLASS + " WHERE a.MemberId = ? AND a.ClassId = ? LIMIT 1")) {
            ps.setInt(1, memberId);
            ps.setInt(2, classId);
            return first(ps);
        }
    }

    // The member's plain gym check-in (no class) today, or null
    // "Today" is MySQL's CURDATE(), the same clock that set CheckInTime
    public Attendance findGymVisitToday(int memberId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                SELECT_WITH_CLASS
                + " WHERE a.MemberId = ? AND a.ClassId IS NULL "
                + "   AND a.CheckInTime >= CURDATE() AND a.CheckInTime < CURDATE() + INTERVAL 1 DAY "
                + " ORDER BY a.CheckInTime LIMIT 1")) {
            ps.setInt(1, memberId);
            return first(ps);
        }
    }

    // One check-in by its id, or null
    public Attendance findById(int attendanceId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                SELECT_WITH_CLASS + " WHERE a.AttendanceId = ?")) {
            ps.setInt(1, attendanceId);
            return first(ps);
        }
    }

    // FR 1.1.8: the member's check-ins, newest first.
    // range: "week" = last 7 days, "month" = last month, anything else = all
    // The range is measured with MySQL's NOW(), the clock that set CheckInTime
    public List<Attendance> findForMember(int memberId, String range) throws SQLException {
        String since = "";
        if ("week".equals(range))       since = " AND a.CheckInTime >= NOW() - INTERVAL 7 DAY ";
        else if ("month".equals(range)) since = " AND a.CheckInTime >= NOW() - INTERVAL 1 MONTH ";

        List<Attendance> list = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                SELECT_WITH_CLASS
                + " WHERE a.MemberId = ? " + since
                + " ORDER BY a.CheckInTime DESC, a.AttendanceId DESC")) {
            ps.setInt(1, memberId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
        }
        return list;
    }

    private static Attendance first(PreparedStatement ps) throws SQLException {
        try (ResultSet rs = ps.executeQuery()) {
            return rs.next() ? map(rs) : null;
        }
    }

    private static Attendance map(ResultSet rs) throws SQLException {
        Attendance a = new Attendance();
        a.setAttendanceId(rs.getInt("AttendanceId"));
        a.setMemberId(rs.getInt("MemberId"));
        a.setClassId(rs.getObject("ClassId", Integer.class));
        a.setCheckInTime(rs.getObject("CheckInTime", LocalDateTime.class));
        a.setClassTitle(rs.getString("Title"));
        a.setClassStart(rs.getObject("StartTime", LocalDateTime.class));
        return a;
    }
}
