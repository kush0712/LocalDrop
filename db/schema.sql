-- ============================================================
--  P2P FILE SHARING APPLICATION — DATABASE SCHEMA
--  MySQL 8.0+
-- ============================================================

CREATE DATABASE IF NOT EXISTS p2p_fileshare CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE p2p_fileshare;

-- -------------------------------------------------------
-- TABLE: shared_files
-- Metadata of every file shared in the local network
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS shared_files (
    file_id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    filename        VARCHAR(255)    NOT NULL,          -- stored file name (UUID-based)
    original_name   VARCHAR(500)    NOT NULL,          -- user-visible name
    file_size       BIGINT          NOT NULL,          -- bytes
    file_type       VARCHAR(100)    NOT NULL,          -- MIME type
    file_hash       VARCHAR(64)     NOT NULL,          -- SHA-256 checksum
    upload_time     TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    download_count  INT             NOT NULL DEFAULT 0,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    INDEX idx_active (is_active),
    INDEX idx_upload_time (upload_time DESC)
);

-- -------------------------------------------------------
-- TABLE: transfers
-- Audit log of every upload / download attempt
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS transfers (
    transfer_id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    file_id             BIGINT          NOT NULL,
    transfer_type       ENUM('UPLOAD','DOWNLOAD') NOT NULL,
    start_time          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_time            TIMESTAMP       NULL,
    file_size           BIGINT          NOT NULL DEFAULT 0,
    bytes_transferred   BIGINT          NOT NULL DEFAULT 0,
    status              ENUM('PENDING','IN_PROGRESS','COMPLETED','FAILED','CANCELLED') NOT NULL DEFAULT 'PENDING',
    error_message       TEXT            NULL,
    FOREIGN KEY (file_id)  REFERENCES shared_files(file_id) ON DELETE CASCADE,
    INDEX idx_status (status),
    INDEX idx_start_time (start_time DESC)
);

-- -------------------------------------------------------
-- USEFUL VIEWS
-- -------------------------------------------------------

-- View: Active files
CREATE OR REPLACE VIEW v_active_files AS
SELECT
    sf.file_id,
    sf.original_name,
    sf.filename,
    sf.file_size,
    sf.file_type,
    sf.file_hash,
    sf.upload_time,
    sf.download_count
FROM shared_files sf
WHERE sf.is_active = 1
ORDER BY sf.upload_time DESC;

-- View: Transfer statistics
CREATE OR REPLACE VIEW v_transfer_stats AS
SELECT
    COUNT(*) AS total_transfers,
    SUM(CASE WHEN transfer_type = 'UPLOAD'   THEN 1 ELSE 0 END) AS total_uploads,
    SUM(CASE WHEN transfer_type = 'DOWNLOAD' THEN 1 ELSE 0 END) AS total_downloads,
    SUM(CASE WHEN status = 'COMPLETED'       THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN status = 'FAILED'          THEN 1 ELSE 0 END) AS failed,
    SUM(bytes_transferred) AS total_bytes
FROM transfers;
