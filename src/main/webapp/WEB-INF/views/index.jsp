<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <meta name="description" content="LocalDrop — High-speed local network file sharing dashboard"/>
    <title>Dashboard — LocalDrop</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css"/>
    <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>📁</text></svg>"/>
</head>
<body>

<!-- ── Navbar ──────────────────────────────────────────── -->
<nav class="navbar">
    <a href="${pageContext.request.contextPath}/" class="navbar-brand">
        <span class="nav-logo">📁</span>
        <span class="nav-title">Local<span>Drop</span></span>
    </a>
    <ul class="navbar-nav">
        <li><a href="${pageContext.request.contextPath}/"       class="nav-link active">🏠 Dashboard</a></li>
        <li><a href="${pageContext.request.contextPath}/files"  class="nav-link">📁 Files</a></li>
        <li><a href="${pageContext.request.contextPath}/upload" class="nav-link">⬆️ Upload</a></li>
        <li><a href="${pageContext.request.contextPath}/transfers" class="nav-link">
            ↔️ Transfers
            <c:if test="${activeCount > 0}"><span class="nav-badge">${activeCount}</span></c:if>
        </a></li>
    </ul>
</nav>

<!-- ── Main Content ────────────────────────────────────── -->
<main class="container">

    <!-- Page header -->
    <div class="page-header">
        <h1 class="page-title">Network Dashboard</h1>
        <p class="page-subtitle">Real-time overview of your local file sharing network</p>
    </div>

    <!-- Error alert -->
    <c:if test="${not empty errorMessage}">
        <div class="alert alert-error">⚠ ${errorMessage}</div>
    </c:if>

    <!-- Stats Grid -->
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon blue">📁</div>
            <div>
                <div class="stat-value">${totalFiles}</div>
                <div class="stat-label">Shared Files</div>
            </div>
        </div>

        <div class="stat-card">
            <div class="stat-icon purple">↔️</div>
            <div>
                <div class="stat-value">${activeTransfers}</div>
                <div class="stat-label">Active Transfers</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon green">💾</div>
            <div>
                <div class="stat-value">${storageBytes}</div>
                <div class="stat-label">Total Storage</div>
            </div>
        </div>
    </div>

    <!-- ── LAN Share Banner ──────────────────────────────────── -->
    <div class="share-banner" style="margin: 1.5rem 0;">
        <div class="share-banner-icon">📡</div>
        <div style="flex:1;min-width:0;">
            <div class="share-banner-title">Share with your local network</div>
            <div class="share-banner-subtitle">
                Anyone on the same Wi‑Fi can open this URL to browse and download files
            </div>
        </div>
        <div class="share-url-group">
            <code id="shareUrl" class="share-url">${lanUrl}</code>
            <button class="btn btn-ghost btn-sm" id="copyBtn" onclick="copyLanUrl()">
                📋 Copy
            </button>
        </div>
    </div>

    <!-- Two column layout -->
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:1.5rem;">

        <!-- Recent Files -->
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">📂 Recent Files</h2>
                <a href="${pageContext.request.contextPath}/files" class="btn btn-ghost btn-sm">View All</a>
            </div>
            <c:choose>
                <c:when test="${empty recentFiles}">
                    <p style="color:var(--text-muted);text-align:center;padding:2rem 0;">
                        No files shared yet.<br/>
                        <a href="${pageContext.request.contextPath}/upload" style="color:var(--accent-blue)">Upload the first file →</a>
                    </p>
                </c:when>
                <c:otherwise>
                    <div class="table-wrapper">
                        <table>
                            <thead>
                                <tr>
                                    <th>Name</th>
                                    <th>Size</th>
                                    <th>Action</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:forEach var="f" items="${recentFiles}">
                                <tr>
                                    <td>
                                        <div style="display:flex;align-items:center;gap:8px;">
                                            <span class="file-icon" style="background:rgba(79,142,247,0.12);">📄</span>
                                            <span style="max-width:150px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;"
                                                  title="${f.originalName}">${f.originalName}</span>
                                        </div>
                                    </td>
                                    <td class="text-mono">${f.formattedSize}</td>
                                    <td>
                                        <a href="${pageContext.request.contextPath}/download?id=${f.fileId}"
                                           class="btn btn-success btn-sm">↓</a>
                                    </td>
                                </tr>
                                </c:forEach>
                            </tbody>
                        </table>
                    </div>
                </c:otherwise>
            </c:choose>
        </div>

        <!-- Recent Transfers -->
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">↔️ Recent Transfers</h2>
                <a href="${pageContext.request.contextPath}/transfers" class="btn btn-ghost btn-sm">View All</a>
            </div>
            <c:choose>
                <c:when test="${empty recentTransfers}">
                    <p style="color:var(--text-muted);text-align:center;padding:2rem 0;">No transfers yet.</p>
                </c:when>
                <c:otherwise>
                    <div class="table-wrapper">
                        <table>
                            <thead>
                                <tr><th>File</th><th>Type</th><th>Status</th></tr>
                            </thead>
                            <tbody>
                                <c:forEach var="t" items="${recentTransfers}">
                                <tr>
                                    <td style="max-width:150px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;"
                                        title="${t.originalName}">${t.originalName}</td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${t.transferType == 'UPLOAD'}">
                                                <span class="badge badge-info">⬆ Upload</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="badge badge-success">⬇ Download</span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${t.status == 'COMPLETED'}">
                                                <span class="badge badge-success">✓ Done</span>
                                            </c:when>
                                            <c:when test="${t.status == 'FAILED'}">
                                                <span class="badge badge-failed">✗ Failed</span>
                                            </c:when>
                                            <c:when test="${t.status == 'IN_PROGRESS'}">
                                                <span class="badge badge-progress">⟳ Active</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="badge badge-pending">${t.status}</span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>
                                </tr>
                                </c:forEach>
                            </tbody>
                        </table>
                    </div>
                </c:otherwise>
            </c:choose>
        </div>
    </div>

    <!-- Quick Actions -->
    <div class="card" style="margin-top:0;">
        <div class="card-header">
            <h2 class="card-title">🚀 Quick Actions</h2>
        </div>
        <div style="display:flex;gap:1rem;flex-wrap:wrap;">
            <a href="${pageContext.request.contextPath}/upload" class="btn btn-primary btn-lg">
                ⬆️ Share a File
            </a>
            <a href="${pageContext.request.contextPath}/files" class="btn btn-ghost btn-lg">
                📂 Browse Files
            </a>
            <a href="${pageContext.request.contextPath}/transfers" class="btn btn-ghost btn-lg">
                ↔️ View Transfers
            </a>
        </div>
    </div>

</main>

<!-- ── Auto-refresh stats every 30s ──────────────────────── -->
<script>
    setTimeout(() => location.reload(), 30000);

    function copyLanUrl() {
        const url = document.getElementById('shareUrl').innerText;
        navigator.clipboard.writeText(url).then(() => {
            const btn = document.getElementById('copyBtn');
            btn.innerText = '✓ Copied';
            btn.style.color = 'var(--success)';
            setTimeout(() => {
                btn.innerText = '📋 Copy';
                btn.style.color = '';
            }, 2000);
        });
    }
</script>

</body>
</html>
