<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <meta name="description" content="Browse and download shared files from the local network"/>
    <title>Shared Files — LocalDrop</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css"/>
</head>
<body>

<nav class="navbar">
    <a href="${pageContext.request.contextPath}/" class="navbar-brand">
        <span class="nav-logo">📁</span>
        <span class="nav-title">Local<span>Drop</span></span>
    </a>
    <ul class="navbar-nav">
        <li><a href="${pageContext.request.contextPath}/"          class="nav-link">🏠 Dashboard</a></li>
        <li><a href="${pageContext.request.contextPath}/files"     class="nav-link active">📁 Files</a></li>
        <li><a href="${pageContext.request.contextPath}/upload"    class="nav-link">⬆️ Upload</a></li>
        <li><a href="${pageContext.request.contextPath}/transfers" class="nav-link">↔️ Transfers</a></li>
    </ul>
</nav>

<main class="container">
    <div class="page-header">
        <h1 class="page-title">Shared Files</h1>
        <p class="page-subtitle">Browse and download files from the local network</p>
    </div>

    <!-- Alerts -->
    <c:if test="${not empty success}">
        <div class="alert alert-success">✓ ${success}</div>
    </c:if>
    <c:if test="${not empty param.error}">
        <div class="alert alert-error">⚠ ${param.error}</div>
    </c:if>

    <!-- Search + Upload CTA -->
    <div class="search-bar">
        <form action="${pageContext.request.contextPath}/files" method="get" style="display:contents;">
            <input type="text" name="search" class="form-control"
                   placeholder="🔍  Search files by name or type…"
                   value="${searchQuery}"/>
            <button type="submit" class="btn btn-primary">Search</button>
        </form>
        <a href="${pageContext.request.contextPath}/upload" class="btn btn-ghost">⬆️ Upload</a>
    </div>

    <!-- Files Table -->
    <div class="card" style="padding:0;">
        <div class="card-header" style="padding:1.25rem 1.5rem;">
            <h2 class="card-title">
                📂 Files
                <c:if test="${not empty searchQuery}">
                    — Results for "<c:out value="${searchQuery}"/>"
                </c:if>
                <span style="font-size:0.8rem;font-weight:400;color:var(--text-muted);margin-left:8px;">
                    ${files.size()} file(s)
                </span>
            </h2>
            <c:if test="${not empty searchQuery}">
                <a href="${pageContext.request.contextPath}/files" class="btn btn-ghost btn-sm">Clear Search</a>
            </c:if>
        </div>

        <c:choose>
            <c:when test="${empty files}">
                <div style="text-align:center;padding:4rem 2rem;color:var(--text-muted);">
                    <p style="font-size:3rem;margin-bottom:1rem;">📭</p>
                    <p style="font-size:1.1rem;margin-bottom:0.5rem;">
                        <c:choose>
                            <c:when test="${not empty searchQuery}">No files match your search.</c:when>
                            <c:otherwise>No files have been shared yet.</c:otherwise>
                        </c:choose>
                    </p>
                    <a href="${pageContext.request.contextPath}/upload"
                       class="btn btn-primary" style="margin-top:1rem;">
                        ⬆️ Share a File
                    </a>
                </div>
            </c:when>
            <c:otherwise>
                <div class="table-wrapper" style="border:none;border-radius:0 0 20px 20px;">
                    <table>
                        <thead>
                            <tr>
                                <th>File</th>
                                <th>Type</th>
                                <th>Size</th>
                                <th>Downloads</th>
                                <th>Uploaded</th>
                                <th>Hash (SHA-256)</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="f" items="${files}">
                            <tr>
                                <td>
                                    <div style="display:flex;align-items:center;gap:10px;">
                                        <span class="file-icon"
                                              style="background:rgba(79,142,247,0.1);"
                                              id="icon-${f.fileId}">📄</span>
                                        <div>
                                            <div style="font-weight:600;max-width:180px;overflow:hidden;
                                                        text-overflow:ellipsis;white-space:nowrap;"
                                                 title="${f.originalName}">
                                                <c:out value="${f.originalName}"/>
                                            </div>
                                            <div class="text-mono" style="font-size:0.7rem;">ID #${f.fileId}</div>
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    <span class="text-mono" style="font-size:0.78rem;">
                                        <c:out value="${f.fileType}"/>
                                    </span>
                                </td>
                                <td class="text-mono">${f.formattedSize}</td>
                                <td>
                                    <span class="badge badge-success">${f.downloadCount}</span>
                                </td>
                                <td class="text-mono" style="font-size:0.78rem;">
                                    ${f.formattedUploadTime}
                                </td>
                                <td>
                                    <span class="text-mono"
                                          style="font-size:0.7rem;max-width:120px;display:block;
                                                 overflow:hidden;text-overflow:ellipsis;"
                                          title="${f.fileHash}">
                                        ${f.fileHash}
                                    </span>
                                </td>
                                <td>
                                    <div style="display:flex;gap:6px;">
                                        <a href="${pageContext.request.contextPath}/download?id=${f.fileId}"
                                           class="btn btn-success btn-sm" title="Download">
                                            ⬇ Download
                                        </a>
                                        <form action="${pageContext.request.contextPath}/files/delete"
                                              method="post" style="display:inline;"
                                              onsubmit="return confirm('Delete this file?');">
                                            <input type="hidden" name="id" value="${f.fileId}"/>
                                            <button type="submit" class="btn btn-danger btn-sm" title="Delete">✕</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>
            </c:otherwise>
        </c:choose>
    </div>
</main>

<script>
// Assign file-type icons dynamically
function getFileIcon(name) {
    const ext = (name || '').split('.').pop().toLowerCase();
    const m = {
        pdf:'📕',doc:'📝',docx:'📝',txt:'📄',
        jpg:'🖼',jpeg:'🖼',png:'🖼',gif:'🎞',webp:'🖼',svg:'🎨',
        mp4:'🎬',avi:'🎬',mov:'🎬',mkv:'🎬',
        mp3:'🎵',wav:'🎵',flac:'🎵',
        zip:'🗜',rar:'🗜',tar:'🗜',gz:'🗜',
        exe:'⚙',py:'🐍',js:'🟨',java:'☕',ts:'🔷',html:'🌐',json:'📋'
    };
    return m[ext] || '📄';
}

document.querySelectorAll('[id^=icon-]').forEach(el => {
    const row = el.closest('tr');
    const nameEl = row?.querySelector('[title]');
    if (nameEl) el.textContent = getFileIcon(nameEl.getAttribute('title'));
});
</script>

</body>
</html>
