package com.p2pshare;

import com.p2pshare.Models.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.security.MessageDigest;
import java.util.List;
import java.util.stream.Collectors;

@WebServlet(urlPatterns = {
    "", "/index",
    "/files", "/files/delete",
    "/upload",
    "/download",
    "/transfers", "/transfers/cancel"
})
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,
    maxFileSize       = 500L * 1024 * 1024,
    maxRequestSize    = 500L * 1024 * 1024
)
public class MainServlet extends HttpServlet {

    private static final Logger log = LoggerFactory.getLogger(MainServlet.class);

    private String uploadDir;

    @Override
    public void init() throws ServletException {
        // Use a persistent directory in the user's home folder so uploads survive Tomcat restarts
        uploadDir = System.getProperty("user.home") + File.separator + "LANShare_Uploads";
        File dir = new File(uploadDir);
        if (!dir.exists()) dir.mkdirs();
        log.info("MainServlet initialised. Upload dir: {}", uploadDir);
    }

    // ── GET ──────────────────────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String path = req.getServletPath();

        try {
            switch (path) {
                case "", "/index" -> handleDashboard(req, resp);
                case "/files"     -> handleFileList(req, resp);
                case "/upload"    -> forward(req, resp, "/WEB-INF/views/upload.jsp");
                case "/transfers" -> {
                    if ("json".equals(req.getParameter("format"))) {
                        handleTransfersJson(req, resp);
                    } else {
                        handleTransfers(req, resp);
                    }
                }
                case "/download"  -> handleDownload(req, resp);
                default           -> resp.sendError(404);
            }
        } catch (Exception e) {
            e.printStackTrace();
            req.setAttribute("errorMessage", e.getMessage());
            forward(req, resp, "/WEB-INF/views/error.jsp");
        }
    }

    // ── POST ─────────────────────────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String path = req.getServletPath();

        try {
            switch (path) {
                case "/upload"          -> handleUpload(req, resp);
                case "/files/delete"    -> handleFileDelete(req, resp);
                case "/transfers/cancel"-> handleTransferCancel(req, resp);
                default                 -> resp.sendError(404);
            }
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/?error=" + encode(e.getMessage()));
        }
    }

    // ── Dashboard ────────────────────────────────────────────────────────────────

    private void handleDashboard(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        // Stats
        req.setAttribute("totalFiles",      Database.countActiveFiles());
        req.setAttribute("totalTransfers",  Database.countTransfers());
        req.setAttribute("activeTransfers", Database.countActiveTransfers());
        req.setAttribute("storageBytes",    formatBytes(Database.sumStorageBytes()));

        // LAN share URL — shows the machine's local network IP so others can connect
        String localIp = getLanIpAddress();
        String lanUrl = "http://" + localIp + ":" + req.getServerPort()
                      + req.getContextPath() + "/";
        req.setAttribute("lanUrl", lanUrl);

        // Recent data for the two dashboard tables
        List<SharedFile> allFiles = Database.getFiles(null);
        req.setAttribute("recentFiles",     allFiles.stream().limit(5).collect(Collectors.toList()));

        List<Transfer> allTransfers = Database.getTransfers();
        req.setAttribute("recentTransfers", allTransfers.stream().limit(5).collect(Collectors.toList()));

        // Active transfer count badge on navbar
        long activeCount = allTransfers.stream()
                .filter(t -> "IN_PROGRESS".equals(t.getStatus())).count();
        req.setAttribute("activeCount", activeCount);

        forward(req, resp, "/WEB-INF/views/index.jsp");
    }

    // ── Files ────────────────────────────────────────────────────────────────────

    private void handleFileList(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        String search = req.getParameter("search");
        req.setAttribute("files",       Database.getFiles(search));
        req.setAttribute("searchQuery", search);
        req.setAttribute("success",     req.getParameter("success"));
        forward(req, resp, "/WEB-INF/views/files.jsp");
    }

    private void handleFileDelete(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        String idParam = req.getParameter("id");
        if (idParam != null) {
            Database.deleteFile(Long.parseLong(idParam));
        }
        resp.sendRedirect(req.getContextPath() + "/files?success=File+deleted");
    }


    // ── Transfers ────────────────────────────────────────────────────────────────

    private void handleTransfers(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        List<Transfer> all = Database.getTransfers();

        List<Transfer> active = all.stream()
                .filter(t -> "IN_PROGRESS".equals(t.getStatus()))
                .collect(Collectors.toList());

        req.setAttribute("transfers",   all);
        req.setAttribute("active",      active);
        req.setAttribute("activeCount", active.size());
        forward(req, resp, "/WEB-INF/views/transfers.jsp");
    }

    private void handleTransferCancel(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        long transferId = Long.parseLong(req.getParameter("id"));
        Database.cancelTransfer(transferId);
        log.info("Transfer {} cancelled by user", transferId);
        resp.sendRedirect(req.getContextPath() + "/transfers?success=Transfer+cancelled");
    }

    // ── Transfers JSON (for live polling) ────────────────────────────────────────

    private void handleTransfersJson(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        List<Transfer> active = Database.getTransfers().stream()
                .filter(t -> "IN_PROGRESS".equals(t.getStatus()))
                .collect(Collectors.toList());

        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");

        // Build JSON manually — no extra library needed for this simple payload
        StringBuilder json = new StringBuilder();
        json.append("{\"activeCount\":").append(active.size()).append(",\"active\":[");
        for (int i = 0; i < active.size(); i++) {
            Transfer t = active.get(i);
            if (i > 0) json.append(",");
            json.append("{");
            json.append("\"transferId\":").append(t.getTransferId()).append(",");
            json.append("\"fileSize\":").append(t.getFileSize()).append(",");
            json.append("\"bytesTransferred\":").append(t.getBytesTransferred()).append(",");
            json.append("\"status\":\"").append(t.getStatus()).append("\"");
            json.append("}");
        }
        json.append("]}");

        resp.getWriter().write(json.toString());
    }

    // ── Upload ───────────────────────────────────────────────────────────────────

    private void handleUpload(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        Part filePart = req.getPart("file");
        if (filePart == null || filePart.getSize() == 0) {
            resp.sendRedirect(req.getContextPath() + "/upload?error=No+file+selected");
            return;
        }

        String originalName = extractFilename(filePart);
        String storedName   = System.currentTimeMillis() + "_" + originalName;
        File   destFile     = new File(uploadDir, storedName);
        log.info("Upload started: {}", originalName);

        // Save file to disk and compute SHA-256 in a single pass
        MessageDigest digest;
        try {
            digest = MessageDigest.getInstance("SHA-256");
        } catch (Exception e) {
            throw new ServletException("SHA-256 not available", e);
        }

        try (InputStream in  = filePart.getInputStream();
             OutputStream out = new FileOutputStream(destFile)) {
            byte[] buffer = new byte[8192];
            int    read;
            while ((read = in.read(buffer)) != -1) {
                out.write(buffer, 0, read);
                digest.update(buffer, 0, read);
            }
        }

        // Hex-encode the digest
        byte[] hashBytes = digest.digest();
        StringBuilder hexHash = new StringBuilder(64);
        for (byte b : hashBytes) {
            hexHash.append(String.format("%02x", b));
        }

        // Persist metadata
        SharedFile sf = new SharedFile();
        sf.setFilename(storedName);
        sf.setOriginalName(originalName);
        sf.setFileSize(destFile.length());
        sf.setFileType(filePart.getContentType() != null
                ? filePart.getContentType() : "application/octet-stream");
        sf.setFileHash(hexHash.toString());

        long fileId = Database.insertFile(sf);
        if (fileId == -1) {
            resp.sendRedirect(req.getContextPath() +
                    "/upload?error=Database+error:+Failed+to+save+file+metadata");
            return;
        }

        // Log transfer
        long transferId = Database.createTransfer(fileId, "UPLOAD", destFile.length());
        Database.completeTransfer(transferId, "COMPLETED");

        resp.sendRedirect(req.getContextPath() + "/files?success=Upload+successful");
    }

    // ── Download ─────────────────────────────────────────────────────────────────

    private void handleDownload(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        long fileId = Long.parseLong(req.getParameter("id"));
        SharedFile sf = Database.getFileById(fileId);

        if (sf == null) {
            resp.sendError(404, "File not found in database");
            return;
        }

        File file = new File(uploadDir, sf.getFilename());
        if (!file.exists()) {
            log.warn("File record exists in DB but missing on disk: {}", sf.getFilename());
            resp.sendError(404, "File not found on disk");
            return;
        }

        log.info("Download started: {} ({})", sf.getOriginalName(), sf.getFileSize());

        long transferId = Database.createTransfer(fileId, "DOWNLOAD", sf.getFileSize());

        resp.setContentType(sf.getFileType());
        resp.setHeader("Content-Disposition",
                "attachment; filename=\"" + sf.getOriginalName() + "\"");
        resp.setContentLengthLong(file.length());

        try (InputStream  in  = new FileInputStream(file);
             OutputStream out = resp.getOutputStream()) {
            byte[] buffer = new byte[8192];
            int    read;
            while ((read = in.read(buffer)) != -1) {
                out.write(buffer, 0, read);
            }
            Database.completeTransfer(transferId, "COMPLETED");
            Database.incrementDownload(fileId);
        } catch (Exception e) {
            Database.completeTransfer(transferId, "FAILED");
            throw e;
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────────────

    private void forward(HttpServletRequest req, HttpServletResponse resp, String view)
            throws ServletException, IOException {
        req.getRequestDispatcher(view).forward(req, resp);
    }

    private String extractFilename(Part part) {
        String disposition = part.getHeader("content-disposition");
        if (disposition != null) {
            for (String token : disposition.split(";")) {
                if (token.trim().startsWith("filename")) {
                    return token.substring(token.indexOf('=') + 1)
                                .trim().replace("\"", "");
                }
            }
        }
        return "unknown_" + System.currentTimeMillis();
    }

    /** URL-encodes a string for safe use in redirect query parameters. */
    private static String encode(String s) {
        try {
            return java.net.URLEncoder.encode(s != null ? s : "", "UTF-8");
        } catch (Exception e) {
            return s != null ? s : "";
        }
    }

    /** Formats a byte count as a human-readable string (B / KB / MB / GB). */
    private static String formatBytes(long bytes) {
        if (bytes < 1024)            return bytes + " B";
        if (bytes < 1024 * 1024)     return String.format("%.1f KB", bytes / 1024.0);
        if (bytes < 1024L * 1024 * 1024) return String.format("%.1f MB", bytes / (1024.0 * 1024));
        return String.format("%.2f GB", bytes / (1024.0 * 1024 * 1024));
    }
    /** Retrieves the active LAN IPv4 address (avoids loopback). */
    private String getLanIpAddress() {
        try {
            java.util.Enumeration<java.net.NetworkInterface> interfaces = java.net.NetworkInterface.getNetworkInterfaces();
            while (interfaces.hasMoreElements()) {
                java.net.NetworkInterface iface = interfaces.nextElement();
                // Filter out loopback, inactive, or virtual interfaces
                if (iface.isLoopback() || !iface.isUp() || iface.isVirtual()) continue;

                java.util.Enumeration<java.net.InetAddress> addresses = iface.getInetAddresses();
                while (addresses.hasMoreElements()) {
                    java.net.InetAddress addr = addresses.nextElement();
                    // Looks for an IPv4 address
                    if (addr instanceof java.net.Inet4Address) {
                        return addr.getHostAddress();
                    }
                }
            }
        } catch (Exception e) {
            // fallback
        }
        try {
            return java.net.InetAddress.getLocalHost().getHostAddress();
        } catch (Exception e) {
            return "localhost";
        }
    }
}
