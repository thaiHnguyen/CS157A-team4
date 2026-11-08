package fittrack.dao;

import fittrack.model.Membership;

import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class MembershipDAO {
    /**
     * "Active" = Status ACTIVE and today between StartDate and EndDate
     * alias is the table alias with its dot ("m.") or "" for none
     */
    private static String activeToday(String alias) {
        return alias + "Status = 'ACTIVE' AND CURDATE() BETWEEN "
            + alias + "StartDate AND " + alias + "EndDate";
    }

    private final Connection con;

    public MembershipDAO(Connection con) {
        this.con = con;
    }

    // True if the member has a membership that is active today
    public boolean hasActive(int memberId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT 1 FROM Membership WHERE MemberId = ? AND " + activeToday(""))) {
            ps.setInt(1, memberId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /**
     * The member's membership that is active today, with its tier name and
     * days left, or null. If several overlap, the one ending last.
     */
    public Membership findActive(int memberId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT m.MembershipId, m.MemberId, t.TierName, m.StartDate, m.EndDate, m.Status, "
                + "       DATEDIFF(m.EndDate, CURDATE()) AS DaysLeft "
                + "  FROM Membership m JOIN MembershipTier t ON t.TierId = m.TierId "
                + " WHERE m.MemberId = ? AND " + activeToday("m.")
                + " ORDER BY m.EndDate DESC LIMIT 1")) {
            ps.setInt(1, memberId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                Membership m = new Membership();
                m.setMembershipId(rs.getInt("MembershipId"));
                m.setMemberId(rs.getInt("MemberId"));
                m.setTierName(rs.getString("TierName"));
                m.setStartDate(rs.getObject("StartDate", LocalDate.class));
                m.setEndDate(rs.getObject("EndDate", LocalDate.class));
                m.setStatus(rs.getString("Status"));
                m.setDaysLeft(rs.getInt("DaysLeft"));
                return m;
            }
        }
    }
    
    // The last EndDate among the member's ACTIVE memberships that have not
    // ended yet (today's one or a renewal waiting to start), or null if none.
    // A renewal starts the day after this date.
    public LocalDate findLatestActiveEndDate(int memberId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT MAX(EndDate) FROM Membership "
                + " WHERE MemberId = ? AND Status = 'ACTIVE' AND EndDate >= CURDATE()")) {
            ps.setInt(1, memberId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getObject(1, LocalDate.class);
            }
        }
    }

    // Every membership of this member, newest start first, with the tier name
    // and the total paid for it (the history table on membership.jsp)
    public List<Membership> findAllForMember(int memberId) throws SQLException {
        List<Membership> list = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT m.MembershipId, m.MemberId, m.TierId, t.TierName, m.StartDate, m.EndDate, m.Status, "
                + "       DATEDIFF(m.EndDate, CURDATE()) AS DaysLeft, "
                + "       (SELECT COALESCE(SUM(p.Amount), 0) FROM Payment p "
                + "         WHERE p.MembershipId = m.MembershipId) AS TotalPaid "
                + "  FROM Membership m JOIN MembershipTier t ON t.TierId = m.TierId "
                + " WHERE m.MemberId = ? "
                + " ORDER BY m.StartDate DESC, m.MembershipId DESC")) {
            ps.setInt(1, memberId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Membership m = new Membership();
                    m.setMembershipId(rs.getInt("MembershipId"));
                    m.setMemberId(rs.getInt("MemberId"));
                    m.setTierId(rs.getInt("TierId"));
                    m.setTierName(rs.getString("TierName"));
                    m.setStartDate(rs.getObject("StartDate", LocalDate.class));
                    m.setEndDate(rs.getObject("EndDate", LocalDate.class));
                    m.setStatus(rs.getString("Status"));
                    m.setDaysLeft(rs.getInt("DaysLeft"));
                    m.setTotalPaid(rs.getBigDecimal("TotalPaid"));
                    list.add(m);
                }
            }
        }
        return list;
    }

    // Inserts a membership the member bought themselves (Status ACTIVE,
    // UpdatedBy NULL because no staff member was involved) and returns the
    // new MembershipId.
    public int insert(int memberId, int tierId, LocalDate start, LocalDate end) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO Membership (MemberId, TierId, StartDate, EndDate, Status, UpdatedBy) "
                    + "VALUES (?, ?, ?, ?, 'ACTIVE', NULL)",
                Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, memberId);
            ps.setInt(2, tierId);
            ps.setObject(3, start);
            ps.setObject(4, end);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                return keys.getInt(1);
            }
        }
    }
}
