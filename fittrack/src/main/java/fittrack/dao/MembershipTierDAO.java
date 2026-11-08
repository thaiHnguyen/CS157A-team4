package fittrack.dao;

import fittrack.model.MembershipTier;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

// All SQL for the MembershipTier table. Runs on the caller's Connection.
public class MembershipTierDAO {
    private static final String COLUMNS = "TierId, TierName, TierLevel, Fee, Description";

    private final Connection con;

    public MembershipTierDAO(Connection con) {
        this.con = con;
    }

    // Every tier, cheapest level first (the plan list on membership.jsp)
    public List<MembershipTier> findAll() throws SQLException {
        List<MembershipTier> list = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT " + COLUMNS + " FROM MembershipTier ORDER BY TierLevel, Fee, TierName");
            ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(map(rs));
            }
        }
        return list;
    }

    // The tier with this id, or null
    public MembershipTier findById(int tierId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT " + COLUMNS + " FROM MembershipTier WHERE TierId = ?")) {
            ps.setInt(1, tierId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    private static MembershipTier map(ResultSet rs) throws SQLException {
        MembershipTier t = new MembershipTier();
        t.setTierId(rs.getInt("TierId"));
        t.setTierName(rs.getString("TierName"));
        t.setTierLevel(rs.getInt("TierLevel"));
        t.setFee(rs.getBigDecimal("Fee"));
        t.setDescription(rs.getString("Description"));
        return t;
    }
}
