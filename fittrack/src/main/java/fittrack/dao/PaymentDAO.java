package fittrack.dao;

import fittrack.model.Payment;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

// All SQL for the Payment table (weak entity of Membership). Runs on the
// caller's Connection.
public class PaymentDAO {
    private final Connection con;

    public PaymentDAO(Connection con) {
        this.con = con;
    }

    // The next PaymentNo for this membership: 1 for its first payment, then 2, 3, ...
    // Locking read (FOR UPDATE), so it sees the latest committed rows and two
    // payments for the same membership cannot get the same number
    public int nextPaymentNo(int membershipId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COALESCE(MAX(PaymentNo), 0) + 1 FROM Payment WHERE MembershipId = ? FOR UPDATE")) {
            ps.setInt(1, membershipId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    // Inserts the payment. PayDate defaults to now (CURRENT_TIMESTAMP)
    public void insert(Payment p) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO Payment (MembershipId, PaymentNo, Amount, Method) VALUES (?, ?, ?, ?)")) {
            ps.setInt(1, p.getMembershipId());
            ps.setInt(2, p.getPaymentNo());
            ps.setBigDecimal(3, p.getAmount());
            ps.setString(4, p.getMethod());
            ps.executeUpdate();
        }
    }

    // Every payment for this member's memberships, newest first, with the tier name
    public List<Payment> findByMember(int memberId) throws SQLException {
        List<Payment> list = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT p.MembershipId, p.PaymentNo, p.Amount, p.PayDate, p.Method, t.TierName "
                + "  FROM Payment p "
                + "  JOIN Membership m     ON m.MembershipId = p.MembershipId "
                + "  JOIN MembershipTier t ON t.TierId = m.TierId "
                + " WHERE m.MemberId = ? "
                + " ORDER BY p.PayDate DESC, p.MembershipId DESC, p.PaymentNo DESC")) {
            ps.setInt(1, memberId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Payment p = new Payment();
                    p.setMembershipId(rs.getInt("MembershipId"));
                    p.setPaymentNo(rs.getInt("PaymentNo"));
                    p.setAmount(rs.getBigDecimal("Amount"));
                    p.setPayDate(rs.getObject("PayDate", LocalDateTime.class));
                    p.setMethod(rs.getString("Method"));
                    p.setTierName(rs.getString("TierName"));
                    list.add(p);
                }
            }
        }
        return list;
    }
}
