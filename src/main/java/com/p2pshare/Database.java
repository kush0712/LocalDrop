package com.p2pshare;

import com.p2pshare.Models.*;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import java.io.IOException;
import java.io.InputStream;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

public class Database {

    // ── Connection Pool ──────────────────────────────────────────────────────────
    private static final HikariDataSource POOL;

    static {
        Properties props = new Properties();
        try (InputStream in = Database.class.getClassLoader()
                .getResourceAsStream("db.properties")) {
            if (in == null) {
                throw new ExceptionInInitializerError(
                    "db.properties not found on classpath. " +
                    "Copy src/main/resources/db.properties and fill in your credentials.");
            }
            props.load(in);
        } catch (IOException e) {
            e.printStackTrace(System.err);
            throw new ExceptionInInitializerError(e);
        }

        // Allow password override from environment variable DB_PASSWORD
        String envPwd = System.getenv("DB_PASSWORD");
        String password = (envPwd != null && !envPwd.isEmpty())
                ? envPwd
                : props.getProperty("db.password", "");

        HikariConfig cfg = new HikariConfig();
        cfg.setDriverClassName("com.mysql.cj.jdbc.Driver");
        cfg.setJdbcUrl(props.getProperty("db.url"));
        cfg.setUsername(props.getProperty("db.username"));
        cfg.setPassword(password);
        cfg.setMaximumPoolSize(10);
        cfg.setMinimumIdle(2);
        cfg.setConnectionTimeout(30_000);
        cfg.setIdleTimeout(600_000);
        cfg.setMaxLifetime(1_800_000);
        cfg.setInitializationFailTimeout(-1); // Don't fail-fast; validate on first use
        cfg.setPoolName("P2PSharePool");

        try {
            POOL = new HikariDataSource(cfg);
            System.out.println("[P2PShare] HikariCP pool initialised successfully.");
        } catch (Exception e) {
            System.err.println("[P2PShare] FATAL: HikariCP pool failed to initialise:");
            e.printStackTrace(System.err);
            throw new ExceptionInInitializerError(e);
        }
    }

    /** Returns a pooled connection. Always use try-with-resources. */
    public static Connection getConnection() throws SQLException {
        return POOL.getConnection();
    }

    // ── Named Stat Methods (replaces the raw-SQL getStat(String)) ────────────────

    /** Count of active (not soft-deleted) shared files. */
    public static int countActiveFiles() {
        return queryCount("SELECT COUNT(*) FROM shared_files WHERE is_active = 1");
    }

    /** Total number of transfer log entries. */
    public static int countTransfers() {
        return queryCount("SELECT COUNT(*) FROM transfers");
    }

    /** Number of transfers currently IN_PROGRESS. */
    public static int countActiveTransfers() {
        return queryCount("SELECT COUNT(*) FROM transfers WHERE status = 'IN_PROGRESS'");
    }

    /** Sum of file_size for all active files, in bytes. Returns 0 if none. */
    public static long sumStorageBytes() {
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(
                     "SELECT COALESCE(SUM(file_size), 0) FROM shared_files WHERE is_active = 1")) {
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) return rs.getLong(1);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0L;
    }

    /** Internal helper: runs a COUNT-style query and returns the int result. */
    private static int queryCount(String sql) {
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    // ── File Operations ──────────────────────────────────────────────────────────

    public static List<SharedFile> getFiles(String search) {
        List<SharedFile> list = new ArrayList<>();
        String sql = "SELECT * FROM shared_files WHERE is_active = 1";
        if (search != null && !search.isEmpty()) {
            sql += " AND original_name LIKE ?";
        }
        sql += " ORDER BY upload_time DESC";

        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            if (search != null && !search.isEmpty()) {
                stmt.setString(1, "%" + search + "%");
            }
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                list.add(mapSharedFile(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public static long insertFile(SharedFile f) {
        String sql = "INSERT INTO shared_files " +
                     "(filename, original_name, file_size, file_type, file_hash) " +
                     "VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setString(1, f.getFilename());
            stmt.setString(2, f.getOriginalName());
            stmt.setLong(3, f.getFileSize());
            stmt.setString(4, f.getFileType());
            stmt.setString(5, f.getFileHash());
            stmt.executeUpdate();
            ResultSet rs = stmt.getGeneratedKeys();
            if (rs.next()) return rs.getLong(1);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return -1;
    }

    public static void deleteFile(long fileId) {
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(
                     "UPDATE shared_files SET is_active = 0 WHERE file_id = ?")) {
            stmt.setLong(1, fileId);
            stmt.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static SharedFile getFileById(long fileId) {
        String sql = "SELECT * FROM shared_files WHERE file_id = ?";
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, fileId);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) return mapSharedFile(rs);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public static void incrementDownload(long fileId) {
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(
                     "UPDATE shared_files SET download_count = download_count + 1 WHERE file_id = ?")) {
            stmt.setLong(1, fileId);
            stmt.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static SharedFile mapSharedFile(ResultSet rs) throws SQLException {
        SharedFile sf = new SharedFile();
        sf.setFileId(rs.getLong("file_id"));
        sf.setOriginalName(rs.getString("original_name"));
        sf.setFilename(rs.getString("filename"));
        sf.setFileSize(rs.getLong("file_size"));
        sf.setFileType(rs.getString("file_type"));
        sf.setFileHash(rs.getString("file_hash"));
        Timestamp ts = rs.getTimestamp("upload_time");
        if (ts != null) sf.setUploadTime(ts.toLocalDateTime());
        sf.setDownloadCount(rs.getInt("download_count"));
        sf.setActive(rs.getBoolean("is_active"));
        return sf;
    }

    // ── Transfer Operations ──────────────────────────────────────────────────────

    public static List<Transfer> getTransfers() {
        List<Transfer> list = new ArrayList<>();
        String sql = "SELECT t.*, f.original_name FROM transfers t " +
                     "LEFT JOIN shared_files f ON t.file_id = f.file_id " +
                     "ORDER BY t.start_time DESC LIMIT 50";
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                list.add(mapTransfer(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public static long createTransfer(long fileId, String type, long size) {
        String sql = "INSERT INTO transfers " +
                     "(file_id, transfer_type, file_size, status) " +
                     "VALUES (?, ?, ?, 'IN_PROGRESS')";
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setLong(1, fileId);
            stmt.setString(2, type);
            stmt.setLong(3, size);
            stmt.executeUpdate();
            ResultSet rs = stmt.getGeneratedKeys();
            if (rs.next()) return rs.getLong(1);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return -1;
    }

    public static void completeTransfer(long transferId, String status) {
        String sql = "UPDATE transfers " +
                     "SET status = ?, end_time = NOW(), bytes_transferred = file_size " +
                     "WHERE transfer_id = ?";
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, status);
            stmt.setLong(2, transferId);
            stmt.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /** Marks a transfer as CANCELLED (does not abort any I/O — purely a status update). */
    public static void cancelTransfer(long transferId) {
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(
                     "UPDATE transfers SET status = 'CANCELLED', end_time = NOW() " +
                     "WHERE transfer_id = ? AND status = 'IN_PROGRESS'")) {
            stmt.setLong(1, transferId);
            stmt.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static Transfer mapTransfer(ResultSet rs) throws SQLException {
        Transfer t = new Transfer();
        t.setTransferId(rs.getLong("transfer_id"));
        t.setFileId(rs.getLong("file_id"));
        t.setOriginalName(rs.getString("original_name"));
        t.setTransferType(rs.getString("transfer_type"));
        Timestamp start = rs.getTimestamp("start_time");
        if (start != null) t.setStartTime(start.toLocalDateTime());
        Timestamp end = rs.getTimestamp("end_time");
        if (end != null) t.setEndTime(end.toLocalDateTime());
        t.setFileSize(rs.getLong("file_size"));
        t.setBytesTransferred(rs.getLong("bytes_transferred"));
        t.setStatus(rs.getString("status"));
        t.setErrorMessage(rs.getString("error_message"));
        return t;
    }
}
