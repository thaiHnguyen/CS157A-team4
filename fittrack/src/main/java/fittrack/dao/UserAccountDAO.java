package fittrack.dao;

import fittrack.model.UserAccount;

import java.sql.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * All SQL for the UserAccount table
 *
 * Like every DAO here, it runs on a Connection the caller opened. It never
 * commits, rolls back, or closes it, so the JSP can put several DAO calls in
 * one transaction
 */
public class UserAccountDAO {
    private static final String COLUMNS =
        "UserId, Email, PasswordHash, Role, Name, Phone, DateOfBirth, CreatedAt";

    private final Connection con;

    public UserAccountDAO(Connection con) {
        this.con = con;
    }

    //The account with this email, or null. Used by login
    public UserAccount findByEmail(String email) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT " + COLUMNS + " FROM UserAccount WHERE Email = ?")) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    // The account with this id, or null
    public UserAccount findById(int userId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT " + COLUMNS + " FROM UserAccount WHERE UserId = ?")) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    // True if an account already uses this email
    public boolean emailExists(String email) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT 1 FROM UserAccount WHERE Email = ?")) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /**
     * Inserts the account and returns the new UserId
     * passwordHash must already be hashed (hashPassword() in common.jspf)
     */
    public int insert(UserAccount u) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO UserAccount (Email, PasswordHash, Role, Name, Phone, DateOfBirth) "
                    + "VALUES (?, ?, ?, ?, ?, ?)",
                Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, u.getEmail());
            ps.setString(2, u.getPasswordHash());
            ps.setString(3, u.getRole());
            ps.setString(4, u.getName());
            ps.setString(5, u.getPhone());
            ps.setObject(6, u.getDateOfBirth());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                int id = keys.getInt(1);
                u.setUserId(id);
                return id;
            }
        }
    }

    // Updates the fields a user may change on the profile page
    public void updateContact(int userId, String name, String phone) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE UserAccount SET Name = ?, Phone = ? WHERE UserId = ?")) {
            ps.setString(1, name);
            ps.setString(2, phone);
            ps.setInt(3, userId);
            ps.executeUpdate();
        }
    }

    private static UserAccount map(ResultSet rs) throws SQLException {
        UserAccount u = new UserAccount();
        u.setUserId(rs.getInt("UserId"));
        u.setEmail(rs.getString("Email"));
        u.setPasswordHash(rs.getString("PasswordHash"));
        u.setRole(rs.getString("Role"));
        u.setName(rs.getString("Name"));
        u.setPhone(rs.getString("Phone"));
        u.setDateOfBirth(rs.getObject("DateOfBirth", LocalDate.class));
        u.setCreatedAt(rs.getObject("CreatedAt", LocalDateTime.class));
        return u;
    }
}
