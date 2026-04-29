package com.p2pshare;

import com.p2pshare.Models.*;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class Database {

    // Simple DB connection (student-style)
    public static Connection getConnection() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            return DriverManager.getConnection("jdbc:mysql://localhost:3306/p2p_fileshare", "root", "");
        } catch (ClassNotFoundException e) {
            throw new SQLException("Driver not found", e);
        }
    }

    // --- File Operations ---
    public static List<SharedFile> getFiles(String search) {
        List<SharedFile> list = new ArrayList<>();
        String sql = "SELECT f.*, p.peer_name FROM shared_files f JOIN peers p ON f.peer_id = p.peer_id WHERE f.is_active = 1";
        if (search != null && !search.isEmpty()) {
            sql += " AND f.original_name LIKE ?";
        }
        sql += " ORDER BY f.upload_time DESC";

        try (Connection conn = getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {
            if (search != null && !search.isEmpty()) {
                stmt.setString(1, "%" + search + "%");
            }
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
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
                sf.setPeerId(rs.getInt("peer_id"));
                sf.setPeerName(rs.getString("peer_name"));
                sf.setActive(rs.getBoolean("is_active"));
                list.add(sf);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public static long insertFile(SharedFile f) {
        String sql = "INSERT INTO shared_files (filename, original_name, file_size, file_type, file_hash, peer_id) VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = getConnection(); PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setString(1, f.getFilename());
            stmt.setString(2, f.getOriginalName());
            stmt.setLong(3, f.getFileSize());
            stmt.setString(4, f.getFileType());
            stmt.setString(5, f.getFileHash());
            stmt.setInt(6, f.getPeerId());
            stmt.executeUpdate();
            ResultSet rs = stmt.getGeneratedKeys();
            if (rs.next()) return rs.getLong(1);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return -1;
    }

    public static void deleteFile(long fileId) {
        String sql = "UPDATE shared_files SET is_active = 0 WHERE file_id = ?";
        try (Connection conn = getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, fileId);
            stmt.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static SharedFile getFileById(long fileId) {
        String sql = "SELECT f.*, p.peer_name FROM shared_files f JOIN peers p ON f.peer_id = p.peer_id WHERE f.file_id = ?";
        try (Connection conn = getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, fileId);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                SharedFile sf = new SharedFile();
                sf.setFileId(rs.getLong("file_id"));
                sf.setOriginalName(rs.getString("original_name"));
                sf.setFilename(rs.getString("filename"));
                sf.setFileSize(rs.getLong("file_size"));
                sf.setFileType(rs.getString("file_type"));
                sf.setFileHash(rs.getString("file_hash"));
                sf.setPeerId(rs.getInt("peer_id"));
                sf.setPeerName(rs.getString("peer_name"));
                return sf;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public static void incrementDownload(long fileId) {
        try (Connection conn = getConnection(); PreparedStatement stmt = conn.prepareStatement("UPDATE shared_files SET download_count = download_count + 1 WHERE file_id = ?")) {
            stmt.setLong(1, fileId);
            stmt.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }

    // --- Peer Operations ---
    public static List<Peer> getPeers() {
        List<Peer> list = new ArrayList<>();
        try (Connection conn = getConnection(); PreparedStatement stmt = conn.prepareStatement("SELECT * FROM peers ORDER BY status, joined_at DESC")) {
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                Peer p = new Peer();
                p.setPeerId(rs.getInt("peer_id"));
                p.setPeerName(rs.getString("peer_name"));
                p.setIpAddress(rs.getString("ip_address"));
                p.setPort(rs.getInt("port"));
                p.setStatus(rs.getString("status"));
                Timestamp ts = rs.getTimestamp("joined_at");
                if (ts != null) p.setJoinedAt(ts.toLocalDateTime());
                list.add(p);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public static Peer getLocalPeer() {
        try (Connection conn = getConnection(); PreparedStatement stmt = conn.prepareStatement("SELECT * FROM peers WHERE ip_address = '127.0.0.1' LIMIT 1")) {
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                Peer p = new Peer();
                p.setPeerId(rs.getInt("peer_id"));
                p.setPeerName(rs.getString("peer_name"));
                p.setIpAddress(rs.getString("ip_address"));
                return p;
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    // --- Transfer Operations ---
    public static List<Transfer> getTransfers() {
        List<Transfer> list = new ArrayList<>();
        String sql = "SELECT t.*, f.original_name, p.peer_name FROM transfers t " +
                     "LEFT JOIN shared_files f ON t.file_id = f.file_id " +
                     "LEFT JOIN peers p ON t.peer_id = p.peer_id ORDER BY t.start_time DESC LIMIT 50";
        try (Connection conn = getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                Transfer t = new Transfer();
                t.setTransferId(rs.getLong("transfer_id"));
                t.setFileId(rs.getLong("file_id"));
                t.setOriginalName(rs.getString("original_name"));
                t.setPeerId(rs.getInt("peer_id"));
                t.setPeerName(rs.getString("peer_name"));
                t.setTransferType(rs.getString("transfer_type"));
                Timestamp start = rs.getTimestamp("start_time");
                if (start != null) t.setStartTime(start.toLocalDateTime());
                Timestamp end = rs.getTimestamp("end_time");
                if (end != null) t.setEndTime(end.toLocalDateTime());
                t.setFileSize(rs.getLong("file_size"));
                t.setBytesTransferred(rs.getLong("bytes_transferred"));
                t.setStatus(rs.getString("status"));
                t.setErrorMessage(rs.getString("error_message"));
                list.add(t);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public static long createTransfer(long fileId, int peerId, String type, long size) {
        String sql = "INSERT INTO transfers (file_id, peer_id, transfer_type, file_size, status) VALUES (?, ?, ?, ?, 'IN_PROGRESS')";
        try (Connection conn = getConnection(); PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setLong(1, fileId);
            stmt.setInt(2, peerId);
            stmt.setString(3, type);
            stmt.setLong(4, size);
            stmt.executeUpdate();
            ResultSet rs = stmt.getGeneratedKeys();
            if (rs.next()) return rs.getLong(1);
        } catch (Exception e) { e.printStackTrace(); }
        return -1;
    }

    public static void completeTransfer(long transferId, String status) {
        String sql = "UPDATE transfers SET status = ?, end_time = NOW(), bytes_transferred = file_size WHERE transfer_id = ?";
        try (Connection conn = getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, status);
            stmt.setLong(2, transferId);
            stmt.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }
    
    // --- Stats ---
    public static int getStat(String query) {
        try (Connection conn = getConnection(); PreparedStatement stmt = conn.prepareStatement(query)) {
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }
}
