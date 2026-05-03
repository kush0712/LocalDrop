<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <meta name="description" content="Monitor live file transfer progress in the local network"/>
    <title>Transfers — LocalDrop</title>
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
        <li><a href="${pageContext.request.contextPath}/files"     class="nav-link">📁 Files</a></li>
        <li><a href="${pageContext.request.contextPath}/upload"    class="nav-link">⬆️ Upload</a></li>
        <li><a href="${pageContext.request.contextPath}/transfers" class="nav-link active">↔️ Transfers</a></li>
    </ul>
</nav>

<main class="container">
    <div class="page-header" style="display:flex;align-items:flex-start;justify-content:space-between;flex-wrap:wrap;gap:1rem;">
        <div>
            <h1 class="page-title">Transfer Monitor</h1>
            <p class="page-subtitle">
                <span class="spinner"></span>
                &nbsp;Live updates every 3s &nbsp;·&nbsp;
                <strong style="color:var(--accent-cyan);" id="activeCountBadge">${activeCount}</strong> active
            </p>
        </div>
        <div style="display:flex;gap:8px;align-items:center;">
            <span id="liveIndicator"
                  style="display:inline-flex;align-items:center;gap:6px;font-size:0.8rem;color:var(--accent-green);">
                <span style="width:8px;height:8px;border-radius:50%;background:var(--accent-green);
                             animation:pulse-dot 1s infinite;"></span>
                LIVE
            </span>
        </div>
    </div>

    <!-- Alerts -->
    <c:if test="${not empty param.success}">
        <div class="alert alert-success" id="successAlert">✓ ${param.success}</div>
    </c:if>

    <!-- Active Transfers -->
    <div class="card" id="activeCard">
        <div class="card-header">
            <h2 class="card-title">⚡ Active Transfers</h2>
            <span style="font-size:0.8rem;color:var(--text-muted);">Auto-polled every 3 seconds</span>
        </div>
        <div id="activeTableWrap">
            <c:choose>
                <c:when test="${empty active}">
                    <p style="text-align:center;color:var(--text-muted);padding:2rem;">
                        No active transfers. Upload or download a file to see live progress.
                    </p>
                </c:when>
                <c:otherwise>
                    <div class="table-wrapper" style="border:none;">
                        <table>
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>File</th>
                                    <th>Type</th>
                                    <th>Progress</th>
                                    <th>Status</th>
                                    <th>Duration</th>
                                    <th>Action</th>
                                </tr>
                            </thead>
                            <tbody id="activeBody">
                                <c:forEach var="t" items="${active}">
                                <tr id="tr-${t.transferId}">
                                    <td class="text-mono">#${t.transferId}</td>
                                    <td style="max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">
                                        <c:out value="${t.originalName}"/>
                                    </td>
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
                                    <td style="min-width:120px;">
                                        <div class="progress-bar-wrap">
                                            <div class="progress-bar-fill"
                                                 style="width:${t.progressPercent}%"
                                                 id="pg-${t.transferId}"></div>
                                        </div>
                                        <span style="font-size:0.75rem;color:var(--text-secondary);">
                                            <span id="pct-${t.transferId}">${t.progressPercent}</span>%
                                        </span>
                                    </td>
                                    <td><span class="badge badge-progress">⟳ In Progress</span></td>
                                    <td class="text-mono">${t.duration}</td>
                                    <td>
                                        <form action="${pageContext.request.contextPath}/transfers/cancel"
                                              method="post"
                                              onsubmit="return confirm('Cancel this transfer?');">
                                            <input type="hidden" name="id" value="${t.transferId}"/>
                                            <button type="submit" class="btn btn-danger btn-sm">✕ Cancel</button>
                                        </form>
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

    <!-- All Recent Transfers -->
    <div class="card">
        <div class="card-header">
            <h2 class="card-title">📋 Transfer History (Last 50)</h2>
        </div>
        <c:choose>
            <c:when test="${empty transfers}">
                <p style="text-align:center;color:var(--text-muted);padding:2rem;">No transfer history yet.</p>
            </c:when>
            <c:otherwise>
                <div class="table-wrapper" style="border:none;">
                    <table>
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>File</th>
                                <th>Type</th>
                                <th>Size</th>
                                <th>Progress</th>
                                <th>Status</th>
                                <th>Started</th>
                                <th>Duration</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="t" items="${transfers}">
                            <tr>
                                <td class="text-mono">#${t.transferId}</td>
                                <td style="max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;"
                                    title="${t.originalName}">
                                    <c:out value="${t.originalName}"/>
                                </td>
                                <td>
                                    <c:choose>
                                        <c:when test="${t.transferType == 'UPLOAD'}">
                                            <span class="badge badge-info" style="font-size:0.7rem;">⬆ Up</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge badge-success" style="font-size:0.7rem;">⬇ Down</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="text-mono" style="font-size:0.78rem;">${t.fileSize}</td>
                                <td>
                                    <div style="display:flex;align-items:center;gap:8px;">
                                        <div class="progress-bar-wrap" style="min-width:60px;">
                                            <div class="progress-bar-fill"
                                                 style="width:${t.progressPercent}%;
                                                        background:${t.status == 'FAILED' ? 'var(--accent-red)' :
                                                                    t.status == 'CANCELLED' ? 'var(--text-muted)' :
                                                                    'linear-gradient(90deg,var(--accent-blue),var(--accent-cyan))'}">
                                            </div>
                                        </div>
                                        <span style="font-size:0.75rem;color:var(--text-secondary);">${t.progressPercent}%</span>
                                    </div>
                                </td>
                                <td>
                                    <c:choose>
                                        <c:when test="${t.status == 'COMPLETED'}">
                                            <span class="badge badge-success">✓ Done</span>
                                        </c:when>
                                        <c:when test="${t.status == 'FAILED'}">
                                            <span class="badge badge-failed" title="${t.errorMessage}">✗ Failed</span>
                                        </c:when>
                                        <c:when test="${t.status == 'IN_PROGRESS'}">
                                            <span class="badge badge-progress">⟳ Active</span>
                                        </c:when>
                                        <c:when test="${t.status == 'CANCELLED'}">
                                            <span class="badge badge-cancelled">⊘ Cancelled</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge badge-pending">${t.status}</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="text-mono" style="font-size:0.78rem;">
                                    ${t.formattedStartTime}
                                </td>
                                <td class="text-mono" style="font-size:0.78rem;">${t.duration}</td>
                            </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>
            </c:otherwise>
        </c:choose>
    </div>
</main>

<!-- AJAX live polling for active transfers -->
<script>
const CTX = '${pageContext.request.contextPath}';

function pollActive() {
    fetch(CTX + '/transfers?format=json')
        .then(r => r.json())
        .then(data => {
            document.getElementById('activeCountBadge').textContent = data.activeCount || 0;

            // Update progress bars for active transfers
            if (data.active && data.active.length > 0) {
                data.active.forEach(t => {
                    const pg  = document.getElementById('pg-' + t.transferId);
                    const pct = document.getElementById('pct-' + t.transferId);
                    if (pg && t.fileSize > 0) {
                        const p = Math.round(t.bytesTransferred / t.fileSize * 100);
                        pg.style.width = p + '%';
                        if (pct) pct.textContent = p;
                    }
                });
            }
        })
        .catch(() => {
            document.getElementById('liveIndicator').style.color = 'var(--accent-red)';
        });
}

setInterval(pollActive, 3000);

// Auto-dismiss success alert
const sa = document.getElementById('successAlert');
if (sa) setTimeout(() => sa.style.display='none', 5000);
</script>

</body>
</html>
