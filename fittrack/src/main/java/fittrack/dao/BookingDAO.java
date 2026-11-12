package fittrack.dao;

import fittrack.model.Booking;
import fittrack.model.RosterEntry;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * All SQL for the Booking table. Runs on the caller's Connection.
 *
 * A booking is never deleted: cancelling sets Status = 'CANCELLED', and
 * booking the same class again reuses that row, because uq_member_class
 * allows one row per (MemberId, ClassId).
 */
public class BookingDAO {
    private static final String SELECT_WITH_CLASS =
        "SELECT b.BookingId, b.MemberId, b.ClassId, b.Status, c.StartTime, ct.Title "
        + "  FROM Booking b "
        + "  JOIN `Class` c    ON c.ClassId = b.ClassId "
        + "  JOIN ClassType ct ON ct.ClassTypeId = c.ClassTypeId "
        + " WHERE b.MemberId = ? AND b.ClassId = ?";

    private final Connection con;

    public BookingDAO(Connection con) {
        this.con = con;
    }

    // This member's booking for the class (any status), or null
    public Booking findByMemberAndClass(int memberId, int classId) throws SQLException {
        return find(SELECT_WITH_CLASS, memberId, classId);
    }

    /**
     * Same as findByMemberAndClass, but locks the Booking row
     * (SELECT ... FOR UPDATE) until the caller commits or rolls back.
     * Needs autocommit off.
     */
    public Booking findByMemberAndClassForUpdate(int memberId, int classId) throws SQLException {
        return find(SELECT_WITH_CLASS + " FOR UPDATE", memberId, classId);
    }

    /** Number of BOOKED (not cancelled) rows for the class. */
    public int countBooked(int classId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM Booking WHERE ClassId = ? AND Status = 'BOOKED'")) {
            ps.setInt(1, classId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    /**
     * Same count, but as a locking read (FOR SHARE) for use inside the booking
     * transaction. Under MySQL's default REPEATABLE READ, a plain SELECT reads
     * the snapshot taken at the transaction's first read, so it can miss
     * bookings another member committed while we waited for the Class lock and
     * let the class go over capacity. A locking read always sees the latest
     * committed rows. Needs autocommit off.
     */
    public int countBookedForUpdate(int classId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM Booking WHERE ClassId = ? AND Status = 'BOOKED' FOR SHARE")) {
            ps.setInt(1, classId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    // New BOOKED row. Use rebook() instead if a CANCELLED row already exists
    public void insert(int memberId, int classId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO Booking (MemberId, ClassId, Status) VALUES (?, ?, 'BOOKED')")) {
            ps.setInt(1, memberId);
            ps.setInt(2, classId);
            ps.executeUpdate();
        }
    }

    // Turns a CANCELLED row back into BOOKED and resets BookedAt
    public void rebook(int bookingId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE Booking SET Status = 'BOOKED', BookedAt = NOW() WHERE BookingId = ?")) {
            ps.setInt(1, bookingId);
            ps.executeUpdate();
        }
    }

    // Marks the booking CANCELLED. MemberId is checked too, so a member can only cancel their own
    public void cancel(int bookingId, int memberId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE Booking SET Status = 'CANCELLED' WHERE BookingId = ? AND MemberId = ?")) {
            ps.setInt(1, bookingId);
            ps.setInt(2, memberId);
            ps.executeUpdate();
        }
    }
    
    // Members with a BOOKED spot in this class, only if this trainer leads it (FR 1.2.1)
    public List<RosterEntry> findRoster(int trainerId, int classId) throws SQLException {
        List<RosterEntry> out = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT u.UserId, u.Name, u.Email, u.Phone, b.BookedAt "
                + "  FROM Booking b "
                + "  JOIN `Class` c     ON c.ClassId = b.ClassId "
                + "  JOIN UserAccount u ON u.UserId  = b.MemberId "
                + " WHERE c.TrainerId = ? AND b.ClassId = ? AND b.Status = 'BOOKED' "
                + " ORDER BY u.Name")) {
            ps.setInt(1, trainerId);
            ps.setInt(2, classId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    RosterEntry r = new RosterEntry();
                    r.setMemberId(rs.getInt("UserId"));
                    r.setName(rs.getString("Name"));
                    r.setEmail(rs.getString("Email"));
                    r.setPhone(rs.getString("Phone"));
                    r.setBookedAt(rs.getObject("BookedAt", LocalDateTime.class));
                    out.add(r);
                }
            }
        }
        return out;
    }

    private Booking find(String sql, int memberId, int classId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, memberId);
            ps.setInt(2, classId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                Booking b = new Booking();
                b.setBookingId(rs.getInt("BookingId"));
                b.setMemberId(rs.getInt("MemberId"));
                b.setClassId(rs.getInt("ClassId"));
                b.setStatus(rs.getString("Status"));
                b.setClassStart(rs.getObject("StartTime", LocalDateTime.class));
                b.setClassTitle(rs.getString("Title"));
                return b;
            }
        }
    }
}
