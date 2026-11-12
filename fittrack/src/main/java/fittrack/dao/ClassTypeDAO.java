
package fittrack.dao;

import fittrack.model.ClassType;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

// SQL operations for managing class types.
public class ClassTypeDAO {

    private final Connection con;

    public ClassTypeDAO(Connection con) {
        this.con = con;
    }

    // Retrieve every class type, sorted by title.
    public List<ClassType> findAll() throws SQLException {
        List<ClassType> list = new ArrayList<>();

        String sql = "SELECT ClassTypeId, Title, Description "
                   + "FROM ClassType ORDER BY Title";

        try (PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                list.add(new ClassType(
                    rs.getInt("ClassTypeId"),
                    rs.getString("Title"),
                    rs.getString("Description")
                ));
            }
        }

        return list;
    }

    // Retrieve a specific class type by ID.
    public ClassType findById(int classTypeId) throws SQLException {

        String sql = "SELECT ClassTypeId, Title, Description "
                   + "FROM ClassType WHERE ClassTypeId = ?";

        try (PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, classTypeId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new ClassType(
                        rs.getInt("ClassTypeId"),
                        rs.getString("Title"),
                        rs.getString("Description")
                    );
                }
            }
        }

        return null;
    }

    // Add a new class type.
    public boolean addClassType(String title, String description)
            throws SQLException {

        String sql = "INSERT INTO ClassType (Title, Description) "
                   + "VALUES (?, ?)";

        try (PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, title);
            ps.setString(2, description);

            return ps.executeUpdate() > 0;
        }
    }

    // Update an existing class type.
    public boolean updateClassType(
            int classTypeId,
            String title,
            String description) throws SQLException {

        String sql = "UPDATE ClassType "
                   + "SET Title = ?, Description = ? "
                   + "WHERE ClassTypeId = ?";

        try (PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, title);
            ps.setString(2, description);
            ps.setInt(3, classTypeId);

            return ps.executeUpdate() > 0;
        }
    }
}
