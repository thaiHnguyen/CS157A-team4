package fittrack.dao;

import fittrack.model.ClassType;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

// All SQL for the ClassType table. Runs on the caller's Connection
public class ClassTypeDAO {
    private final Connection con;

    public ClassTypeDAO(Connection con) {
        this.con = con;
    }

    // Every class type, sorted by title 
    public List<ClassType> findAll() throws SQLException {
        List<ClassType> list = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT ClassTypeId, Title FROM ClassType ORDER BY Title");
        ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new ClassType(rs.getInt("ClassTypeId"), rs.getString("Title")));
            }
        }
        return list;
    }
}
