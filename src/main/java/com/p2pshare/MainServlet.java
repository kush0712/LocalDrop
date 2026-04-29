package com.p2pshare;

import com.p2pshare.Models.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.*;
import java.security.MessageDigest;
import java.util.List;

@WebServlet(urlPatterns = {"", "/index", "/files", "/files/delete", "/upload", "/download", "/peers", "/transfers"})
@MultipartConfig(fileSizeThreshold = 1024 * 1024, maxFileSize = 500 * 1024 * 1024, maxRequestSize = 500 * 1024 * 1024)
public class MainServlet extends HttpServlet {

    private String uploadDir;

    @Override
    public void init() throws ServletException {
        uploadDir = getServletContext().getRealPath("") + File.separator + "uploads";
        File dir = new File(uploadDir);
        if (!dir.exists()) dir.mkdirs();
        System.out.println("MainServlet initialized. Upload dir: " + uploadDir);
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String path = req.getServletPath();

        try {
            if (path.equals("") || path.equals("/index")) {
                req.setAttribute("totalFiles", Database.getStat("SELECT COUNT(*) FROM shared_files WHERE is_active=1"));
                req.setAttribute("totalPeers", Database.getStat("SELECT COUNT(*) FROM peers"));
                req.setAttribute("totalTransfers", Database.getStat("SELECT COUNT(*) FROM transfers"));
                req.setAttribute("recentFiles", Database.getFiles("")); // Just send all or limit in JSP
                req.getRequestDispatcher("/WEB-INF/views/index.jsp").forward(req, resp);
            } 
            else if (path.equals("/files")) {
                String search = req.getParameter("search");
                List<SharedFile> files = Database.getFiles(search);
                req.setAttribute("files", files);
                req.setAttribute("searchQuery", search);
                req.setAttribute("success", req.getParameter("success"));
                req.setAttribute("error", req.getParameter("error"));
                req.getRequestDispatcher("/WEB-INF/views/files.jsp").forward(req, resp);
            } 
            else if (path.equals("/upload")) {
                req.getRequestDispatcher("/WEB-INF/views/upload.jsp").forward(req, resp);
            } 
            else if (path.equals("/peers")) {
                req.setAttribute("peers", Database.getPeers());
                req.getRequestDispatcher("/WEB-INF/views/peers.jsp").forward(req, resp);
            } 
            else if (path.equals("/transfers")) {
                req.setAttribute("transfers", Database.getTransfers());
                req.getRequestDispatcher("/WEB-INF/views/transfers.jsp").forward(req, resp);
            } 
            else if (path.equals("/download")) {
                handleDownload(req, resp);
            }
            else {
                resp.sendError(404);
            }
        } catch (Exception e) {
            e.printStackTrace();
            req.setAttribute("errorMessage", e.getMessage());
            req.getRequestDispatcher("/WEB-INF/views/error.jsp").forward(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String path = req.getServletPath();

        try {
            if (path.equals("/upload")) {
                handleUpload(req, resp);
            } 
            else if (path.equals("/files/delete")) {
                String idParam = req.getParameter("id");
                if (idParam != null) {
                    Database.deleteFile(Long.parseLong(idParam));
                }
                resp.sendRedirect(req.getContextPath() + "/files?success=File+deleted");
            }
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/files?error=" + e.getMessage());
        }
    }

    private void handleUpload(HttpServletRequest req, HttpServletResponse resp) throws Exception {
        Part filePart = req.getPart("file");
        if (filePart == null || filePart.getSize() == 0) {
            resp.sendRedirect(req.getContextPath() + "/upload?error=No+file+selected");
            return;
        }

        String originalName = extractFilename(filePart);
        String storedName = System.currentTimeMillis() + "_" + originalName;
        File destFile = new File(uploadDir, storedName);

        // Save file to disk
        try (InputStream in = filePart.getInputStream(); OutputStream out = new FileOutputStream(destFile)) {
            byte[] buffer = new byte[8192];
            int read;
            while ((read = in.read(buffer)) != -1) {
                out.write(buffer, 0, read);
            }
        }

        // Create Database Entry
        SharedFile sf = new SharedFile();
        sf.setFilename(storedName);
        sf.setOriginalName(originalName);
        sf.setFileSize(destFile.length());
        sf.setFileType(filePart.getContentType());
        sf.setFileHash("hash_not_computed_for_simplicity"); // Simplified
        Peer localPeer = Database.getLocalPeer();
        int peerId = localPeer != null ? localPeer.getPeerId() : 1;
        sf.setPeerId(peerId);

        long fileId = Database.insertFile(sf);

        if (fileId == -1) {
            resp.sendRedirect(req.getContextPath() + "/upload?error=Database+error:+Failed+to+save+file+metadata");
            return;
        }

        // Record transfer
        long transferId = Database.createTransfer(fileId, peerId, "UPLOAD", destFile.length());
        Database.completeTransfer(transferId, "COMPLETED");

        resp.sendRedirect(req.getContextPath() + "/files?success=Upload+Successful");
    }

    private void handleDownload(HttpServletRequest req, HttpServletResponse resp) throws Exception {
        long fileId = Long.parseLong(req.getParameter("id"));
        SharedFile sf = Database.getFileById(fileId);

        if (sf == null) {
            resp.sendError(404, "File not found in DB");
            return;
        }

        File file = new File(uploadDir, sf.getFilename());
        if (!file.exists()) {
            resp.sendError(404, "File not found on disk");
            return;
        }

        // Record transfer
        Peer localPeer = Database.getLocalPeer();
        int peerId = localPeer != null ? localPeer.getPeerId() : 1;
        long transferId = Database.createTransfer(fileId, peerId, "DOWNLOAD", sf.getFileSize());

        // Send file to client
        resp.setContentType(sf.getFileType());
        resp.setHeader("Content-Disposition", "attachment; filename=\"" + sf.getOriginalName() + "\"");
        resp.setContentLengthLong(file.length());

        try (InputStream in = new FileInputStream(file); OutputStream out = resp.getOutputStream()) {
            byte[] buffer = new byte[8192];
            int read;
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

    private String extractFilename(Part part) {
        String disposition = part.getHeader("content-disposition");
        for (String token : disposition.split(";")) {
            if (token.trim().startsWith("filename")) {
                return token.substring(token.indexOf('=') + 1).trim().replace("\"", "");
            }
        }
        return "unknown";
    }
}
