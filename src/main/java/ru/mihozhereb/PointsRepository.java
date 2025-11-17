package ru.mihozhereb;

import jakarta.servlet.ServletContext;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class PointsRepository {

    private final String url;
    private final String user;
    private final String pass;
    private final String table = "points";

    public PointsRepository(ServletContext ctx) {
        this.url   = ctx.getInitParameter("db.url");
        this.user  = ctx.getInitParameter("db.user");
        this.pass  = ctx.getInitParameter("db.password");

        if (url == null || user == null || pass == null) {
            throw new IllegalStateException("Missing DB configuration in web.xml");
        }

        ensureTableExists();
    }

    private Connection getConnection() throws SQLException {
        return DriverManager.getConnection(url, user, pass);
    }

    private void ensureTableExists() {
        String createSql =
                "CREATE TABLE IF NOT EXISTS " + table + " (" +
                        " id BIGSERIAL PRIMARY KEY," +
                        " session_id VARCHAR(64) NOT NULL," +
                        " x DOUBLE PRECISION NOT NULL," +
                        " y DOUBLE PRECISION NOT NULL," +
                        " r INTEGER NOT NULL," +
                        " hit BOOLEAN NOT NULL," +
                        " time TIMESTAMP NOT NULL," +
                        " timing_ms BIGINT NOT NULL" +
                        ")";

        try (Connection con = getConnection();
             Statement st = con.createStatement()) {

            st.executeUpdate(createSql);

        } catch (SQLException e) {
            throw new RuntimeException("Failed creating table", e);
        }
    }

    public void save(String sessionId, PointRecord rec) {
        String sql = "INSERT INTO " + table +
                "(session_id, x, y, r, hit, time, timing_ms)" +
                "VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, sessionId);
            ps.setDouble(2, rec.getX());
            ps.setDouble(3, rec.getY());
            ps.setInt(4, rec.getR());
            ps.setBoolean(5, rec.isHit());
            ps.setTimestamp(6, Timestamp.valueOf(rec.getTime()));
            ps.setLong(7, rec.getTimingMs());

            ps.executeUpdate();

        } catch (SQLException e) {
            throw new RuntimeException("DB insert error", e);
        }
    }

    public List<PointRecord> findBySession(String sessionId) {
        String sql = "SELECT x, y, r, hit, time, timing_ms FROM " + table +
                " WHERE session_id=? ORDER BY id";

        List<PointRecord> list = new ArrayList<>();

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, sessionId);
            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                list.add(new PointRecord(
                        rs.getDouble("x"),
                        rs.getDouble("y"),
                        rs.getInt("r"),
                        rs.getBoolean("hit"),
                        rs.getTimestamp("time").toLocalDateTime(),
                        rs.getLong("timing_ms")));
            }
        } catch (SQLException e) {
            throw new RuntimeException("DB select error", e);
        }

        return list;
    }

    public void clearBySession(String sessionId) {
        String sql = "DELETE FROM " + table + " WHERE session_id=?";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, sessionId);
            ps.executeUpdate();

        } catch (SQLException e) {
            throw new RuntimeException("DB delete error", e);
        }
    }
}