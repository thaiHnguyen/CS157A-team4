package fittrack.dao;

import fittrack.model.Trainer;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

// All SQL for the Trainer table. Runs on the caller's Connection
public class TrainerDAO {
    private final Connection con;

    public TrainerDAO(Connection con) {
        this.con = con;
    }

    // Every trainer with their name, sorted by name
    public List<Trainer> findAll() throws SQLException {
        List<Trainer> list = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT t.UserId, u.Name FROM Trainer t "
                + "  JOIN UserAccount u ON u.UserId = t.UserId ORDER BY u.Name");
            ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new Trainer(rs.getInt("UserId"), rs.getString("Name")));
            }
        }
        return list;
    }
}
