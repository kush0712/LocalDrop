package com.p2pshare;

import java.time.LocalDateTime;

public class Models {

    public static class SharedFile {
        private long fileId;
        private String originalName;
        private String filename;
        private long fileSize;
        private String fileType;
        private String fileHash;
        private LocalDateTime uploadTime;
        private int downloadCount;
        private boolean active;

        public long getFileId() { return fileId; }
        public void setFileId(long fileId) { this.fileId = fileId; }
        public String getOriginalName() { return originalName; }
        public void setOriginalName(String originalName) { this.originalName = originalName; }
        public String getFilename() { return filename; }
        public void setFilename(String filename) { this.filename = filename; }
        public long getFileSize() { return fileSize; }
        public void setFileSize(long fileSize) { this.fileSize = fileSize; }
        public String getFileType() { return fileType; }
        public void setFileType(String fileType) { this.fileType = fileType; }
        public String getFileHash() { return fileHash; }
        public void setFileHash(String fileHash) { this.fileHash = fileHash; }
        public LocalDateTime getUploadTime() { return uploadTime; }
        public void setUploadTime(LocalDateTime uploadTime) { this.uploadTime = uploadTime; }
        public int getDownloadCount() { return downloadCount; }
        public void setDownloadCount(int downloadCount) { this.downloadCount = downloadCount; }
        public boolean isActive() { return active; }
        public void setActive(boolean active) { this.active = active; }

        public String getFormattedSize() {
            if (fileSize < 1024) return fileSize + " B";
            if (fileSize < 1024 * 1024) return String.format("%.1f KB", fileSize / 1024.0);
            return String.format("%.1f MB", fileSize / (1024.0 * 1024));
        }

        public String getFormattedUploadTime() {
            return uploadTime != null ? uploadTime.format(java.time.format.DateTimeFormatter.ofPattern("dd MMM yy")) : "";
        }
    }

    public static class Transfer {
        private long transferId;
        private long fileId;
        private String originalName;
        private String transferType;
        private LocalDateTime startTime;
        private LocalDateTime endTime;
        private long fileSize;
        private long bytesTransferred;
        private String status;
        private String errorMessage;

        public long getTransferId() { return transferId; }
        public void setTransferId(long transferId) { this.transferId = transferId; }
        public long getFileId() { return fileId; }
        public void setFileId(long fileId) { this.fileId = fileId; }
        public String getOriginalName() { return originalName; }
        public void setOriginalName(String originalName) { this.originalName = originalName; }
        public String getTransferType() { return transferType; }
        public void setTransferType(String transferType) { this.transferType = transferType; }
        public LocalDateTime getStartTime() { return startTime; }
        public void setStartTime(LocalDateTime startTime) { this.startTime = startTime; }
        public LocalDateTime getEndTime() { return endTime; }
        public void setEndTime(LocalDateTime endTime) { this.endTime = endTime; }
        public long getFileSize() { return fileSize; }
        public void setFileSize(long fileSize) { this.fileSize = fileSize; }
        public long getBytesTransferred() { return bytesTransferred; }
        public void setBytesTransferred(long bytesTransferred) { this.bytesTransferred = bytesTransferred; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public String getErrorMessage() { return errorMessage; }
        public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }

        public int getProgressPercent() {
            if (fileSize <= 0) return 0;
            return (int) Math.min(100, (bytesTransferred * 100L) / fileSize);
        }

        public String getDuration() {
            if (startTime == null) return "—";
            LocalDateTime end = endTime != null ? endTime : LocalDateTime.now();
            long seconds = java.time.Duration.between(startTime, end).getSeconds();
            return seconds + "s";
        }
        
        public String getFormattedStartTime() {
            return startTime != null ? startTime.format(java.time.format.DateTimeFormatter.ofPattern("HH:mm dd/MM")) : "";
        }
    }
}
