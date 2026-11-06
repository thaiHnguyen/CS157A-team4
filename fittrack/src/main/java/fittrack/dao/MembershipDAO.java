package fittrack.dao;

import fittrack.model.Membership;

import java.sql.*;
import java.time.LocalDate;

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
}
