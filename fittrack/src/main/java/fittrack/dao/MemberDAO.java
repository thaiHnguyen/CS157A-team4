package fittrack.dao;

import fittrack.model.Member;

import java.sql.*;

// All SQL for the Member table. Runs on the caller's Connection.
public class MemberDAO {
    private final Connection con;

    public MemberDAO(Connection con) {
        this.con = con;
    }

    // The Member row for this user, or null (trainers and staff have none)
    public Member findById(int userId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT UserId, EmergencyPhoneNumber FROM Member WHERE UserId = ?")) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next()
                    ? new Member(rs.getInt("UserId"), rs.getString("EmergencyPhoneNumber"))
                    : null;
            }
        }
    }

    /** Adds the Member row for an account that was just inserted. */
    public void insert(Member m) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO Member (UserId, EmergencyPhoneNumber) VALUES (?, ?)")) {
            ps.setInt(1, m.getUserId());
            ps.setString(2, m.getEmergencyPhone());
            ps.executeUpdate();
        }
    }

    // Sets or clears (null) the emergency phone 
    public void updateEmergencyPhone(int userId, String phone) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE Member SET EmergencyPhoneNumber = ? WHERE UserId = ?")) {
            ps.setString(1, phone);
            ps.setInt(2, userId);
            ps.executeUpdate();
        }
    }
}
